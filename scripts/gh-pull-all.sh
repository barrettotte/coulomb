#!/bin/bash

# clones all public and private GitHub repositories to a specified directory
# setup PAT
#   - https://github.com/settings/personal-access-tokens/new
#   - Repo access = All, add permissions 'Metadata' and 'Contents'
# Usage: GH_TOKEN="ghp_YourTokenGoesHere" ./gh-pull-all.sh /path/to/backup-dir

if [[ -z "$GH_TOKEN" ]]; then
  echo "Error: GH_TOKEN environment variable is not set."
  exit 1
fi

ARCHIVE_DIR="$1"

if [[ -z "$ARCHIVE_DIR" ]]; then
  echo "Error: No archive directory specified."
  echo "Usage: $0 /path/to/your/clone/directory"
  exit 1
fi

mkdir -p "$ARCHIVE_DIR"
cd "$ARCHIVE_DIR" || exit
echo "Cloning all repositories to $ARCHIVE_DIR..."

PAGE=1
while true; do
  REPO_URLS=$(curl -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/user/repos?type=all&per_page=100&page=$PAGE" | jq -r '.[].ssh_url')

  if [[ -z "$REPO_URLS" ]]; then
    break
  fi

  echo "$REPO_URLS" | while read -r URL; do
    REPO_NAME=$(basename "$URL" .git)

    if [[ -d "$REPO_NAME" ]]; then
      echo "-> '$REPO_NAME' already exists. Skipping."
    else
      echo "-> Cloning '$REPO_NAME'..."
      git clone "$URL"
    fi
  done
  ((PAGE++))
done

echo "================================"
echo "All repositories cloned."
