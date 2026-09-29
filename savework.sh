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

# Add local Git ignore rules for files that should never be student work.
# These rules live in .git/info/exclude, so they are local to this clone
# and are not committed to the course repository.
configure_local_excludes() {
    local exclude_file=".git/info/exclude"
    local marker="# BEGIN ENGR1451 LOCAL EXCLUDES"

    if ! grep -Fq "$marker" "$exclude_file"; then
        cat >> "$exclude_file" <<'EOF'

# BEGIN ENGR1451 LOCAL EXCLUDES
# Hidden files/directories
.*

# Common editor / OS / temporary files
*~
*.tmp
*.temp
*.swp
*.swo
*.bak
~$*
__pycache__/
*.py[cod]
# END ENGR1451 LOCAL EXCLUDES
EOF
    fi
}

if [[ ! -d "$REPO/.git" ]]; then
    echo "ERROR: Repository not found at:"
    echo "  $REPO"
    echo "Run setup.sh first."
    exit 1
fi

cd "$REPO"

configure_local_excludes

BRANCH="$(git branch --show-current)"

if [[ "$BRANCH" != "$WORK_BRANCH" ]]; then
    echo "ERROR: You are on '$BRANCH'."
    echo "Student work should be saved on '$WORK_BRANCH'."
    echo
    echo "Run:"
    echo "  git switch $WORK_BRANCH"
    exit 1
fi

# Also exclude hidden/temporary paths explicitly when checking and staging.
# This protects against files that may already have been tracked previously.
IGNORE_PATHS=(
    ':(exclude,glob)**/.*'
    ':(exclude,glob)**/.*/**'
    ':(exclude,glob)**/*~'
    ':(exclude,glob)**/*.tmp'
    ':(exclude,glob)**/*.temp'
    ':(exclude,glob)**/*.swp'
    ':(exclude,glob)**/*.swo'
    ':(exclude,glob)**/*.bak'
    ':(exclude,glob)**/~$*'
    ':(exclude,glob)**/__pycache__/**'
    ':(exclude,glob)**/*.pyc'
    ':(exclude,glob)**/*.pyo'
    ':(exclude,glob)**/*.pyd'
)

if [[ -z "$(git status --porcelain -- . "${IGNORE_PATHS[@]}")" ]]; then
    echo "No changes to save."
    exit 0
fi

echo "Files being saved:"
git status --short -- . "${IGNORE_PATHS[@]}"
echo

read -n 1 -s -r -p "Press any key to stage, commit, and push these changes..."
echo
echo

echo "Staging changes..."
git add -A -- . "${IGNORE_PATHS[@]}"

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
