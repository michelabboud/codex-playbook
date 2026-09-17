#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-playbook-tests.XXXXXX")
active_skill_names=$(cat "$repo_root/config/managed-skills.txt")
retired_skill_names=$(cat "$repo_root/config/retired-skills.txt")
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

assert_absent() {
  target=$1
  label=$2
  if [ ! -e "$target" ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

mode_of() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

assert_mode() {
  expected=$1
  target=$2
  label=$3
  actual=$(mode_of "$target")
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    printf 'Expected mode %s, got %s: %s\n' "$expected" "$actual" "$target" >&2
    fail "$label"
  fi
}

assert_active_install() {
  skill_root=$1
  label_prefix=$2
  for skill_name in $active_skill_names
  do
    assert_file_equal       "$repo_root/.agents/skills/$skill_name/SKILL.md"       "$skill_root/$skill_name/SKILL.md"       "$label_prefix: $skill_name"
  done
  for skill_name in $retired_skill_names
  do
    assert_absent "$skill_root/$skill_name"       "$label_prefix: retired $skill_name is inactive"
  done
}

reported_path() {
  label=$1
  log_file=$2
  match_count=$(grep -Fc "$label: " "$log_file" || true)
  [ "$match_count" -eq 1 ] || fail "$log_file must report exactly one $label"
  sed -n "s|^$label: ||p" "$log_file"
}

run_first_install_and_restore_test() {
  case_root="$test_root/first-install"
  home="$case_root/home"
  codex_home="$case_root/custom-codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$skill_root/unrelated" "$codex_home"
  printf 'keep me\n' > "$skill_root/unrelated/SKILL.md"
  printf 'model = "example"\n' > "$codex_home/config.toml"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" > "$case_root/install.log"

  assert_file_equal "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"     'custom CODEX_HOME receives AGENTS.md'
  assert_absent "$home/.codex/AGENTS.md"     'default Codex home stays untouched when CODEX_HOME is set'
  assert_active_install "$skill_root" 'first install matches source'

  backup_dir=$(reported_path 'Recovery checkpoint' "$case_root/install.log")
  [ -n "$backup_dir" ] || fail 'first installation creates a recovery checkpoint'
  assert_contains 'format=2' "$backup_dir/manifest"     'first-install checkpoint uses format 2'
  managed_count=$(grep -c '^managed_skill=' "$backup_dir/manifest")
  if [ "$managed_count" -eq 18 ]; then
    pass 'format-2 checkpoint records the 16 active and two retired skill names'
  else
    fail 'format-2 checkpoint inventory is incomplete'
  fi
  assert_contains 'agents=absent' "$backup_dir/manifest"     'first-install checkpoint records absent AGENTS.md'

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/restore.sh" "$backup_dir" > "$case_root/restore.log"

  assert_absent "$codex_home/AGENTS.md"     'restore removes AGENTS.md that did not exist before installation'
  for skill_name in $active_skill_names $retired_skill_names
  do
    assert_absent "$skill_root/$skill_name"       "restore removes previously absent $skill_name"
  done
  assert_contains 'keep me' "$skill_root/unrelated/SKILL.md"     'restore preserves unrelated skills'
  assert_contains 'model = "example"' "$codex_home/config.toml"     'restore preserves unrelated Codex configuration'
}

run_refusal_test() {
  case_root="$test_root/refusal"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$skill_root/codex-playbook-release" "$codex_home"
  printf 'tailored rules\n' > "$codex_home/AGENTS.md"
  printf 'tailored skill\n' > "$skill_root/codex-playbook-release/SKILL.md"

  if HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'default install refuses to overwrite different global rules'
  else
    pass 'default install refuses to overwrite different global rules'
  fi

  assert_contains 'tailored rules' "$codex_home/AGENTS.md"     'refused install preserves tailored global rules'
  assert_contains 'tailored skill'     "$skill_root/codex-playbook-release/SKILL.md"     'refused install preserves a retired tailored skill'
  assert_absent "$codex_home/backups"     'refused install creates no misleading backup'
}

run_shadowed_agents_refusal_test() {
  case_root="$test_root/shadowed-agents"
  home="$case_root/home"
  codex_home="$case_root/codex"
  mkdir -p "$home" "$codex_home"
  printf 'shadowing rules\n' > "$codex_home/AGENTS.override.md"

  if HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'install refuses a non-empty global AGENTS.override.md'
  else
    pass 'install refuses a non-empty global AGENTS.override.md'
  fi
  assert_contains 'would shadow' "$case_root/install.log"     'shadow refusal explains why installation would be inactive'
  assert_absent "$codex_home/backups"     'shadow refusal occurs before backup or destination writes'
}

write_nested_copy_guard() {
  destination_path=$1
  cat > "$destination_path" <<'EOF'
#!/bin/sh
destination=''
for argument in "$@"
do
  destination=$argument
done
case "$destination" in
  */codex-playbook-preinstall-*/codex-playbook-code|\
  */codex-playbook-prerestore-*/codex-playbook-code)
    printf 'simulated recursive-copy guard\n' >&2
    exit 97
    ;;
esac
exec /bin/cp "$@"
EOF
  chmod +x "$destination_path"
}

run_overlapping_codex_home_refusal_test() {
  case_root="$test_root/overlapping-codex-home"
  home="$case_root/home"
  skill_root="$home/.agents/skills"
  codex_home="$skill_root/codex-playbook-code"
  fake_bin="$case_root/fake-bin"
  mkdir -p "$codex_home" "$fake_bin"
  printf 'keep rules\n' > "$codex_home/AGENTS.md"
  printf 'keep skill\n' > "$codex_home/SKILL.md"
  write_nested_copy_guard "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'install refuses CODEX_HOME inside a managed skill'
  else
    pass 'install refuses CODEX_HOME inside a managed skill'
  fi
  assert_contains 'overlap' "$case_root/install.log" \
    'install explains the CODEX_HOME overlap'
  assert_contains 'keep rules' "$codex_home/AGENTS.md" \
    'overlap refusal preserves global rules'
  assert_contains 'keep skill' "$codex_home/SKILL.md" \
    'overlap refusal preserves the managed skill'
  assert_absent "$codex_home/backups" \
    'install overlap is rejected before checkpoint creation'

  checkpoint="$codex_home/backups/codex-playbook-preinstall-overlap-fixture"
  mkdir -p "$checkpoint"
  printf 'format=2\nagents=absent\nmanaged_skill=codex-playbook-code\nskill_codex_playbook_code=absent\n' \
    > "$checkpoint/manifest"
  printf 'complete\n' > "$checkpoint/COMPLETE"
  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses CODEX_HOME inside a managed skill'
  else
    pass 'restore refuses CODEX_HOME inside a managed skill'
  fi
  assert_contains 'overlap' "$case_root/restore.log" \
    'restore explains the CODEX_HOME overlap'
  assert_contains 'keep rules' "$codex_home/AGENTS.md" \
    'restore overlap refusal preserves global rules'
  assert_contains 'keep skill' "$codex_home/SKILL.md" \
    'restore overlap refusal preserves the managed skill'
  if find "$codex_home/backups" -mindepth 1 -maxdepth 1 -type d \
      -name 'codex-playbook-prerestore-*' -print | grep -q .; then
    fail 'restore overlap is rejected before pre-restore checkpoint creation'
  else
    pass 'restore overlap is rejected before pre-restore checkpoint creation'
  fi
}

run_ambiguous_codex_home_refusal_test() {
  case_root="$test_root/ambiguous-codex-home"
  home="$case_root/home"
  skill_root="$home/.agents/skills"
  managed_skill="$skill_root/codex-playbook-code"
  physical_codex_home="$managed_skill/state"
  codex_home="$case_root/link/../state"
  fake_bin="$case_root/fake-bin"
  mkdir -p "$managed_skill/nested" "$physical_codex_home" "$fake_bin"
  ln -s "$managed_skill/nested" "$case_root/link"
  printf 'keep rules\n' > "$physical_codex_home/AGENTS.md"
  printf 'keep skill\n' > "$managed_skill/SKILL.md"
  write_nested_copy_guard "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'install refuses an ambiguous CODEX_HOME path'
  else
    pass 'install refuses an ambiguous CODEX_HOME path'
  fi
  assert_contains 'must not contain . or .. path components' "$case_root/install.log" \
    'install explains the ambiguous CODEX_HOME refusal'
  assert_contains 'keep rules' "$physical_codex_home/AGENTS.md" \
    'ambiguous install path preserves global rules'
  assert_contains 'keep skill' "$managed_skill/SKILL.md" \
    'ambiguous install path preserves the managed skill'
  assert_absent "$physical_codex_home/backups" \
    'ambiguous install path is rejected before checkpoint creation'

  checkpoint="$physical_codex_home/backups/codex-playbook-preinstall-ambiguous-fixture"
  mkdir -p "$checkpoint"
  printf 'format=2\nagents=absent\nmanaged_skill=codex-playbook-code\nskill_codex_playbook_code=absent\n' \
    > "$checkpoint/manifest"
  printf 'complete\n' > "$checkpoint/COMPLETE"
  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses an ambiguous CODEX_HOME path'
  else
    pass 'restore refuses an ambiguous CODEX_HOME path'
  fi
  assert_contains 'must not contain . or .. path components' "$case_root/restore.log" \
    'restore explains the ambiguous CODEX_HOME refusal'
  assert_contains 'keep rules' "$physical_codex_home/AGENTS.md" \
    'ambiguous restore path preserves global rules'
  assert_contains 'keep skill' "$managed_skill/SKILL.md" \
    'ambiguous restore path preserves the managed skill'
  if find "$physical_codex_home/backups" -mindepth 1 -maxdepth 1 -type d \
      -name 'codex-playbook-prerestore-*' -print | grep -q .; then
    fail 'ambiguous restore path is rejected before pre-restore checkpoint creation'
  else
    pass 'ambiguous restore path is rejected before pre-restore checkpoint creation'
  fi
}

run_upgrade_and_checkpoint_test() {
  case_root="$test_root/upgrade"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p     "$skill_root/codex-playbook-release"     "$skill_root/codex-playbook-quarantine"     "$skill_root/unrelated"     "$codex_home"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  printf 'original release\n' > "$skill_root/codex-playbook-release/SKILL.md"
  printf 'original quarantine\n' > "$skill_root/codex-playbook-quarantine/SKILL.md"
  printf 'unrelated\n' > "$skill_root/unrelated/SKILL.md"
  chmod 640 "$codex_home/AGENTS.md"
  chmod 751 "$skill_root/codex-playbook-quarantine"
  chmod 754 "$skill_root/codex-playbook-quarantine/SKILL.md"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log"
  backup_dir=$(reported_path 'Recovery checkpoint' "$case_root/install.log")

  assert_contains 'original rules' "$backup_dir/AGENTS.md"     'replacement checkpoint preserves original global rules'
  assert_contains 'original release'     "$backup_dir/codex-playbook-release/SKILL.md"     'replacement checkpoint preserves the retired release skill'
  assert_contains 'original quarantine'     "$backup_dir/codex-playbook-quarantine/SKILL.md"     'replacement checkpoint preserves the prior quarantine skill'
  assert_mode 640 "$backup_dir/AGENTS.md" \
    'replacement checkpoint preserves global-rule mode'
  assert_mode 751 "$backup_dir/codex-playbook-quarantine" \
    'replacement checkpoint preserves skill-directory mode'
  assert_mode 754 "$backup_dir/codex-playbook-quarantine/SKILL.md" \
    'replacement checkpoint preserves skill-file mode'
  assert_active_install "$skill_root" 'upgrade activates exact modular inventory'

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/restore.sh" "$backup_dir" > "$case_root/restore.log"

  assert_contains 'original rules' "$codex_home/AGENTS.md"     'restore reinstates checkpointed global rules'
  assert_contains 'original release' "$skill_root/codex-playbook-release/SKILL.md"     'restore reinstates a retired checkpointed skill'
  assert_contains 'original quarantine' "$skill_root/codex-playbook-quarantine/SKILL.md"     'restore reinstates the prior current skill'
  assert_mode 640 "$codex_home/AGENTS.md" \
    'restore reinstates global-rule mode'
  assert_mode 751 "$skill_root/codex-playbook-quarantine" \
    'restore reinstates skill-directory mode'
  assert_mode 754 "$skill_root/codex-playbook-quarantine/SKILL.md" \
    'restore reinstates skill-file mode'
  for skill_name in $active_skill_names
  do
    case "$skill_name" in
      codex-playbook-quarantine) continue ;;
    esac
    assert_absent "$skill_root/$skill_name"       "restore removes new-only skill $skill_name"
  done
  assert_contains 'unrelated' "$skill_root/unrelated/SKILL.md"     'upgrade and restore preserve unrelated skills'
}

