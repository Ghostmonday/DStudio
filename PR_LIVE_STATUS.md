# Live PR Status - GitHub Integration

## 🤖 **GitHub PR Automation System**

**Repository:** Ghostmonday/DStudio  
**Status:** ✅ ACTIVE  
**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")  

## 🔄 **Available Operations**

### **Create PR**
```powershell
.\scripts\github-pr-automation.ps1 -Action create -Title "Your PR Title" -Description "Your PR Description" -SourceBranch "your-branch" -TargetBranch "main"
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

## 📊 **Live GitHub Data**

*This section will be automatically populated when you run the automation scripts.*

## 🎯 **Quick Start**

1. **Authenticate with GitHub:**
   ```powershell
   gh auth login
   ```

2. **Create your first PR:**
   ```powershell
   .\scripts\github-pr-automation.ps1 -Action create -Title "feat: Add new feature" -Description "Description of changes" -SourceBranch "feature-branch" -TargetBranch "main"
   ```

3. **Monitor status:**
   The scripts will automatically update this file with real-time GitHub data.

## 🔧 **System Information**

- **GitHub CLI:** Required (`winget install GitHub.cli`)
- **Authentication:** `gh auth login`
- **Repository Access:** Ghostmonday/DStudio
- **Automation:** Live GitHub API integration

---
*This file is automatically updated by the GitHub PR automation system with live data from the GitHub API.*
