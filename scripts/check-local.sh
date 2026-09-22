#!/bin/sh

# -f disables pathname expansion for the whole run. Every expansion below is
# quoted, so nothing depends on globbing; turning it off means a file name that
# carries a glob character can never be expanded against the current directory
# by a future edit, whatever quoting that edit forgets. A name that carries one
# is refused outright — see resolve_named_file.
set -euf

usage() {
  cat <<'EOF'
Usage: ./scripts/check-local.sh <local-file> <agents-root> <skills-root>

Check every "Dead words:" line of a local layer file against the playbook text
it was written for.

  <local-file>    the user's playbook-local.md; an absent file is not an error
  <agents-root>   the directory holding AGENTS.md
  <skills-root>   the directory holding the skill packages

An item names AGENTS.md, or a path under the skills root such as
codex-playbook-reviews/SKILL.md, and quotes the playbook words the override
replaced. The words are searched as a fixed string.

The grammar of the line, which this script reads left to right over its code
spans and never splits on the separator:

  **Dead words:** `some words` (in `AGENTS.md`) · `other` (in `a/SKILL.md`)

  * optional leading spaces or tabs, then the literal **Dead words:**, then at
    least one space or tab, then the first item;
  * items are separated by " · " (space, U+00B7, space);
  * each item is one code span of the quoted words, then " (in ", then one or
    more code spans naming files joined by ", ", " and " or ", and ", then ")";
  * after the last item, one optional "." and then only blanks;
  * the quoted words are taken verbatim between their backticks -- they may
    contain " · ", parentheses and the word "in" -- and may neither be empty
    nor contain a backtick.

It fails closed. A line carrying the bare marker anywhere other than its start
is an error, never a skipped entry: prose that needs to name the marker puts it
inside a code span. Lines inside a fenced code block are ignored, so a file may
quote this grammar without the example binding anyone; a fence left open at the
end of the file is an error.

An Override entry owes a section verifier: **Anchor:** names one literal Markdown
heading and file, **Rule digest:** gives that normalized section's SHA-256, and
its **Dead words:** quote has at least 16 non-whitespace bytes and occurs exactly
once in that section. Outside a fenced code block, an entry
line is one that -- after any indentation and an optional "- " or "* " bullet --
begins with **Fill, **Add or **Override; a heading is a line beginning with #.
An **Override entry with no valid Dead-words line before the next entry line,
the next heading, or the end of the file is an error**, so a marker spelled any
other way cannot pass as prose and leave the override unchecked. A Dead-words
line with no Override before it is still parsed and searched.

Exit status:
  0  every override still matches the playbook text, or there is no local file
  1  at least one override is stale: its quoted words are gone
  2  usage error, an unparsable verifier or "Dead words:" line, a bare marker that is not
     at the start of its line, an Override with no Dead-words line, an over-long
     line, a UTF-8 BOM, an unclosed fenced code block, a named file that carries a glob
     character, does not exist, is not a regular file, or escapes its root, or a
     local file that exists and cannot be read as a regular file -- including
     one behind a directory that cannot be searched, which is never reported as
     an absent file
EOF
}

# A byte-wise locale for the whole run. It makes the fixed-string search below
# mean the same thing whatever locale the operator is in — which is what "as a
# fixed string" has to mean for text that is UTF-8 — and it makes the line
# bound below a count of bytes in every POSIX shell, rather than bytes in one
# and characters in another.
LC_ALL=C
export LC_ALL

backtick='`'
tab=$(printf '\t')
carriage_return=$(printf '\r')
utf8_bom=$(printf '\357\273\277')
marker='**Dead words:**'
anchor_marker='**Anchor:**'
digest_marker='**Rule digest:**'
separator=' · '

# A local-layer line longer than this, in bytes, is refused rather than
# parsed. The scanner walks a line span by span, so the cost of one line grows
# with the square of its length; the longest line measured in the real local
# files this grammar was written for is 844 bytes, so the bound leaves nearly
# five times that headroom and still bounds the work: measured here, a line of
# 113 items at 3,742 bytes parses in 11 ms, and the same line with every file
# present takes 127 ms, most of it the 113 fixed-string searches themselves.
# Unbounded, the review measured 7.5 s for 3,000 items and 57 s for 12,000.
# A local layer needs no line longer than this; a file that has one is
# refused, loudly, rather than parsed slowly.
max_line_bytes=4096

