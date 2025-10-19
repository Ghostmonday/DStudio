#!/bin/bash

# PR creation without GitHub CLI - uses git and manual steps
# Usage: ./no-cli-pr.sh "PR Title" "Description"

set -e

TITLE="$1"
DESCRIPTION="${2:-Ready for BugBot review}"

echo "🚀 Creating PR without GitHub CLI: $TITLE"

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

# Generate PR creation instructions
echo ""
echo "🎉 Branch pushed successfully!"
echo "================================="
echo "📝 PR Title: $TITLE"
echo "🌿 Branch: $BRANCH"
echo "📋 Description: $DESCRIPTION"
echo ""
echo "🔗 Create PR manually at:"
echo "https://github.com/Ghostmonday/DStudio/compare/$BRANCH"
echo ""
echo "📋 Copy this for the PR description:"
echo "------------------------------------"
echo "$DESCRIPTION"
echo ""
echo "## 🤖 Automated PR Workflow"
echo ""
echo "This PR has been created using the No-CLI PR workflow."
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
echo "*Created by No-CLI PR workflow at $(date)*"
echo "------------------------------------"
echo ""
echo "✅ Ready to create PR manually!"
echo "🔗 Click the link above to create the PR"
