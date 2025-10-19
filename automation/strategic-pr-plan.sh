#!/bin/bash

# Strategic PR Plan for BugBot Scanning
# Breaks down the repository into logical components for comprehensive review

set -e

echo "🎯 Strategic PR Plan for BugBot Scanning"
echo "========================================"
echo ""

# Function to create PR for Core App Components
create_core_app_pr() {
    echo "📱 PR 1: Core App Components"
    echo "---------------------------"
    echo "Files to include:"
    echo "- DirectorStudioApp.swift (main app entry point)"
    echo "- ContentView.swift (main UI)"
    echo "- Core/AppState.swift (app state management)"
    echo "- Core/Models.swift (data models)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Core App Components Review' 'BugBot scan of main app entry point, content view, app state, and core data models'"
    echo ""
}

# Function to create PR for UI Components
create_ui_components_pr() {
    echo "🎨 PR 2: UI Components & Views"
    echo "-----------------------------"
    echo "Files to include:"
    echo "- Components/ (all UI components)"
    echo "- Views/ (all main views)"
    echo "- Sheets/ (modal sheets)"
    echo "- UI/ (UI integration files)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'UI Components & Views Review' 'BugBot scan of all UI components, views, sheets, and user interface elements'"
    echo ""
}

# Function to create PR for Pipeline Modules
create_pipeline_modules_pr() {
    echo "⚙️  PR 3: Pipeline & Processing Modules"
    echo "--------------------------------------"
    echo "Files to include:"
    echo "- Modules/ (all processing modules)"
    echo "- Pipeline/ (pipeline configuration)"
    echo "- ContinuityEngineAnalysis/ (continuity logic)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Pipeline & Processing Modules Review' 'BugBot scan of all pipeline modules, processing logic, and continuity engine'"
    echo ""
}

# Function to create PR for Services & Backend
create_services_pr() {
    echo "🔧 PR 4: Services & Backend Integration"
    echo "--------------------------------------"
    echo "Files to include:"
    echo "- Services/ (all service classes)"
    echo "- backend/ (backend configuration)"
    echo "- Supabase/ (database integration)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Services & Backend Review' 'BugBot scan of all services, backend integration, and database connections'"
    echo ""
}

# Function to create PR for Data & Persistence
create_data_persistence_pr() {
    echo "💾 PR 5: Data & Persistence Layer"
    echo "--------------------------------"
    echo "Files to include:"
    echo "- Persistence/ (Core Data)"
    echo "- Storage/ (local storage)"
    echo "- Sync/ (data synchronization)"
    echo "- DirectorStudio.xcdatamodeld/ (data model)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Data & Persistence Review' 'BugBot scan of data models, persistence layer, and synchronization logic'"
    echo ""
}

# Function to create PR for Configuration & Setup
create_config_pr() {
    echo "⚙️  PR 6: Configuration & Project Setup"
    echo "--------------------------------------"
    echo "Files to include:"
    echo "- Info.plist (app configuration)"
    echo "- Assets.xcassets/ (app assets)"
    echo "- DirectorStudio.xcodeproj/ (project configuration)"
    echo "- Resources/ (app resources)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Configuration & Setup Review' 'BugBot scan of project configuration, assets, and setup files'"
    echo ""
}

# Function to create PR for Documentation & Guides
create_docs_pr() {
    echo "📚 PR 7: Documentation & Developer Guides"
    echo "----------------------------------------"
    echo "Files to include:"
    echo "- DEVELOPER_SETUP.md"
    echo "- Guides/ (developer guides)"
    echo "- README.md"
    echo "- AUTOMATION_GUIDE.md"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Documentation & Guides Review' 'BugBot scan of all documentation, guides, and developer resources'"
    echo ""
}

# Function to create comprehensive PR
create_comprehensive_pr() {
    echo "🌐 PR 8: Comprehensive Full-Stack Review"
    echo "---------------------------------------"
    echo "Files to include:"
    echo "- ALL FILES (complete repository scan)"
    echo ""
    echo "Command:"
    echo "./automation/local-to-pr.sh 'Comprehensive Full-Stack Review' 'BugBot complete repository scan - all components, services, UI, and configuration'"
    echo ""
}

