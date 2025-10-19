# --- DirectorStudio Strategic PR Wave for BugBot Review ---
# Creates 8 focused PRs for systematic codebase analysis

Write-Host "🎯 Initializing Strategic PR Wave for BugBot Review..." -ForegroundColor Cyan

# Ensure script is run from repo root
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not inside a Git repository. Navigate to the project root first." -ForegroundColor Red
    exit 1
}

# Check GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI not found. Please install: winget install GitHub.cli" -ForegroundColor Red
    exit 1
}

# Sync environment
Write-Host "🔄 Syncing with GitHub..." -ForegroundColor Cyan
git fetch origin
git checkout main
git pull origin main

# Define strategic PR configurations
$strategicPRs = @(
    @{
        Branch = "bugbot-core-components"
        Title = "BugBot Review: Core App Components"
        Description = "BugBot scan of main app entry point, content view, app state, and core data models"
        Files = @("DirectorStudioApp.swift", "ContentView.swift", "Core/AppState.swift", "Core/Project.swift", "Core/PromptSegment.swift", "Core/SceneModel.swift", "Core/DeepSeekConfig.swift")
    },
    @{
        Branch = "bugbot-ui-components"
        Title = "BugBot Review: UI Components & Views"
        Description = "BugBot scan of all UI components, views, sheets, and user interface elements"
        Files = @("Components/", "Views/", "Sheets/", "UI/", "Onboarding/")
    },
    @{
        Branch = "bugbot-pipeline-modules"
        Title = "BugBot Review: Pipeline & Processing Modules"
        Description = "BugBot scan of AI pipeline modules, processing engines, and workflow management"
        Files = @("Modules/", "Pipeline/", "ContinuityEngineAnalysis/")
    },
    @{
        Branch = "bugbot-services-backend"
        Title = "BugBot Review: Services & Backend Integration"
        Description = "BugBot scan of API services, authentication, data sync, and external integrations"
        Files = @("Services/", "backend/", "Sync/")
    },
    @{
        Branch = "bugbot-data-persistence"
        Title = "BugBot Review: Data & Persistence Layer"
        Description = "BugBot scan of CoreData, storage, persistence, and data management"
        Files = @("Persistence/", "Storage/", "DirectorStudio.xcdatamodeld/")
    },
    @{
        Branch = "bugbot-config-project"
        Title = "BugBot Review: Configuration & Project Setup"
        Description = "BugBot scan of project configuration, assets, build settings, and resources"
        Files = @("Assets.xcassets/", "Info.plist", "Resources/", "DirectorStudio.xcodeproj/")
    },
    @{
        Branch = "bugbot-documentation"
        Title = "BugBot Review: Documentation & Developer Guides"
        Description = "BugBot scan of documentation, guides, and developer resources"
        Files = @("*.md", "Guides/", "DEVELOPER_SETUP.md")
    },
    @{
        Branch = "bugbot-comprehensive"
        Title = "BugBot Review: Comprehensive Full-Stack Review"
        Description = "BugBot complete end-to-end scan of entire codebase"
        Files = @("**/*")
    }
)

Write-Host "🚀 Creating $($strategicPRs.Count) Strategic PRs for BugBot Review" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

$createdPRs = @()