errors=0
stale=0
checked=0

span_value=''
span_rest=''
resolved_path=''
trim_value=''
parse_stopped_at=''

# Fenced-code-block state while the file is being read.
fence_char=''
fence_length=0
fence_line=0

# The line of an Override entry that is still waiting for its "Dead words:"
# line, or 0 when none is. An Override that never gets one is an error: without
# this, every way of mistyping the marker — lower case, the colon outside the
# bold, no bold at all — read as ordinary prose, and the Override installed with
# nothing checked and "every override still matches" on the console. The window
# closes at the next entry line, the next heading, or the end of the file.
pending_override_line=0
pending_anchor_heading=''
pending_anchor_name=''
pending_anchor_path=''
pending_digest=''
active_anchor_name=''
active_section_file=''

# Every live Override is bound to one Markdown section.  The small private
# directory holds only normalized section text and one quoted phrase while an
# item is being checked; it is never placed beside the local layer or managed
# text.  `mktemp`, `awk`, and one of sha256sum/shasum/openssl are therefore
# prerequisites for an Override (a checker that cannot make the proof refuses
# it rather than silently falling back to a phrase search).
scratch_dir=''
section_file=''
words_file=''

cleanup_scratch() {
  if [ -n "$scratch_dir" ]; then
    rm -rf -- "$scratch_dir"
  fi
}

report_error() {
  printf '%s:%s: error: %s\n' "$local_file" "$1" "$2" >&2
  errors=$((errors + 1))
}

report_stale() {
  printf '%s:%s: stale: `%s` is no longer in %s\n' \
    "$local_file" "$1" "$2" "$3" >&2
  stale=$((stale + 1))
}

# Records where a parse gave up, so the report can point at it. Always
# succeeds: it runs on the failing path, where a non-zero status would be
# taken for the failure itself.
note_stop() {
  parse_stopped_at=$1
}

# Reports an Override whose window has just closed with no valid "Dead words:"
# line in it, and clears the wait. Called at every entry line, every heading,
# and once at the end of the file.
report_pending_override() {
  if [ "$pending_override_line" -ne 0 ]; then
    report_error "$pending_override_line" \
      "this Override entry carries no complete verifier before the next entry, the next heading, or the end of the file: an Override must carry $anchor_marker, $digest_marker, and a valid $marker line"
    pending_override_line=0
    pending_anchor_heading=''
    pending_anchor_name=''
    pending_anchor_path=''
    pending_digest=''
  fi
}

# Removes an optional list bullet from a line already stripped of its leading
# blanks, leaving the result in trim_value. Only the two Markdown bullets an
# entry is ever written with count; a numbered list is not an entry shape here.
strip_list_bullet() {
  case "$1" in
    '- '*) trim_value=${1#'- '} ;;
    '* '*) trim_value=${1#'* '} ;;
    *) trim_value=$1 ;;
  esac
}

# Removes leading, then trailing, spaces and tabs. The result is in
# trim_value, because a function whose result came back through $( ) would
# lose every counter it incremented.
strip_leading_blanks() {
  lead_text=$1
  while :
  do
    case "$lead_text" in
      ' '*) lead_text=${lead_text# } ;;
      "$tab"*) lead_text=${lead_text#"$tab"} ;;
      *) break ;;
    esac
  done
  trim_value=$lead_text
}

strip_trailing_blanks() {
  trail_text=$1
  while :
  do
    case "$trail_text" in
      *' ') trail_text=${trail_text% } ;;
      *"$tab") trail_text=${trail_text%"$tab"} ;;
      *) break ;;
    esac
  done
  trim_value=$trail_text
}

# Reads one code span off the front of its argument. Sets span_value to the
# quoted text and span_rest to what follows the closing backtick. Returns 1
# when the text does not open with a complete, non-empty code span — which is
# also how words containing a backtick are rejected.
take_code_span() {
  take_rest=$1
  case "$take_rest" in
    "$backtick"*) ;;
    *) return 1 ;;
  esac
  take_rest=${take_rest#"$backtick"}
  case "$take_rest" in
    *"$backtick"*) ;;
    *) return 1 ;;
  esac
  span_value=${take_rest%%"$backtick"*}
  span_rest=${take_rest#*"$backtick"}
  [ -n "$span_value" ] || return 1
}

