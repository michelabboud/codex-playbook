#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

failures=0

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  if [ -s "$1" ]; then
    pass "$1 exists and is non-empty"
  else
    fail "$1 is missing or empty"
  fi
}

for required_file in \
  AGENTS.md \
  README.md \
  PROGRESS.md \
  CHANGELOG.md \
  ARCHITECTURE.md \
  LICENSE \
  VERSION \
  INSTALL.md \
  CONTRIBUTING.md \
  SECURITY.md \
  docs/index.html \
  docs/assets/codex-playbook-hero.png
do
  require_file "$required_file"
done

version=$(tr -d '\r\n' < VERSION)
if printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  pass "VERSION is a bare semantic version ($version)"
else
  fail "VERSION is not a bare semantic version"
fi

agents_bytes=$(wc -c < AGENTS.md | tr -d ' ')
if [ "$agents_bytes" -le 32768 ]; then
  pass "AGENTS.md is within Codex's default 32 KiB limit ($agents_bytes bytes)"
else
  fail "AGENTS.md exceeds Codex's default 32 KiB limit ($agents_bytes bytes)"
fi

rule_count=$(grep -Ec '^[0-9]+\. \*\*' AGENTS.md || true)
if [ "$rule_count" -eq 42 ]; then
  pass "AGENTS.md contains all 42 numbered rules"
else
  fail "AGENTS.md contains $rule_count numbered rules; expected 42"
fi

skill_count=0
for skill_file in .agents/skills/codex-playbook-*/SKILL.md
do
  if [ ! -f "$skill_file" ]; then
    continue
  fi
  skill_count=$((skill_count + 1))
  if grep -Eq '^name: codex-playbook-[a-z-]+$' "$skill_file" &&
     grep -Eq '^description: .+' "$skill_file"; then
    pass "$skill_file has required metadata"
  else
    fail "$skill_file is missing valid name or description metadata"
  fi
done

if [ "$skill_count" -eq 3 ]; then
  pass "three Codex Playbook skills are present"
else
  fail "$skill_count skills found; expected 3"
fi

map_rule_count=$(grep -Ec '^      \["([1-9]|[1-3][0-9]|4[0-2])",' docs/index.html || true)
if [ "$map_rule_count" -eq 42 ]; then
  pass "visual map contains all 42 numbered rules"
else
  fail "visual map contains $map_rule_count numbered rules; expected 42"
fi

if grep -RInE 'TBD|FIXME|lorem ipsum' \
  --exclude-dir=.git \
  --exclude=verify.sh \
  . >/dev/null 2>&1; then
  fail "placeholder text remains"
else
  pass "no placeholder text remains"
fi

whitespace_matches=$(grep -RInE '[[:blank:]]+$' \
  --exclude-dir=.git \
  --exclude='*.png' \
  . || true)
if [ -z "$whitespace_matches" ]; then
  pass "tracked text contains no trailing whitespace"
else
  printf '%s\n' "$whitespace_matches" >&2
  fail "tracked text contains trailing whitespace"
fi

if [ "$failures" -ne 0 ]; then
  printf '\n%s verification check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll Codex Playbook verification checks passed.\n'
