# DirectorStudio Pipeline Refactor Package

## Overview

This package contains all the files related to the DirectorStudio AI pipeline system. The pipeline processes user stories through 6 distinct steps, each with individual API calls and full transparency. This refactor package allows for complete pipeline reconstruction while maintaining integration compatibility.

## Current Pipeline Architecture

### Pipeline Steps (Sequential Processing)

1. **Rewording** (`RewordingModule.swift`)
   - **Purpose**: Transform writing style (modernize, refine grammar, restyle narrative)
   - **API**: DeepSeek API with custom system prompts
   - **Input**: Raw story text
   - **Output**: Enhanced/transformed story text
   - **Optional**: Yes (can be disabled)

2. **Story Analysis** (`StoryAnalyzerModule.swift`)
   - **Purpose**: Extract characters, locations, scenes, dialogue blocks
   - **API**: DeepSeek API with JSON extraction
   - **Input**: Story text (original or reworded)
   - **Output**: Structured analysis (characters, locations, scenes, dialogue)
   - **Optional**: No (currently mandatory - needs to be made optional)

3. **Prompt Segmentation** (`PromptSegmentationModule.swift`)
   - **Purpose**: Break story into 15-second video-ready segments
   - **API**: DeepSeek API with segmentation logic
   - **Input**: Story text
   - **Output**: Array of PromptSegment objects
   - **Optional**: Yes (can be disabled)

4. **Cinematic Taxonomy** (`CinematicTaxonomyModule.swift`)
   - **Purpose**: Add camera angles, lighting, shot types to segments
   - **API**: DeepSeek API with cinematic analysis
   - **Input**: Individual scene segments
   - **Output**: CinematicTaxonomy objects with visual details
   - **Optional**: Yes (can be disabled)

5. **Continuity Anchors** (`ContinuityAnchorModule.swift`)
   - **Purpose**: Generate visual continuity markers for character consistency
   - **API**: DeepSeek API with continuity analysis
   - **Input**: Story text
   - **Output**: Array of ContinuityAnchor objects
   - **Optional**: No (currently mandatory - needs to be made optional)

6. **Final Packaging** (`PromptPackagingModule.swift`)
   - **Purpose**: Package everything into final exportable format
   - **API**: Local processing (no external API)
   - **Input**: All previous step outputs
   - **Output**: Final packaged screenplay/prompts
   - **Optional**: No (final step)

## File Structure

```
PipelineRefactor/
├── README.md                           # This documentation
├── CreateView.swift                    # Main UI with individual step toggles
├── IndividualStepView.swift            # UI component for step controls
├── PipelineProgressSheet.swift         # Progress display sheet
├── Modules/                            # All pipeline modules
│   ├── DirectorStudioPipeline.swift    # Main pipeline coordinator
│   ├── RewordingModule.swift           # Step 1: Text transformation
│   ├── StoryAnalyzerModule.swift       # Step 2: Story analysis
│   ├── PromptSegmentationModule.swift  # Step 3: Segment creation
│   ├── CinematicTaxonomyModule.swift   # Step 4: Cinematic analysis
│   ├── ContinuityAnchorModule.swift    # Step 5: Continuity generation
│   └── PromptPackagingModule.swift     # Step 6: Final packaging
├── Services/                           # API services
│   ├── AIServiceProtocol.swift         # Service interface
│   ├── DeepSeekService.swift           # DeepSeek API implementation
│   └── AIModuleError.swift             # Error handling
└── Core/                               # Data models
    ├── CinematicTags.swift             # Cinematic taxonomy models
    ├── PromptSegment.swift             # Segment data model
    └── Project.swift                   # Project and analysis models
```

## Current Issues & Required Refactoring

### 1. **Story Analysis is Mandatory** ❌
- **Problem**: Step 2 (Story Analysis) cannot be disabled
- **Impact**: Blocks pipeline execution when AI processing is turned off
- **Solution**: Make it optional with proper fallback handling

### 2. **Continuity Anchors are Mandatory** ❌
- **Problem**: Step 5 (Continuity Anchors) cannot be disabled
- **Impact**: Blocks pipeline execution when disabled
- **Solution**: Make it optional with proper fallback handling

### 3. **No Individual Step Execution** ❌
- **Problem**: Steps cannot be run independently
- **Impact**: No granular control over pipeline execution
- **Solution**: Implement individual step execution with proper state management

### 4. **Limited Error Handling** ⚠️
- **Problem**: Errors in one step can break entire pipeline
- **Impact**: Poor user experience and debugging difficulty
- **Solution**: Implement robust error handling with step-by-step recovery