# Function to show execution plan
show_execution_plan() {
    echo "🚀 Execution Plan"
    echo "================="
    echo ""
    echo "Recommended approach:"
    echo "1. Start with Core App Components (PR 1) - most critical"
    echo "2. Review UI Components (PR 2) - user-facing elements"
    echo "3. Check Pipeline Modules (PR 3) - processing logic"
    echo "4. Verify Services (PR 4) - backend integration"
    echo "5. Validate Data Layer (PR 5) - persistence"
    echo "6. Review Configuration (PR 6) - project setup"
    echo "7. Check Documentation (PR 7) - guides and docs"
    echo "8. Final comprehensive review (PR 8) - everything"
    echo ""
    echo "⏱️  Estimated time: 2-3 hours for all PRs"
    echo "🤖 BugBot will review each PR automatically"
    echo "🔧 Auto-fixes will be applied as needed"
    echo ""
}

# Function to create batch execution script
create_batch_script() {
    cat > automation/execute-all-prs.sh << 'EOF'
#!/bin/bash

# Batch execution of all strategic PRs
echo "🚀 Executing Strategic PR Plan"
echo "=============================="

# PR 1: Core App Components
echo "📱 Creating PR 1: Core App Components..."
./automation/local-to-pr.sh "Core App Components Review" "BugBot scan of main app entry point, content view, app state, and core data models"

# Wait for user to create PR before continuing
echo "⏳ Please create the PR for Core App Components, then press Enter to continue..."
read

# PR 2: UI Components
echo "🎨 Creating PR 2: UI Components & Views..."
./automation/local-to-pr.sh "UI Components & Views Review" "BugBot scan of all UI components, views, sheets, and user interface elements"

echo "⏳ Please create the PR for UI Components, then press Enter to continue..."
read

# PR 3: Pipeline Modules
echo "⚙️ Creating PR 3: Pipeline & Processing Modules..."
./automation/local-to-pr.sh "Pipeline & Processing Modules Review" "BugBot scan of all pipeline modules, processing logic, and continuity engine"

echo "⏳ Please create the PR for Pipeline Modules, then press Enter to continue..."
read

# PR 4: Services
echo "🔧 Creating PR 4: Services & Backend Integration..."
./automation/local-to-pr.sh "Services & Backend Review" "BugBot scan of all services, backend integration, and database connections"

echo "⏳ Please create the PR for Services, then press Enter to continue..."
read

# PR 5: Data & Persistence
echo "💾 Creating PR 5: Data & Persistence Layer..."
./automation/local-to-pr.sh "Data & Persistence Review" "BugBot scan of data models, persistence layer, and synchronization logic"

echo "⏳ Please create the PR for Data & Persistence, then press Enter to continue..."
read

# PR 6: Configuration
echo "⚙️ Creating PR 6: Configuration & Project Setup..."
./automation/local-to-pr.sh "Configuration & Setup Review" "BugBot scan of project configuration, assets, and setup files"

echo "⏳ Please create the PR for Configuration, then press Enter to continue..."
read

# PR 7: Documentation
echo "📚 Creating PR 7: Documentation & Developer Guides..."
./automation/local-to-pr.sh "Documentation & Guides Review" "BugBot scan of all documentation, guides, and developer resources"

echo "⏳ Please create the PR for Documentation, then press Enter to continue..."
read

# PR 8: Comprehensive
echo "🌐 Creating PR 8: Comprehensive Full-Stack Review..."
./automation/local-to-pr.sh "Comprehensive Full-Stack Review" "BugBot complete repository scan - all components, services, UI, and configuration"

echo "🎉 All strategic PRs created!"
echo "============================="
echo "BugBot will now review all PRs systematically."
echo "Check GitHub for review progress and automated fixes."
EOF

    chmod +x automation/execute-all-prs.sh
    echo "✅ Batch execution script created: automation/execute-all-prs.sh"
}

# Main execution
main() {
    echo "🎯 DirectorStudio Strategic PR Plan"
    echo "==================================="
    echo ""
    echo "This plan breaks down your repository into 8 logical PRs for comprehensive BugBot scanning:"
    echo ""
    
    create_core_app_pr
    create_ui_components_pr
    create_pipeline_modules_pr
    create_services_pr
    create_data_persistence_pr
    create_config_pr
    create_docs_pr
    create_comprehensive_pr
    
    show_execution_plan
    
    echo "🛠️  Quick Start Options:"
    echo "========================"
    echo ""
    echo "Option 1: Execute all PRs automatically"
    echo "./automation/execute-all-prs.sh"
    echo ""
    echo "Option 2: Create PRs one by one manually"
    echo "Copy and paste the commands above"
    echo ""
    echo "Option 3: Start with most critical (Core App)"
    echo "./automation/local-to-pr.sh 'Core App Components Review' 'BugBot scan of main app entry point, content view, app state, and core data models'"
    echo ""
    
    # Create batch script
    create_batch_script
    
    echo "🎉 Strategic PR plan ready!"
    echo "Choose your approach and start with the commands above."
}

# Run main function
main "$@"