run_unique_checkpoint_test() {
  case_root="$test_root/unique-checkpoints"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$home" "$codex_home"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" > "$case_root/install-one.log"
  backup_one=$(reported_path 'Recovery checkpoint' "$case_root/install-one.log")

  printf 'second local rules\n' > "$codex_home/AGENTS.md"
  printf 'second local skill\n' > "$skill_root/codex-playbook-code/SKILL.md"
  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install-two.log"
  backup_two=$(reported_path 'Recovery checkpoint' "$case_root/install-two.log")

  if [ "$backup_one" != "$backup_two" ]; then
    pass 'each installation creates a unique checkpoint'
  else
    fail 'each installation creates a unique checkpoint'
  fi
  assert_contains 'second local rules' "$backup_two/AGENTS.md"     'later checkpoint captures immediately previous global rules'
  assert_contains 'second local skill'     "$backup_two/codex-playbook-code/SKILL.md"     'later checkpoint captures immediately previous skill rules'
  assert_contains 'agents=absent' "$backup_one/manifest"     'later installs do not rewrite earlier checkpoints'
}

run_source_preflight_test() {
  case_root="$test_root/source-preflight"
  home="$case_root/home"
  codex_home="$case_root/codex"
  broken_repo="$case_root/broken-repo"
  mkdir -p "$home" "$codex_home" "$broken_repo/scripts"
  cp "$repo_root/scripts/install.sh" "$broken_repo/scripts/install.sh"
  chmod +x "$broken_repo/scripts/install.sh"

  if HOME="$home" CODEX_HOME="$codex_home"       "$broken_repo/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'install refuses an incomplete source checkout'
  else
    pass 'install refuses an incomplete source checkout'
  fi
  assert_absent "$codex_home/AGENTS.md"     'source preflight failure leaves global rules untouched'
  assert_absent "$home/.agents/skills"     'source preflight failure writes no skill directories'
}

