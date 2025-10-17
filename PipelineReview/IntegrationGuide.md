# Pipeline Integration Guide

## Quick Integration Checklist

### 1. File Replacement
```bash
# Replace these files in your DirectorStudio project:
cp PipelineRefactor/Modules/* DirectorStudio/Modules/
cp PipelineRefactor/CreateView.swift DirectorStudio/Views/
cp PipelineRefactor/IndividualStepView.swift DirectorStudio/Components/
cp PipelineRefactor/Services/* DirectorStudio/Services/
cp PipelineRefactor/Core/* DirectorStudio/Core/
```

### 2. Required Interface Compliance

The new pipeline implementation MUST maintain these interfaces:

#### DirectorStudioPipeline Class
```swift
@MainActor
class DirectorStudioPipeline: ObservableObject {
    // REQUIRED: These properties must exist
    @Published var currentStep: Int = 0
    @Published var isRunning: Bool = false
    @Published var completedSteps: Set<Int> = []
    @Published var errorMessage: String?
    
    // REQUIRED: These module references must exist
    let rewordingModule: RewordingModule
    let storyAnalyzer: StoryAnalyzerModule
    let segmentationModule: PromptSegmentationModule
    let taxonomyModule: CinematicTaxonomyModule
    let continuityModule: ContinuityAnchorModule
    let packagingModule: PromptPackagingModule
    
    // REQUIRED: This method signature must be maintained
    func runFullPipeline(
        story: String,
        rewordType: RewordingType?,
        projectTitle: String,
        enableTransform: Bool,
        enableCinematic: Bool,
        enableBreakdown: Bool
    ) async
}
```

#### Data Models (DO NOT CHANGE)
```swift
// These models must remain exactly the same:
struct PromptSegment: Identifiable, Codable { ... }
struct CinematicTaxonomy: Codable { ... }
struct ContinuityAnchor: Codable, Identifiable { ... }
struct StoryAnalysis: Codable { ... }
```

### 3. UI Integration Points

#### CreateView.swift
- Individual step toggles must work
- Step status must be displayed
- Progress indication must be accurate
- Button states must be correct

#### StudioView.swift
- Generated segments must be accessible via `pipeline.segmentationModule.segments`
- Video generation must work with segments
- Project data must be properly saved

### 4. Critical Integration Points

#### AppState Integration
```swift
// Project creation must work with this structure:
let newProject = Project(
    id: UUID(),
    title: projectTitle,
    originalStory: storyInput,
    rewordedStory: pipeline.rewordingModule.result,
    analysis: StoryAnalysisCache(...),
    segments: pipeline.segmentationModule.segments,
    continuityAnchors: pipeline.continuityModule.anchors.map { ... },
    createdAt: Date(),
    updatedAt: Date()
)
```

#### Video Generation Integration
```swift
// StudioView expects segments to be available:
let segments = pipeline.segmentationModule.segments
// Each segment should have:
// - id: UUID
// - content: String (the prompt)
// - duration: Int
// - order: Int
```

### 5. Error Handling Requirements

The new pipeline must handle these error scenarios gracefully:

1. **API Failures**: Individual step failures should not crash the pipeline
2. **Network Issues**: Proper timeout and retry handling
3. **Invalid Input**: Validation and user-friendly error messages
4. **Partial Failures**: Allow pipeline to continue with available steps

### 6. Performance Considerations

- **Async/Await**: All API calls must be properly async
- **Memory Management**: Large story inputs should be handled efficiently
- **Progress Updates**: UI should update in real-time during processing
- **Cancellation**: Pipeline should be cancellable

### 7. Testing Integration

Before deployment, test these scenarios:

1. **All Steps Enabled**: Full pipeline execution
2. **Some Steps Disabled**: Partial pipeline execution
3. **API Failures**: Error handling and recovery
4. **Large Inputs**: Performance with long stories
5. **Network Issues**: Offline/online behavior
6. **UI States**: Button states, progress indicators
7. **Data Persistence**: Project saving/loading

### 8. Configuration Requirements

#### API Keys
- DeepSeek API key must be properly configured
- Error handling for missing/invalid keys
- Secure key storage

#### Dependencies
- All existing dependencies must be maintained
- No breaking changes to external libraries
- SwiftUI compatibility maintained

### 9. Rollback Plan

If integration fails:

1. **Keep Original Files**: Backup existing pipeline files
2. **Gradual Rollout**: Test with subset of users first
3. **Feature Flags**: Consider feature flags for new pipeline
4. **Monitoring**: Track error rates and performance

### 10. Success Criteria

The new pipeline is successfully integrated when:

- ✅ All existing functionality works
- ✅ Individual step toggles function correctly
- ✅ Video generation works with new segments
- ✅ Projects save/load correctly
- ✅ Error handling is robust
- ✅ Performance is acceptable
- ✅ UI is responsive and intuitive

## Common Integration Issues

### Issue 1: Module References Missing
**Problem**: `pipeline.segmentationModule.segments` returns empty
**Solution**: Ensure module references are properly initialized and accessible

### Issue 2: UI Not Updating
**Problem**: Progress indicators don't update
**Solution**: Ensure all state changes happen on MainActor

### Issue 3: Data Model Mismatch
**Problem**: Project saving fails
**Solution**: Verify all data models match exactly

### Issue 4: API Integration Fails
**Problem**: DeepSeek API calls fail
**Solution**: Check API key configuration and network handling

## Support

If you encounter integration issues:

1. Check this guide first
2. Verify interface compliance
3. Test individual components
4. Check error logs
5. Ensure all dependencies are met

The pipeline is the core of DirectorStudio - take time to ensure proper integration!
