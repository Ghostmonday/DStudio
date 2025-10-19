# GitHub PR Automation Scripts

This directory contains scripts for **genuine GitHub integration** instead of simulation documentation.

## 🚀 **Quick Start**

### **1. Setup**
```powershell
# Install GitHub CLI
winget install GitHub.cli

# Authenticate
gh auth login

# Verify access
gh auth status
```

### **2. Create PR Automatically**
```powershell
.\scripts\github-pr-automation.ps1 -Action create -Title "Your PR Title" -Description "Your PR Description" -SourceBranch "your-branch" -TargetBranch "main"
```

## 📁 **Script Files**

### **`github-pr-automation.ps1`**
Main automation script with GitHub CLI integration:
- ✅ Create PRs automatically
- ✅ Check PR status
- ✅ List all PRs
- ✅ Merge PRs
- ✅ Update documentation automatically

### **`github-api-client.ps1`**
Direct GitHub API client:
- ✅ Direct API calls to GitHub
- ✅ Repository information
- ✅ PR data export
- ✅ Advanced API operations

## 🔄 **GitHub Actions Workflow**

### **`.github/workflows/pr-automation.yml`**
Automated workflow for:
- ✅ Manual PR creation via GitHub UI
- ✅ Automatic PR monitoring
- ✅ Auto-merge capabilities
- ✅ Status updates

## 📊 **Live Status Files**

### **`PR_LIVE_STATUS.md`**
Automatically updated with real-time GitHub data:
- Current PR information
- Repository status
- Recent activity
- Next steps

### **`PR_NOTE.md`**
Auto-generated notes for PR operations

## 🎯 **Usage Examples**

### **Create a PR**
```powershell
.\scripts\github-pr-automation.ps1 -Action create -Title "feat: Add new feature" -Description "Description of changes" -SourceBranch "feature-branch" -TargetBranch "main"
```

### **Check PR Status**
```powershell
.\scripts\github-pr-automation.ps1 -Action status -PRNumber "123"
```

### **List All PRs**
```powershell
.\scripts\github-pr-automation.ps1 -Action list
```

### **Merge PR**
```powershell
.\scripts\github-pr-automation.ps1 -Action merge -PRNumber "123"
```

### **Get Repository Info**
```powershell
.\scripts\github-api-client.ps1 -Endpoint "repo"
```

### **Export PR Data**
```powershell
.\scripts\github-api-client.ps1 -Endpoint "export" -outputFile "pr-data.json"
```

## 🔧 **Configuration**

### **Environment Variables**
- `GITHUB_TOKEN` - GitHub API token (optional, uses gh auth)

### **Repository Settings**
- Repository: `Ghostmonday/DStudio`
- Default branch: `main`

## 📋 **Requirements**

1. **PowerShell 7+**
2. **GitHub CLI** (`gh` command)
3. **Git repository access**
4. **GitHub authentication**

## 🚀 **Benefits**

- ✅ **Real GitHub connections** instead of simulation
- ✅ **Automated PR creation** and management
- ✅ **Live status monitoring**
- ✅ **GitHub Actions integration**
- ✅ **Direct API access**
- ✅ **Automatic documentation updates**

## 📚 **Documentation**

- `PR_CREATION_DETAILS.md` - Live PR creation guide
- `PR_DETAILS.md` - Comprehensive PR automation
- `PR_NOTE.md` - Auto-updated status file
- `PR_LIVE_STATUS.md` - Real-time GitHub data

---
*These scripts provide genuine GitHub integration for automated PR operations.*
