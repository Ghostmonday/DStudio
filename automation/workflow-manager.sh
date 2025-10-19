#!/bin/bash

# Workflow Manager - Central control for automated PR workflow
# Usage: ./workflow-manager.sh [command] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    echo "🤖 Workflow Manager - Automated PR Workflow Control"
    echo ""
    echo "Usage: ./workflow-manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create <title> [description]     Create a new PR with automated workflow"
    echo "  fix <pr_number>                  Apply automated fixes to existing PR"
    echo "  merge <pr_number>                Merge PR after automated checks"
    echo "  status <pr_number>               Check PR status and workflow progress"
    echo "  monitor                          Monitor all open PRs"
    echo "  cleanup                          Clean up merged branches and old PRs"
    echo "  setup                            Initial setup and configuration"
    echo "  test                             Test the automation workflow"
    echo ""
    echo "Options:"
    echo "  --auto-fix                       Enable automated fixes"
    echo "  --auto-merge                     Enable automated merging"
    echo "  --force                          Force operation (skip confirmations)"
    echo ""
    echo "Examples:"
    echo "  ./workflow-manager.sh create 'Fix Swift errors'"
    echo "  ./workflow-manager.sh fix 123 --auto-fix"
    echo "  ./workflow-manager.sh merge 123 --auto-merge"
    echo "  ./workflow-manager.sh status 123"
    echo "  ./workflow-manager.sh monitor"
}

# Function to check prerequisites
check_prerequisites() {
    print_status $BLUE "🔍 Checking prerequisites..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_status $RED "❌ GitHub CLI (gh) is not installed"
        echo "Install it with: brew install gh"
        exit 1
    fi
    
    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        print_status $RED "❌ GitHub CLI is not authenticated"
        echo "Run: gh auth login"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_status $RED "❌ jq is not installed"
        echo "Install it with: brew install jq"
        exit 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        print_status $RED "❌ Not in a git repository"
        exit 1
    fi
    
    # Check if automation scripts exist
    if [ ! -f "./automation/smart-pr.sh" ]; then
        print_status $RED "❌ Automation scripts not found"
        echo "Run: ./workflow-manager.sh setup"
        exit 1
    fi
    
    print_status $GREEN "✅ All prerequisites met"
}

# Function to create PR
create_pr() {
    local title="$1"
    local description="$2"
    
    if [ -z "$title" ]; then
        print_status $RED "❌ PR title is required"
        show_usage
        exit 1
    fi
    
    print_status $BLUE "🚀 Creating PR: $title"
    
    # Make scripts executable
    chmod +x ./automation/smart-pr.sh
    
    # Create PR with smart workflow
    ./automation/smart-pr.sh "$title" "$description" --auto-fix
    
    print_status $GREEN "✅ PR created successfully"
}

# Function to apply fixes
fix_pr() {
    local pr_number="$1"
    
    if [ -z "$pr_number" ]; then
        print_status $RED "❌ PR number is required"
        exit 1
    fi
    
    print_status $BLUE "🔧 Applying fixes to PR #$pr_number"
    
    # Make scripts executable
    chmod +x ./automation/auto-fix.sh
    
    # Apply fixes
    ./automation/auto-fix.sh "$pr_number"
    
    print_status $GREEN "✅ Fixes applied to PR #$pr_number"
}

# Function to merge PR
merge_pr() {
    local pr_number="$1"
    
    if [ -z "$pr_number" ]; then
        print_status $RED "❌ PR number is required"
        exit 1
    fi
    
    print_status $BLUE "🔄 Merging PR #$pr_number"
    
    # Make scripts executable
    chmod +x ./automation/auto-merge.sh
    
    # Merge PR
    ./automation/auto-merge.sh "$pr_number"
    
    print_status $GREEN "✅ PR #$pr_number merged successfully"
}

