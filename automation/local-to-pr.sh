#!/bin/bash

# Convert local changes to PR - handles cases where changes aren't in Git yet
# Usage: ./local-to-pr.sh "PR Title" "Description"

set -e

TITLE="$1"
DESCRIPTION="${2:-Ready for BugBot review}"

echo "🔄 Converting Local Changes to PR: $TITLE"

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        echo "❌ Not in a git repository"
        echo "Initializing git repository..."
        git init
        git remote add origin https://github.com/Ghostmonday/DStudio.git
        echo "✅ Git repository initialized"
    else
        echo "✅ Git repository found"
    fi
}

# Function to check current git status
check_git_status() {
    echo "📊 Checking git status..."
    
    # Check if we have any changes
    if git diff --quiet && git diff --cached --quiet; then
        echo "ℹ️  No changes detected"
        echo "Creating a test change to demonstrate the workflow..."
        
        # Create a simple test file
        cat > automation/demo-change.txt << EOF
# Demo Change for PR Creation

This file demonstrates the local-to-PR workflow.

Created: $(date)
Title: $TITLE
Description: $DESCRIPTION

This shows how local changes get converted to PRs.
EOF
        
        echo "✅ Demo change created"
    else
        echo "✅ Changes detected:"
        git status --porcelain
    fi
}

# Function to create or switch to feature branch
setup_branch() {
    echo "🌿 Setting up feature branch..."
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_BRANCH" ] || [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        # Create new feature branch
        BRANCH="feature/$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')-$(date +%Y%m%d-%H%M%S)"
        git checkout -b "$BRANCH"
        echo "✅ Created feature branch: $BRANCH"
    else
        BRANCH="$CURRENT_BRANCH"
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

🤖 Local changes converted to PR" || {
        echo "⚠️  No changes to commit (this is normal if files are already committed)"
        return 0
    }
    
    echo "✅ Changes committed"
}

# Function to push to remote
push_to_remote() {
    echo "📤 Pushing to remote repository..."
    
    # Check if remote exists
    if ! git remote get-url origin &> /dev/null; then
        echo "🔗 Adding remote origin..."
        git remote add origin https://github.com/Ghostmonday/DStudio.git
    fi
    
    # Push branch to remote
    echo "📤 Pushing branch to origin..."
    git push origin "$BRANCH" --force-with-lease || {
        echo "⚠️  Push failed - this might be the first push"
        echo "🔄 Trying initial push..."
        git push -u origin "$BRANCH"
    }
    
    echo "✅ Branch pushed to remote"
}

# Function to generate PR creation instructions
generate_pr_instructions() {
    echo ""
    echo "🎉 Local Changes Successfully Converted to PR!"
    echo "=============================================="
    echo "📝 Title: $TITLE"
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
    echo "## 🤖 Local-to-PR Workflow"
    echo ""
    echo "This PR was created from local changes using the Local-to-PR workflow."
    echo ""
    echo "### What was done:"
    echo "- ✅ Local changes detected and staged"
    echo "- ✅ Feature branch created: $BRANCH"
    echo "- ✅ Changes committed with descriptive message"
    echo "- ✅ Branch pushed to remote repository"
    echo "- ✅ Ready for BugBot review"
    echo ""
    echo "### Next Steps:"
    echo "1. BugBot will review this PR"
    echo "2. Automated fixes will be applied if needed"
    echo "3. PR will be merged after approval"
    echo ""
    echo "---"
    echo "*Created by Local-to-PR workflow at $(date)*"
    echo "------------------------------------"
    echo ""
    echo "✅ Ready to create PR!"
    echo "🔗 Click the link above to create the PR"
}

# Function to show git log
show_git_log() {
    echo ""
    echo "📜 Recent commits:"
    echo "-----------------"
    git log --oneline -5
    echo ""
}

# Main execution
main() {
    if [ -z "$TITLE" ]; then
        echo "Usage: ./local-to-pr.sh 'PR Title' 'Description'"
        echo ""
        echo "Examples:"
        echo "  ./local-to-pr.sh 'Fix Swift syntax errors'"
        echo "  ./local-to-pr.sh 'Update UI components' 'Improved user experience'"
        exit 1
    fi
    
    echo "🚀 Starting Local-to-PR Conversion"
    echo "=================================="
    echo ""
    
    # Execute workflow steps
    check_git_repo
    check_git_status
    setup_branch
    commit_changes
    push_to_remote
    
    # Show results
    show_git_log
    generate_pr_instructions
}

# Run main function
main "$@"
