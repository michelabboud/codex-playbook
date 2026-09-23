#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--replace-agents]

Install the Codex Playbook global authority router and personal skills.

By default, installation refuses to replace a different global AGENTS.md.
Pass --replace-agents only after reviewing or merging existing rules. A unique,
verified recovery checkpoint is always completed before any destination changes.
EOF
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

skill_name_pattern='^codex-playbook-[a-z]+(-[a-z]+)*$'
resource_path_pattern='^\.agents/skills/codex-playbook-[a-z]+(-[a-z]+)*(/[A-Za-z0-9_-]+)*/[A-Za-z0-9_-]+(\.[A-Za-z0-9]+)+$'

validate_inventory() {
  inventory_path=$1
  inventory_label=$2
  inventory_pattern=$3
  inventory_entry=$4

  [ -f "$inventory_path" ] && [ ! -L "$inventory_path" ] ||
    die "$inventory_label inventory is missing or unsafe."
  [ -s "$inventory_path" ] ||
    die "$inventory_label inventory is empty."

  invalid_inventory_lines=$(grep -Env "$inventory_pattern" "$inventory_path" || true)
  [ -z "$invalid_inventory_lines" ] ||
    die "$inventory_label inventory contains an invalid $inventory_entry."

  inventory_duplicates=$(LC_ALL=C sort "$inventory_path" | uniq -d)
  [ -z "$inventory_duplicates" ] ||
    die "$inventory_label inventory contains duplicate ${inventory_entry}s."

  sorted_inventory=$(LC_ALL=C sort "$inventory_path")
  current_inventory=$(cat "$inventory_path")
  [ "$sorted_inventory" = "$current_inventory" ] ||
    die "$inventory_label inventory must be sorted."
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

validate_local_link_step() {
  case "$1" in
    "${canonical_codex_home%/}/AGENTS.md")
      die 'The local-file path traverses a managed destination that would be replaced.' ;;
  esac
  for link_skill_name in $link_managed_skill_names
  do
    case "$1" in
      "${link_skills_root%/}/$link_skill_name"|"${link_skills_root%/}/$link_skill_name"/*)
        die 'The local-file path traverses a managed destination that would be replaced.' ;;
    esac
  done
}

resolve_local_link_target() {
  link_pending=$1
  link_managed_skill_names=$2
  link_skills_root=$(canonical_path_for_check "$skills_root") || return 1
  link_resolved=/
  link_hops=0
  validate_path_encoding "$link_pending"
  # Resolve one component at a time and check it BEFORE following any symlink.
  # A final external file is not enough: replacing a managed intermediate link
  # or directory would break the user's local file even if its bytes survived.
  # Resolving a whole parent with cd/pwd would hide those directory-link hops.
  while [ -n "$link_pending" ]
  do
    link_component=${link_pending%%/*}
    case "$link_pending" in
      */*) link_pending=${link_pending#*/} ;;
      *) link_pending='' ;;
    esac
    case "$link_component" in
      ''|.) continue ;;
      ..)
        link_resolved=${link_resolved%/*}
        [ -n "$link_resolved" ] || link_resolved=/
        continue
        ;;
    esac
    link_path="${link_resolved%/}/$link_component"
    validate_local_link_step "$link_path"
    if [ -L "$link_path" ]; then
      link_hops=$((link_hops + 1))
      [ "$link_hops" -le 40 ] || die 'The local-file symlink chain is too deep to verify.'
      link_value=$(readlink "$link_path" && printf '.') ||
        die 'The local-file symlink target could not be read.'
      link_value=${link_value%.}
      link_value=${link_value%'
'}
      validate_path_encoding "$link_value"
      case "$link_value" in
        /*) link_resolved=/ ;;
      esac
      link_pending="$link_value${link_pending:+/$link_pending}"
    else
      if [ -n "$link_pending" ] && [ ! -d "$link_path" ]; then
        die 'The local-file symlink path contains a component that is not a directory.'
      fi
      link_resolved=$link_path
    fi
  done
  [ -f "$link_resolved" ] || die 'The local-file symlink target is not a regular file.'
  printf '%s\n' "$link_resolved"
}

replace_agents=0
case "${1:-}" in
  '') ;;
  --replace-agents) replace_agents=1 ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 64 ;;
esac

[ "$#" -le 1 ] || { usage >&2; exit 64; }
[ -n "${HOME:-}" ] || die 'HOME is not set.'

# Check the invocation before dirname can strip bytes, then resolve physically
# with the same byte-preserving validation used for destination paths.
validate_path_encoding "$0"
repo_root=$(physical_directory_for_check "$(dirname -- "$0")/..")
codex_home=${CODEX_HOME:-"$HOME/.codex"}
skills_root="$HOME/.agents/skills"
agents_source="$repo_root/AGENTS.md"
agents_target="$codex_home/AGENTS.md"
local_layer_target="$codex_home/playbook-local.md"
active_inventory="$repo_root/config/managed-skills.txt"
retired_inventory="$repo_root/config/retired-skills.txt"
resource_inventory="$repo_root/config/managed-resources.txt"
agents_stage=''
staging_root=''
previous_root=''
agents_previous_root=''
backup_dir=''
installation_started=0
agents_touched=0
skills_touched=''
preserve_rollback_storage=0

cleanup_staging() {
  if [ -n "$agents_stage" ] && [ -f "$agents_stage" ] &&
     ! rm "$agents_stage"; then
    printf 'WARNING: AGENTS.md staging remains at %s\n' "$agents_stage" >&2
  fi
  if [ -n "$staging_root" ] && [ -d "$staging_root" ] &&
     ! rm -R "$staging_root"; then
    printf 'WARNING: skill staging remains at %s\n' "$staging_root" >&2
  fi
  if [ "$preserve_rollback_storage" -eq 0 ] &&
     [ -n "$previous_root" ] && [ -d "$previous_root" ] &&
     ! rm -R "$previous_root"; then
    printf 'WARNING: redundant pre-replacement copies remain at %s\n' \
      "$previous_root" >&2
  fi
  if [ "$preserve_rollback_storage" -eq 0 ] &&
     [ -n "$agents_previous_root" ] && [ -d "$agents_previous_root" ] &&
     ! rm -R "$agents_previous_root"; then
    printf 'WARNING: pre-replacement AGENTS.md remains at %s\n' \
      "$agents_previous_root" >&2
  fi
}

# This is recovery of this process's own transaction, not a public restore.
# Move original destinations back without reinterpreting the local layer or
# accepting an arbitrary checkpoint. Retain originals if any move/check fails.
rollback_installation() {
  trap '' HUP INT TERM
  rollback_failed=0
  preserve_rollback_storage=1
  if [ "$agents_touched" -eq 1 ]; then
    if [ -f "$agents_previous_root/AGENTS.md" ]; then
      if { [ -e "$agents_target" ] || [ -L "$agents_target" ]; } &&
         ! mv "$agents_target" "$agents_previous_root/failed-AGENTS.md"; then
        rollback_failed=1
      elif ! mv "$agents_previous_root/AGENTS.md" "$agents_target"; then
        rollback_failed=1
      fi
    elif [ ! -f "$backup_dir/AGENTS.md" ] &&
         { [ -e "$agents_target" ] || [ -L "$agents_target" ]; }; then
      mv "$agents_target" "$agents_previous_root/failed-AGENTS.md" || rollback_failed=1
    fi
  fi

  for rollback_skill_name in $skills_touched
  do
    rollback_target="$skills_root/$rollback_skill_name"
    if [ -d "$previous_root/$rollback_skill_name" ]; then
      if { [ -e "$rollback_target" ] || [ -L "$rollback_target" ]; } &&
         ! mv "$rollback_target" "$previous_root/failed-$rollback_skill_name"; then
        rollback_failed=1
      elif ! mv "$previous_root/$rollback_skill_name" "$rollback_target"; then
        rollback_failed=1
      fi
    elif [ ! -d "$backup_dir/$rollback_skill_name" ] &&
         { [ -e "$rollback_target" ] || [ -L "$rollback_target" ]; }; then
      mv "$rollback_target" "$previous_root/failed-$rollback_skill_name" || rollback_failed=1
    fi
  done

  # A failed preservation rename may leave the original in place. Verify the
  # entire preinstall state rather than inferring success from rename exits.
  if [ -f "$backup_dir/AGENTS.md" ]; then
    cmp -s "$backup_dir/AGENTS.md" "$agents_target" || rollback_failed=1
  elif [ -e "$agents_target" ] || [ -L "$agents_target" ]; then
    rollback_failed=1
  fi
  for rollback_skill_name in $managed_skill_names
  do
    rollback_target="$skills_root/$rollback_skill_name"
    if [ -d "$backup_dir/$rollback_skill_name" ]; then
      diff -qr "$backup_dir/$rollback_skill_name" "$rollback_target" >/dev/null 2>&1 ||
        rollback_failed=1
    elif [ -e "$rollback_target" ] || [ -L "$rollback_target" ]; then
      rollback_failed=1
    fi
  done
  installation_started=0
  if [ "$rollback_failed" -eq 0 ]; then
    preserve_rollback_storage=0
    return 0
  fi
  printf 'ERROR: rollback originals retained at %s and %s; verified checkpoint: %s\n' \
    "$agents_previous_root" "$previous_root" "$backup_dir" >&2
  return 1
}

handle_signal() {
  trap - HUP INT TERM
  if [ "$installation_started" -eq 1 ] &&
     [ -n "$backup_dir" ] && [ -f "$backup_dir/COMPLETE" ]; then
    if rollback_installation; then
      printf 'ERROR: installation interrupted; the verified checkpoint was restored: %s\n' \
        "$backup_dir" >&2
    else
      printf 'ERROR: installation interrupted and automatic recovery failed. Recovery checkpoint: %s\n' \
        "$backup_dir" >&2
    fi
  else
    printf 'ERROR: installation interrupted before managed destinations changed.\n' >&2
  fi
  exit 130
}

recover_installation_and_die() {
  failure_message=$1
  if rollback_installation; then
    installation_started=0
    die "$failure_message The verified checkpoint was restored."
  else
    die "$failure_message Automatic recovery failed. Recovery checkpoint: $backup_dir"
  fi
}

trap cleanup_staging EXIT
trap handle_signal HUP INT TERM

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

case "$skills_root" in
  /*) ;;
  *) die 'HOME must be an absolute path.' ;;
esac

validate_inventory "$active_inventory" 'Active skill' "$skill_name_pattern" 'skill name'
validate_inventory "$retired_inventory" 'Retired skill' "$skill_name_pattern" 'skill name'
validate_inventory "$resource_inventory" 'Managed resource' "$resource_path_pattern" 'resource path'

active_skill_names=$(cat "$active_inventory")
retired_skill_names=$(cat "$retired_inventory")
managed_skill_names=$(
  {
    cat "$active_inventory"
    cat "$retired_inventory"
  } | LC_ALL=C sort -u
)

canonical_codex_home=$(canonical_path_for_check "$codex_home")
for skill_name in $managed_skill_names
do
  canonical_skill_target=$(canonical_path_for_check "$skills_root/$skill_name")
  case "$canonical_codex_home" in
    "$canonical_skill_target"|"$canonical_skill_target"/*)
      die "CODEX_HOME overlaps the managed skill directory $skills_root/$skill_name."
      ;;
  esac
done

[ -f "$agents_source" ] && [ ! -L "$agents_source" ] ||
  die 'The source AGENTS.md is missing or is not a regular file.'
[ -f "$repo_root/VERSION" ] || die 'The source VERSION file is missing.'
[ -x "$repo_root/scripts/restore.sh" ] ||
  die 'The restore script is missing or is not executable.'
[ -x "$repo_root/scripts/check-local.sh" ] ||
  die 'The local-layer check script is missing or is not executable.'

for source_tree in "$repo_root/.agents" "$repo_root/.agents/skills"
do
  [ -d "$source_tree" ] && [ ! -L "$source_tree" ] ||
    die "The source directory $source_tree is missing, is not a directory, or is a symbolic link."
done

for skill_name in $active_skill_names
do
  skill_source="$repo_root/.agents/skills/$skill_name"
  [ -d "$skill_source" ] && [ ! -L "$skill_source" ] ||
    die "The source skill $skill_name is missing or is not a directory."
  [ -f "$skill_source/SKILL.md" ] && [ ! -L "$skill_source/SKILL.md" ] ||
    die "The source skill $skill_name has no regular SKILL.md."
  skill_symlinks=$(find "$skill_source" -type l)
  [ -z "$skill_symlinks" ] ||
    die "The source skill $skill_name contains a symbolic link. Unsafe path: $skill_symlinks"
done

managed_resource_paths=$(cat "$resource_inventory")
for resource_path in $managed_resource_paths
do
  resource_source="$repo_root/$resource_path"
  [ -f "$resource_source" ] && [ ! -L "$resource_source" ] ||
    die "The source resource $resource_path is missing or is not a regular file."
  resource_owner=${resource_path#.agents/skills/}
  resource_owner=${resource_owner%%/*}
  grep -Fxq "$resource_owner" "$active_inventory" ||
    die "The managed resource $resource_path belongs to $resource_owner, which is not an active skill."
done

# Source preflight, still before umask, before any directory is created and
# before any backup: every "Dead words:" entry of the user's local layer is
# checked against the text this run is about to install. A stale or unparsable
# entry refuses the installation. This adds no write path: the local layer is
# read here and touched nowhere else.
"$repo_root/scripts/check-local.sh" "$local_layer_target" "$repo_root" \
  "$repo_root/.agents/skills" ||
  die "The local layer at $local_layer_target does not match the playbook text this run would install. Re-read the rules named above and rewrite those entries; there is no flag to install past this."

# Even a regular local file can depend on a managed directory symlink in its
# parent path. Inspect the complete path whenever a local file exists.
if [ -e "$local_layer_target" ] || [ -L "$local_layer_target" ]; then
  local_link_target=$(resolve_local_link_target "$local_layer_target" "$managed_skill_names")
  case "$local_link_target" in
    "$canonical_codex_home/AGENTS.md")
      die 'The local-file symlink targets a managed destination that installation would replace.' ;;
  esac
  for skill_name in $managed_skill_names
  do
    canonical_skill_target=$(canonical_path_for_check "$skills_root/$skill_name")
    case "$local_link_target" in
      "$canonical_skill_target"|"$canonical_skill_target"/*)
        die 'The local-file symlink targets a managed destination that installation would replace.' ;;
    esac
  done
fi

override_target="$codex_home/AGENTS.override.md"
if [ -L "$override_target" ] || { [ -e "$override_target" ] && [ ! -f "$override_target" ]; }; then
  die 'Refusing installation because the global AGENTS.override.md is unsafe.'
fi
if [ -s "$override_target" ]; then
  die 'A non-empty global AGENTS.override.md would shadow the installed AGENTS.md. Merge or remove the override first.'
fi

if [ -L "$agents_target" ]; then
  die 'Refusing to replace a symlinked global AGENTS.md.'
fi
if [ -e "$agents_target" ] && [ ! -f "$agents_target" ]; then
  die 'Refusing to replace a global AGENTS.md that is not a regular file.'
fi
if [ -f "$agents_target" ] && ! cmp -s "$agents_source" "$agents_target" &&
   [ "$replace_agents" -ne 1 ]; then
  die 'A different global AGENTS.md already exists. Merge it first or rerun with --replace-agents after reviewing the replacement.'
fi

for skill_name in $managed_skill_names
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
mkdir -p "$codex_home"
backup_root="$codex_home/backups"
mkdir -p "$backup_root"
chmod 700 "$backup_root"

timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
backup_dir=$(mktemp -d "$backup_root/codex-playbook-preinstall-$timestamp-XXXXXX")
manifest="$backup_dir/manifest"
printf 'format=2\n' > "$manifest"
for skill_name in $managed_skill_names
do
  printf 'managed_skill=%s\n' "$skill_name" >> "$manifest"
done

if [ -f "$agents_target" ]; then
  if ! cp -p "$agents_target" "$backup_dir/AGENTS.md"; then
    die "AGENTS.md checkpoint creation failed before installation. Incomplete checkpoint: $backup_dir"
  fi
  cmp -s "$agents_target" "$backup_dir/AGENTS.md" ||
    die "The AGENTS.md checkpoint could not be verified at $backup_dir."
  printf 'agents=present\n' >> "$manifest"
else
  printf 'agents=absent\n' >> "$manifest"
fi

for skill_name in $managed_skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  if [ -d "$skill_target" ]; then
    if ! cp -pR "$skill_target" "$backup_dir/$skill_name"; then
      die "$skill_name checkpoint creation failed before installation. Incomplete checkpoint: $backup_dir"
    fi
    diff -qr "$skill_target" "$backup_dir/$skill_name" >/dev/null ||
      die "The $skill_name checkpoint could not be verified at $backup_dir."
    printf 'skill_%s=present\n' "$manifest_key" >> "$manifest"
  else
    printf 'skill_%s=absent\n' "$manifest_key" >> "$manifest"
  fi
done

chmod 600 "$manifest"
printf 'complete\n' > "$backup_dir/COMPLETE"
chmod 600 "$backup_dir/COMPLETE"

agents_stage=$(mktemp "$codex_home/.AGENTS.md.codex-playbook.XXXXXX")
install -m 600 "$agents_source" "$agents_stage"
cmp -s "$agents_source" "$agents_stage" ||
  die "The staged AGENTS.md could not be verified. Recovery checkpoint: $backup_dir"

mkdir -p "$skills_root"
staging_root=$(mktemp -d "$skills_root/.codex-playbook-install-XXXXXX")
for skill_name in $active_skill_names
do
  cp -pR "$repo_root/.agents/skills/$skill_name" "$staging_root/$skill_name"
  diff -qr "$repo_root/.agents/skills/$skill_name" "$staging_root/$skill_name" >/dev/null ||
    die "The staged $skill_name skill could not be verified. Recovery checkpoint: $backup_dir"
done

if ! previous_root=$(mktemp -d "$skills_root/.codex-playbook.previous.XXXXXX"); then
  die 'Could not allocate rollback storage before managed destinations changed.'
fi
if ! agents_previous_root=$(mktemp -d "$codex_home/.codex-playbook.previous.XXXXXX"); then
  die 'Could not allocate AGENTS.md rollback storage before managed destinations changed.'
fi

installation_started=1
preserve_rollback_storage=1
agents_touched=1
if [ -f "$agents_target" ] &&
   ! mv "$agents_target" "$agents_previous_root/AGENTS.md"; then
  recover_installation_and_die 'Could not preserve AGENTS.md for replacement.'
fi
if ! mv -f "$agents_stage" "$agents_target"; then
  recover_installation_and_die 'AGENTS.md installation failed.'
fi

for skill_name in $managed_skill_names
do
  skill_target="$skills_root/$skill_name"
  skills_touched="$skills_touched $skill_name"
  if [ -d "$skill_target" ] &&
     ! mv "$skill_target" "$previous_root/$skill_name"; then
    recover_installation_and_die "Could not preserve $skill_name for replacement."
  fi
done

for skill_name in $active_skill_names
do
  skill_target="$skills_root/$skill_name"
  if ! mv "$staging_root/$skill_name" "$skill_target"; then
    recover_installation_and_die "Could not install $skill_name."
  fi
done

if ! rmdir "$staging_root"; then
  printf 'WARNING: the empty skill staging directory remains at %s\n' \
    "$staging_root" >&2
fi

cmp -s "$agents_source" "$agents_target" ||
  recover_installation_and_die 'Installed AGENTS.md verification failed.'
for skill_name in $active_skill_names
do
  diff -qr "$repo_root/.agents/skills/$skill_name" "$skills_root/$skill_name" >/dev/null ||
    recover_installation_and_die "Installed $skill_name verification failed."
done
for skill_name in $retired_skill_names
do
  [ ! -e "$skills_root/$skill_name" ] ||
    recover_installation_and_die "Retired skill $skill_name is still active."
done

installation_started=0
preserve_rollback_storage=0
if ! rm -R "$previous_root"; then
  printf 'WARNING: installation is verified, but redundant pre-replacement copies remain at %s\n' \
    "$previous_root" >&2
fi

version=$(tr -d '\r\n' < "$repo_root/VERSION")
printf 'Installed Codex Playbook %s.\n' "$version"
printf 'Global rules: %s\n' "$agents_target"
printf 'Personal skills: %s\n' "$skills_root"
printf 'Managed skills: %s\n' "$(wc -l < "$active_inventory" | tr -d ' ')"
printf 'Recovery checkpoint: %s\n' "$backup_dir"
