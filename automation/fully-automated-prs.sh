#!/bin/bash

# Fully automated PR creation - no pauses, creates all PRs immediately
echo "🚀 Creating ALL Strategic PRs Automatically"
echo "==========================================="

# Function to create PR with specific files
create_targeted_pr() {
    local title="$1"
    local description="$2"
    local files="$3"
    
    echo "📝 Creating: $title"
    
    # Create new branch for this PR
    local branch="pr/$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')-$(date +%Y%m%d-%H%M%S)"
    
    # Stash current changes
    git stash push -m "Stashing for $title"
    
    # Create and checkout new branch
    git checkout -b "$branch"
    
    # Restore stashed changes
    git stash pop
    
    # Add only specific files if specified
    if [ -n "$files" ]; then
        git add $files
    else
        git add .
    fi
    
    # Commit changes
    git commit -m "$title

$description

🤖 Automated strategic PR creation" || echo "No changes to commit for $title"
    
    # Push branch
    git push origin "$branch" --force-with-lease
    
    # Create PR using GitHub CLI
    gh pr create \
        --title "$title" \
        --body "$description

## 🤖 Automated Strategic PR

This PR was created as part of the strategic PR plan for comprehensive BugBot scanning.

### What's included:
- $files

### Next Steps:
1. BugBot will automatically review this PR
2. Automated fixes will be applied if needed
3. PR will be merged after approval

---
*Created by automated strategic PR workflow at $(date)*" \
        --assignee @me \
        --label "strategic-review" \
        --label "bugbot-ready" \
        --label "automated"
    
    echo "✅ Created PR: $title"
    echo ""
    
    # Switch back to main branch for next PR
    git checkout main
}

# PR 1: Core App Components
create_targeted_pr \
    "Core App Components Review" \
    "BugBot scan of main app entry point, content view, app state, and core data models" \
    "DirectorStudio/DirectorStudioApp.swift DirectorStudio/ContentView.swift DirectorStudio/Core/AppState.swift DirectorStudio/Core/Models.swift"

# PR 2: UI Components & Views  
create_targeted_pr \
    "UI Components & Views Review" \
    "BugBot scan of all UI components, views, sheets, and user interface elements" \
    "DirectorStudio/Components/ DirectorStudio/Views/ DirectorStudio/Sheets/ DirectorStudio/UI/"

# PR 3: Pipeline & Processing Modules
create_targeted_pr \
    "Pipeline & Processing Modules Review" \
    "BugBot scan of all pipeline modules, processing logic, and continuity engine" \
    "DirectorStudio/Modules/ Pipeline/ ContinuityEngineAnalysis/"

# PR 4: Services & Backend Integration
create_targeted_pr \
    "Services & Backend Integration Review" \
    "BugBot scan of all services, backend integration, and database connections" \
    "DirectorStudio/Services/ backend/"

# PR 5: Data & Persistence Layer
create_targeted_pr \
    "Data & Persistence Layer Review" \
    "BugBot scan of data models, persistence layer, and synchronization logic" \
    "DirectorStudio/Persistence/ DirectorStudio/Storage/ DirectorStudio/Sync/ DirectorStudio.xcdatamodeld/"

# PR 6: Configuration & Project Setup
create_targeted_pr \
    "Configuration & Project Setup Review" \
    "BugBot scan of project configuration, assets, and setup files" \
    "DirectorStudio/Info.plist DirectorStudio/Assets.xcassets/ DirectorStudio.xcodeproj/ DirectorStudio/Resources/"

# PR 7: Documentation & Developer Guides
create_targeted_pr \
    "Documentation & Developer Guides Review" \
    "BugBot scan of all documentation, guides, and developer resources" \
    "DEVELOPER_SETUP.md DirectorStudio/Guides/ README.md AUTOMATION_GUIDE.md *.md"

# PR 8: Comprehensive Full-Stack Review
create_targeted_pr \
    "Comprehensive Full-Stack Review" \
    "BugBot complete repository scan - all components, services, UI, and configuration" \
    ""

echo "🎉 ALL STRATEGIC PRs CREATED!"
echo "============================="
echo "✅ 8 PRs created for comprehensive BugBot scanning"
echo "🤖 BugBot will now review all PRs automatically"
echo "🔧 Auto-fixes will be applied as needed"
echo ""
echo "📊 Check your GitHub repository for all the new PRs!"
echo "🔗 https://github.com/Ghostmonday/DStudio/pulls"
