#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-playbook-rulebook-tests.XXXXXX")
trap 'rm -R "$test_root"' EXIT HUP INT TERM
failures=0
passes=0

pass() {
  passes=$((passes + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1" >&2
}

cat > "$test_root/expected-ids" <<'EOF'
0.1
0.2
0.3
0.4
1.1
1.2
1.3
1.4
1.5
1.6
2.1
2.2
2.3
3.1
3.2
3.3
3.4
4.1
4.2
4.3
5.1
5.2
5.3
6.1
6.2
6.3
6.4
7.1
7.2
7.3
7.4
7.5
7.6
7.7
8.1
9.1
9.2
9.3
9.4
9.5
9.6
10.1
10.2
10.3
11.1
12.1
12.2
12.3
12.4
EOF

agents_bytes=$(wc -c < AGENTS.md | tr -d ' ')
if [ "$agents_bytes" -le 12288 ]; then
  pass "AGENTS.md is a lean router ($agents_bytes bytes; limit 12288)"
else
  fail "AGENTS.md exceeds the 12288-byte router budget ($agents_bytes bytes)"
fi

grep -Eho '^[0-9]+\.[0-9]+ \*\*' AGENTS.md |
  sed 's/ \*\*$//' > "$test_root/agents-ids"
cat > "$test_root/expected-core-ids" <<'EOF'
0.1
0.2
0.3
0.4
EOF
if cmp -s "$test_root/expected-core-ids" "$test_root/agents-ids"; then
  pass 'AGENTS.md contains only critical rule bodies 0.1-0.4'
else
  fail 'AGENTS.md must contain exactly critical rule bodies 0.1-0.4'
fi

managed_count=$(wc -l < config/managed-skills.txt | tr -d ' ')
managed_unique=$(LC_ALL=C sort -u config/managed-skills.txt | wc -l | tr -d ' ')
if [ "$managed_count" -eq 16 ] &&
   [ "$managed_unique" -eq 16 ] &&
   [ "$(LC_ALL=C sort config/managed-skills.txt)" = "$(cat config/managed-skills.txt)" ] &&
   ! grep -Evq '^codex-playbook-[a-z]+(-[a-z]+)*$' config/managed-skills.txt; then
  pass 'managed skill inventory is sorted, valid, unique, and contains 16 skills'
else
  fail 'managed skill inventory must be sorted, valid, unique, and contain 16 skills'
fi

metadata_chars=0
while IFS= read -r skill_name
do
  skill_file=".agents/skills/$skill_name/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    fail "$skill_file is missing"
    continue
  fi
  if grep -Fxq "name: $skill_name" "$skill_file" &&
     [ "$(grep -Ec '^description: .+' "$skill_file")" -eq 1 ]; then
    pass "$skill_file metadata matches its directory"
  else
    fail "$skill_file metadata is invalid"
  fi
  router_mentions=$(
    sed -n '/^## Mandatory Skill Router$/,/^## Codex Loading Model$/p' AGENTS.md |
      grep -Foc "$skill_name" || true
  )
  if [ "$router_mentions" -eq 1 ]; then
    pass "$skill_name appears exactly once in the mandatory router"
  else
    fail "$skill_name appears $router_mentions times in the mandatory router"
  fi
  description=$(sed -n 's/^description: //p' "$skill_file")
  metadata_chars=$((metadata_chars + ${#skill_name} + ${#description}))
done < config/managed-skills.txt

actual_skill_count=$(find .agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md -path '*/codex-playbook-*/*' | wc -l | tr -d ' ')
if [ "$actual_skill_count" -eq 16 ]; then
  pass 'the repository contains all and only 16 Codex Playbook skills'
else
  fail "the repository contains $actual_skill_count Codex Playbook skills; expected 16"
fi

if [ "$metadata_chars" -le 8000 ]; then
  pass "skill discovery metadata stays within 8000 characters ($metadata_chars)"
else
  fail "skill discovery metadata exceeds 8000 characters ($metadata_chars)"
fi

manifest_ids="$test_root/manifest-ids"
cut -f1 config/rule-manifest.tsv > "$manifest_ids"
if cmp -s "$test_root/expected-ids" "$manifest_ids"; then
  pass 'rule manifest contains the canonical 49 IDs in order'
else
  fail 'rule manifest does not match the canonical 49-ID set'
fi

occurrences="$test_root/rule-occurrences"
: > "$occurrences"
for owner_file in AGENTS.md .agents/skills/codex-playbook-*/SKILL.md
do
  grep -En '^[0-9]+\.[0-9]+ \*\*' "$owner_file" 2>/dev/null |
  while IFS=: read -r line_number rule_text
  do
    rule_id=$(printf '%s\n' "$rule_text" | sed 's/ \*\*.*$//')
    printf '%s\t%s\t%s\n' "$rule_id" "$owner_file" "$line_number"
  done >> "$occurrences"
done

cut -f1 "$occurrences" | LC_ALL=C sort -V -u > "$test_root/actual-ids"
if cmp -s "$test_root/expected-ids" "$test_root/actual-ids"; then
  pass 'rule headings contain no missing or unknown IDs'
else
  fail 'rule headings contain a missing or unknown ID'
fi

ownership_failures=0
tab=$(printf '\t')
while IFS="$tab" read -r rule_id owner_pattern
do
  expected_matches=1
  [ "$rule_id" != '11.1' ] || expected_matches=3
  actual_matches=0
  while IFS="$tab" read -r occurrence_id occurrence_file occurrence_line
  do
    [ "$occurrence_id" = "$rule_id" ] || continue
    owner_allowed=0
    for allowed_file in $owner_pattern
    do
      [ "$occurrence_file" != "$allowed_file" ] || owner_allowed=1
    done
    if [ "$owner_allowed" -ne 1 ]; then
      printf 'Unexpected owner for rule %s: %s:%s\n'         "$rule_id" "$occurrence_file" "$occurrence_line" >&2
      ownership_failures=$((ownership_failures + 1))
    fi
    actual_matches=$((actual_matches + 1))
  done < "$occurrences"
  if [ "$actual_matches" -ne "$expected_matches" ]; then
    printf 'Rule %s has %s heading(s); expected %s\n'       "$rule_id" "$actual_matches" "$expected_matches" >&2
    ownership_failures=$((ownership_failures + 1))
  fi
done < config/rule-manifest.tsv

if [ "$ownership_failures" -eq 0 ]; then
  pass 'all rule headings are unique and in their declared owners; 11.1 has three platform implementations'
else
  fail "$ownership_failures rule ownership checks failed"
fi

grep -Eo '"[0-9]+\.[0-9]+",' docs/index.html |
  sed -e 's/^"//' -e 's/",$//' > "$test_root/site-ids"
if [ "$(wc -l < "$test_root/site-ids" | tr -d ' ')" -eq 49 ] &&
   [ "$(LC_ALL=C sort -V -u "$test_root/site-ids" | wc -l | tr -d ' ')" -eq 49 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/site-ids"; then
  pass 'visual playbook contains the exact canonical 49-ID set'
else
  fail 'visual playbook rule IDs do not match the canonical 49-ID set'
fi

grep -E '^\| [0-9]+\.[0-9]+ \|' docs/reports/2026-09-17-rule-parity-matrix.md |
  sed -E 's/^\| ([0-9]+\.[0-9]+) \|.*$/\1/' > "$test_root/report-ids"
if [ "$(wc -l < "$test_root/report-ids" | tr -d ' ')" -eq 49 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/report-ids"; then
  pass 'human-readable parity matrix contains the canonical 49 IDs in order'
else
  fail 'human-readable parity matrix does not match the canonical 49-ID set'
fi

if grep -Fq 'Linux or WSL' .agents/skills/codex-playbook-platform-linux/SKILL.md &&
   grep -Fq 'only when running on macOS' .agents/skills/codex-playbook-platform-macos/SKILL.md &&
   grep -Fq 'only when running on native Windows' .agents/skills/codex-playbook-platform-windows/SKILL.md; then
  pass 'platform skill triggers are explicit and mutually exclusive'
else
  fail 'platform skill triggers must distinguish Linux or WSL, macOS, and native Windows'
fi

if [ "$failures" -ne 0 ]; then
  printf '\n%s rulebook verification check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll %s rulebook verification checks passed.\n' "$passes"