# Does this line, already stripped of its leading blanks, open a fenced code
# block? Sets fence_char, fence_length and fence_line when it does.
fence_opens() {
  fence_open_text=$1
  case "$fence_open_text" in
    '```'*) fence_open_char=$backtick ;;
    '~~~'*) fence_open_char='~' ;;
    *) return 1 ;;
  esac

  fence_open_length=0
  fence_open_rest=$fence_open_text
  while :
  do
    case "$fence_open_rest" in
      "$fence_open_char"*)
        fence_open_length=$((fence_open_length + 1))
        fence_open_rest=${fence_open_rest#"$fence_open_char"}
        ;;
      *) break ;;
    esac
  done

  # A backtick fence's info string may not itself contain a backtick.
  if [ "$fence_open_char" = "$backtick" ]; then
    case "$fence_open_rest" in
      *"$backtick"*) return 1 ;;
    esac
  fi

  fence_char=$fence_open_char
  fence_length=$fence_open_length
  fence_line=$2
}

# Does this line close the open fence? The run must be of the same character,
# at least as long as the opening one, and followed by nothing but blanks.
fence_closes() {
  fence_close_length=0
  fence_close_rest=$1
  while :
  do
    case "$fence_close_rest" in
      "$fence_char"*)
        fence_close_length=$((fence_close_length + 1))
        fence_close_rest=${fence_close_rest#"$fence_char"}
        ;;
      *) break ;;
    esac
  done
  [ "$fence_close_length" -ge "$fence_length" ] || return 1
  strip_trailing_blanks "$fence_close_rest"
  [ -z "$trim_value" ]
}

# Is the bare marker present outside every code span of this line? Complete
# code spans are removed first; an unterminated backtick leaves its text in
# place, so a marker after one still counts — fail closed.
line_has_bare_marker() {
  bare_out=''
  bare_rest=$1
  while :
  do
    case "$bare_rest" in
      *"$backtick"*"$backtick"*)
        bare_out=$bare_out${bare_rest%%"$backtick"*}
        bare_rest=${bare_rest#*"$backtick"}
        bare_rest=${bare_rest#*"$backtick"}
        ;;
      *) break ;;
    esac
  done
  bare_out=$bare_out$bare_rest
  case "$bare_out" in
    *"$marker"*) return 0 ;;
  esac
  return 1
}

# Refuse a Markdown-shaped entry a person could reasonably read as a Fill, Add,
# or Override but that the canonical grammar does not recognize. Code spans are
# removed first, so prose can safely discuss the grammar.
line_has_unrecognized_entry_marker() {
  entry_out=''
  entry_rest=$1
  while :
  do
    case "$entry_rest" in
      *"$backtick"*"$backtick"*)
        entry_out=$entry_out${entry_rest%%"$backtick"*}
        entry_rest=${entry_rest#*"$backtick"}
        entry_rest=${entry_rest#*"$backtick"}
        ;;
      *) break ;;
    esac
  done
  entry_out=$entry_out$entry_rest
  strip_leading_blanks "$entry_out"
  case "$trim_value" in
    [0-9]*.\ \*\*Override*|[0-9]*.\ \*\*Fill*|[0-9]*.\ \*\*Add*|\
    \>\ \*\*Override*|\>\ \*\*Fill*|\>\ \*\*Add*|\
    \#*\ \*\*Override*|\#*\ \*\*Fill*|\#*\ \*\*Add*|\
    \*\*\*Override*|\*\*\*Fill*|\*\*\*Add*) return 0 ;;
  esac
  return 1
}