run_invalid_inventory_test() {
  case_root="$test_root/invalid-inventory"
  home="$case_root/home"
  codex_home="$case_root/codex"
  broken_repo="$case_root/broken-repo"
  mkdir -p "$home" "$codex_home" "$broken_repo/scripts" "$broken_repo/config"
  cp "$repo_root/scripts/install.sh" "$broken_repo/scripts/install.sh"
  cp "$repo_root/scripts/restore.sh" "$broken_repo/scripts/restore.sh"
  cp "$repo_root/AGENTS.md" "$broken_repo/AGENTS.md"
  cp "$repo_root/VERSION" "$broken_repo/VERSION"
  cp "$repo_root/config/retired-skills.txt" "$broken_repo/config/retired-skills.txt"
  printf '../outside\n' > "$broken_repo/config/managed-skills.txt"
  chmod +x "$broken_repo/scripts/install.sh" "$broken_repo/scripts/restore.sh"

  if HOME="$home" CODEX_HOME="$codex_home"       "$broken_repo/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'install refuses an invalid managed skill name'
  else
    pass 'install refuses an invalid managed skill name'
  fi
  assert_absent "$codex_home/backups"     'invalid inventory is rejected before checkpoint creation'
}

run_backup_failure_test() {
  case_root="$test_root/backup-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  mkdir -p "$skill_root/codex-playbook-code" "$codex_home" "$fake_bin"
  cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"
  printf 'preserve this skill\n' > "$skill_root/codex-playbook-code/SKILL.md"
  cat > "$fake_bin/cp" <<'EOF'
#!/bin/sh
printf 'simulated backup copy failure\n' >&2
exit 1
EOF
  chmod +x "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    fail 'a backup copy failure aborts installation'
  else
    pass 'a backup copy failure aborts installation'
  fi
  assert_file_equal "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"     'backup failure leaves global rules unchanged'
  assert_contains 'preserve this skill'     "$skill_root/codex-playbook-code/SKILL.md"     'backup failure leaves managed skills unchanged'
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
  mkdir -p "$codex_home" "$skill_root/codex-playbook-code" "$fake_bin"
  cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"
  printf 'old code skill\n' > "$skill_root/codex-playbook-code/SKILL.md"
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

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" > "$case_root/install.log" 2>&1; then
    pass 'redundant-copy cleanup failure does not invalidate installation'
  else
    fail 'redundant-copy cleanup failure does not invalidate installation'
  fi
  assert_active_install "$skill_root" 'install remains complete after cleanup warning'
  assert_contains 'WARNING:' "$case_root/install.log"     'cleanup failure is reported rather than swallowed'
}

