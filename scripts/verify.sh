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
  BACKLOG.md \
  HANDOFF.md \
  LICENSE \
  PLAN.md \
  VERSION \
  .env.example \
  INSTALL.md \
  CONTRIBUTING.md \
  SECURITY.md \
  config/managed-skills.txt \
  config/retired-skills.txt \
  config/rule-manifest.tsv \
  docs/index.html \
  docs/assets/codex-playbook-hero.png \
  docs/runbooks/github-pages.md \
  docs/reports/2026-09-17-rule-parity-matrix.md \
  scripts/check-local.sh \
  scripts/install.sh \
  scripts/restore.sh \
  templates/playbook-local.md \
  tests/check_local_test.sh \
  tests/install_test.sh \
  tests/rulebook_test.sh
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
   grep -Fq "rulebook is version $version" AGENTS.md &&
   grep -Fq "**Current version:** $version" PROGRESS.md &&
   grep -Fq "## $version —" CHANGELOG.md &&
   grep -Fq "Codex Playbook / $version" docs/index.html; then
  pass "public version carriers match VERSION"
else
  fail "one or more public version carriers disagree with VERSION"
fi

if ./tests/rulebook_test.sh; then
  pass "modular rulebook contract passes"
else
  fail "modular rulebook contract fails"
fi

for shell_file in scripts/check-local.sh scripts/install.sh scripts/restore.sh \
  tests/check_local_test.sh tests/install_test.sh tests/rulebook_test.sh
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

if ./tests/check_local_test.sh; then
  pass "local-layer staleness tests pass"
else
  fail "local-layer staleness tests fail"
fi

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

if grep -RInE 'TBD|FIXME|lorem ipsum' \
  --exclude-dir=.git \
  --exclude=verify.sh \
  . >/dev/null 2>&1; then
  fail "placeholder text remains"
else
  pass "no placeholder text remains"
fi

# The shared conformance vectors are excluded because two of them are *about*
# trailing blanks — "trailing spaces are allowed" after an item, and the marker
# followed by one space and nothing else. The file is carried byte-identical by
# both editions and its SHA-256 is pinned in tests/check_local_test.sh, so it is
# guarded more tightly than this sweep could guard it.
whitespace_matches=$(grep -RInE '[[:blank:]]+$' \
  --exclude-dir=.git \
  --exclude='*.png' \
  --exclude=dead-words-vectors.tsv \
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
