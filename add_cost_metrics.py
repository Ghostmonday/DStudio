#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('DirectorStudio.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs
cost_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
cost_build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add CostMetricsManager.swift file reference
file_ref = f"""
		1A0000{cost_uuid[:6]} /* CostMetricsManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CostMetricsManager.swift; sourceTree = "<group>"; }};"""

# Add to Services group children
services_group_pattern = r'(1A000055 /\* Services \*/ = \{\s*isa = PBXGroup;\s*children = \(\s*1A00007D /\* StoreManager\.swift \*/,)'
services_replacement = r'\1\n\t\t\t1A0000' + cost_uuid[:6] + ' /* CostMetricsManager.swift */,'

# Add to build file
build_file = f"""
		1A0000{cost_build_uuid[:6]} /* CostMetricsManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = 1A0000{cost_uuid[:6]} /* CostMetricsManager.swift */; }};"""

# Apply changes
content = re.sub(services_group_pattern, services_replacement, content)

# Add file reference before the end of PBXFileReference section
file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
file_ref_replacement = file_ref + r'\n\n/* End PBXFileReference section */'
content = re.sub(file_ref_pattern, file_ref_replacement, content)

# Add to sources build phase
sources_pattern = r'(1A000064 /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*1A000003 /\* ContentView\.swift in Sources \*/,)'
sources_replacement = r'\1\n\t\t\t1A0000' + cost_build_uuid[:6] + ' /* CostMetricsManager.swift in Sources */,'
content = re.sub(sources_pattern, sources_replacement, content)

# Add build file reference before the end of PBXBuildFile section
build_file_pattern = r'(/\* End PBXBuildFile section \*/)'
build_file_replacement = build_file + r'\n\n/* End PBXBuildFile section */'
content = re.sub(build_file_pattern, build_file_replacement, content)

# Write back
with open('DirectorStudio.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Added CostMetricsManager.swift to project")
