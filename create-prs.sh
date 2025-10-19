#!/bin/bash

BRANCH="fix/20251018-212413"
BASE="main"
LABEL="automated"

declare -a TITLES=(
  "Core App Components Review"
  "UI Components & Views Review"
  "Pipeline & Processing Modules Review"
  "Services & Backend Review"
  "Data & Persistence Review"
  "Configuration & Setup Review"
  "Documentation & Guides Review"
  "Comprehensive Full-Stack Review"
)

declare -a BODIES=(
  "BugBot scan of main app entry point, content view, app state, and core data models"
  "BugBot scan of all UI components, views, sheets, and user interface elements"
  "BugBot scan of all pipeline modules, processing logic, and continuity engine"
  "BugBot scan of all services, backend integration, and database connections"
  "BugBot scan of data models, persistence layer, and synchronization logic"
  "BugBot scan of project configuration, assets, and setup files"
  "BugBot scan of all documentation, guides, and developer resources"
  "BugBot complete repository scan - all components, services, UI, and configuration"
)

for i in "${!TITLES[@]}"; do
  echo "Creating PR $((i+1)): ${TITLES[$i]}"
  gh pr create \
    --base "$BASE" \
    --head "$BRANCH" \
    --title "${TITLES[$i]}" \
    --body "${BODIES[$i]}" \
    --label "$LABEL"
done
