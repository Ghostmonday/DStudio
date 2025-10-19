#!/bin/bash

# Ultra-fast PR creation script
# Usage: ./create-pr.sh "PR Title" "Description"

if [ $# -lt 1 ]; then
    echo "Usage: ./create-pr.sh 'PR Title' 'Description'"
    exit 1
fi

TITLE="$1"
DESCRIPTION="${2:-Ready for BugBot review}"

# Get current branch or create new one
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ]; then
    BRANCH="fix/$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BRANCH"
fi

# Quick conflict resolution
echo "🔧 Quick conflict check..."
git add .
git commit -m "$TITLE" || echo "No changes to commit"

# Push and create PR
git push origin "$BRANCH" --force-with-lease
gh pr create --title "$TITLE" --body "$DESCRIPTION

@GhostMonday bugbot run" --assignee @me

echo "✅ PR created: $TITLE"
echo "🔗 View at: $(gh pr view --web)"
