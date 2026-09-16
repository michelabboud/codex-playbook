#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--replace-agents]

Install Codex Playbook global rules and personal skills.

By default, installation refuses to replace a different global AGENTS.md.
Pass --replace-agents only after reviewing or merging the existing rules. A
verified, unique recovery checkpoint is always created before installation.
EOF
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
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

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
codex_home=${CODEX_HOME:-"$HOME/.codex"}
skills_root="$HOME/.agents/skills"
agents_source="$repo_root/AGENTS.md"
agents_target="$codex_home/AGENTS.md"
skill_names='codex-playbook-dependency-review codex-playbook-quarantine codex-playbook-release'
agents_stage=''
staging_root=''
previous_root=''
backup_dir=''
installation_started=0

cleanup_staging() {
  if [ -n "$agents_stage" ] && [ -f "$agents_stage" ] &&
     ! rm "$agents_stage"; then
    printf 'WARNING: AGENTS.md staging remains at %s\n' "$agents_stage" >&2
  fi
  if [ -n "$staging_root" ] && [ -d "$staging_root" ] &&
     ! rm -R "$staging_root"; then
    printf 'WARNING: skill staging remains at %s\n' "$staging_root" >&2
  fi
  if [ -n "$previous_root" ] && [ -d "$previous_root" ] &&
     ! rm -R "$previous_root"; then
    printf 'WARNING: redundant pre-replacement copies remain at %s\n' \
      "$previous_root" >&2
  fi
}

handle_signal() {
  trap - HUP INT TERM
  if [ "$installation_started" -eq 1 ] &&
     [ -n "$backup_dir" ] && [ -f "$backup_dir/COMPLETE" ]; then
    if HOME="$HOME" CODEX_HOME="$codex_home" \
        "$repo_root/scripts/restore.sh" "$backup_dir" >/dev/null 2>&1; then
      printf 'ERROR: installation interrupted; the verified checkpoint was restored: %s\n' \
        "$backup_dir" >&2
    else
      printf 'ERROR: installation interrupted and automatic recovery failed. Restore manually from %s\n' \
        "$backup_dir" >&2
    fi
  else
    printf 'ERROR: installation interrupted before managed destinations changed.\n' >&2
  fi
  exit 130
}

recover_installation_and_die() {
  failure_message=$1
  if HOME="$HOME" CODEX_HOME="$codex_home" \
      "$repo_root/scripts/restore.sh" "$backup_dir" >/dev/null 2>&1; then
    installation_started=0
    die "$failure_message The verified checkpoint was restored."
  else
    die "$failure_message Automatic recovery failed. Restore manually from $backup_dir"
  fi
}

trap cleanup_staging EXIT
trap handle_signal HUP INT TERM

case "$codex_home" in
  /*) ;;
  *) die 'CODEX_HOME must be an absolute path.' ;;
esac

case "$skills_root" in
  /*) ;;
  *) die 'HOME must be an absolute path.' ;;
esac

[ -f "$agents_source" ] && [ ! -L "$agents_source" ] ||
  die 'The source AGENTS.md is missing or is not a regular file.'
[ -f "$repo_root/VERSION" ] || die 'The source VERSION file is missing.'
[ -x "$repo_root/scripts/restore.sh" ] ||
  die 'The restore script is missing or is not executable.'

for skill_name in $skill_names
do
  skill_source="$repo_root/.agents/skills/$skill_name"
  [ -d "$skill_source" ] && [ ! -L "$skill_source" ] ||
    die "The source skill $skill_name is missing or is not a directory."
  [ -f "$skill_source/SKILL.md" ] && [ ! -L "$skill_source/SKILL.md" ] ||
    die "The source skill $skill_name has no regular SKILL.md."
done

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

for skill_name in $skill_names
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
printf 'format=1\n' > "$manifest"

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

for skill_name in $skill_names
do
  skill_target="$skills_root/$skill_name"
  manifest_key=$(printf '%s' "$skill_name" | tr '-' '_')
  if [ -d "$skill_target" ]; then
    if ! cp -R "$skill_target" "$backup_dir/$skill_name"; then
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
for skill_name in $skill_names
do
  cp -R "$repo_root/.agents/skills/$skill_name" "$staging_root/$skill_name"
  diff -qr "$repo_root/.agents/skills/$skill_name" "$staging_root/$skill_name" >/dev/null ||
    die "The staged $skill_name skill could not be verified. Recovery checkpoint: $backup_dir"
done

if ! previous_root=$(mktemp -d "$skills_root/.codex-playbook.previous.XXXXXX"); then
  die 'Could not allocate rollback storage before managed destinations changed.'
fi

installation_started=1
if ! mv -f "$agents_stage" "$agents_target"; then
  recover_installation_and_die 'AGENTS.md installation failed.'
fi

for skill_name in $skill_names
do
  skill_target="$skills_root/$skill_name"
  previous_target="$previous_root/$skill_name"
  if [ -d "$skill_target" ]; then
    if ! mv "$skill_target" "$previous_target"; then
      recover_installation_and_die "Could not prepare $skill_name for replacement."
    fi
  fi
  if ! mv "$staging_root/$skill_name" "$skill_target"; then
    if [ -d "$previous_target" ] && ! mv "$previous_target" "$skill_target"; then
      printf 'WARNING: immediate %s rollback failed; using the verified checkpoint.\n' \
        "$skill_name" >&2
    fi
    recover_installation_and_die "Could not install $skill_name."
  fi
done
if ! rmdir "$staging_root"; then
  printf 'WARNING: the empty skill staging directory remains at %s\n' \
    "$staging_root" >&2
fi

cmp -s "$agents_source" "$agents_target" ||
  recover_installation_and_die 'Installed AGENTS.md verification failed.'
for skill_name in $skill_names
do
  diff -qr "$repo_root/.agents/skills/$skill_name" "$skills_root/$skill_name" >/dev/null ||
    recover_installation_and_die "Installed $skill_name verification failed."
done
installation_started=0
if ! rm -R "$previous_root"; then
  printf 'WARNING: installation is verified, but redundant pre-replacement copies remain at %s\n' \
    "$previous_root" >&2
fi

version=$(tr -d '\r\n' < "$repo_root/VERSION")
printf 'Installed Codex Playbook %s.\n' "$version"
printf 'Global rules: %s\n' "$agents_target"
printf 'Personal skills: %s\n' "$skills_root"
printf 'Recovery checkpoint: %s\n' "$backup_dir"
