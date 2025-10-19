#!/usr/bin/env python3

import re

# Read the project file
with open('DirectorStudio.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Files to add
files_to_add = [
    'DirectorStudio/Core/Models.swift',
    'DirectorStudio/Modules/StoryAnalyzerModule.swift',
    'DirectorStudio/Modules/PromptSegmentationModule.swift',
    'DirectorStudio/Modules/PromptPackagingModule.swift'
]

# Generate UUIDs for the new files
import uuid

# Find the Core group and Modules group in the project
core_group_pattern = r'(1A000052 /\* Core \*/ = \{[^}]+children = \([^)]+)([^)]+)\);'
modules_group_pattern = r'(1A000053 /\* Modules \*/ = \{[^}]+children = \([^)]+)([^)]+)\);'

# Add Models.swift to Core group
models_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
models_build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add the file reference
file_ref_section = f"""
		1A0000{models_uuid[:6]} /* Models.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Models.swift; sourceTree = "<group>"; }};"""

# Add to Core group
core_replacement = r'\1\2		1A0000' + models_uuid[:6] + ' /* Models.swift */,\n		);'

# Add to build phase
build_phase_section = f"""
		1A0000{models_build_uuid[:6]} /* Models.swift in Sources */ = {{isa = PBXBuildFile; fileRef = 1A0000{models_uuid[:6]} /* Models.swift */; }};"""

# Add to sources build phase
sources_replacement = r'\1\2		1A0000' + models_build_uuid[:6] + ' /* Models.swift in Sources */,\n		);'

# Apply the changes
content = re.sub(core_group_pattern, core_replacement, content)
content = re.sub(r'(1A000019 /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = [^}]+;\};)', r'\1' + build_phase_section, content)
content = re.sub(r'(1A000019 /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = [^}]+;\};)', r'\1' + file_ref_section, content)

# Add module files to Modules group
for i, file_path in enumerate(files_to_add[1:], 1):  # Skip Models.swift
    file_name = file_path.split('/')[-1]
    module_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
    module_build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    # Add file reference
    file_ref_section = f"""
		1A0000{module_uuid[:6]} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};"""
    
    # Add to Modules group
    modules_replacement = r'\1\2		1A0000' + module_uuid[:6] + f' /* {file_name} */,\n		);'
    
    # Add to build phase
    build_phase_section = f"""
		1A0000{module_build_uuid[:6]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = 1A0000{module_uuid[:6]} /* {file_name} */; }};"""
    
    # Apply changes
    content = re.sub(modules_group_pattern, modules_replacement, content)
    content = re.sub(r'(1A000019 /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = [^}]+;\};)', r'\1' + build_phase_section, content)
    content = re.sub(r'(1A000019 /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = [^}]+;\};)', r'\1' + file_ref_section, content)

# Write the updated content back
with open('DirectorStudio.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Added new files to project.pbxproj")