write_fail_once_mv() {
  destination_path=$1
  cat > "$destination_path" <<'EOF'
#!/bin/sh
destination=''
for argument in "$@"
do
  destination=$argument
done
case "$destination" in
  */codex-playbook-environment)
    if [ ! -e "$FAIL_ONCE_MARKER" ]; then
      : > "$FAIL_ONCE_MARKER"
      printf 'simulated skill activation failure\n' >&2
      exit 1
    fi
    ;;
esac
exec /bin/mv "$@"
EOF
  chmod +x "$destination_path"
}

write_signal_mv() {
  destination_path=$1
  cat > "$destination_path" <<'EOF'
#!/bin/sh
destination=''
for argument in "$@"
do
  destination=$argument
done
/bin/mv "$@" || exit $?
case "$destination" in
  */codex-playbook-environment)
    if [ ! -e "$SIGNAL_ONCE_MARKER" ]; then
      : > "$SIGNAL_ONCE_MARKER"
      kill -TERM "$PPID"
    fi
    ;;
esac
exit 0
EOF
  chmod +x "$destination_path"
}

seed_original_managed_state() {
  skill_root=$1
  codex_home=$2
  mkdir -p     "$skill_root/codex-playbook-code"     "$skill_root/codex-playbook-release"     "$codex_home"
  printf 'original rules\n' > "$codex_home/AGENTS.md"
  printf 'original code\n' > "$skill_root/codex-playbook-code/SKILL.md"
  printf 'original release\n' > "$skill_root/codex-playbook-release/SKILL.md"
}

