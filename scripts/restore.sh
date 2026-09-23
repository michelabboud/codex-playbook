#!/bin/sh

set -eu

usage() {
  printf 'Usage: ./scripts/restore.sh <checkpoint-directory>\n'
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

validate_skill_name() {
  printf '%s\n' "$1" | grep -Eq '^codex-playbook-[a-z]+(-[a-z]+)*$' ||
    die "The checkpoint contains an invalid managed skill name: $1"
}

# These scripts use line-oriented manifests and shell command substitution.
# Reject control bytes instead of silently resolving a different pathname.
validate_path_encoding() {
  case "$1" in
    *'
'*) die 'A path contains an unsupported control character.' ;;
  esac
  if printf '%s' "$1" | LC_ALL=C grep -q '[[:cntrl:]]'; then
    die 'A path contains an unsupported control character.'
  fi
}

physical_directory_for_check() {
  # Keep pwd's final delimiter until after capture, so a pathname's own
  # trailing newline cannot disappear during command substitution.
  physical_output=$(CDPATH='' cd -P -- "$1" && pwd -P && printf '.') ||
    die 'A path could not be physically resolved.'
  physical_output=${physical_output%.}
  physical_output=${physical_output%'
'}
  validate_path_encoding "$physical_output"
  printf '%s\n' "$physical_output"
}

canonical_path_for_check() {
  validate_path_encoding "$1"
  # Resolve the existing prefix before handling a missing suffix. Never
  # collapse .. lexically across a symlink.
  existing_path=$1
  missing_suffix=''
  while [ ! -d "$existing_path" ]
  do
    [ ! -e "$existing_path" ] || {
      printf 'ERROR: path component is not a directory: %s\n' "$existing_path" >&2
      return 1
    }
    path_component=${existing_path##*/}
    missing_suffix="/$path_component$missing_suffix"
    existing_path=${existing_path%/*}
    [ -n "$existing_path" ] || existing_path=/
  done
  physical_path=$(physical_directory_for_check "$existing_path") || return 1
  if [ "$physical_path" = / ]; then
    printf '/%s\n' "${missing_suffix#/}"
  else
    printf '%s%s\n' "$physical_path" "$missing_suffix"
  fi
}

resolve_local_link_target() {
  link_path=$1
  link_hops=0
  while [ -L "$link_path" ]
  do
    link_hops=$((link_hops + 1))
    [ "$link_hops" -le 40 ] || die 'The local-file symlink chain is too deep to verify.'
    link_value=$(readlink "$link_path" && printf '.') ||
      die 'The local-file symlink target could not be read.'
    link_value=${link_value%.}
    link_value=${link_value%'
'}
    validate_path_encoding "$link_value"
    case "$link_value" in
      /*) link_path=$link_value ;;
      *) link_path=$(dirname -- "$link_path")/$link_value ;;
    esac
    link_parent=$(physical_directory_for_check "$(dirname -- "$link_path")") ||
      die 'The local-file symlink target could not be resolved.'
    link_path=$link_parent/$(basename -- "$link_path")
  done
  [ -f "$link_path" ] || die 'The local-file symlink target is not a regular file.'
  printf '%s\n' "$link_path"
}

manifest_state_from() {
  state_manifest=$1
  key=$2
  matches=$(grep -Ec "^$key=" "$state_manifest" || true)
  [ "$matches" -eq 1 ] || die "The checkpoint manifest has an invalid $key entry."
  state_value=$(sed -n "s/^$key=//p" "$state_manifest")
  case "$state_value" in
    present|absent) printf '%s\n' "$state_value" ;;
    *) die "The checkpoint manifest has an invalid $key entry." ;;
  esac
}

list_contains() {
  list_value=$1
  sought_value=$2
  for listed_value in $list_value
  do
    [ "$listed_value" != "$sought_value" ] || return 0
  done
  return 1
}

checkpoint_skill_state() {
  requested_skill=$1
  if list_contains "$checkpoint_skill_names" "$requested_skill"; then
    requested_key=$(printf '%s' "$requested_skill" | tr '-' '_')
    manifest_state_from "$checkpoint/manifest" "skill_$requested_key"
  else
    printf 'absent\n'
  fi
}

prerestore_state() {
  manifest_state_from "$prerestore_manifest" "$1"
}

[ "$#" -eq 1 ] || { usage >&2; exit 64; }
[ -n "${HOME:-}" ] || die 'HOME is not set.'

checkpoint_input=$1
# Check the invocation before dirname can strip bytes, then resolve physically
# with the same byte-preserving validation used for destination paths.
validate_path_encoding "$0"
repo_root=$(physical_directory_for_check "$(dirname -- "$0")/..")
codex_home=${CODEX_HOME:-"$HOME/.codex"}
skills_root="$HOME/.agents/skills"
active_inventory="$repo_root/config/managed-skills.txt"
retired_inventory="$repo_root/config/retired-skills.txt"
legacy_skill_names='codex-playbook-dependency-review codex-playbook-quarantine codex-playbook-release'
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
case "$codex_home/" in
  */./*|*/../*) die 'CODEX_HOME must not contain . or .. path components.' ;;
esac
case "$HOME" in
  /*) ;;
  *) die 'HOME must be an absolute path.' ;;
esac
case "$HOME/" in
  */./*|*/../*) die 'HOME must not contain . or .. path components.' ;;
esac
validate_path_encoding "$HOME"
validate_path_encoding "$codex_home"

[ -f "$active_inventory" ] && [ ! -L "$active_inventory" ] ||
  die 'The active skill inventory is missing or unsafe.'
[ -f "$retired_inventory" ] && [ ! -L "$retired_inventory" ] ||
  die 'The retired skill inventory is missing or unsafe.'

current_managed_skill_names=$(
  {
    cat "$active_inventory"
    cat "$retired_inventory"
  } | LC_ALL=C sort -u
)
for skill_name in $current_managed_skill_names
do
  validate_skill_name "$skill_name"
done

[ -d "$checkpoint_input" ] && [ ! -L "$checkpoint_input" ] ||
  die 'The checkpoint must be a real directory, not a symlink.'
[ -d "$codex_home/backups" ] || die 'The managed backup directory does not exist.'

validate_path_encoding "$checkpoint_input"
checkpoint=$(physical_directory_for_check "$checkpoint_input")
backup_root=$(physical_directory_for_check "$codex_home/backups")
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
complete_marker_size=$(wc -c < "$checkpoint/COMPLETE" | tr -d ' ')
[ "$complete_marker_size" -eq 9 ] && grep -Fxq 'complete' "$checkpoint/COMPLETE" ||
  die 'The checkpoint completion marker is invalid.'

format_matches=$(grep -Ec '^format=(1|2)$' "$checkpoint/manifest" || true)
[ "$format_matches" -eq 1 ] ||
  die 'The checkpoint format entry is missing or ambiguous.'
checkpoint_format=$(sed -n 's/^format=//p' "$checkpoint/manifest")

case "$checkpoint_format" in
  1)
    checkpoint_skill_names=$legacy_skill_names
    ;;
  2)
    checkpoint_skill_names=$(sed -n 's/^managed_skill=//p' "$checkpoint/manifest")
    [ -n "$checkpoint_skill_names" ] ||
      die 'The format-2 checkpoint has no managed skill inventory.'
    duplicate_checkpoint_skills=$(printf '%s\n' "$checkpoint_skill_names" | LC_ALL=C sort | uniq -d)
    [ -z "$duplicate_checkpoint_skills" ] ||
      die 'The format-2 checkpoint repeats a managed skill.'
    ;;
  *)
    die 'The checkpoint format is unsupported.'
    ;;
esac

for skill_name in $checkpoint_skill_names
do
  validate_skill_name "$skill_name"
done

transition_skill_names=$(
  {
    printf '%s\n' "$current_managed_skill_names"
    printf '%s\n' "$checkpoint_skill_names"
  } | tr ' ' '\n' | sed '/^$/d' | LC_ALL=C sort -u
)

canonical_codex_home=$(canonical_path_for_check "$codex_home")
for skill_name in $transition_skill_names
do
  canonical_skill_target=$(canonical_path_for_check "$skills_root/$skill_name")
  case "$canonical_codex_home" in
    "$canonical_skill_target"|"$canonical_skill_target"/*)
      die "CODEX_HOME overlaps the managed skill directory $skills_root/$skill_name."
      ;;
  esac
done

agents_state=$(manifest_state_from "$checkpoint/manifest" agents)
if [ "$agents_state" = present ]; then
  [ -f "$checkpoint/AGENTS.md" ] && [ ! -L "$checkpoint/AGENTS.md" ] ||
    die 'The checkpointed AGENTS.md is missing or unsafe.'
fi

for skill_name in $checkpoint_skill_names
do
  skill_state=$(checkpoint_skill_state "$skill_name")
  if [ "$skill_state" = present ]; then
    [ -d "$checkpoint/$skill_name" ] && [ ! -L "$checkpoint/$skill_name" ] ||
      die "The checkpointed $skill_name skill is missing or unsafe."
    [ -f "$checkpoint/$skill_name/SKILL.md" ] &&
      [ ! -L "$checkpoint/$skill_name/SKILL.md" ] ||
      die "The checkpointed $skill_name skill has no safe SKILL.md."
  fi
done

# A restore changes the managed text beneath the user's standing local layer.
# Validate that layer against the checkpoint, before creating a pre-restore
# checkpoint or touching any managed destination. A stale Override is suspended
# until its owner rewrites it; restoring past it would silently make it inert.
"$repo_root/scripts/check-local.sh" "$codex_home/playbook-local.md" \
  "$checkpoint" "$checkpoint" ||
  die "The local layer at $codex_home/playbook-local.md does not match the checkpoint text this restore would install. Re-read the rules named above and rewrite those entries; there is no flag to restore past this."

if [ -L "$codex_home/playbook-local.md" ]; then
  local_link_target=$(resolve_local_link_target "$codex_home/playbook-local.md")
  case "$local_link_target" in
    "$canonical_codex_home/AGENTS.md")
      die 'The local-file symlink targets a managed destination that restoration would replace.' ;;
  esac
  for skill_name in $transition_skill_names
  do
    canonical_skill_target=$(canonical_path_for_check "$skills_root/$skill_name")
    case "$local_link_target" in
      "$canonical_skill_target"|"$canonical_skill_target"/*)
        die 'The local-file symlink targets a managed destination that restoration would replace.' ;;
    esac
  done
fi

# A Fill or Add has no Dead-words verifier. Even an Override can bind to an
# unchanged section of an older router, so freshness alone cannot prove that
# restored instructions would load the local file. Accept only the complete
# known active router shipped by this checkout: a matching paragraph inside a
# fenced example is not an instruction. An older or tailored checkpoint waits
# for an owner-led compatibility decision; this script never changes the local file.
if [ -e "$codex_home/playbook-local.md" ] || [ -L "$codex_home/playbook-local.md" ]; then
  [ "$agents_state" = present ] ||
    die 'The checkpoint does not load the local layer: it has no AGENTS.md. No destination was changed.'
  cmp -s "$repo_root/AGENTS.md" "$checkpoint/AGENTS.md" ||
    die 'The checkpoint does not load the local layer: it is not a known active local-layer router from this checkout. No destination was changed.'
fi

override_target="$codex_home/AGENTS.override.md"
if [ -L "$override_target" ] || { [ -e "$override_target" ] && [ ! -f "$override_target" ]; }; then
  die 'Refusing restore because the global AGENTS.override.md is unsafe.'
fi
if [ -s "$override_target" ]; then
  die 'A non-empty global AGENTS.override.md would shadow the restored AGENTS.md and its local-layer instruction.'
fi

agents_target="$codex_home/AGENTS.md"
if [ -L "$agents_target" ]; then
  die 'Refusing to replace a symlinked global AGENTS.md.'
fi
if [ -e "$agents_target" ] && [ ! -f "$agents_target" ]; then
  die 'Refusing to replace a global AGENTS.md that is not a regular file.'
fi
for skill_name in $transition_skill_names
do
  skill_target="$skills_root/$skill_name"
  if [ -L "$skill_target" ]; then
    die "Refusing to replace the symlinked skill directory $skill_target."
  fi
  if [ -e "$skill_target" ] && [ ! -d "$skill_target" ]; then
    die "Refusing to replace $skill_target because it is not a directory."
  fi
done

umask 077
mkdir -p "$codex_home" "$skills_root"
backup_root="$codex_home/backups"
timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
prerestore=$(mktemp -d "$backup_root/codex-playbook-prerestore-$timestamp-XXXXXX")
prerestore_manifest="$prerestore/manifest"
printf 'format=2\n' > "$prerestore_manifest"
for skill_name in $transition_skill_names
do
  printf 'managed_skill=%s\n' "$skill_name" >> "$prerestore_manifest"
done

if [ -f "$agents_target" ]; then
  if ! cp -p "$agents_target" "$prerestore/AGENTS.md"; then
    die "The pre-restore AGENTS.md checkpoint failed before restoration. Incomplete checkpoint: $prerestore"
  fi
  cmp -s "$agents_target" "$prerestore/AGENTS.md" ||
    die "The pre-restore AGENTS.md checkpoint could not be verified at $prerestore."
  printf 'agents=present\n' >> "$prerestore_manifest"
else
  printf 'agents=absent\n' >> "$prerestore_manifest"
fi

for skill_name in $transition_skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  if [ -d "$skill_target" ]; then
    if ! cp -pR "$skill_target" "$prerestore/$skill_name"; then
      die "The pre-restore $skill_name checkpoint failed before restoration. Incomplete checkpoint: $prerestore"
    fi
    diff -qr "$skill_target" "$prerestore/$skill_name" >/dev/null ||
      die "The pre-restore $skill_name checkpoint could not be verified at $prerestore."
    printf 'skill_%s=present\n' "$manifest_key" >> "$prerestore_manifest"
  else
    printf 'skill_%s=absent\n' "$manifest_key" >> "$prerestore_manifest"
  fi
done

chmod 600 "$prerestore_manifest"
printf 'complete\n' > "$prerestore/COMPLETE"
chmod 600 "$prerestore/COMPLETE"

agents_stage_root=$(mktemp -d "$codex_home/.codex-playbook-restore-stage.XXXXXX")
skills_stage_root=$(mktemp -d "$skills_root/.codex-playbook-restore-stage.XXXXXX")
if [ "$agents_state" = present ]; then
  cp -p "$checkpoint/AGENTS.md" "$agents_stage_root/AGENTS.md"
  cmp -s "$checkpoint/AGENTS.md" "$agents_stage_root/AGENTS.md" ||
    die "AGENTS.md restore staging verification failed. Pre-restore checkpoint: $prerestore"
fi

for skill_name in $transition_skill_names
do
  skill_state=$(checkpoint_skill_state "$skill_name")
  if [ "$skill_state" = present ]; then
    if ! cp -pR "$checkpoint/$skill_name" "$skills_stage_root/$skill_name"; then
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

  for rollback_skill_name in $transition_skill_names
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
  trap - HUP INT TERM
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

for skill_name in $transition_skill_names
do
  skill_target="$skills_root/$skill_name"
  skill_state=$(checkpoint_skill_state "$skill_name")
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

for skill_name in $transition_skill_names
do
  skill_target="$skills_root/$skill_name"
  skill_state=$(checkpoint_skill_state "$skill_name")
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