foreach ($i in 0..($strategicPRs.Count - 1)) {
    $pr = $strategicPRs[$i]
    $prNumber = $i + 1
    
    Write-Host "📋 Creating PR $prNumber/$($strategicPRs.Count): $($pr.Title)" -ForegroundColor Yellow
    Write-Host "   Branch: $($pr.Branch)" -ForegroundColor Gray
    Write-Host "   Description: $($pr.Description)" -ForegroundColor Gray
    Write-Host ""

    # Create branch
    git checkout -b $pr.Branch

    # Create BugBot trigger file
    $bugBotContent = @"
# BugBot Review Trigger - $($pr.Title)

**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Branch:** $($pr.Branch)
**PR Number:** $prNumber of $($strategicPRs.Count)

## Analysis Scope
$($pr.Description)

## Files to Review
$($pr.Files -join ", ")

## BugBot Analysis Request
Please perform comprehensive analysis of:
1. Code quality and best practices
2. Security vulnerabilities
3. Performance optimizations
4. Architecture improvements
5. Bug detection and fixes

## Strategic Review Context
This PR is part of a systematic 8-PR review strategy:
- PR 1: Core App Components
- PR 2: UI Components & Views
- PR 3: Pipeline & Processing Modules
- PR 4: Services & Backend Integration
- PR 5: Data & Persistence Layer
- PR 6: Configuration & Project Setup
- PR 7: Documentation & Developer Guides
- PR 8: Comprehensive Full-Stack Review

## Status
- [x] PR created via strategic automation
- [x] BugBot trigger file created
- [ ] BugBot analysis in progress
- [ ] Results reviewed
- [ ] Fixes applied

---
*Created by DirectorStudio Strategic PR Automation*
"@

    $bugBotContent | Out-File -FilePath "BUG_BOT_TRIGGER.md" -Encoding utf8

    # Commit and push
    git add BUG_BOT_TRIGGER.md
    git commit -m "BugBot Review: $($pr.Title)

$($pr.Description)

Strategic PR $prNumber of $($strategicPRs.Count) for systematic codebase review.
BugBot trigger file created for focused analysis."

    git push origin $pr.Branch

    # Create PR via GitHub CLI
    Write-Host "🔗 Creating PR on GitHub..." -ForegroundColor Cyan
    $prUrl = gh pr create `
        --title $pr.Title `
        --body "$($pr.Description)

## BugBot Analysis Request

This PR is part of a strategic systematic review of the DirectorStudio codebase.

### Analysis Scope
- Code quality and best practices
- Security vulnerabilities
- Performance optimizations
- Architecture improvements
- Bug detection and fixes

### Files Included
$($pr.Files -join ", ")

### Strategic Context
This is PR $prNumber of $($strategicPRs.Count) in our systematic review strategy.

### Next Steps
1. BugBot will analyze the focused component set
2. Issues and improvements will be identified
3. Fixes will be applied as needed
4. Results will be documented

---
*Created by DirectorStudio Strategic PR Automation*" `
        --label "bugbot-review,automation,strategic-review" `
        --assignee "@me"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PR $prNumber created successfully!" -ForegroundColor Green
        Write-Host "   URL: $prUrl" -ForegroundColor Cyan
        $createdPRs += @{
            Number = $prNumber
            Title = $pr.Title
            URL = $prUrl
            Branch = $pr.Branch
        }
    } else {
        Write-Host "❌ Failed to create PR $prNumber" -ForegroundColor Red
    }

    # Return to main branch
    git checkout main
    
    Write-Host ""
    Write-Host "⏳ Waiting 5 seconds before next PR..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    Write-Host ""
}

# Summary
Write-Host "🎉 Strategic PR Wave Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "- Total PRs planned: $($strategicPRs.Count)" -ForegroundColor White
Write-Host "- PRs created successfully: $($createdPRs.Count)" -ForegroundColor White
Write-Host "- Failed PRs: $($strategicPRs.Count - $createdPRs.Count)" -ForegroundColor White
Write-Host ""

if ($createdPRs.Count -gt 0) {
    Write-Host "✅ Successfully Created PRs:" -ForegroundColor Green
    foreach ($pr in $createdPRs) {
        Write-Host "   PR $($pr.Number): $($pr.Title)" -ForegroundColor White
        Write-Host "   URL: $($pr.URL)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Monitor BugBot analysis progress" -ForegroundColor White
Write-Host "2. Review findings from each PR" -ForegroundColor White
Write-Host "3. Apply recommended fixes" -ForegroundColor White
Write-Host "4. Merge approved PRs" -ForegroundColor White
Write-Host "5. Continue with development" -ForegroundColor White
Write-Host ""

Write-Host "🔗 Monitor all PRs at:" -ForegroundColor Cyan
Write-Host "https://github.com/Ghostmonday/DStudio/pulls" -ForegroundColor Blue
Write-Host ""

Write-Host "🤖 BugBot will now systematically review your entire codebase!" -ForegroundColor Green
Write-Host "Each PR focuses on specific components for thorough analysis." -ForegroundColor Green
Write-Host ""
