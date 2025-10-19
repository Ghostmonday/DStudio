#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('DirectorStudio.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Files to add to build phase
files_to_add = [
    ('Models.swift', '1A00002835AC'),
    ('DirectorStudioPipeline.swift', '1A0000283F20'),
    ('StoryAnalyzerModule.swift', '1A0000E67026'),
    ('PromptSegmentationModule.swift', '1A0000C6ABE6'),
    ('PromptPackagingModule.swift', '1A0000760A32')
]

# Add each file to the build phase
for file_name, file_ref_id in files_to_add:
    # Generate build UUID
    build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    # Add build file reference
    build_file = f"""
		1A0000{build_uuid[:6]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};"""
    
    # Add to sources build phase
    sources_pattern = r'(1A000064 /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*1A000003 /\* ContentView\.swift in Sources \*/,)'
    sources_replacement = r'\1\n\t\t\t1A0000' + build_uuid[:6] + f' /* {file_name} in Sources */,'
    
    # Apply changes
    content = re.sub(sources_pattern, sources_replacement, content)
    
    # Add build file reference before the end of PBXBuildFile section
    build_file_pattern = r'(/\* End PBXBuildFile section \*/)'
    build_file_replacement = build_file + r'\n\n/* End PBXBuildFile section */'
    content = re.sub(build_file_pattern, build_file_replacement, content)

# Write back
with open('DirectorStudio.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Added all files to build phase")
