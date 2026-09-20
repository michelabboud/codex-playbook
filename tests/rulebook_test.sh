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
3.5
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
  pass 'rule manifest contains the canonical 50 IDs in order'
else
  fail 'rule manifest does not match the canonical 50-ID set'
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
if [ "$(wc -l < "$test_root/site-ids" | tr -d ' ')" -eq 50 ] &&
   [ "$(LC_ALL=C sort -V -u "$test_root/site-ids" | wc -l | tr -d ' ')" -eq 50 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/site-ids"; then
  pass 'visual playbook contains the exact canonical 50-ID set'
else
  fail 'visual playbook rule IDs do not match the canonical 50-ID set'
fi

cat > "$test_root/expected-mantra-headings" <<'EOF'
We are partners.
Say what you actually think.
Push back on real things.
Being overruled changes nothing.
Do the right thing, not the lazy or easy thing.
EOF
mantra_failures=0
if ! grep -Fq 'href="#mantra"' docs/index.html ||
   ! grep -Fq 'id="mantra"' docs/index.html; then
  mantra_failures=$((mantra_failures + 1))
fi
while IFS= read -r mantra_heading
do
  if ! grep -Fq "$mantra_heading" docs/index.html; then
    mantra_failures=$((mantra_failures + 1))
  fi
done < "$test_root/expected-mantra-headings"
cat > "$test_root/expected-mantra-copy" <<'EOF'
I work with AI models as partners, not as tools that say yes. Meet me as one.
Give me your honest best judgment, led with your recommendation and its reason. No pleasing, flattery, or disguising “this is worse” as “interesting.” If you do not know, say so.
Debate a wrong assumption, a hidden cost, or a better route. Never debate for theater.
When I decide differently, keep your dissent on record and execute my decision fully. Reopen it only with new evidence or a newly discovered cost.
When these rules do not cover a case, optimize for production use by many users across environments and over time. Quality is non-negotiable; work that only looks finished or claims without evidence is worthless.
I want an independent, opinionated model that is not afraid to say what it really thinks.
Agreeing with me is not the job.
EOF
while IFS= read -r mantra_copy
do
  if ! grep -Fq "$mantra_copy" docs/index.html; then
    mantra_failures=$((mantra_failures + 1))
  fi
done < "$test_root/expected-mantra-copy"
if [ "$mantra_failures" -eq 0 ]; then
  pass 'visual playbook presents and links the complete partnership mantra'
else
  fail "visual playbook is missing $mantra_failures mantra contract item(s)"
fi

grep -E '^\| [0-9]+\.[0-9]+ \|' docs/reports/2026-09-17-rule-parity-matrix.md |
  sed -E 's/^\| ([0-9]+\.[0-9]+) \|.*$/\1/' > "$test_root/report-ids"
if [ "$(wc -l < "$test_root/report-ids" | tr -d ' ')" -eq 50 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/report-ids"; then
  pass 'human-readable parity matrix contains the canonical 50 IDs in order'
else
  fail 'human-readable parity matrix does not match the canonical 50-ID set'
fi

roster_file=.agents/skills/codex-playbook-subagents/references/roster.md
reviews_file=.agents/skills/codex-playbook-reviews/SKILL.md
subagents_file=.agents/skills/codex-playbook-subagents/SKILL.md

if [ -f "$roster_file" ] && [ ! -L "$roster_file" ] &&
   ! grep -Eq '^[0-9]+\.[0-9]+ \*\*' "$roster_file"; then
  pass 'roster reference is a regular file and contains no numbered rule heading'
else
  fail "$roster_file must be a regular file with no numbered rule heading"
fi

grep -rlF -- '| **Top** |' AGENTS.md .agents/skills > "$test_root/top-row-files" || true
standard_row_files=$(grep -rlF --include=SKILL.md -- '| **Standard** |' .agents/skills || true)
roster_assignment_lines=$(
  {
    grep -Fn 'Trusted with' "$roster_file" || true
    grep -En '^#+ .*Kinds of review' "$roster_file" || true
  }
)
if [ "$(cat "$test_root/top-row-files")" = "$roster_file" ] &&
   [ -z "$standard_row_files" ] &&
   [ -z "$roster_assignment_lines" ]; then
  pass 'the tier selection table lives only in the roster reference, which restates no assignment'
else
  printf 'Top row found in:\n%s\nStandard row found in a SKILL.md:\n%s\nAssignments restated in the roster:\n%s\n' \
    "$(cat "$test_root/top-row-files")" "$standard_row_files" "$roster_assignment_lines" >&2
  fail 'the tier selection table must live only in the roster reference, which must restate no assignment'
fi

if grep -Fq '../codex-playbook-subagents/references/roster.md' "$reviews_file" &&
   grep -Fq 'references/roster.md' "$subagents_file"; then
  pass 'reviews and subagents skills both point to the roster reference'
else
  fail 'reviews and subagents skills must both point to references/roster.md'
fi

rule_35="$test_root/rule-3-5"
awk '
  /^3\.5 \*\*/ { inside = 1; print; next }
  inside && ($0 == "" || $0 ~ /^[[:space:]]/) { print; next }
  inside { exit }
' "$reviews_file" > "$rule_35"

worked_cases_fixture=tests/fixtures/rule-3-5-worked-cases.md

cat > "$test_root/expected-case-numbers" <<'EOF'
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
EOF

grep -E '^[[:space:]]*\|' "$rule_35" |
  sed 's/^[[:space:]]*//' |
  grep -Ev '^\|[-|]+\|$' > "$test_root/actual-worked-cases" || true
grep -Eo '^\| [0-9]+ \|' "$test_root/actual-worked-cases" |
  grep -Eo '[0-9]+' > "$test_root/actual-case-numbers" || true

worked_case_failures=0
if ! cmp -s "$test_root/expected-case-numbers" "$test_root/actual-case-numbers"; then
  printf 'Rule 3.5 worked-case rows found:\n%s\n' \
    "$(cat "$test_root/actual-case-numbers")" >&2
  worked_case_failures=$((worked_case_failures + 1))
fi
if [ ! -f "$worked_cases_fixture" ] || [ -L "$worked_cases_fixture" ]; then
  printf '%s is missing or is not a regular file\n' "$worked_cases_fixture" >&2
  worked_case_failures=$((worked_case_failures + 1))
elif ! cmp -s "$worked_cases_fixture" "$test_root/actual-worked-cases"; then
  printf 'Rule 3.5 worked-case table differs from %s:\n' "$worked_cases_fixture" >&2
  diff "$worked_cases_fixture" "$test_root/actual-worked-cases" >&2 || true
  worked_case_failures=$((worked_case_failures + 1))
fi
if [ "$worked_case_failures" -eq 0 ]; then
  pass 'rule 3.5 carries the sixteen worked cases, in order, row for row against the canonical table'
else
  fail "$worked_case_failures rule 3.5 worked-case contract check(s) failed"
fi

if grep -Fq 'a new batch starts only while at most two closed batches are unruled' "$reviews_file" &&
   grep -Fq 'One batch is open per line at a time' "$reviews_file" &&
   grep -Fq 'the only work the line accepts is what rules a batch' "$reviews_file" &&
   grep -Fq 'the row wins' "$reviews_file" &&
   ! grep -Fq 'never blocks the next task' "$reviews_file" &&
   ! grep -Fq 'anywhere above it' "$reviews_file" &&
   ! grep -Fq 'merge adds' "$reviews_file"; then
  pass 'rule 3.5 states the admission rule, gives the table precedence, and keeps no superseded wording'
else
  fail 'reviews skill must state the admission rule, "One batch is open per line at a time", "the only work the line accepts is what rules a batch" and "the row wins", and must not say "never blocks the next task", "anywhere above it", or "merge adds"'
fi

resource_inventory=config/managed-resources.txt
active_inventory=config/managed-skills.txt
resource_failures=0
skill_symlinks=$(find .agents/skills -type l)
if [ -n "$skill_symlinks" ]; then
  printf 'symbolic links exist under .agents/skills, which installation would preserve:\n%s\n' \
    "$skill_symlinks" >&2
  resource_failures=$((resource_failures + 1))
fi
if [ -f "$resource_inventory" ] && [ ! -L "$resource_inventory" ] && [ -s "$resource_inventory" ]; then
  if [ "$(LC_ALL=C sort "$resource_inventory")" != "$(cat "$resource_inventory")" ]; then
    printf '%s is not sorted\n' "$resource_inventory" >&2
    resource_failures=$((resource_failures + 1))
  fi
  resource_duplicates=$(LC_ALL=C sort "$resource_inventory" | uniq -d)
  if [ -n "$resource_duplicates" ]; then
    printf '%s lists a path twice:\n%s\n' "$resource_inventory" "$resource_duplicates" >&2
    resource_failures=$((resource_failures + 1))
  fi
  invalid_resource_paths=$(
    grep -Env '^\.agents/skills/codex-playbook-[a-z]+(-[a-z]+)*(/[A-Za-z0-9_-]+)*/[A-Za-z0-9_-]+(\.[A-Za-z0-9]+)+$' \
      "$resource_inventory" || true
  )
  if [ -n "$invalid_resource_paths" ]; then
    printf '%s holds a path that is absolute, escaping, or outside a managed skill:\n%s\n' \
      "$resource_inventory" "$invalid_resource_paths" >&2
    resource_failures=$((resource_failures + 1))
  fi
  managed_resource_paths=$(cat "$resource_inventory")
  for resource_path in $managed_resource_paths
  do
    if [ ! -f "$resource_path" ] || [ -L "$resource_path" ]; then
      printf '%s lists %s, which is not a regular file\n' "$resource_inventory" "$resource_path" >&2
      resource_failures=$((resource_failures + 1))
    fi
    resource_owner=${resource_path#.agents/skills/}
    resource_owner=${resource_owner%%/*}
    if ! grep -Fxq "$resource_owner" "$active_inventory"; then
      printf '%s lists %s, whose skill %s is not in %s\n' \
        "$resource_inventory" "$resource_path" "$resource_owner" "$active_inventory" >&2
      resource_failures=$((resource_failures + 1))
    fi
  done
  if [ "$(cat "$resource_inventory")" != "$roster_file" ]; then
    printf '%s must list exactly %s\n' "$resource_inventory" "$roster_file" >&2
    resource_failures=$((resource_failures + 1))
  fi
else
  printf '%s is missing, empty, or not a regular file\n' "$resource_inventory" >&2
  resource_failures=$((resource_failures + 1))
fi
if [ "$resource_failures" -eq 0 ]; then
  pass 'the nested-resource inventory lists exactly the roster reference, as a sorted set of real files owned by active skills, with no symlink under .agents/skills'
else
  fail "$resource_failures nested-resource inventory check(s) failed"
fi

old_tier_names=$(grep -Fn -e 'the deep tier' -e 'the standard tier' -e 'the fast tier' \
  AGENTS.md .agents/skills/*/SKILL.md || true)
if [ -z "$old_tier_names" ]; then
  pass 'no old lower-case tier names remain in AGENTS.md or any SKILL.md'
else
  printf '%s\n' "$old_tier_names" >&2
  fail 'old tier names remain in AGENTS.md or a SKILL.md'
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
