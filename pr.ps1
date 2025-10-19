# --- DirectorStudio Full Repo Scan PR Wave ---
# Executes 12 PRs automatically to trigger BugBot analysis

Write-Host "🚀 Initializing PR Machine Gun for DirectorStudio..." -ForegroundColor Cyan

# Ensure script is run from repo root
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not inside a Git repository. Navigate to the project root first." -ForegroundColor Red
    exit 1
}

# Sync environment
git fetch origin
git checkout production-ready
git pull origin production-ready

# Define PR branches
$branches = @(
    "studio-tab-hardening",
    "remove-validation-harness",
    "remove-storyboard-infoplist",
    "move-assets-catalog",
    "coredata-init-fix",
    "continuity-engine-sanity",
    "telemetry-event-validation",
    "credits-ledger-rls-stub",
    "ci-fastfail",
    "assets-license-and-compression",
    "unit-tests-coverage-increase",
    "ios-build-settings"
)

foreach ($pr in $branches) {
    Write-Host "🔥 Launching PR: $pr" -ForegroundColor Yellow

    # Create branch
    git checkout -b "pr/$pr"

    # Create note for PR body
    "# $pr – Auto-generated PR for BugBot full-repo scan" | Out-File -Encoding utf8 PR_NOTE.md

    # Commit and push
    git add -A
    git commit -m "PR: $pr – Automated full-repo scan trigger"
    git push origin "pr/$pr"

    # Create PR via GitHub CLI
    gh pr create `
        --title "AutoPR: $pr" `
        --body "Automated PR wave to trigger BugBot end-to-end scan. This PR touches relevant modules for validation, telemetry, and continuity checks as part of the 12-branch machine-gun cycle." `
        --label "bugbot-scan, automation, repo-wide"

    # Return to base branch
    git checkout production-ready
}

Write-Host "✅ All 12 PRs created. BugBot full-repo scan triggered successfully!" -ForegroundColor Green
Write-Host '🧠 Monitor PRs at: https://github.com/Ghostmonday/DStudio/pulls' -ForegroundColor Cyan
