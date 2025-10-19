# GitHub API Client - Direct API Integration
# Provides direct GitHub API access for PR operations

param(
    [string]$Endpoint = "pulls",
    [string]$Method = "GET",
    [string]$PRNumber = "",
    [string]$Body = "",
    [string]$Title = "",
    [string]$Description = "",
    [string]$SourceBranch = "",
    [string]$TargetBranch = "main"
)

# GitHub API Configuration
$GITHUB_REPO = "Ghostmonday/DStudio"
$GITHUB_API_BASE = "https://api.github.com/repos/$GITHUB_REPO"

# Check for GitHub token
$githubToken = $env:GITHUB_TOKEN
if (-not $githubToken) {
    Write-Host "❌ GitHub token not found. Please set GITHUB_TOKEN environment variable" -ForegroundColor Red
    Write-Host "   or run: gh auth login" -ForegroundColor Yellow
    exit 1
}

function Invoke-GitHubAPI {
    param(
        [string]$endpoint,
        [string]$method = "GET",
        [hashtable]$body = @{}
    )
    
    $uri = "$GITHUB_API_BASE/$endpoint"
    $headers = @{
        "Authorization" = "Bearer $githubToken"
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "DirectorStudio-Automation"
    }
    
    try {
        if ($method -eq "GET") {
            $response = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
        } else {
            $jsonBody = $body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -Body $jsonBody -ContentType "application/json"
        }
        
        return $response
    }
    catch {
        Write-Host "❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Response: $errorBody" -ForegroundColor Red
        }
        exit 1
    }
}

function Get-PRList {
    Write-Host "📋 Fetching PR list from GitHub API..." -ForegroundColor Cyan
    
    $response = Invoke-GitHubAPI -endpoint "pulls?state=all&sort=updated&direction=desc&per_page=10"
    
    Write-Host "✅ Found $($response.Count) PRs:" -ForegroundColor Green
    foreach ($pr in $response) {
        $statusColor = if ($pr.state -eq "open") { "Green" } elseif ($pr.state -eq "closed" -and $pr.merged_at) { "Cyan" } else { "Yellow" }
        Write-Host "   #$($pr.number) - $($pr.title) [$($pr.state)]" -ForegroundColor $statusColor
        Write-Host "      URL: $($pr.html_url)" -ForegroundColor Gray
        Write-Host "      Author: $($pr.user.login) - $($pr.created_at)" -ForegroundColor Gray
        Write-Host ""
    }
    
    return $response
}

function Get-PRDetails {
    param([string]$prNumber)
    
    Write-Host "📊 Fetching PR #$prNumber details..." -ForegroundColor Cyan
    
    $response = Invoke-GitHubAPI -endpoint "pulls/$prNumber"
    
    Write-Host "✅ PR Details:" -ForegroundColor Green
    Write-Host "   Title: $($response.title)" -ForegroundColor White
    Write-Host "   State: $($response.state)" -ForegroundColor White
    Write-Host "   URL: $($response.html_url)" -ForegroundColor White
    Write-Host "   Author: $($response.user.login)" -ForegroundColor White
    Write-Host "   Created: $($response.created_at)" -ForegroundColor White
    Write-Host "   Updated: $($response.updated_at)" -ForegroundColor White
    Write-Host "   Mergeable: $($response.mergeable)" -ForegroundColor White
    Write-Host "   Head: $($response.head.ref)" -ForegroundColor White
    Write-Host "   Base: $($response.base.ref)" -ForegroundColor White
    
    return $response
}

function Create-PR {
    param(
        [string]$title,
        [string]$description,
        [string]$sourceBranch,
        [string]$targetBranch
    )
    
    Write-Host "🚀 Creating PR via GitHub API..." -ForegroundColor Cyan
    
    $body = @{
        title = $title
        body = $description
        head = $sourceBranch
        base = $targetBranch
    }
    
    $response = Invoke-GitHubAPI -endpoint "pulls" -method "POST" -body $body
    
    Write-Host "✅ PR created successfully!" -ForegroundColor Green
    Write-Host "   Number: #$($response.number)" -ForegroundColor White
    Write-Host "   Title: $($response.title)" -ForegroundColor White
    Write-Host "   URL: $($response.html_url)" -ForegroundColor White
    
    return $response
}

function Update-PRStatus {
    param(
        [string]$prNumber,
        [string]$state = "open"
    )
    
    Write-Host "🔄 Updating PR #$prNumber status to $state..." -ForegroundColor Cyan
    
    $body = @{
        state = $state
    }
    
    $response = Invoke-GitHubAPI -endpoint "pulls/$prNumber" -method "PATCH" -body $body
    
    Write-Host "✅ PR #$prNumber updated successfully!" -ForegroundColor Green
    Write-Host "   State: $($response.state)" -ForegroundColor White
    
    return $response
}

function Get-RepositoryInfo {
    Write-Host "📊 Fetching repository information..." -ForegroundColor Cyan
    
    $response = Invoke-GitHubAPI -endpoint ""
    
    Write-Host "✅ Repository Info:" -ForegroundColor Green
    Write-Host "   Name: $($response.name)" -ForegroundColor White
    Write-Host "   Full Name: $($response.full_name)" -ForegroundColor White
    Write-Host "   Description: $($response.description)" -ForegroundColor White
    Write-Host "   Default Branch: $($response.default_branch)" -ForegroundColor White
    Write-Host "   Stars: $($response.stargazers_count)" -ForegroundColor White
    Write-Host "   Forks: $($response.forks_count)" -ForegroundColor White
    Write-Host "   Issues: $($response.open_issues_count)" -ForegroundColor White
    
    return $response
}

function Export-PRData {
    param([string]$outputFile = "pr-data.json")
    
    Write-Host "💾 Exporting PR data to $outputFile..." -ForegroundColor Cyan
    
    $prs = Get-PRList
    $prs | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
    
    Write-Host "✅ PR data exported to $outputFile" -ForegroundColor Green
}

# Main execution
Write-Host "🌐 GitHub API Client" -ForegroundColor Cyan
Write-Host "Repository: $GITHUB_REPO" -ForegroundColor Gray
Write-Host "Endpoint: $Endpoint" -ForegroundColor Gray
Write-Host "Method: $Method" -ForegroundColor Gray
Write-Host ""

switch ($Endpoint.ToLower()) {
    "pulls" {
        if ($Method -eq "GET") {
            if ($PRNumber) {
                Get-PRDetails -prNumber $PRNumber
            } else {
                Get-PRList
            }
        }
        elseif ($Method -eq "POST") {
            Create-PR -title $Title -description $Description -sourceBranch $SourceBranch -targetBranch $TargetBranch
        }
        elseif ($Method -eq "PATCH") {
            Update-PRStatus -prNumber $PRNumber
        }
    }
    "repo" {
        Get-RepositoryInfo
    }
    "export" {
        Export-PRData
    }
    default {
        Write-Host "❌ Unknown endpoint: $Endpoint" -ForegroundColor Red
        Write-Host "Available endpoints: pulls, repo, export" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "✅ GitHub API operation completed successfully!" -ForegroundColor Green