# Is the absence of this path something we actually observed, or something we
# merely failed to see? POSIX `test` cannot tell the two apart: [ ! -e PATH ] is
# false both when nothing is there and when a directory along the way may not be
# searched. So absence is proved rather than assumed — every directory above the
# leaf is walked from the top, and one that exists but cannot be searched is an
# error, because a local layer may be sitting inside it. Returns 1, having
# reported why, when the absence cannot be proved.
#
# Root may search any directory, so on a root run every -x below is true and
# this walk proves nothing it did not already know. That is correct: root can in
# fact see the file, so a stat that found nothing really did find nothing.
prove_absence() {
  case "$1" in
    /*) absent_at=''; absent_rest=${1#/} ;;
    *) absent_at='.'; absent_rest=$1 ;;
  esac

  # Only the directories above the leaf are walked; the leaf itself is the thing
  # already known not to be there.
  while :
  do
    case "$absent_rest" in
      */*)
        absent_component=${absent_rest%%/*}
        absent_rest=${absent_rest#*/}
        ;;
      *) return 0 ;;
    esac

    # A doubled or trailing slash names the same directory again.
    [ -n "$absent_component" ] || continue
    absent_at="$absent_at/$absent_component"

    if [ -d "$absent_at" ]; then
      if [ ! -x "$absent_at" ]; then
        printf 'ERROR: %s cannot be searched, so whether a local layer exists at %s is unknown; a local layer that cannot be read is never treated as an absent one.\n' \
          "$absent_at" "$1" >&2
        return 1
      fi
      continue
    fi

    if [ -e "$absent_at" ] || [ -L "$absent_at" ]; then
      printf 'ERROR: %s is not a directory, so the local layer at %s cannot be reached.\n' \
        "$absent_at" "$1" >&2
      return 1
    fi

    # Nothing is here, and its own parent was searchable, so this absence was
    # observed: the leaf below it cannot exist either.
    return 0
  done
}

# Resolves a file named in an item to a path under one of the two roots.
# Sets resolved_path. Returns 1, having reported why, when the name escapes
# its root or does not name a regular file.
resolve_named_file() {
  resolve_line=$1
  resolve_name=$2

  # A name is a literal path, never a pattern. Refusing the three glob
  # characters outright keeps the refusal a rule about the name rather than an
  # accident of what happens to be on disk: `SKILL.m?` must be an error whether
  # or not some file matches it, and a file whose real name carries a star is
  # not reachable through this grammar.
  case "$resolve_name" in
    *'*'*|*'?'*|*'['*)
      report_error "$resolve_line" \
        "the named file contains a glob character (one of * ? [), and a name is a literal path: $resolve_name"
      return 1
      ;;
  esac

  case "$resolve_name" in
    /*)
      report_error "$resolve_line" \
        "the named file is an absolute path: $resolve_name"
      return 1
      ;;
  esac
  case "/$resolve_name/" in
    */../*)
      report_error "$resolve_line" \
        "the named file escapes its root with '..': $resolve_name"
      return 1
      ;;
    */./*)
      report_error "$resolve_line" \
        "the named file carries a '.' path component: $resolve_name"
      return 1
      ;;
    *//*)
      report_error "$resolve_line" \
        "the named file carries an empty path component: $resolve_name"
      return 1
      ;;
  esac

  if [ "$resolve_name" = AGENTS.md ]; then
    walk_path=$agents_root
    walk_rest=AGENTS.md
  else
    walk_path=$skills_root
    walk_rest=$resolve_name
  fi

  while [ -n "$walk_rest" ]
  do
    case "$walk_rest" in
      */*)
        walk_component=${walk_rest%%/*}
        walk_rest=${walk_rest#*/}
        ;;
      *)
        walk_component=$walk_rest
        walk_rest=''
        ;;
    esac
    walk_path="$walk_path/$walk_component"
    if [ -L "$walk_path" ]; then
      report_error "$resolve_line" \
        "the named path crosses a symbolic link at $walk_path: $resolve_name"
      return 1
    fi
  done

  if [ ! -f "$walk_path" ]; then
    report_error "$resolve_line" \
      "the named file does not exist or is not a regular file: $resolve_name (sought at $walk_path)"
    return 1
  fi

  resolved_path=$walk_path
}