assert_original_managed_state() {
  skill_root=$1
  codex_home=$2
  label_prefix=$3
  assert_contains 'original rules' "$codex_home/AGENTS.md"     "$label_prefix: global rules restored"
  assert_contains 'original code' "$skill_root/codex-playbook-code/SKILL.md"     "$label_prefix: current skill restored"
  assert_contains 'original release' "$skill_root/codex-playbook-release/SKILL.md"     "$label_prefix: retired skill restored"
  for skill_name in $active_skill_names
  do
    case "$skill_name" in
      codex-playbook-code) continue ;;
    esac
    assert_absent "$skill_root/$skill_name"       "$label_prefix: partial skill $skill_name removed"
  done
}

run_install_swap_failure_test() {
  case_root="$test_root/install-swap-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  marker="$case_root/fail-once"
  seed_original_managed_state "$skill_root" "$codex_home"
  mkdir -p "$fake_bin"
  write_fail_once_mv "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAIL_ONCE_MARKER="$marker"       HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'install skill activation failure aborts installation'
  else
    pass 'install skill activation failure aborts installation'
  fi
  assert_original_managed_state "$skill_root" "$codex_home"     'install activation rollback'
  assert_contains 'verified checkpoint was restored' "$case_root/install.log"     'install activation failure reports successful rollback'
}

