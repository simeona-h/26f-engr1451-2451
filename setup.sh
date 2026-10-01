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
#   - preserves any student commits accidentally made on main
#   - resets main to match the instructor repository
#   - creates OR restores the student-work branch
#

set -euo pipefail

REPO="26f-engr1451-2451"
COURSE_DIR="$HOME/$REPO"
WORK_BRANCH="student-work"

# Add local Git ignore rules for files that should never be student work.
# These rules live in .git/info/exclude, so they are local to this clone
# and are not committed to the course repository.
configure_local_excludes() {
    local exclude_file=".git/info/exclude"
    local marker="# BEGIN ENGR1451 LOCAL EXCLUDES"

    if ! grep -Fq "$marker" "$exclude_file"; then
        cat >> "$exclude_file" <<'EXCLUDE_EOF'

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
EXCLUDE_EOF
    fi
}

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

echo "Configuring local ignores for hidden and temporary files..."
configure_local_excludes

echo "Adding instructor repository as upstream..."
git remote add upstream "$UPSTREAM"

echo "Fetching instructor repository..."
git fetch upstream

echo "Checking main..."
git switch main

# If local main is already equal to, or strictly behind, upstream/main,
# it is safe to fast-forward it.
if git merge-base --is-ancestor main upstream/main; then
    echo "main can be updated safely by fast-forwarding."
    git merge --ff-only upstream/main
    git push origin main
else
    # main contains at least one commit that is not in upstream/main.
    # Preserve those commits before resetting main.
    echo
    echo "WARNING: Your fork's main branch contains commits that are not"
    echo "in the instructor repository. Preserving them before cleaning main..."

    if git show-ref --verify --quiet "refs/remotes/origin/$WORK_BRANCH"; then
        # student-work already exists. If it already contains main, no extra
        # backup is needed. Otherwise preserve main on a separate backup branch
        # rather than attempting an automatic merge that could create conflicts.
        if git merge-base --is-ancestor main "origin/$WORK_BRANCH"; then
            echo "Those main commits are already contained in origin/$WORK_BRANCH."
        else
            BACKUP_BRANCH="backup-main-before-setup-$(date +%Y%m%d-%H%M%S)"
            echo "Existing '$WORK_BRANCH' branch found."
            echo "Saving the current main as '$BACKUP_BRANCH' instead of merging automatically."
            git branch "$BACKUP_BRANCH" main
            git push -u origin "$BACKUP_BRANCH"
        fi
    else
        echo "No existing '$WORK_BRANCH' branch found."
        echo "Saving the current main as '$WORK_BRANCH'..."
        git branch "$WORK_BRANCH" main
        git push -u origin "$WORK_BRANCH"
    fi

    echo
    echo "Resetting main to match upstream/main..."
    git reset --hard upstream/main

    # A force push is required because origin/main had commits that are not in
    # upstream/main. --force-with-lease protects against overwriting a remote
    # change that occurred after this clone/fetch.
    git push --force-with-lease origin main
fi

echo "Preparing your working branch..."

# If student-work was just created locally above, use it.
if git show-ref --verify --quiet "refs/heads/$WORK_BRANCH"; then
    git switch "$WORK_BRANCH"
# Otherwise, restore an existing student-work branch from the student's fork.
elif git show-ref --verify --quiet "refs/remotes/origin/$WORK_BRANCH"; then
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
