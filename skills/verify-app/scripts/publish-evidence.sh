#!/usr/bin/env bash
# Takes a verification's evidence to a PR, without a commit on any branch.
#
# Usage: publish-evidence.sh <PR> <evidence folder>
#
# Stores images and summaries in a loose commit pointed at by refs/verify-app/<run>: a normal clone
# doesn't fetch that ref and CI doesn't run on it. Then comments on the PR with the images.
# In a public repo, everything published is open to anyone.
# To delete after the merge: git push origin --delete refs/verify-app/<run>
set -euo pipefail

fail() {
  echo "ERROR: $1" >&2
  exit 2
}

pr="${1:-}"
dir="${2:-}"
[[ "$pr" =~ ^[0-9]+$ && -n "$dir" ]] || fail "usage: publish-evidence.sh <PR> <evidence folder>"
[[ -f "$dir/SUMMARY.md" ]] || fail "no $dir/SUMMARY.md: write the summary before publishing"

root=$(git rev-parse --show-toplevel) || fail "not inside a git repository"
dir=$(cd "$dir" && pwd)
run=$(basename "$dir")
[[ "$run" =~ ^[A-Za-z0-9._-]+$ ]] || fail "folder name not valid for a ref: $run"
verified=$(sed -n 's/^Commit: \([0-9a-f]\{7,40\}\).*/\1/p' "$dir/SUMMARY.md" | head -1)
[[ -n "$verified" ]] || fail "SUMMARY.md has no 'Commit: <sha>' line"
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || fail "could not read the repository"

index=$(mktemp -u)
body=$(mktemp)
trap 'rm -f "$index" "$body"' EXIT

ref="refs/verify-app/$run"
git_dir=$(git -C "$root" rev-parse --absolute-git-dir)
# The machine's local path doesn't go into the repo.
sed -i "s#$root/##g" "$dir/SUMMARY.md"
commit=$(
  cd "$dir"
  export GIT_DIR="$git_dir" GIT_WORK_TREE=. GIT_INDEX_FILE="$index"
  # Images and summaries only: traces, failure videos and logs may hold requests and cookies, and stay local.
  find . -type f \( -name '*.png' -o -name '*.md' \) -print0 | xargs -0 git add -f --
  git commit-tree "$(git write-tree)" -m "Evidence of verification $run (commit $verified)"
)
git -C "$root" push --quiet origin "$commit:$ref"

raw_url() {
  echo "https://github.com/$repo/blob/$commit/$1?raw=true"
}

{
  echo "## Evidence of verification \`$run\`"
  echo
  echo "Verified commit: \`$verified\`. Files: [evidence tree](https://github.com/$repo/tree/$commit), [full summary]($(raw_url SUMMARY.md))."
  echo
  # The summary's flow table.
  awk '/^## Flows/ { on = 1; next } on && /^## / { exit } on { print }' "$dir/SUMMARY.md"
  for flow in "$dir"/*/; do
    [[ -d "$flow" ]] || continue
    name=$(basename "$flow")
    echo
    echo "<details><summary>$name</summary>"
    echo
    while IFS= read -r image; do
      file=${image#"$dir/"}
      echo "**$(basename "$image")**"
      echo
      echo "![$(basename "$image")]($(raw_url "$file"))"
      echo
    done < <(find "$flow" -type f -name '*.png' | sort)
    echo "</details>"
  done
  echo
  echo "To delete this evidence: \`git push origin --delete $ref\`"
} >"$body"

gh pr comment "$pr" --repo "$repo" --body-file "$body"
echo "Ref: $ref ($commit)"