run_install_signal_test() {
  case_root="$test_root/install-signal"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  marker="$case_root/signal-once"
  seed_original_managed_state "$skill_root" "$codex_home"
  mkdir -p "$fake_bin"
  write_signal_mv "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" SIGNAL_ONCE_MARKER="$marker"       HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'installation interrupted by TERM exits unsuccessfully'
  else
    pass 'installation interrupted by TERM exits unsuccessfully'
  fi
  assert_original_managed_state "$skill_root" "$codex_home"     'install TERM rollback'
  assert_contains 'interrupted; the verified checkpoint was restored'     "$case_root/install.log"     'TERM interruption reports successful recovery'
}

run_install_rollback_storage_failure_test() {
  case_root="$test_root/install-rollback-storage-failure"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  fake_bin="$case_root/fake-bin"
  seed_original_managed_state "$skill_root" "$codex_home"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/mktemp" <<'EOF'
#!/bin/sh
case "$*" in
  *'.codex-playbook.previous.'*)
    printf 'simulated rollback storage allocation failure\n' >&2
    exit 1
    ;;
esac
exec /usr/bin/mktemp "$@"
EOF
  chmod +x "$fake_bin/mktemp"

  if PATH="$fake_bin:$PATH" HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log" 2>&1; then
    fail 'rollback storage allocation failure aborts installation'
  else
    pass 'rollback storage allocation failure aborts installation'
  fi
  assert_original_managed_state "$skill_root" "$codex_home"     'rollback storage safe abort'
  assert_contains 'before managed destinations changed' "$case_root/install.log"     'rollback storage failure reports the safe abort point'
}

prepare_restore_case() {
  case_root=$1
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$skill_root/codex-playbook-code" "$codex_home"
  printf 'checkpoint rules\n' > "$codex_home/AGENTS.md"
  printf 'checkpoint code\n' > "$skill_root/codex-playbook-code/SKILL.md"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" --replace-agents > "$case_root/install.log"
  checkpoint=$(reported_path 'Recovery checkpoint' "$case_root/install.log")

  printf 'current rules\n' > "$codex_home/AGENTS.md"
  printf 'current code\n' > "$skill_root/codex-playbook-code/SKILL.md"
}

assert_current_restore_state() {
  skill_root=$1
  codex_home=$2
  label_prefix=$3
  assert_contains 'current rules' "$codex_home/AGENTS.md"     "$label_prefix: current global rules retained"
  assert_contains 'current code' "$skill_root/codex-playbook-code/SKILL.md"     "$label_prefix: current skill retained"
}

run_restore_copy_failure_test() {
  case_root="$test_root/restore-copy-failure"
  prepare_restore_case "$case_root"
  fake_bin="$case_root/fake-bin"
  marker="$case_root/fail-once"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/cp" <<'EOF'
#!/bin/sh
case "$*" in
  *'codex-playbook-code'*'.codex-playbook-restore-stage.'*)
    if [ ! -e "$FAIL_ONCE_MARKER" ]; then
      : > "$FAIL_ONCE_MARKER"
      printf 'simulated restore staging failure\n' >&2
      exit 1
    fi
    ;;
esac
exec /bin/cp "$@"
EOF
  chmod +x "$fake_bin/cp"

  if PATH="$fake_bin:$PATH" FAIL_ONCE_MARKER="$marker"       HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore staging failure aborts restoration'
  else
    pass 'restore staging failure aborts restoration'
  fi
  assert_current_restore_state "$skill_root" "$codex_home"     'restore staging safe abort'
  assert_contains 'Pre-restore checkpoint:' "$case_root/restore.log"     'restore staging failure reports its recovery checkpoint'
}

