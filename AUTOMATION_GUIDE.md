# 🤖 Automated PR Workflow Guide

This guide explains how to use the automated pull request and merge workflow that integrates with BugBot for seamless development.

## 🚀 Quick Start

### 1. Setup (One-time)
```bash
# Make sure you have GitHub CLI installed and authenticated
gh auth login

# Setup the automation workflow
./automation/workflow-manager.sh setup
```

### 2. Create a PR with Full Automation
```bash
# Simple PR creation
./automation/workflow-manager.sh create "Fix Swift syntax errors"

# PR with auto-fix and auto-merge
./automation/workflow-manager.sh create "Update UI components" "Improved user experience" --auto-fix --auto-merge
```

### 3. Monitor and Manage PRs
```bash
# Check status of a specific PR
./automation/workflow-manager.sh status 123

# Monitor all open PRs
./automation/workflow-manager.sh monitor

# Apply fixes to existing PR
./automation/workflow-manager.sh fix 123

# Merge PR after approval
./automation/workflow-manager.sh merge 123
```

## 📋 Available Commands

### Workflow Manager (Recommended)
```bash
./automation/workflow-manager.sh [command] [options]
```

**Commands:**
- `create <title> [description]` - Create new PR with automation
- `fix <pr_number>` - Apply automated fixes to existing PR
- `merge <pr_number>` - Merge PR after automated checks
- `status <pr_number>` - Check PR status and workflow progress
- `monitor` - Monitor all open PRs
- `cleanup` - Clean up merged branches and old PRs
- `setup` - Initial setup and configuration
- `test` - Test the automation workflow

**Options:**
- `--auto-fix` - Enable automated fixes
- `--auto-merge` - Enable automated merging
- `--force` - Force operation (skip confirmations)

### Individual Scripts

#### Smart PR Creation
```bash
./automation/smart-pr.sh "PR Title" "Description" [--auto-fix] [--auto-merge]
```

#### Automated Fixes
```bash
./automation/auto-fix.sh [PR_NUMBER]
```

#### Automated Merge
```bash
./automation/auto-merge.sh [PR_NUMBER]
```

#### Legacy Scripts (Still Available)
```bash
./create-pr.sh "PR Title" "Description"
./quick-pr.sh "PR Title"
./fix-conflicts.sh
```

## 🔄 How the Automation Works

### 1. PR Creation
- Creates a feature branch with timestamp
- Resolves merge conflicts automatically
- Pushes to GitHub and creates PR
- Tags PR for BugBot review
- Optionally enables auto-fix and auto-merge

### 2. Automated Review
- GitHub Actions workflow triggers on PR creation
- Builds and tests the project
- Runs automated fixes if needed
- Integrates with @GhostMonday bugbot

### 3. Automated Fixes
- Fixes common Swift syntax issues
- Resolves merge conflicts
- Cleans up Xcode project files
- Applies linting fixes
- Updates PR with fixes

### 4. Automated Merge
- Checks PR readiness (approvals, status checks)
- Verifies no critical file conflicts
- Performs safe merge with rollback capability
- Runs post-merge tests
- Cleans up merged branches

## 🛡️ Safety Features

### Protection Against Breaking Changes
- Main branch protection checks
- Critical file modification warnings
- Post-merge build verification
- Automatic rollback on failure

### Approval Requirements
- BugBot approval required for auto-merge
- Status check validation
- Conflict resolution verification

### Monitoring and Notifications
- Real-time PR status monitoring
- Automated notifications and comments
- Workflow progress tracking

## 🎯 Best Practices

### For Quick Fixes
```bash
# Use auto-fix for syntax and formatting issues
./automation/workflow-manager.sh create "Fix Swift errors" --auto-fix
```

### For Feature Development
```bash
# Use full automation for well-tested features
./automation/workflow-manager.sh create "Add new feature" "Description" --auto-fix --auto-merge
```

### For Critical Changes
```bash
# Create PR without auto-merge for manual review
./automation/workflow-manager.sh create "Update core functionality" "Important changes"
```

## 🔧 Troubleshooting

### Common Issues

**Script Permission Errors:**
```bash
chmod +x automation/*.sh
```

**GitHub CLI Not Authenticated:**
```bash
gh auth login
```

**Conflicts Not Resolving:**
```bash
./fix-conflicts.sh
./automation/auto-fix.sh
```

**Build Failures:**
```bash
# Check Xcode project file
./automation/auto-fix.sh
# Rebuild project
xcodebuild -scheme DirectorStudio clean build
```

### Getting Help

1. **Check PR Status:**
   ```bash
   ./automation/workflow-manager.sh status [PR_NUMBER]
   ```

2. **Monitor All PRs:**
   ```bash
   ./automation/workflow-manager.sh monitor
   ```

3. **Test Workflow:**
   ```bash
   ./automation/workflow-manager.sh test
   ```

## 🚀 Advanced Usage

### Custom Automation Scripts
You can extend the automation by adding custom scripts to the `automation/` directory:

```bash
# Create custom fix script
cat > automation/custom-fix.sh << 'EOF'
#!/bin/bash
# Your custom fixes here
echo "Applying custom fixes..."
EOF

chmod +x automation/custom-fix.sh
```

### Integration with CI/CD
The GitHub Actions workflow (`.github/workflows/automated-pr-workflow.yml`) automatically:
- Triggers on PR creation
- Runs builds and tests
- Applies automated fixes
- Manages the merge process

### Monitoring and Alerts
Set up monitoring for:
- Failed builds
- Merge conflicts
- BugBot review status
- Workflow completion

## 📊 Workflow Status Dashboard

Use the monitor command to see the status of all your PRs:

```bash
./automation/workflow-manager.sh monitor
```

This will show:
- ✅ PRs ready for merge
- ⏳ PRs waiting for review/approval
- 🔧 PRs with issues being fixed
- 📊 Overall workflow health

---

## 🎉 Success!

You now have a fully automated PR workflow that:
- ✅ Creates PRs automatically
- ✅ Integrates with BugBot for reviews
- ✅ Applies fixes automatically
- ✅ Merges safely after approval
- ✅ Prevents breaking changes
- ✅ Provides comprehensive monitoring

**No more mind-numbing manual PR management!** 🚀
