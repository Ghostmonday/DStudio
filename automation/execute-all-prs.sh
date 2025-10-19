#!/bin/bash

# Execute All Strategic PRs for BugBot Review
# Creates all 8 focused PRs for systematic codebase analysis

echo "🎯 DirectorStudio Strategic PR Execution"
echo "========================================"
echo ""

# Check prerequisites
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please run from project root."
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Please install: winget install GitHub.cli"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Please run: gh auth login"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Strategic PR configurations
declare -a PRS=(
    "Core App Components Review|BugBot scan of main app entry point, content view, app state, and core data models"
    "UI Components & Views Review|BugBot scan of all UI components, views, sheets, and user interface elements"
    "Pipeline & Processing Modules Review|BugBot scan of AI pipeline modules, processing engines, and workflow management"
    "Services & Backend Integration Review|BugBot scan of API services, authentication, data sync, and external integrations"
    "Data & Persistence Layer Review|BugBot scan of CoreData, storage, persistence, and data management"
    "Configuration & Project Setup Review|BugBot scan of project configuration, assets, build settings, and resources"
    "Documentation & Developer Guides Review|BugBot scan of documentation, guides, and developer resources"
    "Comprehensive Full-Stack Review|BugBot complete end-to-end scan of entire codebase"
)

echo "🚀 Creating ${#PRS[@]} Strategic PRs for BugBot Review"
echo "===================================================="
echo ""

# Track created PRs
declare -a CREATED_PRS=()

# Execute each PR
for i in "${!PRS[@]}"; do
    IFS='|' read -r title description <<< "${PRS[$i]}"
    pr_num=$((i + 1))
    
    echo "📋 Creating PR $pr_num/${#PRS[@]}: $title"
    echo "Description: $description"
    echo ""
    
    # Execute the PR creation
    if ./automation/local-to-pr.sh "$title" "$description"; then
        echo "✅ PR $pr_num created successfully"
        CREATED_PRS+=("$pr_num")
    else
        echo "❌ Failed to create PR $pr_num"
        echo "Continuing with remaining PRs..."
    fi
    
    echo ""
    echo "⏳ Waiting 10 seconds before next PR..."
    sleep 10
    echo ""
done

# Summary
echo "🎉 Strategic PR Execution Complete!"
echo "==================================="
echo ""
echo "📊 Summary:"
echo "- Total PRs planned: ${#PRS[@]}"
echo "- PRs created successfully: ${#CREATED_PRS[@]}"
echo "- Failed PRs: $((${#PRS[@]} - ${#CREATED_PRS[@]}))"
echo ""

if [ ${#CREATED_PRS[@]} -gt 0 ]; then
    echo "✅ Successfully Created PRs:"
    for pr_num in "${CREATED_PRS[@]}"; do
        echo "   - PR $pr_num"
    done
    echo ""
fi

echo "📋 Next Steps:"
echo "1. Monitor BugBot analysis progress"
echo "2. Review findings from each PR"
echo "3. Apply recommended fixes"
echo "4. Merge approved PRs"
echo "5. Continue with development"
echo ""

echo "🔗 Monitor all PRs at:"
echo "https://github.com/Ghostmonday/DStudio/pulls"
echo ""

echo "🤖 BugBot will now systematically review your entire codebase!"
echo "Each PR focuses on specific components for thorough analysis."
echo ""
