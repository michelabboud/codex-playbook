#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-playbook-tests.XXXXXX")

cleanup() {
  chmod -R u+w "$test_root" 2>/dev/null || true
  rm -R "$test_root"
}

trap cleanup EXIT HUP INT TERM

passes=0

pass() {
  passes=$((passes + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1" >&2
  exit 1
}

assert_file_equal() {
  expected=$1
  actual=$2
  label=$3

  if cmp -s "$expected" "$actual"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_contains() {
  expected=$1
  file=$2
  label=$3

  if grep -Fq "$expected" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

latest_backup() {
  backup_root=$1
  find "$backup_root" -mindepth 1 -maxdepth 1 -type d -name 'codex-playbook-preinstall-*' -print |
    sort |
    tail -n 1
}

run_first_install_and_restore_test() {
  case_root="$test_root/first-install"
  home="$case_root/home"
  codex_home="$case_root/custom-codex"
  mkdir -p "$home/.agents/skills/unrelated" "$codex_home"
  printf 'keep me\n' > "$home/.agents/skills/unrelated/SKILL.md"
  printf 'model = "example"\n' > "$codex_home/config.toml"

  HOME="$home" CODEX_HOME="$codex_home" "$repo_root/scripts/install.sh" > "$case_root/install.log"

  assert_file_equal "$repo_root/AGENTS.md" "$codex_home/AGENTS.md" \
    'custom CODEX_HOME receives AGENTS.md'
  if [ ! -e "$home/.codex/AGENTS.md" ]; then
    pass 'default Codex home stays untouched when CODEX_HOME is set'
  else
    fail 'default Codex home stays untouched when CODEX_HOME is set'
  fi

  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_file_equal \
      "$repo_root/.agents/skills/$skill_name/SKILL.md" \
      "$home/.agents/skills/$skill_name/SKILL.md" \
      "$skill_name installs in the documented user skill directory"
  done

  backup_dir=$(latest_backup "$codex_home/backups")
  [ -n "$backup_dir" ] || fail 'first installation creates a recovery checkpoint'
  assert_contains 'agents=absent' "$backup_dir/manifest" \
    'first-install checkpoint records absent AGENTS.md'

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/restore.sh" "$backup_dir" > "$case_root/restore.log"

  if [ ! -e "$codex_home/AGENTS.md" ]; then
    pass 'restore removes AGENTS.md that did not exist before installation'
  else
    fail 'restore removes AGENTS.md that did not exist before installation'
  fi

  if find "$home/.agents/skills" -mindepth 1 -maxdepth 1 -type d \
      -name 'codex-playbook-*' -print | grep -q .; then
    fail 'restore removes playbook skills that did not exist before installation'
  else
    pass 'restore removes playbook skills that did not exist before installation'
  fi
  assert_contains 'keep me' "$home/.agents/skills/unrelated/SKILL.md" \
    'restore preserves unrelated skills'
  assert_contains 'model = "example"' "$codex_home/config.toml" \
    'restore preserves unrelated Codex configuration'
}

run_refusal_test() {
  case_root="$test_root/refusal"
  home="$case_root/home"
  codex_home="$case_root/codex"
  mkdir -p "$home/.agents/skills/codex-playbook-release" "$codex_home"
  printf 'tailored rules\n' > "$codex_home/AGENTS.md"
  printf 'tailored skill\n' > "$home/.agents/skills/codex-playbook-release/SKILL.md"

  if HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'default install refuses to overwrite different global rules'
  else
    pass 'default install refuses to overwrite different global rules'
  fi

  assert_contains 'tailored rules' "$codex_home/AGENTS.md" \
    'refused install preserves tailored global rules'
  assert_contains 'tailored skill' \
    "$home/.agents/skills/codex-playbook-release/SKILL.md" \
    'refused install makes no partial skill changes'

  if [ ! -e "$codex_home/backups" ]; then
    pass 'refused install creates no misleading backup'
  else
    fail 'refused install creates no misleading backup'
  fi
}

run_upgrade_and_checkpoint_test() {
  case_root="$test_root/upgrade"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$skill_root/codex-playbook-release" "$skill_root/unrelated" "$codex_home"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  printf 'original skill\n' > "$skill_root/codex-playbook-release/SKILL.md"
  printf 'unrelated\n' > "$skill_root/unrelated/SKILL.md"

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install-one.log"
  backup_one=$(latest_backup "$codex_home/backups")
  assert_contains 'original rules' "$backup_one/AGENTS.md" \
    'replacement checkpoint preserves original global rules'
  assert_contains 'original skill' \
    "$backup_one/codex-playbook-release/SKILL.md" \
    'replacement checkpoint preserves original managed skill'

  printf 'second local rules\n' > "$codex_home/AGENTS.md"
  printf 'second local skill\n' > "$skill_root/codex-playbook-release/SKILL.md"
  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install-two.log"
  backup_two=$(find "$codex_home/backups" -mindepth 1 -maxdepth 1 -type d \
    -name 'codex-playbook-preinstall-*' ! -path "$backup_one" -print)

  if [ -n "$backup_two" ] && [ "$backup_one" != "$backup_two" ]; then
    pass 'each installation creates a unique checkpoint'
  else
    fail 'each installation creates a unique checkpoint'
  fi
  assert_contains 'original rules' "$backup_one/AGENTS.md" \
    'later installs do not rewrite earlier checkpoints'
  assert_contains 'second local rules' "$backup_two/AGENTS.md" \
    'later checkpoint captures immediately previous global rules'

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/restore.sh" "$backup_one" > "$case_root/restore.log"
  assert_contains 'original rules' "$codex_home/AGENTS.md" \
    'restore reinstates checkpointed global rules'
  assert_contains 'original skill' "$skill_root/codex-playbook-release/SKILL.md" \
    'restore reinstates checkpointed managed skill'
  assert_contains 'unrelated' "$skill_root/unrelated/SKILL.md" \
    'upgrade and restore preserve unrelated skills'
}

run_source_preflight_test() {
  case_root="$test_root/source-preflight"
  home="$case_root/home"
  codex_home="$case_root/codex"
  broken_repo="$case_root/broken-repo"
  mkdir -p "$home" "$codex_home" "$broken_repo/scripts"
  cp "$repo_root/scripts/install.sh" "$broken_repo/scripts/install.sh"
  chmod +x "$broken_repo/scripts/install.sh"

  if HOME="$home" CODEX_HOME="$codex_home" \
      "$broken_repo/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'install refuses an incomplete source checkout'
  else
    pass 'install refuses an incomplete source checkout'
  fi

  if [ ! -e "$codex_home/AGENTS.md" ] && [ ! -e "$home/.agents/skills" ]; then
    pass 'source preflight failure writes nothing'
  else
    fail 'source preflight failure writes nothing'
  fi
}

run_backup_failure_test() {
  case_root="$test_root/backup-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  mkdir -p "$skill_root/codex-playbook-release" "$codex_home" "$fake_bin"
  cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"
  printf 'preserve this skill\n' > "$skill_root/codex-playbook-release/SKILL.md"
  cat > "$fake_bin/cp" <<'EOF'
#!/bin/sh
printf 'simulated backup copy failure\n' >&2
exit 1
EOF
  chmod +x "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'a backup copy failure aborts installation'
  else
    pass 'a backup copy failure aborts installation'
  fi

  assert_file_equal "$repo_root/AGENTS.md" "$codex_home/AGENTS.md" \
    'backup failure leaves global rules unchanged'
  assert_contains 'preserve this skill' \
    "$skill_root/codex-playbook-release/SKILL.md" \
    'backup failure leaves managed skills unchanged'
  if find "$codex_home/backups" -name COMPLETE -print | grep -q .; then
    fail 'failed backup never receives a COMPLETE marker'
  else
    pass 'failed backup never receives a COMPLETE marker'
  fi
}

run_install_cleanup_failure_test() {
  case_root="$test_root/install-cleanup-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'old %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done
  cat > "$fake_bin/rm" <<'EOF'
#!/bin/sh
case "$*" in
  *'.previous.'*)
    printf 'simulated cleanup failure\n' >&2
    exit 1
    ;;
esac
exec /bin/rm "$@"
EOF
  chmod +x "$fake_bin/rm"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    pass 'redundant-copy cleanup failure does not interrupt installation'
  else
    fail 'redundant-copy cleanup failure does not interrupt installation'
  fi

  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_file_equal \
      "$repo_root/.agents/skills/$skill_name/SKILL.md" \
      "$skill_root/$skill_name/SKILL.md" \
      "$skill_name is fully installed despite cleanup failure"
  done
  assert_contains 'WARNING:' "$case_root/install.log" \
    'cleanup failure is reported rather than swallowed'
}

run_install_swap_failure_test() {
  case_root="$test_root/install-swap-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  move_count="$case_root/move-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'original %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done
  cat > "$fake_bin/mv" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_MV_COUNT" ] || count=$(cat "$FAKE_MV_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNT"
if [ "$count" -eq 5 ] || [ "$count" -eq 6 ]; then
  printf 'simulated install swap and immediate rollback failure\n' >&2
  exit 1
fi
exec /bin/mv "$@"
EOF
  chmod +x "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAKE_MV_COUNT="$move_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'install swap failure aborts installation'
  else
    pass 'install swap failure aborts installation'
  fi

  assert_contains 'original rules' "$codex_home/AGENTS.md" \
    'install swap failure restores original global rules'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "original $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name is rolled back after install swap failure"
  done
  assert_contains 'verified checkpoint was restored' "$case_root/install.log" \
    'install swap failure reports successful rollback'
}

run_install_signal_test() {
  case_root="$test_root/install-signal"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  move_count="$case_root/move-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'original %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done
  cat > "$fake_bin/mv" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_MV_COUNT" ] || count=$(cat "$FAKE_MV_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNT"
if [ "$count" -eq 4 ]; then
  kill -TERM "$PPID"
fi
exec /bin/mv "$@"
EOF
  chmod +x "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAKE_MV_COUNT="$move_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'installation interrupted by TERM exits unsuccessfully'
  else
    pass 'installation interrupted by TERM exits unsuccessfully'
  fi

  assert_contains 'original rules' "$codex_home/AGENTS.md" \
    'TERM interruption restores original global rules'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "original $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name is rolled back after TERM interruption"
  done
  assert_contains 'interrupted; the verified checkpoint was restored' \
    "$case_root/install.log" \
    'TERM interruption reports successful recovery'
}

run_install_rollback_storage_failure_test() {
  case_root="$test_root/install-rollback-storage-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  mktemp_count="$case_root/mktemp-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'original %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done
  cat > "$fake_bin/mktemp" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_MKTEMP_COUNT" ] || count=$(cat "$FAKE_MKTEMP_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MKTEMP_COUNT"
if [ "$count" -eq 4 ]; then
  printf 'simulated rollback storage allocation failure\n' >&2
  exit 1
fi
exec /usr/bin/mktemp "$@"
EOF
  chmod +x "$fake_bin/mktemp"

  if PATH="$fake_bin:$PATH" FAKE_MKTEMP_COUNT="$mktemp_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'rollback storage allocation failure aborts installation'
  else
    pass 'rollback storage allocation failure aborts installation'
  fi

  assert_contains 'original rules' "$codex_home/AGENTS.md" \
    'rollback storage allocation failure leaves global rules unchanged'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "original $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name stays unchanged when rollback storage allocation fails"
  done
  assert_contains 'before managed destinations changed' "$case_root/install.log" \
    'rollback storage allocation failure reports the safe abort point'
}

run_restore_copy_failure_test() {
  case_root="$test_root/restore-copy-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  copy_count="$case_root/copy-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'checkpoint rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'checkpoint %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log"
  checkpoint=$(latest_backup "$codex_home/backups")

  printf 'current rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    printf 'current %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  cat > "$fake_bin/cp" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_CP_COUNT" ] || count=$(cat "$FAKE_CP_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_CP_COUNT"
if [ "$count" -eq 5 ]; then
  printf 'simulated restore copy failure\n' >&2
  exit 1
fi
exec /bin/cp "$@"
EOF
  chmod +x "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" FAKE_CP_COUNT="$copy_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore staging failure aborts restoration'
  else
    pass 'restore staging failure aborts restoration'
  fi

  assert_contains 'current rules' "$codex_home/AGENTS.md" \
    'restore staging failure leaves global rules unchanged'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "current $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name stays unchanged after restore staging failure"
  done
  assert_contains 'Pre-restore checkpoint:' "$case_root/restore.log" \
    'restore staging failure reports its recovery checkpoint'
}

run_restore_swap_failure_test() {
  case_root="$test_root/restore-swap-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  move_count="$case_root/move-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'checkpoint rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'checkpoint %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log"
  checkpoint=$(latest_backup "$codex_home/backups")

  printf 'current rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    printf 'current %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  cat > "$fake_bin/mv" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_MV_COUNT" ] || count=$(cat "$FAKE_MV_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNT"
if [ "$count" -eq 6 ]; then
  printf 'simulated restore swap failure\n' >&2
  exit 1
fi
exec /bin/mv "$@"
EOF
  chmod +x "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAKE_MV_COUNT="$move_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore swap failure aborts restoration'
  else
    pass 'restore swap failure aborts restoration'
  fi

  assert_contains 'current rules' "$codex_home/AGENTS.md" \
    'restore swap failure reinstates current global rules'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "current $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name is rolled back after restore swap failure"
  done
  assert_contains 'pre-restore state was reinstated' "$case_root/restore.log" \
    'restore swap failure reports successful rollback'
  assert_contains 'Pre-restore checkpoint:' "$case_root/restore.log" \
    'restore swap failure reports its recovery checkpoint'
}

run_restore_signal_test() {
  case_root="$test_root/restore-signal"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  move_count="$case_root/move-count"
  mkdir -p "$codex_home" "$skill_root" "$fake_bin"
  printf 'checkpoint rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    mkdir -p "$skill_root/$skill_name"
    printf 'checkpoint %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  HOME="$home" CODEX_HOME="$codex_home" \
    "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log"
  checkpoint=$(latest_backup "$codex_home/backups")

  printf 'current rules\n' > "$codex_home/AGENTS.md"
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    printf 'current %s\n' "$skill_name" > "$skill_root/$skill_name/SKILL.md"
  done

  cat > "$fake_bin/mv" <<'EOF'
#!/bin/sh
count=0
[ ! -f "$FAKE_MV_COUNT" ] || count=$(cat "$FAKE_MV_COUNT")
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNT"
/bin/mv "$@"
status=$?
if [ "$count" -eq 1 ]; then
  kill -TERM "$PPID"
fi
exit "$status"
EOF
  chmod +x "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAKE_MV_COUNT="$move_count" \
      HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restoration interrupted by TERM exits unsuccessfully'
  else
    pass 'restoration interrupted by TERM exits unsuccessfully'
  fi

  assert_contains 'current rules' "$codex_home/AGENTS.md" \
    'restore TERM interruption reinstates current global rules'
  for skill_name in \
    codex-playbook-dependency-review \
    codex-playbook-quarantine \
    codex-playbook-release
  do
    assert_contains "current $skill_name" "$skill_root/$skill_name/SKILL.md" \
      "$skill_name stays unchanged after restore TERM interruption"
  done
  assert_contains 'restoration interrupted; the pre-restore state was reinstated' \
    "$case_root/restore.log" \
    'restore TERM interruption reports successful recovery'
  assert_contains 'Pre-restore checkpoint:' "$case_root/restore.log" \
    'restore TERM interruption reports its recovery checkpoint'
}

run_untrusted_restore_test() {
  case_root="$test_root/untrusted-restore"
  home="$case_root/home"
  codex_home="$case_root/codex"
  untrusted="$case_root/untrusted"
  mkdir -p "$home" "$codex_home" "$untrusted"
  printf 'keep rules\n' > "$codex_home/AGENTS.md"
  printf 'format=1\nagents=absent\n' > "$untrusted/manifest"

  if HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$untrusted" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses checkpoints outside the managed backup directory'
  else
    pass 'restore refuses checkpoints outside the managed backup directory'
  fi
  assert_contains 'keep rules' "$codex_home/AGENTS.md" \
    'refused restore leaves current rules untouched'
}

run_first_install_and_restore_test
run_refusal_test
run_upgrade_and_checkpoint_test
run_source_preflight_test
run_backup_failure_test
run_install_cleanup_failure_test
run_install_swap_failure_test
run_install_signal_test
run_install_rollback_storage_failure_test
run_restore_copy_failure_test
run_restore_swap_failure_test
run_restore_signal_test
run_untrusted_restore_test

printf '\nAll %s installer lifecycle assertions passed.\n' "$passes"
