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
13.1
13.2
13.3
13.4
13.5
13.6
14.1
14.2
14.3
14.4
14.5
14.6
14.7
14.8
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
if [ "$managed_count" -eq 20 ] &&
   [ "$managed_unique" -eq 20 ] &&
   [ "$(LC_ALL=C sort config/managed-skills.txt)" = "$(cat config/managed-skills.txt)" ] &&
   ! grep -Evq '^codex-playbook-[a-z]+(-[a-z]+)*$' config/managed-skills.txt; then
  pass 'managed skill inventory is sorted, valid, unique, and contains 20 skills'
else
  fail 'managed skill inventory must be sorted, valid, unique, and contain 20 skills'
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
      grep -Fwoc "$skill_name" || true
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
if [ "$actual_skill_count" -eq 20 ]; then
  pass 'the repository contains all and only 20 Codex Playbook skills'
else
  fail "the repository contains $actual_skill_count Codex Playbook skills; expected 20"
fi

if [ "$metadata_chars" -le 8000 ]; then
  pass "skill discovery metadata stays within 8000 characters ($metadata_chars)"
else
  fail "skill discovery metadata exceeds 8000 characters ($metadata_chars)"
fi

manifest_ids="$test_root/manifest-ids"
cut -f1 config/rule-manifest.tsv > "$manifest_ids"
if cmp -s "$test_root/expected-ids" "$manifest_ids"; then
  pass 'rule manifest contains the canonical 64 IDs in order'
