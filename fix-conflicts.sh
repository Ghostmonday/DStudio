#!/bin/bash

# Nuclear conflict resolution - use when you just want to move fast
echo "🚀 Nuclear conflict resolution..."

# Remove all conflict markers from all files
find . -name "*.swift" -exec sed -i '' '/<<<<<<< HEAD/,/>>>>>>> origin\/main/d' {} \;
find . -name "*.swift" -exec sed -i '' '/<<<<<<< HEAD/,/=======/d' {} \;
find . -name "*.swift" -exec sed -i '' '/=======/,/>>>>>>> origin\/main/d' {} \;
find . -name "*.swift" -exec sed -i '' '/=======/,/>>>>>>> /d' {} \;

# Fix project file
sed -i '' '/<<<<<<< HEAD/,/>>>>>>> origin\/main/d' DirectorStudio.xcodeproj/project.pbxproj

echo "✅ All conflicts resolved (nuclear option)"
echo "⚠️  You may need to fix structural issues in files"
