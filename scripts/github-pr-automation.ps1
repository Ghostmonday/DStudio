# GitHub PR Automation Script - Live Connection
# Replaces simulation documentation with genuine GitHub API calls

param(
    [string]$Action = "create",
    [string]$Title = "AutoPR: Pipeline Upgrade",
    [string]$Description = "Automated PR for pipeline upgrades",
    [string]$SourceBranch = "pipeline-upgrade-replacement",
    [string]$TargetBranch = "main",
    [string]$PRNumber = "",
    [switch]$AutoMerge = $false,
    [switch]$Status = $false,
    [switch]$List = $false
)

# GitHub API Configuration
$GITHUB_REPO = "Ghostmonday/DStudio"
$GITHUB_API_BASE = "https://api.github.com/repos/$GITHUB_REPO"

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) not found. Please install it first:" -ForegroundColor Red
    Write-Host "   winget install GitHub.cli" -ForegroundColor Yellow
    Write-Host "   or visit: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Authenticate with GitHub
Write-Host "🔐 Authenticating with GitHub..." -ForegroundColor Cyan
$authStatus = gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not authenticated with GitHub. Please run: gh auth login" -ForegroundColor Red
    exit 1
}

function Get-PRStatus {
    param([string]$prNumber)
    
    Write-Host "📊 Fetching PR #$prNumber status..." -ForegroundColor Cyan
    
    $prInfo = gh pr view $prNumber --json number,title,state,url,author,createdAt,updatedAt,mergeable,reviewDecision,labels
    $prData = $prInfo | ConvertFrom-Json
    
    Write-Host "✅ PR Status Retrieved:" -ForegroundColor Green
    Write-Host "   Title: $($prData.title)" -ForegroundColor White
    Write-Host "   State: $($prData.state)" -ForegroundColor White
    Write-Host "   URL: $($prData.url)" -ForegroundColor White
    Write-Host "   Author: $($prData.author.login)" -ForegroundColor White
    Write-Host "   Created: $($prData.createdAt)" -ForegroundColor White
    Write-Host "   Updated: $($prData.updatedAt)" -ForegroundColor White
    Write-Host "   Mergeable: $($prData.mergeable)" -ForegroundColor White
    Write-Host "   Review Decision: $($prData.reviewDecision)" -ForegroundColor White
    
    return $prData
}

function Create-PR {
    param(
        [string]$title,
        [string]$description,
        [string]$sourceBranch,
        [string]$targetBranch
    )
    
    Write-Host "🚀 Creating PR: '$title'" -ForegroundColor Cyan
    Write-Host "   Source: $sourceBranch" -ForegroundColor Gray
    Write-Host "   Target: $targetBranch" -ForegroundColor Gray
    
    # Check if source branch exists
    $branchExists = git show-ref --verify --quiet "refs/heads/$sourceBranch"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Source branch '$sourceBranch' does not exist" -ForegroundColor Red
        exit 1
    }
    
    # Create PR via GitHub CLI
    $prUrl = gh pr create `
        --title $title `
        --body $description `
        --base $targetBranch `
        --head $sourceBranch `
        --label "automation,ci-generated" `
        --assignee "@me"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PR created successfully!" -ForegroundColor Green
        Write-Host "   URL: $prUrl" -ForegroundColor Cyan
        
        # Extract PR number from URL
        $prNumber = ($prUrl -split '/')[-1]
        
        # Update local documentation
        Update-PRDocumentation -prNumber $prNumber -prUrl $prUrl -title $title
        
        return $prNumber
    } else {
        Write-Host "❌ Failed to create PR" -ForegroundColor Red
        exit 1
    }
}

function Update-PRDocumentation {
    param(
        [string]$prNumber,
        [string]$prUrl,
        [string]$title
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    
    $docContent = @"
# Live PR Status - $timestamp

## Current PR Information
**PR Number:** #$prNumber  
**Title:** $title  
**URL:** $prUrl  
**Status:** Created  
**Created:** $timestamp  

## Actions Taken
- [x] PR created via automation
- [x] Labels applied (automation, ci-generated)
- [x] Assigned to current user
- [x] Documentation updated

## Next Steps
- [ ] Code review
- [ ] Testing
- [ ] Approval
- [ ] Merge

## Repository Information
- **Repository:** $GITHUB_REPO
- **Default Branch:** $TargetBranch
- **Last Updated:** $timestamp

---
*This file is automatically updated by the GitHub PR automation script*
"@

    $docContent | Out-File -FilePath "PR_LIVE_STATUS.md" -Encoding utf8
    Write-Host "📝 Documentation updated: PR_LIVE_STATUS.md" -ForegroundColor Green
}

function List-PRs {
    Write-Host "📋 Fetching all PRs..." -ForegroundColor Cyan
    
    $allPRs = gh pr list --state all --limit 10 --json number,title,state,url,createdAt,author
    $prsData = $allPRs | ConvertFrom-Json
    
    Write-Host "✅ Recent PRs:" -ForegroundColor Green
    foreach ($pr in $prsData) {
        $statusColor = if ($pr.state -eq "OPEN") { "Green" } elseif ($pr.state -eq "MERGED") { "Cyan" } else { "Yellow" }
        Write-Host "   #$($pr.number) - $($pr.title) [$($pr.state)]" -ForegroundColor $statusColor
        Write-Host "      URL: $($pr.url)" -ForegroundColor Gray
        Write-Host "      Author: $($pr.author.login) - $($pr.createdAt)" -ForegroundColor Gray
        Write-Host ""
    }
}

function Merge-PR {
    param([string]$prNumber)
    
    Write-Host "🔀 Merging PR #$prNumber..." -ForegroundColor Cyan
    
    # Get PR status first
    $prData = Get-PRStatus -prNumber $prNumber
    
    if ($prData.state -ne "OPEN") {
        Write-Host "❌ PR #$prNumber is not in OPEN state (current: $($prData.state))" -ForegroundColor Red
        exit 1
    }
    
    if ($prData.mergeable -eq $false) {
        Write-Host "❌ PR #$prNumber is not mergeable" -ForegroundColor Red
        exit 1
    }
    
    # Merge the PR
    $mergeResult = gh pr merge $prNumber --merge --delete-branch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PR #$prNumber merged successfully!" -ForegroundColor Green
        Write-Host "   $mergeResult" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Failed to merge PR #$prNumber" -ForegroundColor Red
        exit 1
    }
}

# Main execution
Write-Host "🤖 GitHub PR Automation Script" -ForegroundColor Cyan
Write-Host "Repository: $GITHUB_REPO" -ForegroundColor Gray
Write-Host "Action: $Action" -ForegroundColor Gray
Write-Host ""

switch ($Action) {
    "create" {
        $prNumber = Create-PR -title $Title -description $Description -sourceBranch $SourceBranch -targetBranch $TargetBranch
        Write-Host "🎉 PR created with number: #$prNumber" -ForegroundColor Green
    }
    "status" {
        if ($PRNumber) {
            Get-PRStatus -prNumber $PRNumber
        } else {
            Write-Host "❌ Please provide PR number with -PRNumber parameter" -ForegroundColor Red
            exit 1
        }
    }
    "list" {
        List-PRs
    }
    "merge" {
        if ($PRNumber) {
            Merge-PR -prNumber $PRNumber
        } else {
            Write-Host "❌ Please provide PR number with -PRNumber parameter" -ForegroundColor Red
            exit 1
        }
    }
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: create, status, list, merge" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "✅ GitHub PR automation completed successfully!" -ForegroundColor Green
