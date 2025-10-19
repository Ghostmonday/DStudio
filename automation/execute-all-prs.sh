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
