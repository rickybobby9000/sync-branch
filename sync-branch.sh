#!/usr/bin/env bash
set -uo pipefail

# 1️⃣ URL goes here as the FIRST argument
REPO_URL="${1:?❌ Usage: $0 <github-repo-url> [target-folder]}"
TARGET_DIR="${2:-$(basename "$REPO_URL" .git)}"

# 2️⃣ Clone if folder doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "📦 Cloning repository into '$TARGET_DIR'..."
    git clone "$REPO_URL" "$TARGET_DIR" || { echo "❌ Clone failed."; exit 1; }
fi

cd "$TARGET_DIR" || exit 1

# Verify it's a valid git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: '$TARGET_DIR' exists but is not a Git repository."
    exit 1
fi

echo "📥 Fetching latest remote branches..."
git fetch origin --quiet

# Collect remote branches
BRANCHES=()
while IFS= read -r branch; do
    [[ -n "$branch" ]] && BRANCHES+=("$branch")
done < <(git branch -r --format='%(refname:short)' | grep -v 'HEAD' | sed 's|^origin/||')

if [ ${#BRANCHES[@]} -eq 0 ]; then
    echo "❌ No remote branches found."
    exit 1
fi

echo ""
echo "🌿 Available branches:"
PS3="👉 Enter the number of the branch to sync: "

select BRANCH in "${BRANCHES[@]}"; do
    if [[ -n "$BRANCH" ]]; then
        echo "✅ Selected: $BRANCH"
        break
    else
        echo "❌ Invalid selection. Please enter a valid number."
    fi
done

echo ""
echo "🔄 Resetting to 'origin/$BRANCH'..."
git reset --hard "origin/$BRANCH"

echo "🧹 Cleaning untracked files & directories..."
git clean -fd

if [[ -f ".gitmodules" ]]; then
    echo "📦 Updating submodules..."
    git submodule update --init --recursive --quiet
fi

echo ""
echo "✅ Successfully synced to '$BRANCH'!"
echo "🧪 Folder is ready for testing."

# 👇 Add your test command here:
# npm test
# pytest
# go test ./...