else
  fail 'rule manifest does not match the canonical 64-ID set'
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
if [ "$(wc -l < "$test_root/site-ids" | tr -d ' ')" -eq 64 ] &&
   [ "$(LC_ALL=C sort -V -u "$test_root/site-ids" | wc -l | tr -d ' ')" -eq 64 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/site-ids"; then
  pass 'visual playbook contains the exact canonical 64-ID set'
else
  fail 'visual playbook rule IDs do not match the canonical 64-ID set'
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
if [ "$(wc -l < "$test_root/report-ids" | tr -d ' ')" -eq 64 ] &&
   cmp -s "$test_root/expected-ids" "$test_root/report-ids"; then
  pass 'human-readable parity matrix contains the canonical 64 IDs in order'
else
  fail 'human-readable parity matrix does not match the canonical 64-ID set'
fi

roster_file=.agents/skills/codex-playbook-subagents/references/roster.md
dev_mode_policy_file=.agents/skills/codex-playbook-dev-mode/agents/openai.yaml
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
17
18
19
20
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
  pass 'rule 3.5 carries the twenty worked cases, in order, row for row against the canonical table'
else
  fail "$worked_case_failures rule 3.5 worked-case contract check(s) failed"
fi

required_rule_35_failures=
while IFS= read -r sentence
do
  if ! grep -Fq "$sentence" "$rule_35"; then
    if [ -n "$required_rule_35_failures" ]; then
      required_rule_35_failures="$required_rule_35_failures; "
    fi
    required_rule_35_failures="${required_rule_35_failures}rule 3.5 itself is missing: \"$sentence\""
  fi
done <<'EOF'
a line carries at most three unruled batches, the open one included
One batch is open per line at a time
Every landing belongs to the line's open batch
opens an **ad-hoc batch**
Only closed work merges between lines
What this rule does not name is resolved toward review
the only work the line accepts is what rules a batch
the row wins
EOF
if [ -z "$required_rule_35_failures" ]; then
  pass 'rule 3.5 itself states the ceiling as one invariant, admits every landing to the open batch (ad-hoc where no plan covers it), merges only closed work, resolves the unnamed toward review, and gives the table precedence'
else
  fail "$required_rule_35_failures"
fi

forbidden_reviews_failures=
while IFS= read -r sentence
do
  matches=$(grep -nF "$sentence" "$reviews_file" || true)
  if [ -n "$matches" ]; then
    locations=$(
      printf '%s\n' "$matches" |
        awk -F: -v file="$reviews_file" '{ printf "%s%s:%s", separator, file, $1; separator = ", " }'
    )
    if [ -n "$forbidden_reviews_failures" ]; then
      forbidden_reviews_failures="$forbidden_reviews_failures; "
    fi
    forbidden_reviews_failures="${forbidden_reviews_failures}superseded sentence \"$sentence\" found at $locations"
  fi
done <<'EOF'
never blocks the next task
anywhere above it
merge adds
a new batch starts only while at most two closed batches are unruled
Nothing lands on a line outside a batch
ceiling of two
EOF
if [ -z "$forbidden_reviews_failures" ]; then
  pass 'the reviews skill contains none of the six superseded sentences of rules 3.1, 3.3 and 3.5'
else
  fail "the reviews skill contains one or more of the six superseded sentences of rules 3.1, 3.3 and 3.5: $forbidden_reviews_failures"
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
for skill_tree in .agents .agents/skills
do
  if [ -L "$skill_tree" ] || [ ! -d "$skill_tree" ]; then
    printf '%s must be a real directory: a symbolic link there is an ancestor of every scan root\n' \
      "$skill_tree" >&2
    resource_failures=$((resource_failures + 1))
  fi
done
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
  : > "$test_root/actual-resources"
  while IFS= read -r skill_name
  do
    if [ -d ".agents/skills/$skill_name" ]; then
      find ".agents/skills/$skill_name" -type f ! -path ".agents/skills/$skill_name/SKILL.md" \
        >> "$test_root/actual-resources"
    fi
  done < "$active_inventory"
  LC_ALL=C sort "$test_root/actual-resources" > "$test_root/actual-resources-sorted"
  if ! cmp -s "$resource_inventory" "$test_root/actual-resources-sorted"; then
    printf '%s does not match every file shipped inside active skills:\n' "$resource_inventory" >&2
    diff "$resource_inventory" "$test_root/actual-resources-sorted" >&2 || true
    resource_failures=$((resource_failures + 1))
  fi
  cat > "$test_root/expected-resources" <<'EOF'
.agents/skills/codex-playbook-build-dashboard/agents/openai.yaml
.agents/skills/codex-playbook-build-dashboard/assets/dashboard.html
.agents/skills/codex-playbook-build-dashboard/scripts/dashboard.py
.agents/skills/codex-playbook-build-dashboard/scripts/test_dashboard.py
.agents/skills/codex-playbook-dev-mode/agents/openai.yaml
.agents/skills/codex-playbook-subagents/references/roster.md
EOF
  if ! cmp -s "$resource_inventory" "$test_root/expected-resources"; then
    printf '%s must list exactly the dashboard resources, dev-mode policy, and roster reference\n' \
      "$resource_inventory" >&2
    resource_failures=$((resource_failures + 1))
  fi
else
  printf '%s is missing, empty, or not a regular file\n' "$resource_inventory" >&2
  resource_failures=$((resource_failures + 1))
fi
if [ "$resource_failures" -eq 0 ]; then
  pass 'the nested-resource inventory lists exactly every dashboard resource, the dev-mode invocation policy, and the roster reference, as a sorted set of real files owned by active skills, with no symlink under .agents/skills and neither .agents nor .agents/skills a symbolic link itself'
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

local_layer_pointer='*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*'

agents_local_failures=0
while IFS= read -r required_sentence
do
  sentence_count=$(grep -Fc -e "$required_sentence" AGENTS.md || true)
  if [ "$sentence_count" -ne 1 ]; then
    printf 'AGENTS.md states "%s" %s time(s); expected exactly 1\n' \
      "$required_sentence" "$sentence_count" >&2
    agents_local_failures=$((agents_local_failures + 1))
  fi
done <<'EOF'
**The local layer:**
`${CODEX_HOME:-$HOME/.codex}/playbook-local.md`
The playbook never ships it
never create, write to, copy over, move, or delete it
they read it only to check it against the managed text they would install
Read it at the start of a session when it exists
A **Fill** supplies only a value a rule leaves open
An **Add** supplies non-authorizing guidance or a stricter constraint
under `L1`, `L2`, and onward
An **Override** changes one named rule
A local entry may never expand authority, weaken the destructive-action gate, relax a safety, destructive, security, or secret-handling constraint, change precedence, or override this paragraph
Its authority comes only from this paragraph and never extends beyond it
A stale Override is **suspended**: tell me before relying on it
if its scope or freshness is unclear, do not rely on it, apply the stricter constraint, and hold the affected action for my direction
An absent file means nothing is customized
EOF
while IFS= read -r superseded_sentence
do
  superseded_count=$(grep -Fc -e "$superseded_sentence" AGENTS.md || true)
  if [ "$superseded_count" -ne 0 ]; then
    printf 'AGENTS.md still states the superseded "%s"\n' "$superseded_sentence" >&2
    agents_local_failures=$((agents_local_failures + 1))
  fi
done <<'EOF'
Never replace tailored rules without the backup and approval procedure
never opens
without opening
never touches it
EOF
if grep -Fq -e "$local_layer_pointer" AGENTS.md; then
  printf 'AGENTS.md carries the per-skill pointer line, which belongs only in a SKILL.md\n' >&2
  agents_local_failures=$((agents_local_failures + 1))
fi
if [ "$agents_local_failures" -eq 0 ]; then
  pass 'AGENTS.md limits the local layer to safe tailoring, staleness suspension, and stricter handling under ambiguity'
else
  fail "$agents_local_failures AGENTS.md local-layer wording check(s) failed"
fi

pointer_failures=0
while IFS= read -r skill_name
do
  skill_file=".agents/skills/$skill_name/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    printf '%s is missing\n' "$skill_file" >&2
    pointer_failures=$((pointer_failures + 1))
    continue
  fi
  pointer_count=$(grep -Fc -e "$local_layer_pointer" "$skill_file" || true)
  if [ "$pointer_count" -ne 1 ]; then
    printf '%s carries the local-layer pointer %s time(s); expected exactly 1\n' \
      "$skill_file" "$pointer_count" >&2
    pointer_failures=$((pointer_failures + 1))
  fi
  first_body_line=$(
    awk '/^# / { heading = 1; next } heading && $0 != "" { print; exit }' "$skill_file"
  )
  if [ "$first_body_line" != "$local_layer_pointer" ]; then
    printf '%s opens its body with "%s" instead of the local-layer pointer\n' \
      "$skill_file" "$first_body_line" >&2
    pointer_failures=$((pointer_failures + 1))
  fi
done < config/managed-skills.txt
if [ "$pointer_failures" -eq 0 ]; then
  pass 'every skill on the managed inventory opens its body with the one local-layer pointer line'
else
  fail "$pointer_failures local-layer pointer check(s) failed"
fi

# "The playbook never opens the local file" was untrue: scripts/check-local.sh
# reads it, which is the whole point of the check. The honest claim is that the
# playbook never ships it and no script writes to it, and that the installer
# reads it only to check it. These phrases are swept out of every file the
# public reads. History is excluded — an ADR, a review, or a dated report
# records what was written at the time and is never edited (a superseding
# record is how that gets corrected).
# A claim is what the text says in its own voice; a citation is the same words
# inside a code span or a fenced code block, which is how a changelog entry, a
# contributing note or a lane report names the wording it is retiring or quotes
# the output that exposed it. So the phrase is sought only outside both — the same
# convention the Dead-words grammar itself uses for prose about its marker — while
# the line's subject may be named anywhere on the line, backticks included,
# because a path is nearly always written in a code span.
untrue_contact_claims=$(
  find . -path './.git' -prune \
    -o -path './docs/adr' -prune \
    -o -path './docs/reviews' -prune \
    -o -path './docs/reports' -prune \
    -o -path './docs/handoffs' -prune \
    -o -path './docs/plans' -prune \
    -o -path './tests/rulebook_test.sh' -prune \
    -o -type f \( -name '*.md' -o -name '*.html' -o -name '*.sh' \) \
    -exec awk '
      FNR == 1 { fenced = 0 }
      /^[ \t]*(```|~~~)/ { fenced = !fenced; next }
      fenced { next }
      {
        bare = $0
        gsub(/`[^`]*`/, "", bare)
        if (bare ~ /never open|without opening/) {
          print FILENAME ":" FNR ": " $0
          next
        }
        if (bare ~ /never touch/ &&
            $0 ~ /playbook-local|local layer|local file/) {
          print FILENAME ":" FNR ": " $0
        }
      }
    ' {} +
)
if [ -z "$untrue_contact_claims" ]; then
  pass 'no public file claims the playbook never opens or never touches the local layer; the scripts do read it, to check it'
else
  printf '%s\n' "$untrue_contact_claims" >&2
  fail 'a public file still claims the playbook never opens or never touches the local layer'
fi

template_failures=0
template_check_failed=0
local_template=templates/playbook-local.md
if [ ! -f "$local_template" ] || [ -L "$local_template" ]; then
  printf '%s is missing or is not a regular file\n' "$local_template" >&2
  template_failures=$((template_failures + 1))
else
  if grep -Fq 'templates/' config/managed-skills.txt config/retired-skills.txt \
      config/managed-resources.txt; then
    printf 'an installer inventory names templates/, which the installer must never install\n' >&2
    template_failures=$((template_failures + 1))
  fi
  # A template ships with no live entry. Its examples sit inside a fenced code
  # block, which the checker ignores, so a reader who copies the file whole is
  # bound by nothing and the checker searches for nothing.
  template_check=$(./scripts/check-local.sh "$local_template" . .agents/skills 2>&1) ||
    template_check_failed=1
  if [ "${template_check_failed:-0}" -ne 0 ]; then
    printf '%s does not pass the staleness check against this checkout\n' "$local_template" >&2
    printf '%s\n' "$template_check" >&2
    template_failures=$((template_failures + 1))
  fi
  if ! printf '%s\n' "$template_check" | grep -Fq '0 dead-words item(s) checked'; then
    printf '%s carries a live Dead-words entry; the template must check nothing:\n%s\n' \
      "$local_template" "$template_check" >&2
    template_failures=$((template_failures + 1))
  fi
  # A template ships no live entry at all, not merely no live Dead-words line.
  # An entry line is what scripts/check-local.sh calls one: after any
  # indentation and an optional "- " or "* " bullet, it begins with **Fill,
  # **Add or **Override. A template that writes *about* the kinds in that shape
  # would be carrying entries, and an Override among them would refuse the
  # install — so the shape itself is what this asserts, not just the marker.
  unfenced_entries=$(
    awk '/^[ \t]*(```|~~~)/ { fenced = !fenced; next } !fenced { print }' \
      "$local_template" |
      grep -cE '^[ \t]*(- |\* )?\*\*(Dead words:\*\*|Fill|Add|Override)' || true
  )
  if [ "$unfenced_entries" -ne 0 ]; then
    printf '%s carries %s entry line(s) outside a fenced code block; a template ships none\n' \
      "$local_template" "$unfenced_entries" >&2
    awk '/^[ \t]*(```|~~~)/ { fenced = !fenced; next } !fenced { print FNR ": " $0 }' \
      "$local_template" |
      grep -E ': [ \t]*(- |\* )?\*\*(Dead words:\*\*|Fill|Add|Override)' >&2 || true
    template_failures=$((template_failures + 1))
  fi
fi
if [ "$template_failures" -eq 0 ]; then
  pass 'the local-layer template exists outside every installer inventory, carries no live entry, and checks nothing as shipped'
else
  fail "$template_failures local-layer template check(s) failed"
fi

# Port of source 0.1.20-0.1.21: refusal, worktrees, hygiene, economy mode.
if [ "$(grep -Fc -- '**Two destructive laws hold before any skill loads.**' AGENTS.md)" -eq 1 ]; then
  pass 'the router carries the destructive laws that hold before any skill loads'
else
  fail 'the router carries the destructive laws that hold before any skill loads'
fi
if [ "$(grep -Fc -- 'never re-issue the same effect in another form' AGENTS.md)" -eq 1 ]; then
  pass 'the router forbids re-spelling a refused destructive command'
else
  fail 'the router forbids re-spelling a refused destructive command'
fi
if [ "$(grep -Fc -- 'never `--force` and never by deleting the folder' AGENTS.md)" -eq 1 ]; then
  pass 'the router removes worktrees only through git'
else
  fail 'the router removes worktrees only through git'
fi
if [ "$(grep -Fc -- '| 13.1–13.6 | `codex-playbook-hygiene` |' AGENTS.md)" -eq 1 ]; then
  pass 'the router routes cleanup to the hygiene skill'
else
  fail 'the router routes cleanup to the hygiene skill'
fi
if [ "$(grep -Fc -- '**A blocked command is a stop, not a spelling problem.**' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 says a blocked command is a stop'
else
  fail 'rule 10.1 says a blocked command is a stop'
fi
if [ "$(grep -Fc -- 'When a guard, the sandbox, an approval policy, a permission rule or a hook refuses' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 counts a sandbox or approval-policy refusal'
else
  fail 'rule 10.1 counts a sandbox or approval-policy refusal'
fi
if [ "$(grep -Fc -- '`rm -r` for a refused `rm -rf logs/`' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 names same-effect examples'
else
  fail 'rule 10.1 names same-effect examples'
fi
if [ "$(grep -Fc -- '— the one sanctioned move), or ask me.' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 names quarantine as the one sanctioned move'
else
  fail 'rule 10.1 names quarantine as the one sanctioned move'
fi
if [ "$(grep -Fc -- '**Cleanup follows section 13: load `codex-playbook-hygiene` before any cleanup**' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.2 sends cleanup to section 13'
else
  fail 'rule 10.2 sends cleanup to section 13'
fi
if [ "$(grep -Fc -- 'or `git worktree remove --force`, is a destructive act under rule 10.1' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.2 keeps the worktree law'
else
  fail 'rule 10.2 keeps the worktree law'
fi
if [ "$(grep -Fc -- 'run the hygiene procedure (`codex-playbook-hygiene`, section 13)' .agents/skills/codex-playbook-workflow/SKILL.md)" -eq 1 ]; then
  pass 'the close-out hygiene checkpoint runs section 13'
else
  fail 'the close-out hygiene checkpoint runs section 13'
fi
if [ "$(grep -Fc -- 'the most protective one applies: protected, then evidence, then unknown, then the rest' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 resolves overlapping classes to the most protective'
else
  fail '13.1 resolves overlapping classes to the most protective'
fi
if [ "$(grep -Fc -- 'or a `.gitignore` entry never decides it' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 never lets a name or ignore rule decide'
else
  fail '13.1 never lets a name or ignore rule decide'
fi
if [ "$(grep -Fc -- '| **Disposable, created by this session** |' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 limits the session row to disposable items'
else
  fail '13.1 limits the session row to disposable items'
fi
if [ "$(grep -Fc -- 'debug dumps a document refers to | keep; compress rotated logs (rule 9.4)' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 keeps evidence'
else
  fail '13.1 keeps evidence'
fi
if [ "$(grep -Fc -- 'anything I created | only on my word (rule 10.2) |' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 leaves protected items to the owner'
else
  fail '13.1 leaves protected items to the owner'
fi
if [ "$(grep -Fc -- 'which the quarantine procedure forbids moving: list it in the report instead' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.1 reports in-use unknowns instead of moving them'
else
  fail '13.1 reports in-use unknowns instead of moving them'
fi
if [ "$(grep -Fc -- 'lists the same path' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.2 needs the task record beside a marker'
else
  fail '13.2 needs the task record beside a marker'
fi
if [ "$(grep -Fc -- 'status --short --ignored --untracked-files=all' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 lists files inside ignored folders'
else
  fail '13.3 lists files inside ignored folders'
fi
if [ "$(grep -Fc -- 'for-each-ref --contains HEAD refs/heads refs/tags` must print a ref' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 checks reachability against branches and tags only'
else
  fail '13.3 checks reachability against branches and tags only'
fi
if [ "$(grep -Fc -- 'A stash or a remote-tracking ref alone is not enough' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 does not count a stash'
else
  fail '13.3 does not count a stash'
fi
if [ "$(grep -Fc -- 'prints a ref other than `refs/heads/<branch>` itself' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 needs another ref before deleting a branch'
else
  fail '13.3 needs another ref before deleting a branch'
fi
if [ "$(grep -Fc -- 'Then run `git worktree remove <path>`, without `--force`, alone' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 removes worktrees through git without force'
else
  fail '13.3 removes worktrees through git without force'
fi
if [ "$(grep -Fc -- 'A marker never moves an item out of the protected or evidence class' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.4 markers never override protection'
else
  fail '13.4 markers never override protection'
fi
if [ "$(grep -Fc -- 'or 10 % free when it sets none' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.5 defaults the disk floor to 10 %'
else
  fail '13.5 defaults the disk floor to 10 %'
fi
if [ "$(grep -Fc -- 'Low space calls for this procedure, never for broader deletion' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.5 never widens deletion under low space'
else
  fail '13.5 never widens deletion under low space'
fi
if [ "$(grep -Fc -- 'When a guard, the sandbox, an approval policy or I refuse a removal' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.6 counts sandbox and approval-policy refusals'
else
  fail '13.6 counts sandbox and approval-policy refusals'
fi
if [ "$(grep -Fc -- '**Economy mode — on my word only.**' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'rule 3.1 carries economy mode'
else
  fail 'rule 3.1 carries economy mode'
fi
if [ "$(grep -Fc -- 'you never switch it on yourself to save cost' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'economy mode is switched on by the owner only'
else
  fail 'economy mode is switched on by the owner only'
fi
if [ "$(grep -Fc -- 'In economy mode (rule 3.1) it runs on the economy configuration, and its record says so.' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'rule 3.4 records economy mode'
else
  fail 'rule 3.4 records economy mode'
fi
if [ "$(grep -Fc -- '## Economy mode — code review only (rule 3.1)' .agents/skills/codex-playbook-subagents/references/roster.md)" -eq 1 ]; then
  pass 'the roster defines the economy configuration'
else
  fail 'the roster defines the economy configuration'
fi
if [ "$(grep -Fc -- '| Free disk | `df -h <path>` |' .agents/skills/codex-playbook-platform-linux/SKILL.md)" -eq 1 ]; then
  pass 'the Linux skill gives the free-disk command'
else
  fail 'the Linux skill gives the free-disk command'
fi
if [ "$(grep -Fc -- '| Free disk | `df -h <path>` |' .agents/skills/codex-playbook-platform-macos/SKILL.md)" -eq 1 ]; then
  pass 'the macOS skill gives the free-disk command'
else
  fail 'the macOS skill gives the free-disk command'
fi
if [ "$(grep -Fc -- '| Free disk | `Get-PSDrive' .agents/skills/codex-playbook-platform-windows/SKILL.md)" -eq 1 ]; then
  pass 'the Windows skill gives the free-disk command'
else
  fail 'the Windows skill gives the free-disk command'
fi

# Review follow-up for 0.1.7: every public version carrier matches VERSION.
# (The same check as scripts/verify.sh; verify.sh runs this suite, so this suite
# must never call verify.sh.)
carrier_version=$(tr -d '\r\n' < VERSION)
if grep -Fq "Current: **v$carrier_version**" README.md &&
   grep -Fq "rulebook is version $carrier_version" AGENTS.md &&
   grep -Fq "**Current version:** $carrier_version" PROGRESS.md &&
   grep -Fq "## $carrier_version —" CHANGELOG.md &&
   grep -Fq "Codex Playbook / $carrier_version" docs/index.html; then
  pass 'every public version carrier matches VERSION'
else
  fail 'a public version carrier disagrees with VERSION'
fi
# Review follow-up for 0.1.7: clauses the deep review found untested.
if [ "$(grep -Fc -- 'or an escalated retry of the same command' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 names an escalated retry as a re-spelling'
else
  fail 'rule 10.1 names an escalated retry as a re-spelling'
fi
if [ "$(grep -Fc -- 'never under the `never` approval policy, and never again after I decline' .agents/skills/codex-playbook-destructive/SKILL.md)" -eq 1 ]; then
  pass 'rule 10.1 allows one escalated approval request and no more'
else
  fail 'rule 10.1 allows one escalated approval request and no more'
fi
if [ "$(grep -Fc -- 'take the route the refusal names, quarantine, or ask' AGENTS.md)" -eq 1 ]; then
  pass 'the router names the three routes after a refusal'
else
  fail 'the router names the three routes after a refusal'
fi
if [ "$(grep -Fc -- 'under `on-request`, one escalated request stating the refusal is how you ask me, never after I decline' AGENTS.md)" -eq 1 ]; then
  pass 'the router treats one escalated request as asking'
else
  fail 'the router treats one escalated request as asking'
fi
if [ "$(grep -Fc -- 'the quarantine move may need one escalated approval request (rule 10.1)' .agents/skills/codex-playbook-quarantine/SKILL.md)" -eq 1 ]; then
  pass 'the quarantine skill notes the sandbox escalation'
else
  fail 'the quarantine skill notes the sandbox escalation'
fi
if [ "$(grep -Fc -- 'so branch or tag them first' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 branches or tags detached commits first'
else
  fail '13.3 branches or tags detached commits first'
fi
if [ "$(grep -Fc -- 'if `git -C <worktree> reflog` shows commits you moved away from' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 checks the worktree HEAD log'
else
  fail '13.3 checks the worktree HEAD log'
fi
if [ "$(grep -Fc -- 'Never use `git branch -D` on a branch with unique work' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 forbids branch -D on unique work'
else
  fail '13.3 forbids branch -D on unique work'
fi
if [ "$(grep -Fc -- 'If git refuses, fix the cause it names instead of forcing' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 fixes the cause instead of forcing'
else
  fail '13.3 fixes the cause instead of forcing'
fi
if [ "$(grep -Fc -- 'Treat every git-ignored file that is not regenerable build output' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.3 protects ignored files that are not build output'
else
  fail '13.3 protects ignored files that are not build output'
fi
if [ "$(grep -Fc -- 'A marker you did not write, or cannot show you wrote, is evidence, not permission' .agents/skills/codex-playbook-hygiene/SKILL.md)" -eq 1 ]; then
  pass '13.4 a foreign marker is evidence only'
else
  fail '13.4 a foreign marker is evidence only'
fi
if [ "$(grep -Fc -- 'It covers code review only: planning and design stay on the Top tier' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'economy mode covers code review only'
else
  fail 'economy mode covers code review only'
fi
if [ "$(grep -Fc -- 'every review it runs says *economy mode* in its header' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'economy mode is recorded in every review header'
else
  fail 'economy mode is recorded in every review header'
fi
if [ "$(grep -Fc -- 'economy mode, below, is the one exception, on my word only' .agents/skills/codex-playbook-reviews/SKILL.md)" -eq 1 ]; then
  pass 'the never-drops sentence names the economy exception'
else
  fail 'the never-drops sentence names the economy exception'
fi
if [ "$(grep -Fc -- 'never the deep reviewers of the same batch' .agents/skills/codex-playbook-subagents/references/roster.md)" -eq 1 ]; then
  pass 'economy reviewers are fresh sessions'
else
  fail 'economy reviewers are fresh sessions'
fi
if [ "$(grep -Fc -- 'The binding also names the economy configuration' .agents/skills/codex-playbook-subagents/references/roster.md)" -eq 1 ]; then
  pass 'the binding names the economy configuration'
else
  fail 'the binding names the economy configuration'
fi
if [ "$(grep -Fc -- '4. Is a process using a directory' .agents/skills/codex-playbook-platform-linux/SKILL.md)" -eq 1 ]; then
  pass 'the Linux skill checks for a process using a directory'
else
  fail 'the Linux skill checks for a process using a directory'
fi
if [ "$(grep -Fc -- '4. Is a process using a directory' .agents/skills/codex-playbook-platform-macos/SKILL.md)" -eq 1 ]; then
  pass 'the macOS skill checks for a process using a directory'
else
  fail 'the macOS skill checks for a process using a directory'
fi
if [ "$(grep -Fc -- 'the check was not run, and the folder is not proven idle' .agents/skills/codex-playbook-platform-windows/SKILL.md)" -eq 1 ]; then
  pass 'the Windows skill says when the idle check cannot run'
else
  fail 'the Windows skill says when the idle check cannot run'
fi

# Rule 7.1: tasks run back to back.
if [ "$(grep -Fc -- 'a release blocked by an unfixable advisory (rule 6.3)' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 the stops include an unfixable-advisory release block'
else
  fail '7.1 the stops include an unfixable-advisory release block'
fi
if [ "$(grep -Fc -- 'and never admits the next task itself (rule 3.5: one coordinator admits work)' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 a lane never admits the next task'
else
  fail '7.1 a lane never admits the next task'
fi
if [ "$(grep -Fc -- 'ceiling and its waits (work expensive to undo, anything irreversible or outward-facing)' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 the stops include the review ceiling and its waits'
else
  fail '7.1 the stops include the review ceiling and its waits'
fi
if [ "$(grep -Fc -- 'blocking finding (rule 3.3' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 the stops include stop-the-line'
else
  fail '7.1 the stops include stop-the-line'
fi
if [ "$(grep -Fc -- 'The only stops are the gates this rulebook keeps: a high deep review' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 the stops are the gates this rulebook keeps'
else
  fail '7.1 the stops are the gates this rulebook keeps'
fi
if [ "$(grep -Fc -- '**Tasks run back to back — every plan says so in its header.**' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 tasks run back to back and every plan says so'
else
  fail '7.1 tasks run back to back and every plan says so'
fi
if [ "$(grep -Fc -- 'whoever runs the plan — the coordinator, or a solo session running it — starts the next approved task at once, in the same turn' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 the next approved task starts at once'
else
  fail '7.1 the next approved task starts at once'
fi
if [ "$(grep -Fc -- 'A close-out report is a record, not a stopping point' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 a close-out report is not a stopping point'
else
  fail '7.1 a close-out report is not a stopping point'
fi
if [ "$(grep -Fc -- 'never asks "shall I continue?"' .agents/skills/codex-playbook-collaboration/SKILL.md)" -eq 1 ]; then
  pass '7.1 never asks whether to continue'
else
  fail '7.1 never asks whether to continue'
fi
if [ "$(grep -Fc -- 'then whoever runs the plan starts the next approved task at once (rule 7.1)' .agents/skills/codex-playbook-workflow/SKILL.md)" -eq 1 ]; then
  pass '6.2 the hygiene checkpoint hands on to the next task'
else
  fail '6.2 the hygiene checkpoint hands on to the next task'
fi

# Approvals are destructive-only (0.1.8): each clause must exist exactly once,
# and every retired ask must be gone from the router and every skill.
need_once() { # file phrase name
  if [ "$(grep -Fc -- "$2" "$1")" -eq 1 ]; then pass "$3"; else fail "$3"; fi
}
need_absent() { # phrase name
  if grep -rFq -- "$1" AGENTS.md .agents/skills; then fail "$2"; else pass "$2"; fi
}
COLLAB=.agents/skills/codex-playbook-collaboration/SKILL.md
need_once AGENTS.md '## Approval Table — Destructive Actions Only' 'router names destructive actions as the only approval'
need_once AGENTS.md 'Destructive actions are the only thing that needs my OK.' 'router says destructive actions are the only gate'
need_once AGENTS.md 'Write the design down (`PLAN.md`, an ADR where rule 4.2 applies), then execute. Do not wait for a go.' 'router: plans and designs never wait for a go'
need_once AGENTS.md 'Name the destination and effect in the close-out, then execute.' 'router: publication and configuration need no ask'
need_once AGENTS.md 'configuration that drops or migrates data; any mass or irreversible operation | Ask, naming exact targets.' 'router keeps the destructive ask with exact targets'
need_once "$COLLAB" '7.1 **Plans carry no approval gate.**' '7.1 plans carry no approval gate'
need_once "$COLLAB" 'a destructive action my request did not already cover (rule 10.1); or my word.' '7.1 the last stop is a destructive action not covered'
need_once "$COLLAB" 'Interrupt me only for a **destructive or irreversible action** (rule 10.1) or a **genuine intent ambiguity**' '7.2 interrupts only for destruction or ambiguity'
need_once .agents/skills/codex-playbook-environment/SKILL.md 'is your call when the task needs one' '9.3 a native datastore is the agent call'
need_once .agents/skills/codex-playbook-destructive/SKILL.md 'Changing system, security-sensitive, or performance configuration that destroys nothing needs no ask' '10.2 non-destructive configuration needs no ask'
need_once .agents/skills/codex-playbook-workflow/SKILL.md 'The first `v` tag that publishes off this machine in a repo needs no ask' '6.4 first publish needs no ask'
need_absent 'Ask with a concrete reviewable design' 'retired: ask with a reviewable design'
need_absent 'Ask once, naming destination and effect' 'retired: ask once before publishing'
need_absent 'waits for my go before implementation begins' 'retired: plan waits for my go'
need_absent 'an action on the approval table the plan did not already cover' 'retired: approval-table stop in 7.1'
need_absent 'never introduce a native datastore' 'retired: datastore ban'
need_absent 'or **performance-affecting production** configuration (resource caps, swap, scheduling)' 'retired: performance-configuration ask'
need_absent 'the approval table'"'"'s seventh row' 'retired: seventh-row reference'

# Dev modes (0.1.10): every new clause exactly once.
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Every project has a dev mode, and only I change it.**' "14.1 only the owner changes the dev mode"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'It is one line in the project'"'"'s `AGENTS.md`' "14.1 the mode line lives in the project AGENTS.md"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**The data sets the minimum, not the schedule:**' "14.1 the data sets the minimum mode"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'you never change it yourself, and you never read a deadline as permission to lower it' "14.1 an agent never changes the mode"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**The mode sets the amount and the kind of review**' "14.2 the mode sets the amount and kind of review"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'high deep, **pipelined like a deep review — not a gate**' "14.2 an mvp milestone review is pipelined"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Risk overrides cadence from mvp upward** (rule 3.2)' "14.2 risk overrides cadence from mvp upward"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**The floor — every mode, never deferred, never parked in the backlog.**' "14.3 the floor holds in every mode"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'A floor finding is blocking in every mode, a spike included.' "14.3 a floor finding blocks even in a spike"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**No attack story, no blocker.**' "14.4 no attack story means no blocker"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Downgrading takes a reason:**' "14.4 downgrading a finding takes a reason"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'counts as realistic until someone completes it' "14.4 an incomplete story counts as realistic"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'no proof of concept, no deep dive, no fix proposal' "14.4 hardening findings get one line of effort"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**The security backlog — every finding kept, none ignored.**' "14.5 every security finding is kept"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**In a public repository an open realistic finding is a map for an attacker:**' "14.5 open realistic findings stay out of a public tree"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Moving up a mode is mine, and it starts a hardening phase.**' "14.6 moving up starts a hardening phase"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Extra hardening is its own phase, after production.**' "14.7 extra hardening is its own phase after production"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'nothing in it blocks a feature release' "14.7 extra hardening never blocks a feature release"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md '**Security is designed in, from the first plan.**' "14.8 security is designed in from the first plan"
need_once .agents/skills/codex-playbook-dev-modes/SKILL.md 'Every plan opens with a **threat sketch**, ten lines at most' "14.8 every plan opens with a threat sketch"
need_once .agents/skills/codex-playbook-reviews/SKILL.md '**The project'"'"'s dev mode decides how much of this ladder runs**' "3.1 the dev mode scales the review ladder"
need_once .agents/skills/codex-playbook-reviews/SKILL.md '**Risk overrides cadence, from MVP upward** (rule 14.2)' "3.2 risk overrides cadence from MVP upward"
need_once .agents/skills/codex-playbook-reviews/SKILL.md '**A security finding is classed by its attack story (rule 14.4):**' "3.3 security findings are classed by attack story"
need_once .agents/skills/codex-playbook-reviews/SKILL.md 'It also reads the security backlog:' "3.4 the release review reads the security backlog"
need_once .agents/skills/codex-playbook-reviews/SKILL.md '**More lines, not bigger batches, is how development keeps moving.**' "3.5 more lines keep development moving"
need_once .agents/skills/codex-playbook-collaboration/SKILL.md 'The plan opens with the project'"'"'s dev mode and a threat sketch' "7.1 a plan opens with the dev mode and a threat sketch"
need_once .agents/skills/codex-playbook-collaboration/SKILL.md '**A security defect is triaged by its attack story instead (rule 14.4):**' "7.4 security defects are triaged by attack story"
need_once .agents/skills/codex-playbook-dev-mode/agents/openai.yaml 'allow_implicit_invocation: false' "the dev-mode command disables implicit invocation"
need_once .agents/skills/codex-playbook-dev-mode/SKILL.md 'If you are reading this without my having named it, stop here.' "the dev-mode command stops when not named by the owner"
need_once .agents/skills/codex-playbook-dev-mode/SKILL.md '**Lowering below the data minimum is refused**' "the dev-mode command refuses to go below the data minimum"
need_once AGENTS.md '| Owner command | `codex-playbook-dev-mode` | Only when I name it:' "router marks dev-mode as an owner command"

# Committing and pushing is a standing request (0.1.11).
WF=.agents/skills/codex-playbook-workflow/SKILL.md
need_once AGENTS.md '**Committing and pushing is my standing request:**' 'router makes commit and push a standing request'
need_once AGENTS.md 'never wait to be asked. Exceptions are mine: local-only, review-only, or a pause.' 'router never waits to be asked to commit'
need_once AGENTS.md 'A failed commit or push is reported with its error.' 'router reports a failed commit or push'
need_once AGENTS.md 'When a task'"'"'s work is done, to run its close-out chain;' 'router loads the workflow skill when work is done'
need_once "$WF" '**This is my explicit, standing request — given once, for every session**' '6.1 commit and push is a standing request'
need_once "$WF" 'never end a task'"'"'s turn with its work uncommitted' '6.1 never ends a task uncommitted'
need_once "$WF" 'is reported with the error, never left silent' '6.1 reports a failed commit or push'
need_absent 'Before the first version, commit, tag, push, pull request, merge, or release operation of a task.' 'retired: workflow loads only before a commit'

# Cleanup never stalls on a spelling; the floor is not a stop (0.1.12).
DS=.agents/skills/codex-playbook-destructive/SKILL.md
HY=.agents/skills/codex-playbook-hygiene/SKILL.md
need_once "$DS" '**Build output is the one exception, so cleanup never stalls on a spelling.**' '10.1 build output is the one exception'
need_once "$DS" 'remove it once by the toolchain'"'"'s own clean command (`cargo clean`, `go clean -cache`)' '10.1 build output goes by the toolchain clean command'
need_once "$DS" 'a flag such as `-f`, not the target' '10.1 the exception covers only a refused form'
need_once "$DS" 'If that is refused too, or the refusal named the target, or I declined, it is a stop.' '10.1 the exception ends at a second refusal'
need_once AGENTS.md 'build output proven regenerable and idle whose command form alone was refused (Codex rejects every `rm -rf`)' 'router carries the build-output exception'
need_once "$HY" '**The floor never stops work by itself:**' '13.5 the floor never stops work by itself'
need_once "$HY" 'Stop only for a step whose measured need will not fit in the space left' '13.5 stops only for a step that will not fit'
need_once "$HY" 'except rule 10.1'"'"'s route for build output proven regenerable and idle, once' '13.6 allows only the build-output route'

# An identical retry is never a route; a refusal is not a classification (0.1.14).
need_once AGENTS.md '**An identical retry is never a route:**' 'router says an identical retry is never a route'
need_once AGENTS.md 'under `never` there is no one to ask' 'router says never has no one to ask'
need_once AGENTS.md 'goes once by `cargo clean` or `rm -r`' 'router names the build-output routes'
need_once AGENTS.md 'A refusal is not a classification.' 'router says a refusal is not a classification'
need_once .agents/skills/codex-playbook-destructive/SKILL.md '**An identical retry is never a route on its own:**' '10.1 an identical retry is never a route'
need_once .agents/skills/codex-playbook-hygiene/SKILL.md '**A refusal is not a classification:**' '13.6 a refusal is not a classification'
need_once .agents/skills/codex-playbook-hygiene/SKILL.md 'never turns it into something to keep' '13.6 a recorded refusal never makes a keep'
need_absent 'one escalated request for the refused command itself, unchanged and stating the refusal, is asking' 'retired: router retry-unchanged clause'
# Reviews batch more: automated checks per task, mechanical and deep side by side per batch (0.1.15).
REV=.agents/skills/codex-playbook-reviews/SKILL.md
DM=.agents/skills/codex-playbook-dev-modes/SKILL.md
need_once "$REV" '| **task** | one unit of work, rules 6.1–6.2 | automated checks — tests, lint, type checks (rule 2.2) |' '3.1 the task row is gated by automated checks'
need_once "$REV" '| mechanical and deep, side by side on the same range |' '3.1 mechanical and deep run side by side per batch'
need_once "$REV" '**Per batch**, side by side with the deep review on the same pinned range' '3.1 mechanical review is per batch'
need_once "$REV" '**Per task, the automated checks are the gate:**' '3.1 the automated checks gate each task'
need_once "$REV" '**Per batch** of 5–15 tasks, or about 2,000 changed lines, whichever comes first' '3.1 a deep batch is 5 to 15 tasks or about 2,000 lines'
need_once "$REV" '(b) the diff passes about 2,000 changed lines — a starting value, not a measurement' '3.2 a batch closes at about 2,000 changed lines'
need_once "$REV" 'or unsafe code gets the deep review at task grain, always' '3.2 only floor and unsafe-code tasks get task-grain deep review'
need_once "$REV" '**Concurrency, public-API and other data-path tasks stay in the batch:**' '3.2 concurrency, API and data tasks stay in the batch'
need_once "$DM" '| **production** | automated checks | mechanical and deep, 5–15 tasks or about 2,000 lines |' '14.2 production batches mechanical and deep'
need_once "$DM" 'mechanical and deep, 3–6 tasks or about 1,000 lines' '14.2 sensitive keeps smaller batches'
need_absent 'concurrency, data-safety, unsafe-code and public-API tasks get the deep review at task grain' 'retired: deep review per task for concurrency, data and API'

if [ "$failures" -ne 0 ]; then
  printf '\n%s rulebook verification check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll %s rulebook verification checks passed.\n' "$passes"
