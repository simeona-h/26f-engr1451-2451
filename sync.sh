#!/usr/bin/env bash
#
# ENGR 1451/2451 — SYNC INSTRUCTOR UPDATES
#
# Run before starting new course work:
#   ./sync.sh
#
# This script:
#   upstream/main -> local main -> student-work
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

if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: You have unsaved changes:"
    git status --short
    echo
    echo "Run ./savework.sh before syncing."
    exit 1
fi

echo "Fetching new files from the instructor repository..."
git fetch upstream

echo "Updating clean main..."
git switch main

if ! git merge --ff-only upstream/main; then
    echo
    echo "ERROR: main cannot be updated cleanly."
    echo "Student work may have accidentally been committed to main."
    echo "Ask the instructor for help rather than creating a merge on main."
    exit 1
fi

git push origin main

echo "Switching back to your work..."
git switch "$WORK_BRANCH"

echo "Bringing instructor updates into $WORK_BRANCH..."
if ! git merge main --no-edit; then
    echo
    echo "A merge conflict occurred on $WORK_BRANCH."
    echo "This means you and the instructor changed the same file."
    echo
    echo "The merge has been aborted so your repository is left clean."
    git merge --abort
    echo "Ask the instructor for help resolving the conflict."
    exit 2
fi

git push origin "$WORK_BRANCH"

echo
echo "Sync complete."
echo "You are on: $(git branch --show-current)"
echo "You can now continue working in Jupyter."
