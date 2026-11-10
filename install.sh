#!/usr/bin/env bash
# Links every skill in this repo into the agents' skill folders, so `git pull` updates them everywhere.
#
# Usage: ./install.sh [folder...]
# Default folders: ~/.claude/skills and ~/.codex/skills.
# A skill that already exists there and isn't a link to this repo is left alone and reported.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
targets=("$@")
((${#targets[@]} > 0)) || targets=("$HOME/.claude/skills" "$HOME/.codex/skills")

skipped=0
for target in "${targets[@]}"; do
  mkdir -p "$target"
  for skill in "$repo"/skills/*/; do
    name=$(basename "$skill")
    link="$target/$name"
    if [[ -L "$link" && "$(readlink "$link")" == "${skill%/}" ]]; then
      continue
    elif [[ -e "$link" || -L "$link" ]]; then
      echo "skipped $link: already exists and is not a link to this repo" >&2
      skipped=1
    else
      ln -s "${skill%/}" "$link"
      echo "linked $link"
    fi
  done
done
exit "$skipped"