# Parse `## A section` (in `AGENTS.md`).  The heading is intentionally the
# literal Markdown heading from the managed file: a rule number can be moved or
# repeated, while the bounded section and its digest are the object an Override
# actually relies on.
parse_anchor() {
  anchor_line=$1
  anchor_text=$2
  take_code_span "$anchor_text" || { note_stop "$anchor_text"; return 1; }
  pending_anchor_heading=$span_value
  anchor_text=$span_rest
  case "$pending_anchor_heading" in
    '# '*|'## '*|'### '*|'#### '*|'##### '*|'###### '*) ;;
    *) note_stop "anchor must be a Markdown heading: $pending_anchor_heading"; return 1 ;;
  esac
  case "$anchor_text" in
    ' (in '*) anchor_text=${anchor_text#' (in '} ;;
    *) note_stop "$anchor_text"; return 1 ;;
  esac
  take_code_span "$anchor_text" || { note_stop "$anchor_text"; return 1; }
  pending_anchor_name=$span_value
  anchor_text=$span_rest
  case "$anchor_text" in
    ')') ;;
    *) note_stop "$anchor_text"; return 1 ;;
  esac
  resolve_named_file "$anchor_line" "$pending_anchor_name" || return 1
  pending_anchor_path=$resolved_path

  # An ambiguous heading is not an anchor. Normalize CRLF before counting, as
  # section extraction and digesting do; compare strings, not regular expressions.
  printf '%s\n' "$pending_anchor_heading" > "$scratch_dir/heading"
  set +e
  anchor_count=$(awk '
    NR == FNR { wanted = $0; next }
    { line = $0; sub(/\r$/, "", line); sub(/[ \t]+$/, "", line); if (line == wanted) count++ }
    END { print count + 0 }
  ' "$scratch_dir/heading" "$pending_anchor_path")
  anchor_status=$?
  set -e
  if [ "$anchor_status" -ne 0 ]; then
    note_stop "could not count the anchored heading in $pending_anchor_path"
    return 1
  fi
  if [ "$anchor_count" -ne 1 ]; then
    note_stop "anchored heading must occur exactly once in $pending_anchor_name; found $anchor_count"
    return 1
  fi

  set +e
  awk '
    NR == FNR { wanted = $0; next }
    {
      line = $0
      sub(/\r$/, "", line)
      sub(/[ \t]+$/, "", line)
      plain = line
      sub(/^[ \t]*/, "", plain)
      if (!started && line == wanted) {
        started = 1
        level = 0
        while (substr(plain, level + 1, 1) == "#") level++
      }
      if (started) {
        if (line != wanted && plain ~ /^#+[ \t]/) {
          next_level = 0
          while (substr(plain, next_level + 1, 1) == "#") next_level++
          if (next_level <= level) exit
        }
        print line
      }
    }
    END { if (!started) exit 1 }
  ' "$scratch_dir/heading" "$pending_anchor_path" > "$section_file"
  anchor_status=$?
  set -e
  if [ "$anchor_status" -ne 0 ] || [ ! -s "$section_file" ]; then
    note_stop "could not extract the anchored section from $pending_anchor_name"
    return 1
  fi
  return 0
}

parse_digest() {
  digest_text=$1
  take_code_span "$digest_text" || { note_stop "$digest_text"; return 1; }
  pending_digest=$span_value
  case "$span_rest" in '') ;; *) note_stop "$span_rest"; return 1 ;; esac
  case "$pending_digest" in sha256:*) ;; *) note_stop "expected sha256: followed by 64 lowercase hexadecimal characters"; return 1 ;; esac
  digest_hex=${pending_digest#sha256:}
  case "$digest_hex" in *[!0-9a-f]*|'') note_stop "expected sha256: followed by 64 lowercase hexadecimal characters"; return 1 ;; esac
  [ "${#digest_hex}" -eq 64 ] || { note_stop "expected sha256: followed by 64 lowercase hexadecimal characters"; return 1; }
}

section_digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    computed_digest=$(sha256sum "$section_file" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    computed_digest=$(shasum -a 256 "$section_file" | awk '{print $1}')
  elif command -v openssl >/dev/null 2>&1; then
    computed_digest=$(openssl dgst -sha256 "$section_file" | awk '{print $NF}')
  else
    report_error "$pending_override_line" \
      'cannot calculate the required SHA-256 rule digest (need sha256sum, shasum, or openssl)'
    return 1
  fi
  case "$computed_digest" in *[!0-9a-f]*|'') report_error "$pending_override_line" 'could not calculate a SHA-256 rule digest'; return 1 ;; esac
  [ "${#computed_digest}" -eq 64 ] || { report_error "$pending_override_line" 'could not calculate a SHA-256 rule digest'; return 1; }
  if [ "sha256:$computed_digest" != "$pending_digest" ]; then
    report_stale "$pending_override_line" \
      "section digest $pending_digest (current sha256:$computed_digest)" "$pending_anchor_path"
  fi
}

nonblank_bytes() {
  printf '%s' "$1" | tr -d '[:space:]' | wc -c | tr -d ' '
}

