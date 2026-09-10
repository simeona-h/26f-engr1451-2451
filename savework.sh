#!/usr/bin/env bash
#
# ENGR 1451/2451 — SAVE WORK
#
# Usage:
#   ./save.sh
#   ./save.sh "Complete w03a exercises"
#
# If no commit message is provided, a timestamped message is used.
#
# This script:
#   - checks that the repository exists
#   - checks that you are on student-work
#   - shows changed files
#   - stages all changes
#   - commits them
#   - pushes them to your GitHub fork
#

set -euo pipefail

REPO="$HOME/26f-engr1451-2451"
WORK_BRANCH="student-work"

if [[ ! -d "$REPO/.git" ]]; then
    echo "ERROR: Repository not found at:"
    echo "  $REPO"
    echo "Run setup.sh first."
    exit 1
fi

cd "$REPO"

BRANCH="$(git branch --show-current)"

if [[ "$BRANCH" != "$WORK_BRANCH" ]]; then
    echo "ERROR: You are on '$BRANCH'."
    echo "Student work should be saved on '$WORK_BRANCH'."
    echo
    echo "Run:"
    echo "  git switch $WORK_BRANCH"
    exit 1
fi

if [[ -z "$(git status --porcelain)" ]]; then
    echo "No changes to save."
    exit 0
fi

echo "Files being saved:"
git status --short
echo

read -n 1 -s -r -p "Press any key to stage, commit, and push these changes..."
echo
echo

echo "Staging changes..."
git add -A

if [[ $# -gt 0 ]]; then
    COMMIT_MSG="$*"
else
    CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    COMMIT_MSG="Saving progress, $CURRENT_DATE"
fi

echo "Committing with message:"
echo "  $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

echo "Pushing to your GitHub fork..."
git push origin "$WORK_BRANCH"

echo
echo "Work saved successfully:"
git log -1 --oneline