run_restore_swap_failure_test() {
  case_root="$test_root/restore-swap-failure"
  prepare_restore_case "$case_root"
  fake_bin="$case_root/fake-bin"
  marker="$case_root/fail-once"
  mkdir -p "$fake_bin"
  write_fail_once_mv "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" FAIL_ONCE_MARKER="$marker"       HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore activation failure aborts restoration'
  else
    pass 'restore activation failure aborts restoration'
  fi
  assert_current_restore_state "$skill_root" "$codex_home"     'restore activation rollback'
  assert_contains 'pre-restore state was reinstated' "$case_root/restore.log"     'restore activation failure reports successful rollback'
}

run_restore_signal_test() {
  case_root="$test_root/restore-signal"
  prepare_restore_case "$case_root"
  fake_bin="$case_root/fake-bin"
  marker="$case_root/signal-once"
  mkdir -p "$fake_bin"
  write_signal_mv "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" SIGNAL_ONCE_MARKER="$marker"       HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restoration interrupted by TERM exits unsuccessfully'
  else
    pass 'restoration interrupted by TERM exits unsuccessfully'
  fi
  assert_current_restore_state "$skill_root" "$codex_home"     'restore TERM rollback'
  assert_contains 'restoration interrupted; the pre-restore state was reinstated'     "$case_root/restore.log"     'restore TERM interruption reports successful recovery'
}

run_legacy_format_one_restore_test() {
  case_root="$test_root/legacy-format-one"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  mkdir -p "$home" "$codex_home"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/install.sh" > "$case_root/install.log"
  mkdir -p "$skill_root/unrelated"
  printf 'unrelated\n' > "$skill_root/unrelated/SKILL.md"

  legacy="$codex_home/backups/codex-playbook-preinstall-legacy-format-one"
  mkdir -p     "$legacy/codex-playbook-dependency-review"     "$legacy/codex-playbook-quarantine"     "$legacy/codex-playbook-release"
  printf 'legacy global rules\n' > "$legacy/AGENTS.md"
  printf 'legacy dependency\n' > "$legacy/codex-playbook-dependency-review/SKILL.md"
  printf 'legacy quarantine\n' > "$legacy/codex-playbook-quarantine/SKILL.md"
  printf 'legacy release\n' > "$legacy/codex-playbook-release/SKILL.md"
  cat > "$legacy/manifest" <<'EOF'
format=1
agents=present
skill_codex_playbook_dependency_review=present
skill_codex_playbook_quarantine=present
skill_codex_playbook_release=present
EOF
  printf 'complete\n' > "$legacy/COMPLETE"

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/restore.sh" "$legacy" > "$case_root/restore-legacy.log"
  prerestore=$(reported_path 'Pre-restore checkpoint' "$case_root/restore-legacy.log")

  assert_contains 'legacy global rules' "$codex_home/AGENTS.md"     'format-1 restore reinstates legacy global rules'
  assert_contains 'legacy dependency'     "$skill_root/codex-playbook-dependency-review/SKILL.md"     'format-1 restore reinstates legacy dependency skill'
  assert_contains 'legacy quarantine'     "$skill_root/codex-playbook-quarantine/SKILL.md"     'format-1 restore reinstates legacy quarantine skill'
  assert_contains 'legacy release'     "$skill_root/codex-playbook-release/SKILL.md"     'format-1 restore reinstates legacy release skill'
  for skill_name in $active_skill_names
  do
    case "$skill_name" in
      codex-playbook-quarantine) continue ;;
    esac
    assert_absent "$skill_root/$skill_name"       "format-1 restore removes new-only skill $skill_name"
  done
  assert_contains 'unrelated' "$skill_root/unrelated/SKILL.md"     'format-1 restore preserves unrelated skills'

  HOME="$home" CODEX_HOME="$codex_home"     "$repo_root/scripts/restore.sh" "$prerestore" > "$case_root/restore-format-two.log"
  assert_file_equal "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"     'format-2 pre-restore checkpoint recovers modular global rules'
  assert_active_install "$skill_root"     'format-2 pre-restore checkpoint recovers exact modular inventory'
  assert_contains 'unrelated' "$skill_root/unrelated/SKILL.md"     'format-2 round trip preserves unrelated skills'
}

