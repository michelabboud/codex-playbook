#!/bin/sh

set -eu

usage() {
  printf 'Usage: ./scripts/restore.sh <checkpoint-directory>\n'
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

[ "$#" -eq 1 ] || { usage >&2; exit 64; }
[ -n "${HOME:-}" ] || die 'HOME is not set.'

checkpoint_input=$1
codex_home=${CODEX_HOME:-"$HOME/.codex"}
skills_root="$HOME/.agents/skills"
skill_names='codex-playbook-dependency-review codex-playbook-quarantine codex-playbook-release'
agents_stage_root=''
skills_stage_root=''
agents_previous_root=''
skills_previous_root=''
transaction_started=0
agents_touched=0
skills_touched=''

cleanup_staging() {
  if [ -n "$agents_stage_root" ] && [ -d "$agents_stage_root" ] &&
     ! rm -R "$agents_stage_root"; then
    printf 'WARNING: restore staging remains at %s\n' "$agents_stage_root" >&2
  fi
  if [ -n "$skills_stage_root" ] && [ -d "$skills_stage_root" ] &&
     ! rm -R "$skills_stage_root"; then
    printf 'WARNING: restore staging remains at %s\n' "$skills_stage_root" >&2
  fi
}

trap cleanup_staging EXIT

case "$codex_home" in
  /*) ;;
  *) die 'CODEX_HOME must be an absolute path.' ;;
esac

[ -d "$checkpoint_input" ] && [ ! -L "$checkpoint_input" ] ||
  die 'The checkpoint must be a real directory, not a symlink.'
[ -d "$codex_home/backups" ] || die 'The managed backup directory does not exist.'

checkpoint=$(CDPATH= cd -- "$checkpoint_input" && pwd -P)
backup_root=$(CDPATH= cd -- "$codex_home/backups" && pwd -P)
[ "$(dirname -- "$checkpoint")" = "$backup_root" ] ||
  die 'Refusing a checkpoint outside the managed backup directory.'

case "$(basename -- "$checkpoint")" in
  codex-playbook-preinstall-*|codex-playbook-prerestore-*) ;;
  *) die 'The directory name is not a Codex Playbook checkpoint.' ;;
esac

[ -f "$checkpoint/manifest" ] && [ ! -L "$checkpoint/manifest" ] ||
  die 'The checkpoint manifest is missing or unsafe.'
[ -f "$checkpoint/COMPLETE" ] && [ ! -L "$checkpoint/COMPLETE" ] ||
  die 'The checkpoint is incomplete and cannot be restored.'
grep -Fxq 'format=1' "$checkpoint/manifest" ||
  die 'The checkpoint format is unsupported.'

manifest_state_from() {
  state_manifest=$1
  key=$2
  matches=$(grep -Ec "^${key}=(present|absent)$" "$state_manifest" || true)
  [ "$matches" -eq 1 ] || die "The checkpoint manifest has an invalid $key entry."
  sed -n "s/^${key}=//p" "$state_manifest"
}

manifest_state() {
  manifest_state_from "$checkpoint/manifest" "$1"
}

prerestore_state() {
  manifest_state_from "$prerestore_manifest" "$1"
}

agents_state=$(manifest_state agents)
if [ "$agents_state" = present ]; then
  [ -f "$checkpoint/AGENTS.md" ] && [ ! -L "$checkpoint/AGENTS.md" ] ||
    die 'The checkpointed AGENTS.md is missing or unsafe.'
fi

for skill_name in $skill_names
do
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  skill_state=$(manifest_state "skill_$manifest_key")
  if [ "$skill_state" = present ]; then
    [ -d "$checkpoint/$skill_name" ] && [ ! -L "$checkpoint/$skill_name" ] ||
      die "The checkpointed $skill_name skill is missing or unsafe."
    [ -f "$checkpoint/$skill_name/SKILL.md" ] ||
      die "The checkpointed $skill_name skill has no SKILL.md."
  fi
done

umask 077
mkdir -p "$codex_home"
backup_root="$codex_home/backups"
timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
prerestore=$(mktemp -d "$backup_root/codex-playbook-prerestore-$timestamp-XXXXXX")
prerestore_manifest="$prerestore/manifest"
printf 'format=1\n' > "$prerestore_manifest"

agents_target="$codex_home/AGENTS.md"
if [ -L "$agents_target" ]; then
  die 'Refusing to replace a symlinked global AGENTS.md.'
fi
if [ -f "$agents_target" ]; then
  if ! cp -p "$agents_target" "$prerestore/AGENTS.md"; then
    die "The pre-restore AGENTS.md checkpoint failed before restoration. Incomplete checkpoint: $prerestore"
  fi
  cmp -s "$agents_target" "$prerestore/AGENTS.md" ||
    die "The pre-restore AGENTS.md checkpoint could not be verified at $prerestore."
  printf 'agents=present\n' >> "$prerestore_manifest"
elif [ -e "$agents_target" ]; then
  die 'Refusing to replace a global AGENTS.md that is not a regular file.'
else
  printf 'agents=absent\n' >> "$prerestore_manifest"
fi

for skill_name in $skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  if [ -L "$skill_target" ]; then
    die "Refusing to replace the symlinked skill directory $skill_target."
  fi
  if [ -d "$skill_target" ]; then
    if ! cp -R "$skill_target" "$prerestore/$skill_name"; then
      die "The pre-restore $skill_name checkpoint failed before restoration. Incomplete checkpoint: $prerestore"
    fi
    diff -qr "$skill_target" "$prerestore/$skill_name" >/dev/null ||
      die "The pre-restore $skill_name checkpoint could not be verified at $prerestore."
    printf 'skill_%s=present\n' "$manifest_key" >> "$prerestore_manifest"
  elif [ -e "$skill_target" ]; then
    die "Refusing to replace $skill_target because it is not a directory."
  else
    printf 'skill_%s=absent\n' "$manifest_key" >> "$prerestore_manifest"
  fi
done

chmod 600 "$prerestore_manifest"
printf 'complete\n' > "$prerestore/COMPLETE"
chmod 600 "$prerestore/COMPLETE"

mkdir -p "$skills_root"

agents_stage_root=$(mktemp -d "$codex_home/.codex-playbook-restore-stage.XXXXXX")
skills_stage_root=$(mktemp -d "$skills_root/.codex-playbook-restore-stage.XXXXXX")
if [ "$agents_state" = present ]; then
  install -m 600 "$checkpoint/AGENTS.md" "$agents_stage_root/AGENTS.md"
  cmp -s "$checkpoint/AGENTS.md" "$agents_stage_root/AGENTS.md" ||
    die "AGENTS.md restore staging verification failed. Pre-restore checkpoint: $prerestore"
fi

for skill_name in $skill_names
do
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  skill_state=$(manifest_state "skill_$manifest_key")
  if [ "$skill_state" = present ]; then
    if ! cp -R "$checkpoint/$skill_name" "$skills_stage_root/$skill_name"; then
      die "$skill_name restore staging failed before any destination changed. Pre-restore checkpoint: $prerestore"
    fi
    diff -qr "$checkpoint/$skill_name" "$skills_stage_root/$skill_name" >/dev/null ||
      die "$skill_name restore staging verification failed before any destination changed. Pre-restore checkpoint: $prerestore"
  fi
done

agents_previous_root=$(mktemp -d "$codex_home/.codex-playbook-restore-previous.XXXXXX")
skills_previous_root=$(mktemp -d "$skills_root/.codex-playbook-restore-previous.XXXXXX")

rollback_restore() {
  rollback_failed=0

  if [ "$agents_touched" -eq 1 ]; then
    current_agents_state=$(prerestore_state agents)
    if [ "$current_agents_state" = present ]; then
      if [ -f "$agents_previous_root/AGENTS.md" ]; then
        if [ -e "$agents_target" ]; then
          mv "$agents_target" "$agents_stage_root/failed-AGENTS.md" ||
            rollback_failed=1
        fi
        mv "$agents_previous_root/AGENTS.md" "$agents_target" ||
          rollback_failed=1
      fi
    elif [ -e "$agents_target" ]; then
      mv "$agents_target" "$agents_stage_root/failed-AGENTS.md" || rollback_failed=1
    fi
  fi

  for rollback_skill_name in $skill_names
  do
    case " $skills_touched " in
      *" $rollback_skill_name "*) ;;
      *) continue ;;
    esac
    rollback_target="$skills_root/$rollback_skill_name"
    rollback_key=$(printf '%s' "$rollback_skill_name" | tr '-' '_')
    current_skill_state=$(prerestore_state "skill_$rollback_key")
    if [ "$current_skill_state" = present ]; then
      if [ -d "$skills_previous_root/$rollback_skill_name" ]; then
        if [ -d "$rollback_target" ]; then
          mv "$rollback_target" "$skills_stage_root/failed-$rollback_skill_name" ||
            rollback_failed=1
        fi
        mv "$skills_previous_root/$rollback_skill_name" "$rollback_target" ||
          rollback_failed=1
      fi
    elif [ -d "$rollback_target" ]; then
      mv "$rollback_target" "$skills_stage_root/failed-$rollback_skill_name" ||
        rollback_failed=1
    fi
  done

  transaction_started=0
  [ "$rollback_failed" -eq 0 ]
}

rollback_and_die() {
  failure_message=$1
  if rollback_restore; then
    die "$failure_message The pre-restore state was reinstated. Pre-restore checkpoint: $prerestore"
  else
    die "$failure_message Automatic rollback was incomplete. Restore manually from $prerestore"
  fi
}

handle_signal() {
  if [ "$transaction_started" -eq 1 ]; then
    if rollback_restore; then
      printf 'ERROR: restoration interrupted; the pre-restore state was reinstated. Pre-restore checkpoint: %s\n' \
        "$prerestore" >&2
    else
      printf 'ERROR: interrupted restore rollback was incomplete. Restore manually from %s\n' \
        "$prerestore" >&2
    fi
  fi
  exit 130
}

trap handle_signal HUP INT TERM
transaction_started=1

agents_touched=1
if [ -f "$agents_target" ] &&
   ! mv "$agents_target" "$agents_previous_root/AGENTS.md"; then
  rollback_and_die 'Could not preserve the active AGENTS.md for the restore transaction.'
fi
if [ "$agents_state" = present ] &&
   ! mv "$agents_stage_root/AGENTS.md" "$agents_target"; then
  rollback_and_die 'Could not activate the checkpointed AGENTS.md.'
fi

for skill_name in $skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  skill_state=$(manifest_state "skill_$manifest_key")
  skills_touched="$skills_touched $skill_name"
  if [ -d "$skill_target" ] &&
     ! mv "$skill_target" "$skills_previous_root/$skill_name"; then
    rollback_and_die "Could not preserve the active $skill_name skill."
  fi
  if [ "$skill_state" = present ] &&
     ! mv "$skills_stage_root/$skill_name" "$skill_target"; then
    rollback_and_die "Could not activate the checkpointed $skill_name skill."
  fi
done

if [ "$agents_state" = present ]; then
  cmp -s "$checkpoint/AGENTS.md" "$agents_target" ||
    rollback_and_die 'Restored AGENTS.md verification failed.'
else
  [ ! -e "$agents_target" ] ||
    rollback_and_die 'AGENTS.md removal verification failed.'
fi

for skill_name in $skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  skill_state=$(manifest_state "skill_$manifest_key")
  if [ "$skill_state" = present ]; then
    diff -qr "$checkpoint/$skill_name" "$skill_target" >/dev/null ||
      rollback_and_die "Restored $skill_name verification failed."
  else
    [ ! -e "$skill_target" ] ||
      rollback_and_die "$skill_name removal verification failed."
  fi
done

transaction_started=0
if ! rm -R "$agents_previous_root"; then
  printf 'WARNING: verified pre-restore AGENTS.md copy remains at %s\n' \
    "$agents_previous_root" >&2
fi
if ! rm -R "$skills_previous_root"; then
  printf 'WARNING: verified pre-restore skill copies remain at %s\n' \
    "$skills_previous_root" >&2
fi

printf 'Restored Codex Playbook checkpoint: %s\n' "$checkpoint"
printf 'Pre-restore checkpoint: %s\n' "$prerestore"
