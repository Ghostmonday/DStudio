#!/bin/bash

# Simple PR creation without GitHub CLI dependency
# Usage: ./simple-pr.sh "PR Title" "Description"

set -e

TITLE="$1"
DESCRIPTION="${2:-Ready for BugBot review}"

echo "🚀 Creating PR: $TITLE"

# Get current branch or create new one
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ]; then
    BRANCH="feature/$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BRANCH"
    echo "✅ Created branch: $BRANCH"
fi

# Quick conflict resolution
echo "🔧 Resolving conflicts..."
./fix-conflicts.sh

# Add and commit changes
git add .
git commit -m "$TITLE

$DESCRIPTION

🤖 Automated PR creation" || echo "No changes to commit"

# Push branch
echo "📤 Pushing branch..."
git push origin "$BRANCH" --force-with-lease

# Create PR using git commands (fallback if gh CLI not available)
echo "🔗 Creating PR..."
echo ""
echo "📋 PR Details:"
echo "Title: $TITLE"
echo "Branch: $BRANCH"
echo "Description: $DESCRIPTION"
echo ""
echo "🔗 Create PR manually at:"
echo "https://github.com/Ghostmonday/DStudio/compare/$BRANCH"
echo ""
echo "📝 PR Template:"
echo "Title: $TITLE"
echo ""
echo "Description:"
echo "$DESCRIPTION"
echo ""
echo "## 🤖 Automated PR Workflow"
echo ""
echo "This PR has been created using the Simple PR workflow."
echo ""
echo "### Features:"
echo "- ✅ Automated conflict resolution"
echo "- ✅ BugBot integration ready"
echo "- ✅ Ready for review"
echo ""
echo "### Next Steps:"
echo "1. BugBot will review this PR"
echo "2. Automated fixes will be applied if needed"
echo "3. PR will be merged after approval"
echo ""
echo "---"
echo "*Created by Simple PR workflow at $(date)*"
echo ""
echo "✅ Branch pushed successfully!"
echo "🔗 Please create the PR manually using the link above"
