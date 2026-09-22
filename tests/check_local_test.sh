#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-playbook-check-local-tests.XXXXXX")
check_local="$repo_root/scripts/check-local.sh"
passes=0

cleanup() {
  chmod -R u+w "$test_root" 2>/dev/null || true
  rm -R "$test_root"
}

trap cleanup EXIT HUP INT TERM

pass() {
  passes=$((passes + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1" >&2
  exit 1
}

check_status=0
check_output=''

run_raw_check() {
  set +e
  check_output=$("$check_local" "$@" 2>&1)
  check_status=$?
  set -e
}

# Existing scenarios describe the semantic outcome they care about.  Their
# fixture writer adds the v2 verifier to every canonical Override so those
# scenarios continue to exercise their stated behaviour rather than an old
# syntax.  Dedicated cases below call run_raw_check to prove that an omitted or
# broken verifier is refused.
add_override_verifiers() {
  verifier_file=$1
  verifier_agents=$2
  verifier_skills=$3
  [ -f "$verifier_file" ] || return 0
  grep -Fq '**Override' "$verifier_file" || return 0
  grep -Fq '**Anchor:**' "$verifier_file" && return 0

  verifier_map=$verifier_file.v2-map
  verifier_source=$verifier_agents/AGENTS.md
  verifier_heading=$(sed -n '1p' "$verifier_source")
  verifier_hash=$(sed 's/\r$//; s/[ \t]*$//' "$verifier_source" | sha256sum | awk '{print $1}')
  printf 'AGENTS.md\t%s\t%s\n' "$verifier_heading" "$verifier_hash" > "$verifier_map"
  find "$verifier_skills" -type f -name SKILL.md | while IFS= read -r verifier_source; do
    verifier_name=${verifier_source#"$verifier_skills/"}
    verifier_heading=$(sed -n '1p' "$verifier_source")
    verifier_hash=$(sed 's/\r$//; s/[ \t]*$//' "$verifier_source" | sha256sum | awk '{print $1}')
    printf '%s\t%s\t%s\n' "$verifier_name" "$verifier_heading" "$verifier_hash"
  done >> "$verifier_map"
  awk -F '\t' '
    NR == FNR { anchor[$1] = "  **Anchor:** `" $2 "` (in `" $1 "`)"; digest[$1] = "  **Rule digest:** `sha256:" $3 "`"; next }
    function emit_pending() { if (pending != "") { print pending; pending = "" } }
    {
      line = $0
      if (pending != "") {
        if (line ~ /^[ \t]*\*\*Dead words:\*\*/) {
          name = line
          sub(/^.*\(in `/, "", name)
          sub(/`.*/, "", name)
          print pending
          if (anchor[name] != "") { print anchor[name]; print digest[name] }
          print line
          pending = ""
          next
        }
        if (line ~ /^[ \t]*#|^[ \t]*(- |\* )?\*\*(Fill|Add|Override)/) {
          emit_pending()
        } else {
          pending = pending "\n" line
          next
        }
      }
      if (line ~ /\*\*Override/) { pending = line; next }
      print line
    }
    END { emit_pending() }
  ' "$verifier_map" "$verifier_file" > "$verifier_file.v2"
  mv "$verifier_file.v2" "$verifier_file"
  rm -f -- "$verifier_map"
}

run_check() {
  if [ "$#" -ge 3 ]; then
    add_override_verifiers "$1" "$2" "$3"
  fi
  run_raw_check "$@"
}

assert_status() {
  expected=$1
  label=$2
  if [ "$check_status" -eq "$expected" ]; then
    pass "$label"
  else
    printf 'Expected exit %s, got %s. Output:\n%s\n' \
      "$expected" "$check_status" "$check_output" >&2
    fail "$label"
  fi
}

assert_output_contains() {
  expected=$1
  label=$2
  if printf '%s\n' "$check_output" | grep -Fq -e "$expected"; then
    pass "$label"
  else
    printf 'Output did not contain "%s":\n%s\n' "$expected" "$check_output" >&2
    fail "$label"
  fi
}

assert_output_lacks() {
  unexpected=$1
  label=$2
  if printf '%s\n' "$check_output" | grep -Fq -e "$unexpected"; then
    printf 'Output unexpectedly contained "%s":\n%s\n' "$unexpected" "$check_output" >&2
    fail "$label"
  else
    pass "$label"
  fi
}

# Every case gets its own playbook fixture: a root holding AGENTS.md and a
# separate skills root, exactly the two roots the script is given.
make_case() {
  case_name=$1
  case_root="$test_root/$case_name"
  agents_root="$case_root/playbook"
  skills_root="$case_root/skills"
  local_file="$case_root/playbook-local.md"
  mkdir -p "$agents_root" "$skills_root/codex-playbook-reviews"
  cat > "$agents_root/AGENTS.md" <<'EOF'
# My Global Rules — Codex

This rulebook is version 9.9.9 — source example.
Mechanical review runs on the Standard tier, never the Fast tier.
A literal dot-star .* and a bracket [a-z] live here as text.
A heading like ### 11 · Your platform carries the separator itself.
A backslash \d sequence lives here, as the rulebook's own text does.
EOF
  cat > "$skills_root/codex-playbook-reviews/SKILL.md" <<'EOF'
# 3 · Code reviews

Mechanical review runs on the Standard tier, never the Fast tier.
An option named -n is described here.
EOF
}

run_absent_local_file_test() {
  make_case absent-local-file

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'an absent local file is not an error'
  assert_output_contains 'nothing is customized' \
    'an absent local file says nothing is customized'
  assert_output_contains "$local_file" \
    'an absent local file names the path that was sought'
}

run_fresh_test() {
  make_case fresh
  cat > "$local_file" <<'EOF'
# LOCAL

- **Override — mechanical review.** Whatever I want instead.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `codex-playbook-reviews/SKILL.md`)
- **Override — the version line.** Whatever I want instead.
  **Dead words:** `This rulebook is version` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a fresh local file passes'
  assert_output_lacks 'stale' 'a fresh local file reports nothing stale'
  assert_output_contains ': 2 dead-words item(s) checked' \
    'a fresh local file reports how many items it checked'
}

run_fresh_two_files_in_one_item_test() {
  make_case fresh-two-files
  cat > "$local_file" <<'EOF'
**Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md` and `codex-playbook-reviews/SKILL.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'an item naming two files passes when both still carry the words'
  assert_output_contains ': 2 dead-words item(s) checked' \
    'both files of the item were searched, not just the first'
}

run_stale_test() {
  make_case stale
  cat > "$local_file" <<'EOF'
# LOCAL

- **Override — a rule that was rewritten.** Whatever I want instead.
  **Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'a stale override fails with exit 1'
  assert_output_contains "$local_file:6:" \
    'a stale override is reported as file:line'
  assert_output_contains 'a sentence the playbook no longer carries' \
    'a stale override quotes the words that were sought'
  assert_output_contains "$agents_root/AGENTS.md" \
    'a stale override names where the words were sought'
}

run_stale_one_of_two_files_test() {
  make_case stale-one-of-two
  cat > "$local_file" <<'EOF'
**Dead words:** `An option named -n` (in `codex-playbook-reviews/SKILL.md` and `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'an item is stale when one of its two files lost the words'
  assert_output_contains "$agents_root/AGENTS.md" \
    'the stale report names the file that lost the words'
  assert_output_lacks "$skills_root/codex-playbook-reviews/SKILL.md" \
    'the stale report does not accuse the file that still carries the words'
}

run_leading_dash_words_test() {
  make_case leading-dash
  cat > "$local_file" <<'EOF'
- **Override — words that begin with a dash.** Whatever I want instead.
  **Dead words:** `-n is described here` (in `codex-playbook-reviews/SKILL.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'words beginning with a dash are searched, not read as options'

  cat > "$local_file" <<'EOF'
- **Override — a dash-leading phrase that is gone.** Whatever I want instead.
  **Dead words:** `-n was described here` (in `codex-playbook-reviews/SKILL.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'a missing dash-leading phrase is stale, not an option error'
  assert_output_contains '-n was described here' \
    'the dash-leading phrase is quoted back'
}

run_regex_metacharacter_test() {
  make_case regex-metacharacters
  cat > "$local_file" <<'EOF'
- **Override — literal metacharacters.** Whatever I want instead.
  **Dead words:** `dot-star .* and a bracket [a-z]` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'metacharacters are matched literally when they are present'

  cat > "$local_file" <<'EOF'
- **Override — a regex that would match but a literal that does not.** Whatever.
  **Dead words:** `.*Standard tier.*` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'the search is a fixed string, so a would-be regex match is stale'
}

run_unparsable_tests() {
  make_case unparsable

  cat > "$local_file" <<'EOF'
  **Dead words:** Standard tier (in AGENTS.md)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a Dead words line without code spans is an error'
  assert_output_contains "$local_file:1:" \
    'the unparsable line is reported as file:line'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier`
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a Dead words item with no (in ...) clause is an error'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `AGENTS.md`
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an unclosed (in ...) clause is an error'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `AGENTS.md`) trailing rubbish
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'text after the last item is an error'

  cat > "$local_file" <<'EOF'
  **Dead words:** `` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an empty quoted phrase is an error'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in ``)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an empty file name is an error'
}

run_error_outranks_stale_test() {
  make_case error-outranks-stale
  cat > "$local_file" <<'EOF'
  **Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
  **Dead words:** Standard tier (in AGENTS.md)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an unparsable line outranks a stale one'
}

run_missing_named_file_test() {
  make_case missing-named-file
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-gone/SKILL.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named file that does not exist is an error'
  assert_output_contains 'codex-playbook-gone/SKILL.md' \
    'the missing-file error names the file'
  assert_output_contains 'does not exist or is not a regular file' \
    'the missing-file error says why the file could not be searched'
}

run_named_file_is_not_regular_test() {
  make_case named-file-not-regular
  mkdir -p "$skills_root/codex-playbook-reviews/directory.md"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/directory.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named path that is not a regular file is an error'
}

run_parent_escape_test() {
  make_case parent-escape
  printf 'Standard tier\n' > "$case_root/outside.md"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `../outside.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a name containing .. is refused'
  assert_output_contains '../outside.md' 'the escape error names the offending path'
  assert_output_contains "escapes its root with '..'" \
    'the escape error says the name escaped its root'
}

run_absolute_path_escape_test() {
  make_case absolute-escape
  printf 'Standard tier\n' > "$case_root/outside.md"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `/etc/hostname`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an absolute named path is refused'
  assert_output_contains '/etc/hostname' 'the absolute-path error names the offending path'
  assert_output_contains 'the named file is an absolute path' \
    'the absolute-path error says the name was absolute'
}

run_symlinked_component_escape_test() {
  make_case symlinked-escape
  mkdir -p "$case_root/elsewhere"
  printf 'Standard tier\n' > "$case_root/elsewhere/SKILL.md"
  ln -s "$case_root/elsewhere" "$skills_root/codex-playbook-linked"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-linked/SKILL.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a name whose component is a symbolic link is refused'
  assert_output_contains 'codex-playbook-linked' \
    'the symlink error names the offending component'
  assert_output_contains 'crosses a symbolic link' \
    'the symlink error says the path crossed a symbolic link'
}

run_symlinked_leaf_escape_test() {
  make_case symlinked-leaf
  printf 'Standard tier\n' > "$case_root/outside.md"
  ln -s "$case_root/outside.md" "$skills_root/codex-playbook-reviews/LINK.md"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/LINK.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named file that is itself a symbolic link is refused'
  assert_output_contains 'crosses a symbolic link' \
    'the symlinked-leaf error says the path crossed a symbolic link'
}

run_crlf_test() {
  make_case crlf
  printf '# LOCAL\r\n\r\n  **Dead words:** `Standard tier` (in `AGENTS.md`)\r\n' \
    > "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a local file with CRLF line endings parses and passes'

  printf '  **Dead words:** `a phrase that is gone` (in `AGENTS.md`)\r\n' \
    > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'a CRLF local file still detects a stale override'
  assert_output_contains 'a phrase that is gone' \
    'the CRLF local file quotes its words back'
  assert_output_lacks "$(printf '\r')" \
    'no carriage return survives into the report'
}

run_unterminated_last_line_test() {
  make_case unterminated-last-line
  printf '  **Dead words:** `Standard tier` (in `AGENTS.md`)' > "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a Dead words line with no trailing newline is still read'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the unterminated last line was parsed and its file searched'
}

run_bare_marker_tests() {
  make_case bare-marker

  # The blocking finding of the mechanical review: a marker that is not at the
  # start of its line used to be dropped in silence, so a stale entry written
  # in the natural Markdown shape installed with "every override matches".
  cat > "$local_file" <<'EOF'
# LOCAL

Prose that mentions **Dead words:** in the middle of a sentence is refused.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a bare marker in the middle of a line is an error, not a skipped entry'
  assert_output_contains "$local_file:3:" \
    'the misplaced marker is reported as file:line'
  assert_output_contains 'is not at the start of this line' \
    'the misplaced-marker error says why the line was refused'

  cat > "$local_file" <<'EOF'
- **Override — rule 9.1.** **Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a bullet-led entry whose marker follows prose is an error, never a stale entry that installs'
  assert_output_lacks 'every override still matches' \
    'a refused file never reports that every override matches'

  printf '> **Dead words:** `Standard tier` (in `AGENTS.md`)\n' > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a blockquoted marker is an error'

  cat > "$local_file" <<'EOF'
# LOCAL

Prose that names the `**Dead words:**` marker inside a code span is prose.

- **Fill — something.** A value, with no dead words at all.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'the marker inside a code span is prose and is ignored'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'a file of prose about the marker checks nothing'
  assert_output_contains 'no "Dead words:" entries' \
    'a file with no entries says so instead of claiming every override matches'
  assert_output_lacks 'every override still matches' \
    'zero items checked is never reported as every override matching'

  printf '**Dead words** `no colon, so not the marker` (in `AGENTS.md`)\n' \
    > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a bolded phrase without the colon is not the marker'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'a phrase that is not the marker is checked as nothing'
}

run_fenced_block_tests() {
  make_case fenced-block

  cat > "$local_file" <<'EOF'
# LOCAL

Here is the grammar, shown but not meant:

```markdown
**Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
**Dead words:** this line would not parse either
- **Override — rule 9.1.** **Dead words:** `mid-line` (in `AGENTS.md`)
```

- **Fill — something.** A value of my own.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'every line of a fenced code block is ignored, stale and malformed alike'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'a fenced example is shown, never checked'

  cat > "$local_file" <<'EOF'
~~~
**Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
~~~
  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a tilde fence opens and closes a block too'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the entry after a closed fence is still checked'

  cat > "$local_file" <<'EOF'
````
```
**Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
```
````
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a shorter run of the fence character does not close a longer fence'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'the nested example stays inside the longer fence'

  cat > "$local_file" <<'EOF'
```
**Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a fenced code block left open at the end of the file is an error'
  assert_output_contains "$local_file:1:" \
    'the unclosed fence is reported at the line that opened it'
  assert_output_contains 'never closed' \
    'the unclosed-fence error says the block was never closed'
}

run_line_length_bound_test() {
  make_case line-length

  bound_bytes=4096
  long_words=$(awk 'BEGIN { while (i++ < 4096) printf "x" }')

  printf '%s\n' "$long_words" > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a line exactly at the bound is read'

  printf 'x%s\n' "$long_words" > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a line longer than the bound is refused, not parsed'
  assert_output_contains "may not exceed $bound_bytes bytes" \
    'the over-long-line error states the bound it enforces'
  assert_output_contains "$local_file:1:" \
    'the over-long line is reported as file:line'

  printf '  **Dead words:** `%s` (in `AGENTS.md`)\n' "$long_words" > "$local_file"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an over-long Dead words line is refused before it is parsed'
}

run_indented_marker_test() {
  make_case indented-marker
  printf '\t**Dead words:** `Standard tier` (in `AGENTS.md`)\n' > "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'the marker is recognized after leading blanks'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the indented item was parsed and its file searched'
}

run_multiple_stale_items_test() {
  make_case multiple-stale
  cat > "$local_file" <<'EOF'
  **Dead words:** `gone one` (in `AGENTS.md`)
  **Dead words:** `gone two` (in `codex-playbook-reviews/SKILL.md`) · `gone three` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'several stale items still exit 1'
  assert_output_contains 'gone one' 'the first stale item is reported'
  assert_output_contains 'gone two' 'the second stale item is reported'
  assert_output_contains 'gone three' 'the third stale item is reported'
  assert_output_contains "$local_file:2:" 'each stale item carries its own line number'
}

run_usage_tests() {
  make_case usage

  run_check
  assert_status 2 'no arguments is a usage error'

  run_check "$local_file"
  assert_status 2 'one argument is a usage error'

  run_check "$local_file" "$agents_root" "$skills_root" extra
  assert_status 2 'a fourth argument is a usage error'

  run_check "$local_file" '' "$skills_root"
  assert_status 2 'an empty root argument is a usage error'
}

run_local_file_not_regular_test() {
  make_case local-file-not-regular
  mkdir -p "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a local path that is not a regular file is an error'
  assert_output_contains 'is not a regular file' \
    'a local path that is a directory says it is not a regular file'
}

run_dangling_local_symlink_test() {
  make_case dangling-local-symlink
  ln -s "$case_root/never-created.md" "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a dangling local-file symlink is an error, not an absent file'
}

run_unreadable_local_file_test() {
  if [ "$(id -u)" = 0 ]; then
    pass 'an unreadable local file is an error (skipped: running as root, which can read anything)'
    return 0
  fi

  make_case unreadable-local-file
  cat > "$local_file" <<'EOF'
  **Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
EOF
  chmod 000 "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a local file that exists and cannot be read is an error, never an absent file'
  assert_output_contains 'cannot be read' \
    'the unreadable-local-file error says the file could not be read'
  assert_output_lacks 'nothing is customized' \
    'an unreadable local file is never reported as nothing being customized'
  chmod 644 "$local_file"
}

# The fail-open the sibling edition's mechanical review found: POSIX test cannot
# tell "the file is not there" from "I cannot look", because [ ! -e FILE ] is
# false for both. A local layer inside a directory nobody may search used to be
# reported as no local layer at all.
run_unsearchable_ancestor_test() {
  if [ "$(id -u)" = 0 ]; then
    pass 'a local file behind an unsearchable directory is an error (skipped: running as root, which may search anything)'
    return 0
  fi

  make_case unsearchable-ancestor
  mkdir -p "$case_root/closed"
  cat > "$case_root/closed/playbook-local.md" <<'EOF'
  **Dead words:** `a sentence the playbook no longer carries` (in `AGENTS.md`)
EOF
  chmod 000 "$case_root/closed"

  run_check "$case_root/closed/playbook-local.md" "$agents_root" "$skills_root"
  chmod 755 "$case_root/closed"
  assert_status 2 'a local file inside a directory that cannot be searched is an error, not an absent file'
  assert_output_contains 'cannot be searched' \
    'the unsearchable-ancestor error says the directory could not be searched'
  assert_output_lacks 'nothing is customized' \
    'an unsearchable ancestor is never reported as nothing being customized'
}

run_absent_local_file_behind_searchable_parent_test() {
  make_case absent-behind-searchable-parent
  mkdir -p "$case_root/open"

  run_check "$case_root/open/playbook-local.md" "$agents_root" "$skills_root"
  assert_status 0 'a genuinely absent local file inside a searchable directory is still not an error'
  assert_output_contains 'nothing is customized' \
    'a genuinely absent local file still says nothing is customized'

  run_check "$case_root/never-made/playbook-local.md" "$agents_root" "$skills_root"
  assert_status 0 'an absent local file whose whole directory is absent is still not an error'
}

run_symlinked_local_file_test() {
  make_case symlinked-local-file
  cat > "$case_root/real-local.md" <<'EOF'
  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
EOF
  ln -s "$case_root/real-local.md" "$local_file"

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a symbolic link to a readable regular file is read, for the dotfile managers'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the symlinked local file was parsed and its file searched'
}

# An Override with no Dead-words line used to exit 0 having searched nothing, so
# every mistyped marker — **dead words:**, **Dead words**:, Dead words: — was a
# silent pass. The Override's window closes at the next entry line, the next
# heading, or the end of the file.
run_override_owes_dead_words_tests() {
  make_case override-owes-dead-words

  cat > "$local_file" <<'EOF'
# LOCAL

- **Override — mechanical review.** Whatever I want instead.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'case 1: an Override followed by a valid Dead-words line parses normally'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'case 1: the Override was satisfied and its words searched'

  cat > "$local_file" <<'EOF'
# LOCAL

- **Override — mechanical review.** Whatever I want instead.
  **dead words:** `Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'case 2: an Override whose marker is mistyped in lower case is an error'
  assert_output_contains "$local_file:3:" \
    'case 2: the unsatisfied Override is reported at its own line, not the mistyped one'
  assert_output_contains 'no complete verifier' \
    'case 2: the error says the Override carries no complete verifier'
  assert_output_lacks 'every override still matches' \
    'case 2: a mistyped marker never reports that every override matches'

  cat > "$local_file" <<'EOF'
# LOCAL

- **Override — mechanical review.** Whatever I want instead.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'case 3: an Override with nothing after it at all is an error'
  assert_output_contains "$local_file:3:" \
    'case 3: the Override at the end of the file is reported at its own line'

  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Whatever I want instead.

## A later section

  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'case 4: a heading closes the Override window, so the later Dead-words line belongs to nothing'
  assert_output_contains "$local_file:1:" \
    'case 4: the Override before the heading is reported at its own line'
  assert_output_contains '1 dead-words item(s) checked' \
    'case 4: a Dead-words line with no Override before it is still parsed and searched'

  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Whatever I want instead.
- **Fill — something else.** A value of my own.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'case 5: the next entry line closes the Override window'
  assert_output_contains "$local_file:1:" \
    'case 5: the Override whose window a Fill closed is reported at its own line'

  cat > "$local_file" <<'EOF'
# LOCAL

```markdown
- **Override — shown, never in force.** Whatever I want instead.
```
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'case 6: an Override inside a fenced code block owes nothing, because it is not an entry'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'case 6: the fenced Override is shown, never checked'

  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Whatever I want instead.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `AGENTS.md`)
- **Override — the version line.** Whatever I want instead.
  **Dead words:** `This rulebook is version` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'two Overrides each carrying its own Dead-words line are both fine'
  assert_output_contains ': 2 dead-words item(s) checked' \
    'both Overrides were satisfied and both sets of words searched'

  cat > "$local_file" <<'EOF'
# LOCAL

- **Fill — whose rules these are.** Mine.
- **Add — a rule the playbook lacks.** This one.

## L1 · My own additions

* **Fill — a starred bullet is a bullet too.** A value.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a Fill or an Add owes no Dead-words line'
  assert_output_contains ': 0 dead-words item(s) checked' \
    'a file of Fills and Adds checks nothing and is still fresh'

  cat > "$local_file" <<'EOF'
**Override — an Override needs no bullet to be an entry.** Whatever I want.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an Override with no list bullet is an entry line too'

  cat > "$local_file" <<'EOF'
* **Override — a starred bullet is a bullet too.** Whatever I want.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an Override behind a star bullet is an entry line too'

  cat > "$local_file" <<'EOF'
Prose that names an **Override** in the middle of a sentence is prose, and owes
nothing at all.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'the word Override in the middle of a line is not an entry'
}

# The quoted words are one string, taken verbatim between their backticks. An
# implementation that split them on " · " would search a prefix of what the
# entry actually quoted — and a prefix is found far more often than the whole,
# so the check would pass while the sentence it guards had been rewritten.
run_separator_inside_words_tests() {
  make_case separator-inside-words

  cat > "$local_file" <<'EOF'
  **Dead words:** `### 11 · Your platform carries the separator` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a quoted phrase containing the item separator is searched whole and found whole'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the phrase containing the separator is one item, not two'

  # The part before the separator is present; the part after it is not. Only an
  # implementation that searches the whole phrase calls this stale.
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier · a phrase that is gone` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'a phrase whose part after the separator is gone is stale, though its prefix is still there'
  assert_output_contains 'Standard tier · a phrase that is gone' \
    'the stale report quotes the whole phrase back, separator included'
}

# A backslash in the quoted words is part of the words. Reading the local file
# without read -r would consume it, and the search would then look for a phrase
# the entry never wrote.
run_backslash_in_words_test() {
  make_case backslash-in-words
  cat > "$local_file" <<'EOF'
  **Dead words:** `backslash \d sequence` (in `AGENTS.md`)
EOF

  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a backslash inside the quoted words survives into the search'
  assert_output_contains ': 1 dead-words item(s) checked' \
    'the phrase carrying a backslash was searched, not mangled'
}

# The bare marker after a complete code span on the same line still counts: the
# line is prose with an entry buried in it, and burying one is the failure the
# fail-closed rule exists to catch. Neither line below is an entry line, so the
# refusal can only come from the marker check.
run_marker_after_code_span_test() {
  make_case marker-after-code-span

  # After the LAST code span of the line. This is the case that needs the text
  # trailing the final span to be looked at: a scanner that only examined the
  # text between spans would find nothing here and pass the line as prose.
  cat > "$local_file" <<'EOF'
Prose about `a code span` and then **Dead words:** with no code span after it.
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a bare marker after the last code span of a line is still an error'
  assert_output_contains 'is not at the start of this line' \
    'the marker trailing a code span is reported as a misplaced marker'
  assert_output_lacks 'no "Dead words:" entries' \
    'a line whose marker trails a code span is never reported as a file with no entries'

  # And between two of them, which the scan reaches by another path.
  cat > "$local_file" <<'EOF'
Prose about `a code span` and then **Dead words:** `Standard tier` (in `AGENTS.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a bare marker between two code spans is an error'
  assert_output_contains 'is not at the start of this line' \
    'the marker between code spans is reported as a misplaced marker'
}

# grep says 0 for found, 1 for not found, and 2 or more for "I could not look".
# Reading the third as the second would report a searchable-but-unreadable
# playbook file as a fresh override.
run_unsearchable_named_file_test() {
  if [ "$(id -u)" = 0 ]; then
    pass 'a named file that cannot be searched is an error (skipped: running as root, which can read anything)'
    return 0
  fi

  make_case unsearchable-named-file
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL.md`)
EOF
  chmod 000 "$skills_root/codex-playbook-reviews/SKILL.md"

  run_check "$local_file" "$agents_root" "$skills_root"
  chmod 644 "$skills_root/codex-playbook-reviews/SKILL.md"
  assert_status 2 'a named file that exists but cannot be searched is an error, never a match'
  assert_output_contains 'could not search' \
    'the failed search says it could not search the file'
  assert_output_lacks 'every override still matches' \
    'a search that never happened is never reported as an override that matches'
}

run_glob_in_named_file_tests() {
  make_case glob-in-named-file

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/*.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named file containing * is an error'
  assert_output_contains 'glob character' \
    'the glob error says the name carried a glob character'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL.m?`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named file containing ? is an error'
  assert_output_contains 'glob character' \
    'the ? error says the name carried a glob character'

  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL[.]md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a named file containing [ is an error'
  assert_output_contains 'glob character' \
    'the [ error says the name carried a glob character'

  # The refusal must be the rule, not an accident of what happens to be on
  # disk: a file whose real name carries a star is still refused.
  printf 'Standard tier\n' > "$skills_root/codex-playbook-reviews/star*.md"
  cat > "$local_file" <<'EOF'
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/star*.md`)
EOF
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a name carrying a glob character is refused even when a file of exactly that name exists'
  assert_output_contains 'glob character' \
    'the refusal is the rule about the name, not a report that the file is missing'
}

# The conformance vectors are shared with claude-code-playbook, byte for byte:
# one grammar, two implementations, one file that says what it is. The hash is
# pinned here so an edit on either side is a failing test rather than a quiet
# divergence. A vector that looks wrong is a conversation with the other
# edition, never an edit to this fixture.
vectors_file="$repo_root/tests/fixtures/dead-words-vectors.tsv"
vectors_sha=644a4eb1215d06e7486f4b1b256098109d51b428c3130357c56d688e1c8d5765
vectors_expected_count=47
tab=$(printf '\t')

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | sed 's/.*= *//'
  else
    printf 'no-sha256-command-found'
  fi
}

# Replaces every occurrence of a token, leaving the result in replaced_value.
# The shell has no ${var//pattern/text}, and a sed subshell would have to
# escape a file name that may contain a slash.
replaced_value=''
replace_token() {
  replace_out=''
  replace_rest=$1
  while :
  do
    case "$replace_rest" in
      *"$2"*)
        replace_out=$replace_out${replace_rest%%"$2"*}$3
        replace_rest=${replace_rest#*"$2"}
        ;;
      *) break ;;
    esac
  done
  replaced_value=$replace_out$replace_rest
}

# How many fixed-string searches the run reported. Every summary line carries
# the same "<N> dead-words item(s) checked" token, whatever the outcome was.
searches_made() {
  printf '%s\n' "$check_output" |
    awk '{ for (i = 1; i <= NF; i++) if ($i == "dead-words") { print $(i - 1); exit } }'
}

run_shared_vectors_test() {
  make_case shared-vectors

  vectors_actual_sha=$(sha256_of "$vectors_file")
  if [ "$vectors_actual_sha" = "$vectors_sha" ]; then
    pass 'the shared conformance vectors are byte-identical to the file both editions carry'
  else
    printf 'Expected sha256 %s, got %s for %s\n' \
      "$vectors_sha" "$vectors_actual_sha" "$vectors_file" >&2
    fail 'the shared conformance vectors are byte-identical to the file both editions carry'
  fi

  vector_number=0
  vector_line_number=0
  while IFS= read -r vector_line || [ -n "$vector_line" ]
  do
    vector_line_number=$((vector_line_number + 1))
    case "$vector_line" in
      '#'*|'') continue ;;
    esac

    vector_expectation=${vector_line%%"$tab"*}
    vector_text=${vector_line#*"$tab"}
    replace_token "$vector_text" '@F1@' 'AGENTS.md'
    vector_text=$replaced_value
    replace_token "$vector_text" '@F2@' 'codex-playbook-reviews/SKILL.md'
    vector_text=$replaced_value

    printf '%s\n' "$vector_text" > "$local_file"
    run_check "$local_file" "$agents_root" "$skills_root"
    vector_searches=$(searches_made)
    vector_number=$((vector_number + 1))
    vector_label="shared vector $vector_number (line $vector_line_number, $vector_expectation)"

    case "$vector_expectation" in
      'ok '*)
        vector_want=${vector_expectation#ok }
        if [ "$check_status" -gt 1 ]; then
          printf 'Vector expected to parse exited %s. Line: %s\nOutput:\n%s\n' \
            "$check_status" "$vector_text" "$check_output" >&2
          fail "$vector_label"
        elif [ "$vector_searches" != "$vector_want" ]; then
          printf 'Vector expected %s search(es), made %s. Line: %s\nOutput:\n%s\n' \
            "$vector_want" "${vector_searches:-none reported}" "$vector_text" \
            "$check_output" >&2
          fail "$vector_label"
        else
          pass "$vector_label"
        fi
        ;;
      error)
        if [ "$check_status" -eq 2 ]; then
          pass "$vector_label"
        else
          printf 'Vector expected exit 2, got %s. Line: %s\nOutput:\n%s\n' \
            "$check_status" "$vector_text" "$check_output" >&2
          fail "$vector_label"
        fi
        ;;
      ignore)
        if [ "$check_status" -eq 0 ] && [ "$vector_searches" = 0 ]; then
          pass "$vector_label"
        else
          printf 'Vector expected exit 0 with no search, got exit %s and %s search(es). Line: %s\nOutput:\n%s\n' \
            "$check_status" "${vector_searches:-none reported}" "$vector_text" \
            "$check_output" >&2
          fail "$vector_label"
        fi
        ;;
      *)
        printf 'Unknown expectation "%s" on line %s of %s\n' \
          "$vector_expectation" "$vector_line_number" "$vectors_file" >&2
        fail "$vector_label"
        ;;
    esac
  done < "$vectors_file"

  if [ "$vector_number" -eq "$vectors_expected_count" ]; then
    pass "all $vectors_expected_count shared vectors ran"
  else
    printf 'Ran %s vectors, expected %s\n' \
      "$vector_number" "$vectors_expected_count" >&2
    fail "all $vectors_expected_count shared vectors ran"
  fi
}

run_fail_open_boundary_tests() {
  make_case fail-open-boundaries

  printf '**Override — binary words.**\n**Dead words:** `prefix\000suffix` (in `AGENTS.md`)\n' \
    > "$local_file"
  printf 'prefixsuffix\n' > "$agents_root/AGENTS.md"
  run_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a NUL byte in a local file is refused'
  assert_output_contains 'NUL' 'a NUL refusal says why'

  help_root="$case_root/help-path"
  mkdir -p "$help_root"
  printf 'anything\n' > "$help_root/-h"
  set +e
  (cd "$help_root" && "$check_local" -h "$agents_root" "$skills_root") > "$case_root/help.out" 2>&1
  check_status=$?
  set -e
  assert_status 2 'a local file literally named -h is not parsed as help'

  for shape in numbered blockquote heading italicbold
  do
    case "$shape" in
      numbered)   entry='1. **Override — numbered list.**' ;;
      blockquote) entry='> **Override — block quote.**' ;;
      heading)    entry='## **Override — heading.**' ;;
      italicbold) entry='***Override — italic bold.***' ;;
    esac
    printf '%s\n' "$entry" > "$local_file"
    run_check "$local_file" "$agents_root" "$skills_root"
    assert_status 2 "an unrecognized $shape Override is refused"
  done
}

run_section_anchor_tests() {
  make_case section-anchor
  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Keep the local constraint.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `codex-playbook-reviews/SKILL.md`)
EOF
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an Override without a section anchor and digest is refused'
  assert_output_contains 'no complete verifier' 'the missing verifier refusal explains the required proof'

  add_override_verifiers "$local_file" "$agents_root" "$skills_root"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'a unique sixteen-byte quote with a matching section digest passes'

  printf 'A harmless editorial change.\n' >> "$skills_root/codex-playbook-reviews/SKILL.md"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 1 'a rewritten anchored section makes an Override stale'

  make_case section-anchor-duplicate
  printf 'Mechanical review runs on the Standard tier, again.\n' >> "$skills_root/codex-playbook-reviews/SKILL.md"
  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Keep the local constraint.
  **Dead words:** `Mechanical review runs on the Standard tier` (in `codex-playbook-reviews/SKILL.md`)
EOF
  add_override_verifiers "$local_file" "$agents_root" "$skills_root"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a quote that occurs twice inside its anchored section is refused'
  assert_output_contains 'must occur exactly once' 'the duplicate quote refusal names the uniqueness rule'

  make_case section-anchor-short
  cat > "$local_file" <<'EOF'
- **Override — mechanical review.** Keep the local constraint.
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL.md`)
EOF
  add_override_verifiers "$local_file" "$agents_root" "$skills_root"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a quote shorter than sixteen non-whitespace bytes is refused'
  assert_output_contains 'minimum anchor is 16' 'the short quote refusal names the minimum'

  make_case section-anchor-overlap
  printf '# Repeat\n%s\n' 'aaaaaaaaaaaaaaaaa' > "$agents_root/AGENTS.md"
  printf '%s\n' '- **Override — overlapping quote.** Keep the local constraint.' \
    '  **Dead words:** `aaaaaaaaaaaaaaaa` (in `AGENTS.md`)' > "$local_file"
  add_override_verifiers "$local_file" "$agents_root" "$skills_root"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'overlapping copies of a quoted anchor are not unique'
  assert_output_contains 'must occur exactly once' 'overlapping quote refusal explains ambiguity'

  make_case section-anchor-crlf
  printf '# CRLF heading\r\nUnique quoted words in this section.\r\n' > "$agents_root/AGENTS.md"
  crlf_digest=$(sed 's/\r$//; s/[ \t]*$//' "$agents_root/AGENTS.md" | sha256sum | awk '{print $1}')
  {
    printf '%s\n' '- **Override — CRLF heading.** Keep the local constraint.' \
      '  **Anchor:** `# CRLF heading` (in `AGENTS.md`)'
    printf '  **Rule digest:** `sha256:%s`\n' "$crlf_digest"
    printf '%s\n' '  **Dead words:** `Unique quoted words in this section.` (in `AGENTS.md`)'
  } > "$local_file"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 0 'an anchored managed heading with CRLF is normalized before counting'
}

run_bom_entry_test() {
  make_case bom-entry
  printf '\357\273\277**Override — hidden entry.** Keep the local constraint.\n' > "$local_file"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'a BOM-prefixed entry cannot be silently ignored'
  assert_output_contains 'BOM' 'BOM refusal explains the invalid leading bytes'

  printf 'A normal line.\n  \357\273\277**Override — hidden entry.** Keep the local constraint.\n' > "$local_file"
  run_raw_check "$local_file" "$agents_root" "$skills_root"
  assert_status 2 'an indented BOM on a later entry line cannot hide that entry'
}

run_absent_local_file_test
run_fresh_test
run_fresh_two_files_in_one_item_test
run_stale_test
run_stale_one_of_two_files_test
run_leading_dash_words_test
run_regex_metacharacter_test
run_unparsable_tests
run_error_outranks_stale_test
run_missing_named_file_test
run_named_file_is_not_regular_test
run_parent_escape_test
run_absolute_path_escape_test
run_symlinked_component_escape_test
run_symlinked_leaf_escape_test
run_crlf_test
run_unterminated_last_line_test
run_bare_marker_tests
run_fenced_block_tests
run_line_length_bound_test
run_indented_marker_test
run_multiple_stale_items_test
run_usage_tests
run_local_file_not_regular_test
run_dangling_local_symlink_test
run_unreadable_local_file_test
run_unsearchable_ancestor_test
run_absent_local_file_behind_searchable_parent_test
run_symlinked_local_file_test
run_override_owes_dead_words_tests
run_separator_inside_words_tests
run_backslash_in_words_test
run_marker_after_code_span_test
run_unsearchable_named_file_test
run_glob_in_named_file_tests
run_shared_vectors_test
run_fail_open_boundary_tests
run_section_anchor_tests
run_bom_entry_test

printf '\nAll %s local-layer staleness assertions passed.\n' "$passes"
