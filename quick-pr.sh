#!/bin/bash

# One-command PR creation with auto-conflict resolution
# Usage: ./quick-pr.sh "Fix CreateView structural issues"

TITLE="$1"
if [ -z "$TITLE" ]; then
    echo "Usage: ./quick-pr.sh 'PR Title'"
    exit 1
fi

echo "🚀 Creating PR: $TITLE"

# Step 1: Nuclear conflict resolution
./fix-conflicts.sh

# Step 2: Create PR
./create-pr.sh "$TITLE" "Auto-generated PR for BugBot review"

echo "✅ PR created and ready for BugBot!"
