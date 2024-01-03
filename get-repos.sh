#!/bin/bash

# clone/pull all public/private repos of a user
# requires github cli setup -> gh auth login

set -e

USERNAME=barrettotte
REPO_DIR="$HOME/coding/repos"

REPOS=($(gh repo list $USERNAME --source --json name --limit 9999 | jq -r '.[].name' | sort))
TOTAL_REPOS=${#REPOS[@]}

echo "Found $TOTAL_REPOS repositories"

for ((i=0; i<TOTAL_REPOS; i++)); do
  IDX=$((i+1))
  REPO="${REPOS[i]}"

  echo -n "[$IDX of $TOTAL_REPOS] "

  if [ ! -d "$REPO_DIR/$REPO" ]; then
    echo "Cloning repo $REPO..."
    git clone "git@github.com:$USERNAME/$REPO.git" "$REPO_DIR/$REPO" --quiet > /dev/null
  else
    echo "Pulling repo $REPO..."
    git -C "$REPO_DIR/$REPO" pull origin master --quiet > /dev/null
  fi
done