run_invalid_complete_marker_test() {
  case_root="$test_root/invalid-complete-marker"
  home="$case_root/home"
  codex_home="$case_root/codex"
  checkpoint="$codex_home/backups/codex-playbook-preinstall-invalid-complete"
  mkdir -p "$home" "$checkpoint"
  printf 'keep rules\n' > "$codex_home/AGENTS.md"
  printf 'format=2\nagents=absent\nmanaged_skill=codex-playbook-code\nskill_codex_playbook_code=absent\n' \
    > "$checkpoint/manifest"
  : > "$checkpoint/COMPLETE"

  if HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses an invalid COMPLETE marker'
  else
    pass 'restore refuses an invalid COMPLETE marker'
  fi
  assert_contains 'keep rules' "$codex_home/AGENTS.md" \
    'invalid COMPLETE marker leaves current rules untouched'
}

run_invalid_manifest_state_test() {
  case_root="$test_root/invalid-manifest-state"
  home="$case_root/home"
  codex_home="$case_root/codex"
  skill_root="$home/.agents/skills"
  checkpoint="$codex_home/backups/codex-playbook-preinstall-invalid-state"
  mkdir -p "$skill_root/codex-playbook-code" \
    "$checkpoint/codex-playbook-code"
  printf 'current rules\n' > "$codex_home/AGENTS.md"
  printf 'current skill\n' > "$skill_root/codex-playbook-code/SKILL.md"
  printf 'checkpoint rules\n' > "$checkpoint/AGENTS.md"
  printf 'checkpoint skill\n' > "$checkpoint/codex-playbook-code/SKILL.md"
  cat > "$checkpoint/manifest" <<'EOF'
format=2
managed_skill=codex-playbook-code
agents=present
agents=garbage
skill_codex_playbook_code=present
skill_codex_playbook_code=garbage
EOF
  printf 'complete\n' > "$checkpoint/COMPLETE"

  if HOME="$home" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$checkpoint" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses duplicate or invalid manifest state entries'
  else
    pass 'restore refuses duplicate or invalid manifest state entries'
  fi
  assert_contains 'current rules' "$codex_home/AGENTS.md" \
    'invalid manifest state leaves current rules untouched'
  assert_contains 'current skill' "$skill_root/codex-playbook-code/SKILL.md" \
    'invalid manifest state leaves current skills untouched'
}

run_untrusted_restore_test() {
  case_root="$test_root/untrusted-restore"
  home="$case_root/home"
  codex_home="$case_root/codex"
  untrusted="$case_root/untrusted"
  mkdir -p "$home" "$codex_home" "$untrusted"
  printf 'keep rules\n' > "$codex_home/AGENTS.md"
  printf 'format=2\nagents=absent\nmanaged_skill=codex-playbook-code\nskill_codex_playbook_code=absent\n'     > "$untrusted/manifest"
  printf 'complete\n' > "$untrusted/COMPLETE"

  if HOME="$home" CODEX_HOME="$codex_home"       "$repo_root/scripts/restore.sh" "$untrusted" > "$case_root/restore.log" 2>&1; then
    fail 'restore refuses checkpoints outside the managed backup directory'
  else
    pass 'restore refuses checkpoints outside the managed backup directory'
  fi
  assert_contains 'keep rules' "$codex_home/AGENTS.md"     'refused restore leaves current rules untouched'
}

run_first_install_and_restore_test
run_refusal_test
run_shadowed_agents_refusal_test
run_overlapping_codex_home_refusal_test
run_ambiguous_codex_home_refusal_test
run_upgrade_and_checkpoint_test
run_unique_checkpoint_test
run_source_preflight_test
run_invalid_inventory_test
run_backup_failure_test
run_install_cleanup_failure_test
run_install_swap_failure_test
run_install_signal_test
run_install_rollback_storage_failure_test
run_restore_copy_failure_test
run_restore_swap_failure_test
run_restore_signal_test
run_legacy_format_one_restore_test
run_invalid_complete_marker_test
run_invalid_manifest_state_test
run_untrusted_restore_test

printf '\nAll %s installer lifecycle assertions passed.\n' "$passes"
