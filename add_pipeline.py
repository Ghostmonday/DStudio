#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('DirectorStudio.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs
pipeline_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
pipeline_build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add DirectorStudioPipeline.swift file reference
file_ref = f"""
		1A0000{pipeline_uuid[:6]} /* DirectorStudioPipeline.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DirectorStudioPipeline.swift; sourceTree = "<group>"; }};"""

# Add to Modules group children
modules_group_pattern = r'(1A000056 /\* Modules \*/ = \{\s*isa = PBXGroup;\s*children = \(\s*1A00007F /\* ContinuityEngine\.swift \*/,)'
modules_replacement = r'\1\n\t\t\t1A0000' + pipeline_uuid[:6] + ' /* DirectorStudioPipeline.swift */,'

# Add to build file
build_file = f"""
		1A0000{pipeline_build_uuid[:6]} /* DirectorStudioPipeline.swift in Sources */ = {{isa = PBXBuildFile; fileRef = 1A0000{pipeline_uuid[:6]} /* DirectorStudioPipeline.swift */; }};"""

# Apply changes
content = re.sub(modules_group_pattern, modules_replacement, content)

# Add file reference before the end of PBXFileReference section
file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
file_ref_replacement = file_ref + r'\n\n/* End PBXFileReference section */'
content = re.sub(file_ref_pattern, file_ref_replacement, content)

# Add to sources build phase
sources_pattern = r'(1A000019 /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = [^}]+;\};)'
sources_replacement = r'\1' + build_file
content = re.sub(sources_pattern, sources_replacement, content)

# Write back
with open('DirectorStudio.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Added DirectorStudioPipeline.swift to project")
