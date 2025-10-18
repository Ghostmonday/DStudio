# Coding Requirements for Pipeline Refactor

## Critical Issues to Fix

### 1. Make Story Analysis Optional ❌ HIGH PRIORITY

**Current Problem**: Story Analysis (Step 2) is mandatory and blocks pipeline execution when disabled.

**Required Changes**:
```swift
// In DirectorStudioPipeline.swift
// BEFORE (current):
await storyAnalyzer.analyze(story: processedStory)
if await MainActor.run(body: { storyAnalyzer.analysis }) != nil {
    await markStepComplete(2)
} else {
    await setError("Story analysis failed")
    return  // This blocks the entire pipeline!
}

// AFTER (required):
if enableStoryAnalysis {
    await storyAnalyzer.analyze(story: processedStory)
    if await MainActor.run(body: { storyAnalyzer.analysis }) != nil {
        await markStepComplete(2)
    } else {
        await setError("Story analysis failed")
        return
    }
} else {
    // Create mock analysis or skip entirely
    await markStepComplete(2)
    logger.info("⏭️ Skipping story analysis (module disabled)")
}
```

**Files to Modify**:
- `Modules/DirectorStudioPipeline.swift`
- `Views/CreateView.swift` (add enableStoryAnalysis parameter)

### 2. Make Continuity Anchors Optional ❌ HIGH PRIORITY

**Current Problem**: Continuity Anchors (Step 5) is mandatory and blocks pipeline execution when disabled.

**Required Changes**:
```swift
// In DirectorStudioPipeline.swift
// BEFORE (current):
await continuityModule.generateAnchors(story: processedStory)
let anchors = await MainActor.run { continuityModule.anchors }
if !anchors.isEmpty {
    await markStepComplete(5)
} else {
    await setError("Continuity generation failed")
    return  // This blocks the entire pipeline!
}

// AFTER (required):
if enableContinuity {
    await continuityModule.generateAnchors(story: processedStory)
    let anchors = await MainActor.run { continuityModule.anchors }
    if !anchors.isEmpty {
        await markStepComplete(5)
    } else {
        await setError("Continuity generation failed")
        return
    }
} else {
    // Create mock anchors or skip entirely
    await markStepComplete(5)
    logger.info("⏭️ Skipping continuity anchors (module disabled)")
}
```

**Files to Modify**:
- `Modules/DirectorStudioPipeline.swift`
- `Views/CreateView.swift` (add enableContinuity parameter)

### 3. Implement Individual Step Execution ❌ MEDIUM PRIORITY

**Current Problem**: Steps cannot be run independently - it's all or nothing.

**Required Implementation**:
```swift
// Add to DirectorStudioPipeline.swift
func runIndividualStep(_ stepNumber: Int, input: Any) async throws -> Any {
    switch stepNumber {
    case 1:
        return try await runRewordingStep(input as? String ?? "")
    case 2:
        return try await runStoryAnalysisStep(input as? String ?? "")
    case 3:
        return try await runSegmentationStep(input as? String ?? "")
    case 4:
        return try await runCinematicStep(input as? [PromptSegment] ?? [])
    case 5:
        return try await runContinuityStep(input as? String ?? "")
    case 6:
        return try await runPackagingStep(input as? Any)
    default:
        throw PipelineError.invalidStep(stepNumber)
    }
}

private func runRewordingStep(_ story: String) async throws -> String {
    // Individual step implementation
}

private func runStoryAnalysisStep(_ story: String) async throws -> StoryAnalysis {
    // Individual step implementation
}

// ... etc for each step
```

**Files to Create/Modify**:
- `Modules/DirectorStudioPipeline.swift` (add individual step methods)
- `Views/CreateView.swift` (add individual step buttons)

### 4. Add Step Result Visibility ❌ MEDIUM PRIORITY

**Current Problem**: Users can't see what each step produces - it's a black box.

**Required Implementation**:
```swift
// Add to DirectorStudioPipeline.swift
@Published var stepResults: [Int: StepResult] = [:]

struct StepResult {
    let stepNumber: Int
    let title: String
    let status: StepStatus
    let output: Any
    let error: Error?
    let executionTime: TimeInterval
    let timestamp: Date
}

enum StepStatus {
    case pending
    case running
    case completed
    case failed(String)
    case skipped
}
```

**Files to Create/Modify**:
- `Modules/DirectorStudioPipeline.swift` (add result tracking)
- `Views/CreateView.swift` (display results)
- `Components/IndividualStepView.swift` (show results)

### 5. Enhanced Error Handling ❌ MEDIUM PRIORITY

**Current Problem**: Errors in one step can break the entire pipeline.