### 5. **No Step Result Visibility** ❌
- **Problem**: Users can't see individual step outputs
- **Impact**: Black box experience, no transparency
- **Solution**: Display step results in UI with expandable details

## Integration Requirements

### For New Pipeline Implementation

1. **Maintain Interface Compatibility**
   ```swift
   // Required interface for DirectorStudioPipeline
   class DirectorStudioPipeline: ObservableObject {
       @Published var currentStep: Int
       @Published var isRunning: Bool
       @Published var completedSteps: Set<Int>
       @Published var errorMessage: String?
       
       // Module references (must be maintained)
       let rewordingModule: RewordingModule
       let storyAnalyzer: StoryAnalyzerModule
       let segmentationModule: PromptSegmentationModule
       let taxonomyModule: CinematicTaxonomyModule
       let continuityModule: ContinuityAnchorModule
       let packagingModule: PromptPackagingModule
   }
   ```

2. **Required Methods**
   ```swift
   func runFullPipeline(
       story: String,
       rewordType: RewordingType?,
       projectTitle: String,
       enableTransform: Bool,
       enableCinematic: Bool,
       enableBreakdown: Bool
   ) async
   ```

3. **Data Model Compatibility**
   - `PromptSegment` model must remain unchanged
   - `CinematicTaxonomy` model must remain unchanged
   - `ContinuityAnchor` model must remain unchanged
   - `StoryAnalysis` model must remain unchanged

### For UI Integration

1. **CreateView Integration**
   - Individual step toggles must work
   - Step status display must be functional
   - Progress indication must be accurate

2. **StudioView Integration**
   - Generated segments must be accessible
   - Video generation must work with segments
   - Project saving must function correctly

## Recommended Refactor Approach

### Phase 1: Make All Steps Optional
```swift
// Each step should have this pattern:
if isStepEnabled {
    await executeStep()
    if stepFailed {
        await handleStepFailure()
        // Continue to next step or abort based on configuration
    }
} else {
    await skipStep()
}
```

### Phase 2: Individual Step Execution
```swift
// Allow running individual steps
func runStep(_ stepNumber: Int, input: Any) async throws -> Any {
    switch stepNumber {
    case 1: return try await runRewording(input)
    case 2: return try await runStoryAnalysis(input)
    // ... etc
    }
}
```

### Phase 3: Enhanced Error Handling
```swift
// Robust error handling with recovery
enum PipelineError: Error {
    case stepFailed(step: Int, error: Error)
    case dependencyMissing(step: Int, dependency: String)
    case apiError(step: Int, message: String)
}
```

### Phase 4: Result Visibility
```swift
// Display step results
struct StepResult {
    let stepNumber: Int
    let title: String
    let status: StepStatus
    let output: Any
    let error: Error?
    let executionTime: TimeInterval
}
```

## API Integration Points

### DeepSeek API Usage
- **Service**: `DeepSeekService.swift`
- **Protocol**: `AIServiceProtocol.swift`
- **Error Handling**: `AIModuleError.swift`
- **Configuration**: `SecretsManager.swift` (API key management)

### Key API Calls
1. **Rewording**: `sendRequest(systemPrompt, userPrompt, temperature, maxTokens)`
2. **Story Analysis**: `sendRequest()` with JSON extraction
3. **Segmentation**: `sendRequest()` with segmentation logic
4. **Cinematic Analysis**: `sendRequest()` per segment
5. **Continuity**: `sendRequest()` with continuity analysis

## Testing Requirements

### Unit Tests Needed
- Individual step execution
- Error handling and recovery
- Optional step behavior
- Data model serialization/deserialization

### Integration Tests Needed
- Full pipeline execution
- UI state management
- Project saving/loading
- Video generation integration

## Deployment Checklist

When integrating the new pipeline:

1. ✅ Maintain all existing interfaces
2. ✅ Preserve data model compatibility
3. ✅ Ensure UI integration works
4. ✅ Test all step combinations
5. ✅ Verify error handling
6. ✅ Test video generation flow
7. ✅ Validate project saving/loading

## Contact & Support

This refactor package is designed for seamless integration. The new pipeline implementation should maintain full compatibility with the existing DirectorStudio codebase while providing the enhanced functionality described above.

**Key Integration Points:**
- `CreateView.swift` - UI controls
- `StudioView.swift` - Video generation
- `Project.swift` - Data persistence
- `AppState.swift` - State management

The pipeline is the core of the DirectorStudio application and must be implemented with careful attention to compatibility and user experience.
