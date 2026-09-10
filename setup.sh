#!/usr/bin/env bash
#
# ENGR 1451/2451 — ONE-TIME SETUP
#
# Before running:
#   1. Fork https://github.com/pleu/26f-engr1451-2451 on GitHub.
#   2. Run:
#        ./setup.sh YOUR_GITHUB_USERNAME
#
# This script:
#   - clones the student's fork
#   - adds the instructor repository as "upstream"
#   - updates main from the instructor
#   - creates OR restores the student-work branch
#

set -euo pipefail

REPO="26f-engr1451-2451"
COURSE_DIR="$HOME/$REPO"
WORK_BRANCH="student-work"

if [[ $# -ne 1 ]]; then
    echo "Usage: ./setup.sh YOUR_GITHUB_USERNAME"
    exit 1
fi

USERNAME="$1"
ORIGIN="git@github.com:${USERNAME}/${REPO}.git"
UPSTREAM="git@github.com:pleu/${REPO}.git"

if [[ -d "$COURSE_DIR/.git" ]]; then
    echo "ERROR: $COURSE_DIR is already a Git repository."
    echo "If setup was already completed, use sync.sh instead."
    exit 1
fi

if [[ -e "$COURSE_DIR" ]] && [[ -n "$(ls -A "$COURSE_DIR" 2>/dev/null)" ]]; then
    echo "ERROR: $COURSE_DIR already exists and is not empty."
    echo "Move/remove its contents before running setup."
    exit 1
fi

mkdir -p "$COURSE_DIR"
cd "$COURSE_DIR"

echo "Cloning your fork directly into $COURSE_DIR..."
git clone "$ORIGIN" .

echo "Adding instructor repository as upstream..."
git remote add upstream "$UPSTREAM"

echo "Fetching instructor repository..."
git fetch upstream

echo "Updating clean main..."
git switch main
git merge --ff-only upstream/main
git push origin main

echo "Preparing your working branch..."

# If student-work already exists on the student's GitHub fork,
# restore and track that branch instead of creating a new one.
if git show-ref --verify --quiet "refs/remotes/origin/$WORK_BRANCH"; then
    echo "Existing '$WORK_BRANCH' branch found on your GitHub fork."
    git switch --track "origin/$WORK_BRANCH"
else
    echo "Creating new '$WORK_BRANCH' branch..."
    git switch -c "$WORK_BRANCH"
    git push -u origin "$WORK_BRANCH"
fi

echo
echo "Setup complete."
echo
echo "Repository: $COURSE_DIR"
echo "Your work branch: $(git branch --show-current)"
echo
echo "IMPORTANT:"
echo "  Do your coursework on '$WORK_BRANCH'."
echo "  Keep 'main' clean so it can track the instructor repository."
