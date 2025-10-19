#!/bin/bash

# Automated merge script with safety checks
# Usage: ./auto-merge.sh [PR_NUMBER]

set -e

PR_NUMBER="$1"
REPO="Ghostmonday/DStudio"

echo "🔍 Starting automated merge process for PR #$PR_NUMBER..."

# Function to check if PR is ready for merge
check_pr_ready() {
    echo "🔍 Checking PR readiness..."
    
    # Get PR status
    PR_STATUS=$(gh pr view "$PR_NUMBER" --json state,mergeable,statusCheckRollup --jq '.state')
    PR_MERGEABLE=$(gh pr view "$PR_NUMBER" --json state,mergeable,statusCheckRollup --jq '.mergeable')
    
    if [ "$PR_STATUS" != "OPEN" ]; then
        echo "❌ PR is not open (status: $PR_STATUS)"
        return 1
    fi
    
    if [ "$PR_MERGEABLE" != "MERGEABLE" ]; then
        echo "❌ PR is not mergeable (status: $PR_MERGEABLE)"
        return 1
    fi
    
    # Check if all status checks are passing
    CHECKS_STATUS=$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '.statusCheckRollup[].state' | grep -v "SUCCESS" | head -1)
    if [ -n "$CHECKS_STATUS" ]; then
        echo "❌ Some status checks are not passing"
        return 1
    fi
    
    echo "✅ PR is ready for merge"
    return 0
}

# Function to check if PR has been approved
check_approval() {
    echo "👥 Checking PR approval status..."
    
    # Check if BugBot has approved
    APPROVALS=$(gh pr view "$PR_NUMBER" --json reviews --jq '.reviews[] | select(.state == "APPROVED") | .author.login')
    
    if echo "$APPROVALS" | grep -q "GhostMonday\|bugbot"; then
        echo "✅ PR has BugBot approval"
        return 0
    else
        echo "⚠️  PR does not have BugBot approval yet"
        return 1
    fi
}

# Function to check if main branch is protected
check_main_protection() {
    echo "🛡️  Checking main branch protection..."
    
    # Switch to main branch
    git checkout main
    git pull origin main
    
    # Check if there are any critical files that shouldn't be modified
    CRITICAL_FILES=("DirectorStudioApp.swift" "ContentView.swift")
    
    for file in "${CRITICAL_FILES[@]}"; do
        if git diff main.."$PR_NUMBER" --name-only | grep -q "$file"; then
            echo "⚠️  Critical file $file is being modified - manual review recommended"
            return 1
        fi
    done
    
    echo "✅ No critical files modified"
    return 0
}

# Function to perform the merge
perform_merge() {
    echo "🔀 Performing merge..."
    
    # Merge the PR
    gh pr merge "$PR_NUMBER" --merge --delete-branch
    
    # Pull latest changes to main
    git checkout main
    git pull origin main
    
    echo "✅ PR #$PR_NUMBER merged successfully"
}

# Function to run post-merge tests
post_merge_tests() {
    echo "🧪 Running post-merge tests..."
    
    # Build the project to ensure everything still works
    cd DirectorStudio
    xcodebuild -scheme DirectorStudio -destination 'platform=iOS Simulator,name=iPhone 15' build
    
    if [ $? -eq 0 ]; then
        echo "✅ Post-merge build successful"
        return 0
    else
        echo "❌ Post-merge build failed"
        return 1
    fi
}

# Function to notify about merge
notify_merge() {
    echo "📢 Sending merge notification..."
    
    # Comment on the merged PR
    gh pr comment "$PR_NUMBER" --body "🎉 **PR Successfully Merged!**
    
    ✅ All automated checks passed
    ✅ BugBot approval received
    ✅ Post-merge tests successful
    ✅ Branch deleted
    
    Great work! 🚀"
    
    echo "✅ Merge notification sent"
}

# Function to rollback if something goes wrong
rollback() {
    echo "🔄 Rolling back merge..."
    
    # Get the commit hash before merge
    LAST_COMMIT=$(git log --oneline -n 2 | tail -1 | cut -d' ' -f1)
    
    # Reset to previous commit
    git reset --hard "$LAST_COMMIT"
    git push origin main --force
    
    echo "⚠️  Merge rolled back to commit $LAST_COMMIT"
}

# Main execution
main() {
    echo "🚀 Starting automated merge process..."
    
    # Safety checks
    if ! check_pr_ready; then
        echo "❌ PR is not ready for merge"
        exit 1
    fi
    
    if ! check_approval; then
        echo "❌ PR needs BugBot approval before merge"
        exit 1
    fi
    
    if ! check_main_protection; then
        echo "⚠️  Manual review recommended due to critical file changes"
        exit 1
    fi
    
    # Perform merge
    if perform_merge; then
        # Run post-merge tests
        if post_merge_tests; then
            notify_merge
            echo "🎉 Automated merge completed successfully!"
        else
            echo "❌ Post-merge tests failed - rollback may be needed"
            rollback
            exit 1
        fi
    else
        echo "❌ Merge failed"
        exit 1
    fi
}

# Run main function
main "$@"
