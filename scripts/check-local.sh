#!/bin/sh

set -eu

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

Exit status:
  0  every override still matches the playbook text, or there is no local file
  1  at least one override is stale: its quoted words are gone
  2  usage error, an unparsable "Dead words:" line, or a named file that does
     not exist, is not a regular file, or escapes its root
EOF
}

backtick='`'
tab=$(printf '\t')
carriage_return=$(printf '\r')

errors=0
stale=0
checked=0

span_value=''
span_rest=''
resolved_path=''

report_error() {
  printf '%s:%s: error: %s\n' "$local_file" "$1" "$2" >&2
  errors=$((errors + 1))
}

report_stale() {
  printf '%s:%s: stale: `%s` is no longer in %s\n' \
    "$local_file" "$1" "$2" "$3" >&2
  stale=$((stale + 1))
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

# Resolves a file named in an item to a path under one of the two roots.
# Sets resolved_path. Returns 1, having reported why, when the name escapes
# its root or does not name a regular file.
resolve_named_file() {
  resolve_line=$1
  resolve_name=$2

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

# Searches one file for one item's words. Always returns 0: a miss is a
# finding, not a control-flow failure.
check_item() {
  item_line=$1
  item_words=$2
  item_name=$3

  if ! resolve_named_file "$item_line" "$item_name"; then
    return 0
  fi

  # LC_ALL=C makes the comparison byte-wise whatever locale the operator runs
  # in, which is what "as a fixed string" has to mean for text that is UTF-8.
  # -e protects words that begin with a dash; -- protects the path.
  set +e
  LC_ALL=C grep -F -q -e "$item_words" -- "$resolved_path"
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
# is read. Returns 1 when the line does not parse.
parse_dead_words() {
  parse_line=$1
  parse_rest=$2

  while :
  do
    take_code_span "$parse_rest" || return 1
    item_words=$span_value
    parse_rest=$span_rest

    case "$parse_rest" in
      ' (in '*) parse_rest=${parse_rest#' (in '} ;;
      *) return 1 ;;
    esac

    while :
    do
      take_code_span "$parse_rest" || return 1
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
        *) return 1 ;;
      esac
    done

    case "$parse_rest" in
      '') return 0 ;;
      ' · '*) parse_rest=${parse_rest#' · '} ;;
      *) return 1 ;;
    esac
  done
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

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

line_number=0
raw_line=''
while IFS= read -r raw_line || [ -n "$raw_line" ]
do
  line_number=$((line_number + 1))
  raw_line=${raw_line%"$carriage_return"}

  stripped_line=$raw_line
  while :
  do
    case "$stripped_line" in
      ' '*) stripped_line=${stripped_line# } ;;
      "$tab"*) stripped_line=${stripped_line#"$tab"} ;;
      *) break ;;
    esac
  done

  case "$stripped_line" in
    '**Dead words:**'*) ;;
    *) continue ;;
  esac

  item_text=${stripped_line#'**Dead words:**'}
  case "$item_text" in
    ' '*) item_text=${item_text# } ;;
    *)
      report_error "$line_number" \
        'a "Dead words:" line must continue with a space and one quoted phrase'
      continue
      ;;
  esac

  if ! parse_dead_words "$line_number" "$item_text"; then
    report_error "$line_number" \
      'this "Dead words:" line does not parse: expected `words` (in `file`), items separated by " · "'
  fi
done < "$local_file"

if [ "$errors" -ne 0 ]; then
  printf '%s: %s unusable local-layer item(s); nothing was installed.\n' \
    "$local_file" "$errors" >&2
  exit 2
fi

if [ "$stale" -ne 0 ]; then
  printf '%s: %s stale override item(s) of %s checked. Re-read the rule and rewrite the entry.\n' \
    "$local_file" "$stale" "$checked" >&2
  exit 1
fi

printf '%s: %s dead-words item(s) checked; every override still matches the playbook text.\n' \
  "$local_file" "$checked"