**Required Implementation**:
```swift
// Add to DirectorStudioPipeline.swift
enum PipelineError: Error, LocalizedError {
    case stepFailed(step: Int, error: Error)
    case dependencyMissing(step: Int, dependency: String)
    case apiError(step: Int, message: String)
    case invalidStep(Int)
    
    var errorDescription: String? {
        switch self {
        case .stepFailed(let step, let error):
            return "Step \(step) failed: \(error.localizedDescription)"
        case .dependencyMissing(let step, let dependency):
            return "Step \(step) missing dependency: \(dependency)"
        case .apiError(let step, let message):
            return "Step \(step) API error: \(message)"
        case .invalidStep(let step):
            return "Invalid step number: \(step)"
        }
    }
}

// Add error recovery logic
private func handleStepError(_ step: Int, error: Error) async {
    // Log error
    logger.error("Step \(step) failed: \(error.localizedDescription)")
    
    // Update UI
    await MainActor.run {
        stepResults[step] = StepResult(
            stepNumber: step,
            title: getStepTitle(step),
            status: .failed(error.localizedDescription),
            output: nil,
            error: error,
            executionTime: 0,
            timestamp: Date()
        )
    }
    
    // Decide whether to continue or abort
    if shouldAbortOnError(step) {
        await setError("Pipeline failed at step \(step)")
        return
    } else {
        // Continue to next step
        await markStepComplete(step)
    }
}
```

**Files to Create/Modify**:
- `Modules/DirectorStudioPipeline.swift` (add error handling)
- `Services/AIModuleError.swift` (extend error types)

### 6. Update UI for Individual Control ❌ LOW PRIORITY

**Current Problem**: UI doesn't reflect individual step control.

**Required Implementation**:
```swift
// Update CreateView.swift
// Add individual step execution buttons
VStack {
    ForEach(1...6, id: \.self) { stepNumber in
        HStack {
            Text("Step \(stepNumber)")
            Spacer()
            Button("Run") {
                Task {
                    await runIndividualStep(stepNumber)
                }
            }
            .disabled(pipeline.isRunning)
        }
    }
}

// Add step result display
if let result = pipeline.stepResults[stepNumber] {
    StepResultView(result: result)
}
```

**Files to Create/Modify**:
- `Views/CreateView.swift` (add individual controls)
- `Components/IndividualStepView.swift` (add result display)
- `Components/StepResultView.swift` (new component)

## Implementation Priority

### Phase 1: Critical Fixes (Week 1)
1. ✅ Make Story Analysis optional
2. ✅ Make Continuity Anchors optional
3. ✅ Fix pipeline execution flow

### Phase 2: Enhanced Functionality (Week 2)
1. ✅ Individual step execution
2. ✅ Step result visibility
3. ✅ Enhanced error handling

### Phase 3: UI Improvements (Week 3)
1. ✅ Individual step controls
2. ✅ Result display
3. ✅ Progress indicators

## Testing Requirements

### Unit Tests
```swift
// Test individual step execution
func testIndividualStepExecution() async throws {
    let pipeline = DirectorStudioPipeline()
    let result = try await pipeline.runIndividualStep(1, input: "test story")
    XCTAssertNotNil(result)
}

// Test optional step behavior
func testOptionalStepBehavior() async {
    let pipeline = DirectorStudioPipeline()
    await pipeline.runFullPipeline(
        story: "test",
        enableStoryAnalysis: false, // Should not fail
        // ... other params
    )
    XCTAssertTrue(pipeline.completedSteps.contains(2))
}

// Test error handling
func testErrorHandling() async {
    let pipeline = DirectorStudioPipeline()
    // Simulate API failure
    // Verify pipeline continues or fails gracefully
}
```

### Integration Tests
```swift
// Test full pipeline with all steps enabled
func testFullPipelineExecution() async {
    // Test complete flow
}

// Test partial pipeline execution
func testPartialPipelineExecution() async {
    // Test with some steps disabled
}

// Test UI integration
func testUIIntegration() {
    // Test CreateView with individual controls
    // Test StudioView with generated segments
}
```

## Success Criteria

The refactor is successful when:

1. ✅ All steps can be individually enabled/disabled
2. ✅ Pipeline executes successfully with any combination of steps
3. ✅ Individual steps can be run independently
4. ✅ Step results are visible to users
5. ✅ Error handling is robust and user-friendly
6. ✅ UI provides full control and transparency
7. ✅ All existing functionality continues to work
8. ✅ Video generation works with new pipeline
9. ✅ Projects save/load correctly
10. ✅ Performance is acceptable

## Risk Mitigation

### High Risk Areas
1. **Data Model Changes**: Could break existing projects
2. **API Integration**: Could affect video generation
3. **UI Changes**: Could break user workflows

### Mitigation Strategies
1. **Backward Compatibility**: Maintain all existing interfaces
2. **Gradual Rollout**: Test with subset of users first
3. **Feature Flags**: Allow switching between old/new pipeline
4. **Comprehensive Testing**: Unit, integration, and user testing
5. **Rollback Plan**: Keep original files for quick rollback

This refactor will transform the pipeline from a black box into a transparent, controllable system that gives users full visibility and control over the AI processing pipeline.