section_occurrences() {
  printf '%s\n' "$1" > "$words_file"
  awk 'NR == FNR { needle = $0; next }
       { rest = $0; while ((at = index(rest, needle)) != 0) { count++; rest = substr(rest, at + 1) } }
       END { print count + 0 }' "$words_file" "$section_file"
}

# Searches one file for one item's words. Always returns 0: a miss is a
# finding, not a control-flow failure.
check_item() {
  item_line=$1
  item_words=$2
  item_name=$3

  if [ -n "$active_anchor_name" ]; then
    if [ "$item_name" != "$active_anchor_name" ]; then
      report_error "$item_line" \
        "an Override's Dead words must name its anchored file $active_anchor_name, not $item_name"
      return 0
    fi
    item_nonblank=$(nonblank_bytes "$item_words")
    if [ "$item_nonblank" -lt 16 ]; then
      report_error "$item_line" \
        "an Override's quoted words have $item_nonblank non-whitespace bytes; the minimum anchor is 16"
      return 0
    fi
    item_occurrences=$(section_occurrences "$item_words")
    checked=$((checked + 1))
    case "$item_occurrences" in
      0) report_stale "$item_line" "$item_words" "$pending_anchor_path" ;;
      1) ;;
      *) report_error "$item_line" \
           "an Override's quoted words occur $item_occurrences times in the anchored section; they must occur exactly once" ;;
    esac
    return 0
  fi

  if ! resolve_named_file "$item_line" "$item_name"; then
    return 0
  fi

  # The run's LC_ALL=C makes this comparison byte-wise. -e protects words that
  # begin with a dash; -- protects the path.
  set +e
  grep -F -q -e "$item_words" -- "$resolved_path"
  grep_status=$?
  set -e

  checked=$((checked + 1))
  case "$grep_status" in
    0) ;;
    1) report_stale "$item_line" "$item_words" "$resolved_path" ;;
    *)
      report_error "$item_line" \
        "could not search $resolved_path (grep exited $grep_status)"
      ;;
  esac
  return 0
}

# Parses the items of one "Dead words:" line, checking each named file as it
# is read. The caller has already stripped the blanks at both ends. Returns 1,
# having noted where it stopped, when the line does not parse.
parse_dead_words() {
  parse_line=$1
  parse_rest=$2

  while :
  do
    take_code_span "$parse_rest" || { note_stop "$parse_rest"; return 1; }
    item_words=$span_value
    parse_rest=$span_rest

    case "$parse_rest" in
      ' (in '*) parse_rest=${parse_rest#' (in '} ;;
      *) note_stop "$parse_rest"; return 1 ;;
    esac

    while :
    do
      take_code_span "$parse_rest" || { note_stop "$parse_rest"; return 1; }
      parse_rest=$span_rest
      check_item "$parse_line" "$item_words" "$span_value"
      case "$parse_rest" in
        ')'*)
          parse_rest=${parse_rest#')'}
          break
          ;;
        ' and '*) parse_rest=${parse_rest#' and '} ;;
        ', and '*) parse_rest=${parse_rest#', and '} ;;
        ', '*) parse_rest=${parse_rest#', '} ;;
        *) note_stop "$parse_rest"; return 1 ;;
      esac
    done

    # One closing "." is allowed after the last item, so an entry may end like
    # a sentence. Anything else is trailing prose, and a line whose tail was
    # not understood is an error, never a half-read entry.
    case "$parse_rest" in
      '') return 0 ;;
      '.') return 0 ;;
      "$separator"*) parse_rest=${parse_rest#"$separator"} ;;
      *) note_stop "$parse_rest"; return 1 ;;
    esac
  done
}

if [ "$#" -eq 1 ]; then
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac
fi

if [ "$#" -ne 3 ]; then
  printf 'ERROR: exactly three arguments are required.\n' >&2
  usage >&2
  exit 2
fi

local_file=$1
agents_root=$2
skills_root=$3

if [ -z "$local_file" ] || [ -z "$agents_root" ] || [ -z "$skills_root" ]; then
  printf 'ERROR: no argument may be empty.\n' >&2
  usage >&2
  exit 2
fi

