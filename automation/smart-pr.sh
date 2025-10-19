#!/bin/bash

# Smart PR creation with automated workflow integration
# Usage: ./smart-pr.sh "PR Title" "Description" [--auto-fix] [--auto-merge]

set -e

TITLE="$1"
DESCRIPTION="${2:-Ready for BugBot review}"
AUTO_FIX=false
AUTO_MERGE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-fix)
            AUTO_FIX=true
            shift
            ;;
        --auto-merge)
            AUTO_MERGE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "🚀 Smart PR creation: $TITLE"

# Function to create feature branch
create_branch() {
    BRANCH="feature/$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')-$(date +%Y%m%d-%H%M%S)"
    
    if [ "$(git branch --show-current)" = "main" ]; then
        git checkout -b "$BRANCH"
        echo "✅ Created feature branch: $BRANCH"
    else
        BRANCH=$(git branch --show-current)
        echo "✅ Using existing branch: $BRANCH"
    fi
}

# Function to stage and commit changes
commit_changes() {
    echo "📝 Staging and committing changes..."
    
    # Add all changes
    git add .
    
    # Create commit with descriptive message
    git commit -m "$TITLE

$DESCRIPTION

🤖 Automated by Smart PR workflow" || echo "No changes to commit"
    
    echo "✅ Changes committed"
}

# Function to push and create PR
create_pr() {
    echo "🔀 Pushing branch and creating PR..."
    
    # Push branch
    git push origin "$BRANCH" --force-with-lease
    
    # Create PR with proper labels and assignees
    PR_NUMBER=$(gh pr create \
        --title "$TITLE" \
        --body "$DESCRIPTION

## 🤖 Automated PR Workflow

This PR has been created using the Smart PR workflow.

### Features:
- ✅ Automated conflict resolution
- ✅ BugBot integration ready
- ✅ Automated testing enabled
- ✅ Auto-fix capability: $AUTO_FIX
- ✅ Auto-merge capability: $AUTO_MERGE

### Next Steps:
1. BugBot will automatically review this PR
2. Automated fixes will be applied if needed
3. PR will be merged automatically after approval

---
*Created by Smart PR workflow at $(date)*" \
        --assignee @me \
        --label "automated" \
        --label "bugbot-ready" \
        --output json | jq -r '.number')
    
    echo "✅ PR created: #$PR_NUMBER"
    echo "🔗 View at: https://github.com/Ghostmonday/DStudio/pull/$PR_NUMBER"
    
    return "$PR_NUMBER"
}

# Function to trigger automated fixes
trigger_auto_fix() {
    if [ "$AUTO_FIX" = true ]; then
        echo "🔧 Triggering automated fixes..."
        chmod +x ./automation/auto-fix.sh
        ./automation/auto-fix.sh "$1"
        echo "✅ Automated fixes applied"
    fi
}

# Function to set up auto-merge
setup_auto_merge() {
    if [ "$AUTO_MERGE" = true ]; then
        echo "🔄 Setting up auto-merge..."
        
        # Add a comment to the PR indicating auto-merge is enabled
        gh pr comment "$1" --body "🤖 **Auto-merge enabled**
        
        This PR will be automatically merged after:
        - ✅ BugBot approval
        - ✅ All status checks pass
        - ✅ No critical file conflicts
        
        Auto-merge is scheduled to run in 5 minutes."
        
        # Schedule auto-merge (using a simple delay)
        (sleep 300 && ./automation/auto-merge.sh "$1") &
        
        echo "✅ Auto-merge scheduled"
    fi
}

# Function to monitor PR status
monitor_pr() {
    PR_NUMBER="$1"
    
    echo "👀 Monitoring PR #$PR_NUMBER status..."
    
    # Wait for BugBot to review
    echo "⏳ Waiting for BugBot review..."
    
    # Check PR status every 30 seconds for up to 10 minutes
    for i in {1..20}; do
        PR_STATUS=$(gh pr view "$PR_NUMBER" --json state,reviews --jq '.state')
        
        if [ "$PR_STATUS" != "OPEN" ]; then
            echo "📊 PR status changed to: $PR_STATUS"
            break
        fi
        
        # Check if BugBot has reviewed
        REVIEWS=$(gh pr view "$PR_NUMBER" --json reviews --jq '.reviews[] | select(.author.login | contains("GhostMonday") or contains("bugbot"))')
        
        if [ -n "$REVIEWS" ]; then
            echo "✅ BugBot has reviewed the PR"
            break
        fi
        
        echo "⏳ Still waiting for BugBot review... ($i/20)"
        sleep 30
    done
    
    echo "📊 PR monitoring completed"
}

# Function to show PR summary
show_summary() {
    PR_NUMBER="$1"
    
    echo ""
    echo "🎉 Smart PR Creation Complete!"
    echo "================================="
    echo "📝 Title: $TITLE"
    echo "🔗 PR: #$PR_NUMBER"
    echo "🌿 Branch: $BRANCH"
    echo "🔧 Auto-fix: $AUTO_FIX"
    echo "🔄 Auto-merge: $AUTO_MERGE"
    echo ""
    echo "🔗 View PR: https://github.com/Ghostmonday/DStudio/pull/$PR_NUMBER"
    echo ""
    echo "📋 Next steps:"
    echo "1. BugBot will review the PR automatically"
    echo "2. Automated fixes will be applied if needed"
    if [ "$AUTO_MERGE" = true ]; then
        echo "3. PR will be merged automatically after approval"
    else
        echo "3. Manual merge required after approval"
    fi
    echo ""
}

# Main execution
main() {
    if [ -z "$TITLE" ]; then
        echo "Usage: ./smart-pr.sh 'PR Title' 'Description' [--auto-fix] [--auto-merge]"
        echo ""
        echo "Examples:"
        echo "  ./smart-pr.sh 'Fix Swift syntax errors'"
        echo "  ./smart-pr.sh 'Update UI components' 'Improved user experience' --auto-fix"
        echo "  ./smart-pr.sh 'Add new feature' 'Description here' --auto-fix --auto-merge"
        exit 1
    fi
    
    echo "🚀 Starting Smart PR workflow..."
    
    # Execute workflow steps
    create_branch
    commit_changes
    
    # Resolve any conflicts first
    ./fix-conflicts.sh
    
    # Create PR and get PR number
    create_pr
    PR_NUMBER=$?
    
    # Apply automated fixes if requested
    trigger_auto_fix "$PR_NUMBER"
    
    # Set up auto-merge if requested
    setup_auto_merge "$PR_NUMBER"
    
    # Monitor PR status
    monitor_pr "$PR_NUMBER"
    
    # Show summary
    show_summary "$PR_NUMBER"
}

# Run main function
main "$@"
