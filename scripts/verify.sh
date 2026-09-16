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
  docs/assets/codex-playbook-hero.png \
  scripts/install.sh \
  scripts/restore.sh \
  tests/install_test.sh
do
  require_file "$required_file"
done

version=$(tr -d '\r\n' < VERSION)
if printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  pass "VERSION is a bare semantic version ($version)"
else
  fail "VERSION is not a bare semantic version"
fi

if grep -Fq "Current: **v$version**" README.md &&
   grep -Fq "Codex Playbook / $version" docs/index.html; then
  pass "public version carriers match VERSION"
else
  fail "one or more public version carriers disagree with VERSION"
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

for shell_file in scripts/install.sh scripts/restore.sh tests/install_test.sh
do
  if [ -x "$shell_file" ]; then
    pass "$shell_file is executable"
  else
    fail "$shell_file is not executable"
  fi
  if sh -n "$shell_file"; then
    pass "$shell_file has valid shell syntax"
  else
    fail "$shell_file has invalid shell syntax"
  fi
done

if ./tests/install_test.sh; then
  pass "installer lifecycle tests pass"
else
  fail "installer lifecycle tests fail"
fi

if grep -Eq '~/.codex/skills|\$CODEX_HOME/skills' \
  README.md INSTALL.md ARCHITECTURE.md; then
  fail "public installation docs reference a deprecated personal skill path"
else
  pass "public installation docs use the current personal skill path"
fi

link_inventory=$(mktemp "${TMPDIR:-/tmp}/codex-playbook-link-inventory.XXXXXX")
link_failures=$(mktemp "${TMPDIR:-/tmp}/codex-playbook-link-failures.XXXXXX")
find . -path './.git' -prune -o -type f -name '*.md' -print |
while IFS= read -r markdown_file
do
  grep -Eo '\]\([^)]+\)' "$markdown_file" 2>/dev/null |
  sed -e 's/^](/ /' -e 's/)$//' |
  while IFS= read -r link_target
  do
    link_target=${link_target# }
    printf '%s\t%s\n' "$markdown_file" "$link_target"
  done
done > "$link_inventory"

tab=$(printf '\t')
while IFS="$tab" read -r markdown_file link_target
do
  case "$link_target" in
    ''|http://*|https://*|mailto:*|\#*) continue ;;
  esac
  link_path=${link_target%%#*}
  markdown_dir=$(dirname -- "$markdown_file")
  if [ ! -e "$markdown_dir/$link_path" ]; then
    printf '%s: %s\n' "$markdown_file" "$link_target" >> "$link_failures"
  fi
done < "$link_inventory"

if [ -s "$link_failures" ]; then
  cat "$link_failures" >&2
  fail "one or more local Markdown link targets are missing"
else
  pass "local Markdown link targets exist"
fi
rm "$link_inventory" "$link_failures"

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
