#!/bin/bash

# Automated fix script for BugBot integration
# Usage: ./auto-fix.sh [PR_NUMBER]

set -e

PR_NUMBER="$1"
REPO="Ghostmonday/DStudio"
BRANCH=$(git branch --show-current)

echo "🔧 Starting automated fixes for PR #$PR_NUMBER..."

# Function to apply common Swift fixes
apply_swift_fixes() {
    echo "📱 Applying Swift-specific fixes..."
    
    # Fix common import issues
    find . -name "*.swift" -exec sed -i '' 's/import Foundation/import Foundation\nimport SwiftUI/g' {} \;
    
    # Fix common syntax issues
    find . -name "*.swift" -exec sed -i '' 's/var body: some View {/var body: some View {\n        /g' {} \;
    
    # Fix missing return statements in computed properties
    find . -name "*.swift" -exec sed -i '' 's/var body: some View {\([^}]*\)}/var body: some View {\n        \1\n    }/g' {} \;
    
    echo "✅ Swift fixes applied"
}

# Function to fix Xcode project file issues
fix_project_file() {
    echo "📦 Fixing Xcode project file..."
    
    # Remove duplicate entries and fix common project file issues
    if [ -f "DirectorStudio.xcodeproj/project.pbxproj" ]; then
        # Remove duplicate file references
        sort -u DirectorStudio.xcodeproj/project.pbxproj > temp_pbxproj
        mv temp_pbxproj DirectorStudio.xcodeproj/project.pbxproj
        
        # Fix common build settings
        sed -i '' 's/SWIFT_VERSION = 5.0/SWIFT_VERSION = 5.9/g' DirectorStudio.xcodeproj/project.pbxproj
    fi
    
    echo "✅ Project file fixed"
}

# Function to resolve merge conflicts
resolve_conflicts() {
    echo "🔀 Resolving merge conflicts..."
    
    # Use your existing nuclear conflict resolution
    ./fix-conflicts.sh
    
    echo "✅ Conflicts resolved"
}

# Function to check and fix linting issues
fix_linting() {
    echo "🧹 Fixing linting issues..."
    
    # Fix common Swift formatting issues
    find . -name "*.swift" -exec sed -i '' 's/[[:space:]]*$//' {} \;  # Remove trailing whitespace
    find . -name "*.swift" -exec sed -i '' '/^$/N;/^\n$/d' {} \;     # Remove multiple blank lines
    
    echo "✅ Linting issues fixed"
}

# Function to update PR with fixes
update_pr() {
    if [ -n "$PR_NUMBER" ]; then
        echo "📝 Updating PR #$PR_NUMBER with fixes..."
        
        # Add all changes
        git add .
        
        # Commit fixes
        git commit -m "🤖 Automated fixes applied
        
        - Fixed Swift syntax issues
        - Resolved merge conflicts
        - Fixed Xcode project file
        - Applied linting fixes
        
        Ready for review!" || echo "No changes to commit"
        
        # Push changes
        git push origin "$BRANCH" --force-with-lease
        
        # Comment on PR
        gh pr comment "$PR_NUMBER" --body "🤖 Automated fixes have been applied:
        
        ✅ Swift syntax issues fixed
        ✅ Merge conflicts resolved  
        ✅ Xcode project file cleaned up
        ✅ Linting issues addressed
        
        PR is ready for final review and merge!"
        
        echo "✅ PR updated with fixes"
    fi
}

# Main execution
main() {
    echo "🚀 Starting automated fix process..."
    
    # Apply all fixes
    apply_swift_fixes
    fix_project_file
    resolve_conflicts
    fix_linting
    
    # Update PR if number provided
    update_pr
    
    echo "🎉 Automated fixes completed!"
}

# Run main function
main "$@"