if [ ! -e "$local_file" ] && [ ! -L "$local_file" ]; then
  prove_absence "$local_file" || exit 2
  printf 'No local layer at %s; nothing is customized.\n' "$local_file"
  exit 0
fi

if [ ! -f "$local_file" ]; then
  printf 'ERROR: the local layer at %s is not a regular file.\n' "$local_file" >&2
  exit 2
fi

if [ ! -r "$local_file" ]; then
  printf 'ERROR: the local layer at %s cannot be read.\n' "$local_file" >&2
  exit 2
fi

# Command substitution and shell variables cannot represent NUL. Scan the
# original byte stream before the read loop so a NUL cannot be erased into an
# apparently valid local layer.
if ! LC_ALL=C tr -d '\000' < "$local_file" | cmp -s "$local_file" -; then
  printf 'ERROR: the local layer at %s contains a NUL byte, or its binary-safety scan failed.\n' "$local_file" >&2
  exit 2
fi

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/codex-playbook-check-local.XXXXXX") || {
  printf 'ERROR: cannot create private scratch space for local-layer verification.\n' >&2
  exit 2
}
section_file=$scratch_dir/section
words_file=$scratch_dir/words
trap cleanup_scratch EXIT HUP INT TERM

line_number=0
raw_line=''
while IFS= read -r raw_line || [ -n "$raw_line" ]
do
  line_number=$((line_number + 1))
  raw_line=${raw_line%"$carriage_return"}

  case "$raw_line" in
    *"$utf8_bom"*)
      report_error "$line_number" 'a UTF-8 BOM in the local layer is not supported; remove it before checking'
      continue
      ;;
  esac

  if [ "${#raw_line}" -gt "$max_line_bytes" ]; then
    report_error "$line_number" \
      "this line is ${#raw_line} bytes long; a local-layer line may not exceed $max_line_bytes bytes"
    continue
  fi

  strip_leading_blanks "$raw_line"
  stripped_line=$trim_value

  # Inside a fenced code block nothing is an entry: a file may quote this
  # grammar without the example being checked, or binding anyone.
  if [ -n "$fence_char" ]; then
    if fence_closes "$stripped_line"; then
      fence_char=''
    fi
    continue
  fi
  if fence_opens "$stripped_line" "$line_number"; then
    continue
  fi

  # These two lines belong only to the Override currently being read.  They
  # are not entry lines themselves, so they do not close its verifier window.
  case "$stripped_line" in
    "$anchor_marker"*)
      if [ "$pending_override_line" -eq 0 ] || [ -n "$pending_anchor_path" ]; then
        report_error "$line_number" "$anchor_marker is valid only once inside the Override it verifies"
        continue
      fi
      anchor_text=${stripped_line#"$anchor_marker"}
      case "$anchor_text" in
        ' '*|"$tab"*) strip_leading_blanks "$anchor_text"; anchor_text=$trim_value ;;
        *) report_error "$line_number" "$anchor_marker must continue with an anchored Markdown heading"; continue ;;
      esac
      if ! parse_anchor "$line_number" "$anchor_text"; then
        report_error "$line_number" "$anchor_marker does not parse: ${parse_stopped_at:-<end of line>}"
      fi
      continue
      ;;
    "$digest_marker"*)
      if [ "$pending_override_line" -eq 0 ] || [ -z "$pending_anchor_path" ] || [ -n "$pending_digest" ]; then
        report_error "$line_number" "$digest_marker is valid once after a valid $anchor_marker inside the Override it verifies"
        continue
      fi
      digest_text=${stripped_line#"$digest_marker"}
      case "$digest_text" in
        ' '*|"$tab"*) strip_leading_blanks "$digest_text"; digest_text=$trim_value ;;
        *) report_error "$line_number" "$digest_marker must continue with a sha256 code span"; continue ;;
      esac
      if ! parse_digest "$digest_text"; then
        report_error "$line_number" "$digest_marker does not parse: ${parse_stopped_at:-<end of line>}"
      fi
      continue
      ;;
  esac

  # An Override's window for its "Dead words:" line closes at the next entry
  # line and at the next heading. Neither line is itself a marker line, so both
  # fall through to the checks below afterwards.
  case "$stripped_line" in
    '#'* )
      report_pending_override
      if line_has_unrecognized_entry_marker "$raw_line"; then
        report_error "$line_number" \
          'looks like a Fill, Add, or Override but is not in the canonical entry shape (optional - or * bullet, then **Override**, **Fill**, or **Add**); refusing a silently ignored entry'
      fi
      ;;
    *)
      strip_list_bullet "$stripped_line"
      case "$trim_value" in
        '**Fill'*|'**Add'*) report_pending_override ;;
        '**Override'*)
          report_pending_override
          pending_override_line=$line_number
          pending_anchor_heading=''
          pending_anchor_name=''
          pending_anchor_path=''
          pending_digest=''
          ;;
      esac
      ;;
  esac

  case "$stripped_line" in
    "$marker"*) ;;
    *)
      # Not an entry. The bare marker anywhere else on the line is an error,
      # never a silently skipped entry; inside a code span it is prose.
      if line_has_unrecognized_entry_marker "$raw_line"; then
        report_error "$line_number" \
          'looks like a Fill, Add, or Override but is not in the canonical entry shape (optional - or * bullet, then **Override**, **Fill**, or **Add**); refusing a silently ignored entry'
      fi
      if line_has_bare_marker "$raw_line"; then
        report_error "$line_number" \
          "the $marker marker is not at the start of this line, so an entry here would be skipped: give the entry a line of its own, or put the marker inside a code span when the line is prose about it"
      fi
      continue
      ;;
  esac

  item_text=${stripped_line#"$marker"}
  case "$item_text" in
    ' '*|"$tab"*) ;;
    *)
      report_error "$line_number" \
        'a "Dead words:" line must continue with a space or a tab and one quoted phrase'
      continue
      ;;
  esac

  strip_leading_blanks "$item_text"
  item_text=$trim_value
  strip_trailing_blanks "$item_text"
  item_text=$trim_value

  if [ -z "$item_text" ]; then
    report_error "$line_number" \
      'a "Dead words:" line must continue with a space or a tab and one quoted phrase'
    continue
  fi

  if [ "$pending_override_line" -ne 0 ] && { [ -z "$pending_anchor_path" ] || [ -z "$pending_digest" ]; }; then
    report_error "$pending_override_line" \
      "this Override's $marker line has no complete verifier: add $anchor_marker and $digest_marker before it"
    continue
  fi

  if [ "$pending_override_line" -ne 0 ]; then
    active_anchor_name=$pending_anchor_name
    active_section_file=$section_file
    section_digest || :
  else
    active_anchor_name=''
    active_section_file=''
  fi

  if ! parse_dead_words "$line_number" "$item_text"; then
    report_error "$line_number" \
      "this \"Dead words:\" line does not parse: expected \`words\` (in \`file\`), items separated by \" · \"; stopped at: ${parse_stopped_at:-<end of line>}"
  else
    # Only a line that parsed satisfies an Override. A line that did not is
    # reported at its own number, and the Override it should have carried is
    # reported at the Override's — one mistake, two places it shows.
    if [ "$pending_override_line" -ne 0 ]; then
      pending_override_line=0
      pending_anchor_heading=''
      pending_anchor_name=''
      pending_anchor_path=''
      pending_digest=''
      active_anchor_name=''
      active_section_file=''
    fi
  fi
done < "$local_file"

if [ -n "$fence_char" ]; then
  report_error "$fence_line" \
    'this fenced code block is never closed, so every line after it was ignored'
fi

report_pending_override

if [ "$errors" -ne 0 ]; then
  # The count of searches goes out on this path too. A refused file has often
  # had some of its items checked — a Dead-words line that parses is searched
  # whether or not another line of the file is unusable — and saying so keeps
  # the refusal honest about how far it got.
  printf '%s: %s unusable local-layer item(s); nothing was installed. %s dead-words item(s) checked before the refusal.\n' \
    "$local_file" "$errors" "$checked" >&2
  exit 2
fi

if [ "$stale" -ne 0 ]; then
  printf '%s: %s of %s dead-words item(s) checked are stale. Re-read the rule and rewrite the entry.\n' \
    "$local_file" "$stale" "$checked" >&2
  exit 1
fi

if [ "$checked" -eq 0 ]; then
  printf '%s: 0 dead-words item(s) checked; the file carries no "Dead words:" entries.\n' \
    "$local_file"
  exit 0
fi

printf '%s: %s dead-words item(s) checked; every override still matches the playbook text.\n' \
  "$local_file" "$checked"