# Function to check PR status
check_status() {
    local pr_number="$1"
    
    if [ -z "$pr_number" ]; then
        print_status $RED "❌ PR number is required"
        exit 1
    fi
    
    print_status $BLUE "📊 Checking status of PR #$pr_number"
    
    # Get PR details
    local pr_data=$(gh pr view "$pr_number" --json state,title,author,mergeable,statusCheckRollup,reviews)
    
    local state=$(echo "$pr_data" | jq -r '.state')
    local title=$(echo "$pr_data" | jq -r '.title')
    local author=$(echo "$pr_data" | jq -r '.author.login')
    local mergeable=$(echo "$pr_data" | jq -r '.mergeable')
    
    echo ""
    echo "📋 PR #$pr_number Status"
    echo "========================"
    echo "📝 Title: $title"
    echo "👤 Author: $author"
    echo "📊 State: $state"
    echo "🔀 Mergeable: $mergeable"
    echo ""
    
    # Check reviews
    local reviews=$(echo "$pr_data" | jq -r '.reviews[] | select(.state == "APPROVED") | .author.login')
    if [ -n "$reviews" ]; then
        print_status $GREEN "✅ Approved by: $reviews"
    else
        print_status $YELLOW "⏳ Waiting for approval"
    fi
    
    # Check status checks
    local checks=$(echo "$pr_data" | jq -r '.statusCheckRollup[].state' | grep -v "SUCCESS" | head -1)
    if [ -z "$checks" ]; then
        print_status $GREEN "✅ All status checks passing"
    else
        print_status $YELLOW "⏳ Some status checks not passing"
    fi
    
    echo ""
    echo "🔗 View PR: https://github.com/Ghostmonday/DStudio/pull/$pr_number"
}

# Function to monitor all PRs
monitor_prs() {
    print_status $BLUE "👀 Monitoring all open PRs..."
    
    # Get all open PRs
    local prs=$(gh pr list --json number,title,author,state,mergeable)
    
    echo ""
    echo "📋 Open PRs Status"
    echo "=================="
    
    echo "$prs" | jq -r '.[] | "\(.number) | \(.title) | \(.author.login) | \(.state) | \(.mergeable)"' | \
    while IFS='|' read -r number title author state mergeable; do
        # Clean up whitespace
        number=$(echo "$number" | xargs)
        title=$(echo "$title" | xargs)
        author=$(echo "$author" | xargs)
        state=$(echo "$state" | xargs)
        mergeable=$(echo "$mergeable" | xargs)
        
        if [ "$mergeable" = "MERGEABLE" ]; then
            print_status $GREEN "✅ PR #$number: $title ($author)"
        else
            print_status $YELLOW "⏳ PR #$number: $title ($author)"
        fi
    done
    
    echo ""
}

# Function to cleanup
cleanup() {
    print_status $BLUE "🧹 Cleaning up merged branches and old PRs..."
    
    # Switch to main branch
    git checkout main
    git pull origin main
    
    # Delete merged branches
    git branch --merged | grep -v main | xargs -n 1 git branch -d 2>/dev/null || true
    
    # Clean up remote tracking branches
    git remote prune origin
    
    print_status $GREEN "✅ Cleanup completed"
}

# Function to setup automation
setup_automation() {
    print_status $BLUE "⚙️  Setting up automation workflow..."
    
    # Make all scripts executable
    chmod +x ./automation/*.sh
    chmod +x ./create-pr.sh
    chmod +x ./quick-pr.sh
    chmod +x ./fix-conflicts.sh
    
    # Create automation directory if it doesn't exist
    mkdir -p automation
    
    print_status $GREEN "✅ Automation setup completed"
}

# Function to test workflow
test_workflow() {
    print_status $BLUE "🧪 Testing automation workflow..."
    
    # Test creating a test PR
    local test_title="Test PR - $(date +%Y%m%d-%H%M%S)"
    local test_description="This is a test PR for workflow validation"
    
    print_status $YELLOW "Creating test PR..."
    create_pr "$test_title" "$test_description"
    
    # Get the PR number (this would need to be extracted from the output)
    local test_pr_number=$(gh pr list --limit 1 --json number --jq '.[0].number')
    
    if [ -n "$test_pr_number" ]; then
        print_status $GREEN "✅ Test PR created: #$test_pr_number"
        
        # Test fixes
        print_status $YELLOW "Testing automated fixes..."
        fix_pr "$test_pr_number"
        
        # Close the test PR
        gh pr close "$test_pr_number" --comment "Test PR - closing after workflow validation"
        
        print_status $GREEN "✅ Workflow test completed successfully"
    else
        print_status $RED "❌ Failed to create test PR"
    fi
}

# Main execution
main() {
    local command="$1"
    shift
    
    case "$command" in
        "create")
            create_pr "$@"
            ;;
        "fix")
            fix_pr "$@"
            ;;
        "merge")
            merge_pr "$@"
            ;;
        "status")
            check_status "$@"
            ;;
        "monitor")
            monitor_prs
            ;;
        "cleanup")
            cleanup
            ;;
        "setup")
            setup_automation
            ;;
        "test")
            test_workflow
            ;;
        *)
            print_status $RED "❌ Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Check prerequisites before running
check_prerequisites

# Run main function
main "$@"
