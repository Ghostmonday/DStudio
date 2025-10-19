# Simple BugBot PR Creation Script
Write-Host "🎯 Creating BugBot Review PRs..." -ForegroundColor Cyan

# Check prerequisites
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not in git repository" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI not found" -ForegroundColor Red
    exit 1
}

# Sync with GitHub
Write-Host "🔄 Syncing with GitHub..." -ForegroundColor Cyan
git fetch origin
git checkout main
git pull origin main

# Create PRs one by one
$prs = @(
    "Core App Components Review|BugBot scan of main app entry point, content view, app state, and core data models",
    "UI Components & Views Review|BugBot scan of all UI components, views, sheets, and user interface elements",
    "Pipeline & Processing Modules Review|BugBot scan of AI pipeline modules, processing engines, and workflow management",
    "Services & Backend Integration Review|BugBot scan of API services, authentication, data sync, and external integrations",
    "Data & Persistence Layer Review|BugBot scan of CoreData, storage, persistence, and data management",
    "Configuration & Project Setup Review|BugBot scan of project configuration, assets, build settings, and resources",
    "Documentation & Developer Guides Review|BugBot scan of documentation, guides, and developer resources",
    "Comprehensive Full-Stack Review|BugBot complete end-to-end scan of entire codebase"
)

Write-Host "🚀 Creating $($prs.Count) Strategic PRs..." -ForegroundColor Green

$createdPRs = 0

foreach ($i in 0..($prs.Count - 1)) {
    $prData = $prs[$i].Split('|')
    $title = $prData[0]
    $description = $prData[1]
    $prNumber = $i + 1
    $branchName = "bugbot-review-$prNumber"
    
    Write-Host ""
    Write-Host "📋 Creating PR $prNumber/$($prs.Count): $title" -ForegroundColor Yellow
    
    # Create branch
    git checkout -b $branchName
    
    # Create BugBot trigger file
    $triggerContent = "BugBot Review Trigger`n`nTitle: $title`nDescription: $description`nCreated: $(Get-Date)`nBranch: $branchName`nPR Number: $prNumber of $($prs.Count)`n`nBugBot Analysis Request:`nPlease perform comprehensive analysis of code quality, security, performance, architecture, and bugs.`n`nCreated by DirectorStudio Strategic PR Automation"
    
    $triggerContent | Out-File -FilePath "BUG_BOT_TRIGGER.md" -Encoding utf8
    
    # Commit and push
    git add BUG_BOT_TRIGGER.md
    git commit -m "BugBot Review: $title - Strategic PR $prNumber"
    git push origin $branchName
    
    # Create PR without labels (they don't exist yet)
    Write-Host "🔗 Creating PR on GitHub..." -ForegroundColor Cyan
    $prUrl = gh pr create --title "BugBot Review: $title" --body $description --assignee "@me"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PR $prNumber created: $prUrl" -ForegroundColor Green
        $createdPRs++
    } else {
        Write-Host "❌ Failed to create PR $prNumber" -ForegroundColor Red
    }
    
    # Return to main
    git checkout main
    Start-Sleep -Seconds 2
}

# Summary
Write-Host ""
Write-Host "🎉 Strategic PR Wave Complete!" -ForegroundColor Green
Write-Host "Created $createdPRs PRs successfully" -ForegroundColor Yellow
Write-Host "Monitor at: https://github.com/Ghostmonday/DStudio/pulls" -ForegroundColor Cyan
Write-Host ""
Write-Host "🤖 BugBot will now systematically review your codebase!" -ForegroundColor Green
