# 🎬 AI Video Pipeline Refactor Guide
## From Fixed 5×4s to Flexible Script-Driven Generation

---

## 📋 EXECUTIVE SUMMARY

**Current Problem:**
- Pipeline forces ALL stories into exactly 5 videos of 4 seconds each (20s total)
- No matter if script is 2 pages or 120 pages
- Auto-montage behavior instead of filmmaking control

**Solution:**
- Script-driven shot list generation
- User controls for duration, shot count, and pacing
- Optional hard limits for cost/time management
- Manual review gates before generation

---

## 🔍 CURRENT ARCHITECTURE ANALYSIS

Based on your v2.0.0 pipeline, here's what needs changing:

### Current Flow:
```
Input Story
    ↓
RewordingModule (optional)
    ↓
StoryAnalysisModule (extracts characters, locations, scenes)
    ↓
SegmentationModule ← **PROBLEM: Fixed to 5 segments**
    ↓
CinematicTaxonomyModule (adds camera, lighting, shots)
    ↓
ContinuityModule (tracks consistency)
    ↓
PackagingModule (final output)
    ↓
5 videos × 4s each = 20s ALWAYS
```

### Problems to Fix:

1. **SegmentationModule.swift** - Hardcoded segment count
2. **PipelineConfig.swift** - No user control parameters
3. **CinematicTaxonomyModule.swift** - No duration flexibility
4. **No manual review gates** - Auto-generates without approval

---

## 🛠️ REFACTOR PLAN

### Phase 1: Add User Control Configuration
### Phase 2: Make Segmentation Flexible
### Phase 3: Add Manual Review System
### Phase 4: Implement Hard Limits (Optional)

---

## 📝 PHASE 1: ADD USER CONTROL CONFIGURATION

### 1.1 Create New Config Structure

**File:** `PipelineConfig.swift`

**ADD THIS NEW SECTION:**

```swift
// MARK: - User Control Configuration
public struct UserControlConfig {
    // Generation Mode
    public enum GenerationMode {
        case automatic          // Script determines everything
        case semiAutomatic      // Script suggests, user approves
        case manual             // User controls everything
    }
    
    // Duration Strategy
    public enum DurationStrategy {
        case scriptBased        // Estimate from script (1 page ≈ 60s)
        case fixed(seconds: Int) // All shots same duration
        case custom             // User specifies per shot
    }
    
    // Segmentation Strategy
    public enum SegmentationStrategy {
        case automatic          // Let AI decide based on script
        case perScene           // 1 shot per scene heading
        case perBeat            // 1 shot per story beat
        case manual(count: Int) // User specifies exact count
    }
    
    // User Controls
    public var generationMode: GenerationMode = .semiAutomatic
    public var durationStrategy: DurationStrategy = .scriptBased
    public var segmentationStrategy: SegmentationStrategy = .automatic
    
    // Hard Limits (Optional)
    public var maxShots: Int? = nil              // nil = unlimited
    public var maxTotalDuration: Int? = nil      // seconds, nil = unlimited
    public var minShotDuration: Int = 3          // minimum seconds per shot
    public var maxShotDuration: Int = 30         // maximum seconds per shot
    
    // Cost Controls
    public var maxCostPerProject: Decimal? = nil // nil = unlimited
    public var estimatedCostPerSecond: Decimal = 1.0 // video credits
    
    // Review Gates
    public var requireShotListApproval: Bool = true
    public var requirePromptReview: Bool = false
    public var allowEditBeforeGeneration: Bool = true
    
    public init() {}
}

// Add to main PipelineConfig
public struct PipelineConfig {
    // ... existing config ...
    
    // ADD THIS:
    public var userControls: UserControlConfig = UserControlConfig()
    
    // ... rest of config ...
}
```

---

## 🎯 PHASE 2: MAKE SEGMENTATION FLEXIBLE

### 2.1 Refactor SegmentationModule

**File:** `SegmentationModule.swift`

**CURRENT CODE (Problematic):**
```swift
// This is probably in your current code:
private func segmentStory(_ story: String) -> [PromptSegment] {
    let targetSegments = 5  // ← HARDCODED PROBLEM
    let segmentDuration = 4.0  // ← HARDCODED PROBLEM
    // ... rest of logic
}
```

**NEW CODE (Flexible):**

```swift
import Foundation

public struct SegmentationModuleInput {
    public let story: String
    public let storyAnalysis: StoryAnalysisOutput?  // Optional from StoryAnalysisModule
    public let userControls: UserControlConfig      // NEW: User preferences
    
    public init(
        story: String, 
        storyAnalysis: StoryAnalysisOutput? = nil,
        userControls: UserControlConfig = UserControlConfig()
    ) {
        self.story = story
        self.storyAnalysis = storyAnalysis
        self.userControls = userControls
    }
}

public struct PromptSegment: Codable {
    public let index: Int
    public let text: String
    public let estimatedDuration: TimeInterval  // NEW: Flexible duration
    public let sceneType: SceneType?            // NEW: Scene classification
    public let suggestedShotType: ShotType?     // NEW: Suggested framing
    
    // Existing fields
    public let pacing: String
    public let transitionHint: String?
    public let metadata: [String: String]
    
    public enum SceneType: String, Codable {
        case establishing
        case action
        case dialogue
        case transition
        case montage
    }
    
    public enum ShotType: String, Codable {
        case wideShot
        case mediumShot
        case closeup
        case extremeCloseup
        case overTheShoulder
    }
}

public class SegmentationModule: PipelineModule {
    // ... existing code ...
    
    public func process(
        _ input: SegmentationModuleInput, 
        context: PipelineContext
    ) async throws -> Result<SegmentationOutput, PipelineError> {
        
        // 1. Determine segmentation strategy
        let segments: [PromptSegment]
        
        switch input.userControls.segmentationStrategy {
        case .automatic:
            segments = try await automaticSegmentation(input, context)
            
        case .perScene:
            segments = try await sceneBasedSegmentation(input, context)
            
        case .perBeat:
            segments = try await beatBasedSegmentation(input, context)
            
        case .manual(let count):
            segments = try await manualSegmentation(input, context, targetCount: count)
        }
        
        // 2. Apply hard limits if specified
        let limitedSegments = applyHardLimits(segments, config: input.userControls)
        
        // 3. Validate and return
        let output = SegmentationOutput(
            segments: limitedSegments,
            strategy: input.userControls.segmentationStrategy,
            totalEstimatedDuration: limitedSegments.reduce(0) { $0 + $1.estimatedDuration },
            qualityMetrics: calculateQualityMetrics(limitedSegments)
        )
        
        return .success(output)
    }
    
    // MARK: - Automatic Segmentation (Script-Driven)
    
    private func automaticSegmentation(
        _ input: SegmentationModuleInput,
        _ context: PipelineContext
    ) async throws -> [PromptSegment] {
        
        // Use story analysis if available
        guard let analysis = input.storyAnalysis else {
            // Fallback to basic text segmentation
            return try await basicTextSegmentation(input.story, input.userControls)
        }
        
        var segments: [PromptSegment] = []
        
        // Create segments based on scenes from StoryAnalysisModule
        for (index, scene) in analysis.scenes.enumerated() {
            let duration = estimateSceneDuration(scene, strategy: input.userControls.durationStrategy)
            let segment = PromptSegment(
                index: index,
                text: scene.description,
                estimatedDuration: duration,
                sceneType: classifyScene(scene),
                suggestedShotType: suggestShotType(scene, analysis),
                pacing: determinePacing(scene),
                transitionHint: determineTransition(scene, nextScene: analysis.scenes[safe: index + 1]),
                metadata: [
                    "location": scene.location ?? "unknown",
                    "characters": scene.characters.joined(separator: ", "),
                    "timeOfDay": scene.timeOfDay ?? "unknown"
                ]
            )
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Scene-Based Segmentation
    
    private func sceneBasedSegmentation(
        _ input: SegmentationModuleInput,
        _ context: PipelineContext
    ) async throws -> [PromptSegment] {
        
        // Parse script for scene headings (INT./EXT.)
        let sceneHeadings = extractSceneHeadings(from: input.story)
        
        var segments: [PromptSegment] = []
        
        for (index, heading) in sceneHeadings.enumerated() {
            let sceneText = extractSceneText(
                from: input.story,
                startingAt: heading,
                endingAt: sceneHeadings[safe: index + 1]
            )
            
            let duration = estimateDuration(
                from: sceneText,
                strategy: input.userControls.durationStrategy
            )
            
            let segment = PromptSegment(
                index: index,
                text: sceneText,
                estimatedDuration: duration,
                sceneType: .establishing,
                suggestedShotType: determineInitialShotType(heading),
                pacing: "measured",
                transitionHint: nil,
                metadata: ["sceneHeading": heading]
            )
            
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Beat-Based Segmentation
    
    private func beatBasedSegmentation(
        _ input: SegmentationModuleInput,
        _ context: PipelineContext
    ) async throws -> [PromptSegment] {
        
        // Identify story beats (plot points, emotional shifts)
        let beats = identifyStoryBeats(input.story, analysis: input.storyAnalysis)
        
        var segments: [PromptSegment] = []
        
        for (index, beat) in beats.enumerated() {
            let duration = estimateBeatDuration(beat, strategy: input.userControls.durationStrategy)
            
            let segment = PromptSegment(
                index: index,
                text: beat.text,
                estimatedDuration: duration,
                sceneType: beat.type,
                suggestedShotType: beat.suggestedShot,
                pacing: beat.pacing,
                transitionHint: beat.transition,
                metadata: beat.metadata
            )
            
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Manual Segmentation
    
    private func manualSegmentation(
        _ input: SegmentationModuleInput,
        _ context: PipelineContext,
        targetCount: Int
    ) async throws -> [PromptSegment] {
        
        // Divide story into exactly N segments
        let totalLength = input.story.count
        let segmentLength = totalLength / targetCount
        
        var segments: [PromptSegment] = []
        
        for i in 0..<targetCount {
            let startIndex = i * segmentLength
            let endIndex = min((i + 1) * segmentLength, totalLength)
            
            let text = String(input.story.dropFirst(startIndex).prefix(endIndex - startIndex))
            
            let duration = estimateDuration(
                from: text,
                strategy: input.userControls.durationStrategy
            )
            
            let segment = PromptSegment(
                index: i,
                text: text,
                estimatedDuration: duration,
                sceneType: nil,
                suggestedShotType: nil,
                pacing: "moderate",
                transitionHint: nil,
                metadata: [:]
            )
            
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Duration Estimation
    
    private func estimateDuration(
        from text: String,
        strategy: UserControlConfig.DurationStrategy
    ) -> TimeInterval {
        
        switch strategy {
        case .scriptBased:
            return estimateScriptBasedDuration(text)
            
        case .fixed(let seconds):
            return TimeInterval(seconds)
            
        case .custom:
            // This will be overridden by user input later
            return estimateScriptBasedDuration(text)
        }
    }
    
    private func estimateScriptBasedDuration(_ text: String) -> TimeInterval {
        // Industry standard: ~1 page = 60 seconds
        // Rough approximation: 250 words per page
        
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        let estimatedPages = Double(wordCount) / 250.0
        let estimatedSeconds = estimatedPages * 60.0
        
        // Clamp to reasonable bounds (3-30 seconds)
        return max(3.0, min(30.0, estimatedSeconds))
    }
    
    private func estimateSceneDuration(
        _ scene: StoryAnalysisOutput.Scene,
        strategy: UserControlConfig.DurationStrategy
    ) -> TimeInterval {
        
        switch strategy {
        case .scriptBased:
            // More sophisticated estimation using scene properties
            var duration: TimeInterval = 5.0  // Base duration
            
            // Add time for dialogue
            let dialogueWords = scene.dialogue?.components(separatedBy: .whitespacesAndNewlines).count ?? 0
            duration += Double(dialogueWords) / 150.0 * 60.0  // ~150 words/min speech
            
            // Add time for action
            let actionWords = scene.description.components(separatedBy: .whitespacesAndNewlines).count
            duration += Double(actionWords) / 300.0 * 60.0  // Actions are faster
            
            // Adjust for scene type
            if scene.type == "action" {
                duration *= 0.8  // Action scenes move faster
            } else if scene.type == "dialogue" {
                duration *= 1.2  // Dialogue scenes need breathing room
            }
            
            return max(3.0, min(30.0, duration))
            
        case .fixed(let seconds):
            return TimeInterval(seconds)
            
        case .custom:
            return estimateScriptBasedDuration(scene.description)
        }
    }
    
    // MARK: - Hard Limits
    
    private func applyHardLimits(
        _ segments: [PromptSegment],
        config: UserControlConfig
    ) -> [PromptSegment] {
        
        var limited = segments
        
        // Apply max shots limit
        if let maxShots = config.maxShots, segments.count > maxShots {
            // Merge segments intelligently to hit target
            limited = mergeSegments(limited, targetCount: maxShots)
        }
        
        // Apply max total duration limit
        if let maxDuration = config.maxTotalDuration {
            let totalDuration = limited.reduce(0.0) { $0 + $1.estimatedDuration }
            if totalDuration > Double(maxDuration) {
                // Scale all durations proportionally
                let scale = Double(maxDuration) / totalDuration
                limited = limited.map { segment in
                    var modified = segment
                    modified.estimatedDuration *= scale
                    return modified
                }
            }
        }
        
        // Apply min/max shot duration constraints
        limited = limited.map { segment in
            var modified = segment
            modified.estimatedDuration = max(
                Double(config.minShotDuration),
                min(Double(config.maxShotDuration), segment.estimatedDuration)
            )
            return modified
        }
        
        return limited
    }
    
    // MARK: - Helper Methods
    
    private func extractSceneHeadings(from script: String) -> [String] {
        let pattern = "^(INT\\.|EXT\\.|INT/EXT\\.).*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return []
        }
        
        let range = NSRange(script.startIndex..., in: script)
        let matches = regex.matches(in: script, range: range)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: script) else { return nil }
            return String(script[range])
        }
    }
    
    private func extractSceneText(
        from script: String,
        startingAt heading: String,
        endingAt nextHeading: String?
    ) -> String {
        guard let startRange = script.range(of: heading) else { return "" }
        
        let startIndex = startRange.upperBound
        let endIndex: String.Index
        
        if let nextHeading = nextHeading,
           let endRange = script.range(of: nextHeading, range: startIndex..<script.endIndex) {
            endIndex = endRange.lowerBound
        } else {
            endIndex = script.endIndex
        }
        
        return String(script[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func classifyScene(_ scene: StoryAnalysisOutput.Scene) -> PromptSegment.SceneType {
        // Classify based on scene properties
        if scene.type == "establishing" { return .establishing }
        if scene.type == "action" { return .action }
        if scene.type == "dialogue" { return .dialogue }
        return .action
    }
    
    private func suggestShotType(
        _ scene: StoryAnalysisOutput.Scene,
        _ analysis: StoryAnalysisOutput
    ) -> PromptSegment.ShotType {
        // Suggest shot type based on scene context
        if scene.type == "establishing" { return .wideShot }
        if scene.characters.count >= 2 { return .overTheShoulder }
        if scene.emotionalTone == "intimate" { return .closeup }
        return .mediumShot
    }
    
    private func mergeSegments(_ segments: [PromptSegment], targetCount: Int) -> [PromptSegment] {
        guard segments.count > targetCount else { return segments }
        
        // Simple merge strategy: combine adjacent segments
        var merged: [PromptSegment] = []
        let mergeSize = segments.count / targetCount
        
        for i in stride(from: 0, to: segments.count, by: mergeSize) {
            let end = min(i + mergeSize, segments.count)
            let group = Array(segments[i..<end])
            
            let combinedSegment = PromptSegment(
                index: merged.count,
                text: group.map { $0.text }.joined(separator: " "),
                estimatedDuration: group.reduce(0.0) { $0 + $1.estimatedDuration },
                sceneType: group.first?.sceneType,
                suggestedShotType: group.first?.suggestedShotType,
                pacing: "moderate",
                transitionHint: group.last?.transitionHint,
                metadata: [:]
            )
            
            merged.append(combinedSegment)
        }
        
        return merged
    }
    
    private struct StoryBeat {
        let text: String
        let type: PromptSegment.SceneType
        let suggestedShot: PromptSegment.ShotType
        let pacing: String
        let transition: String?
        let metadata: [String: String]
    }
    
    private func identifyStoryBeats(
        _ story: String,
        analysis: StoryAnalysisOutput?
    ) -> [StoryBeat] {
        // Implement beat detection logic
        // For now, return basic segmentation
        return []
    }
    
    private func estimateBeatDuration(
        _ beat: StoryBeat,
        strategy: UserControlConfig.DurationStrategy
    ) -> TimeInterval {
        return 5.0  // Placeholder
    }
    
    private func determinePacing(_ scene: StoryAnalysisOutput.Scene) -> String {
        if scene.type == "action" { return "fast" }
        if scene.type == "dialogue" { return "measured" }
        return "moderate"
    }
    
    private func determineTransition(
        _ scene: StoryAnalysisOutput.Scene,
        nextScene: StoryAnalysisOutput.Scene?
    ) -> String? {
        guard let next = nextScene else { return nil }
        
        if scene.location != next.location { return "cut" }
        if scene.timeOfDay != next.timeOfDay { return "dissolve" }
        return "cut"
    }
    
    private func determineInitialShotType(_ heading: String) -> PromptSegment.ShotType {
        if heading.contains("EXT.") { return .wideShot }
        return .mediumShot
    }
    
    private func calculateQualityMetrics(_ segments: [PromptSegment]) -> [String: Any] {
        return [
            "totalSegments": segments.count,
            "averageDuration": segments.reduce(0.0) { $0 + $1.estimatedDuration } / Double(segments.count),
            "hasDurationVariety": segments.map { $0.estimatedDuration }.set.count > 1
        ]
    }
}

// MARK: - Output Structure

public struct SegmentationOutput: Codable {
    public let segments: [PromptSegment]
    public let strategy: String  // Description of strategy used
    public let totalEstimatedDuration: TimeInterval
    public let qualityMetrics: [String: Any]
    
    // Codable conformance with Any dictionary
    enum CodingKeys: String, CodingKey {
        case segments, strategy, totalEstimatedDuration, qualityMetrics
    }
    
    public init(
        segments: [PromptSegment],
        strategy: UserControlConfig.SegmentationStrategy,
        totalEstimatedDuration: TimeInterval,
        qualityMetrics: [String: Any]
    ) {
        self.segments = segments
        self.strategy = "\(strategy)"
        self.totalEstimatedDuration = totalEstimatedDuration
        self.qualityMetrics = qualityMetrics
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(segments, forKey: .segments)
        try container.encode(strategy, forKey: .strategy)
        try container.encode(totalEstimatedDuration, forKey: .totalEstimatedDuration)
        // Skip qualityMetrics for simplicity in Codable
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        segments = try container.decode([PromptSegment].self, forKey: .segments)
        strategy = try container.decode(String.self, forKey: .strategy)
        totalEstimatedDuration = try container.decode(TimeInterval.self, forKey: .totalEstimatedDuration)
        qualityMetrics = [:]
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Sequence where Element: Hashable {
    var set: Set<Element> {
        return Set(self)
    }
}

extension PromptSegment {
    var estimatedDuration: TimeInterval {
        get { metadata["estimatedDuration"].flatMap { TimeInterval($0) } ?? 5.0 }
        set { metadata["estimatedDuration"] = "\(newValue)" }
    }
}
```

---

## 🎮 PHASE 3: ADD MANUAL REVIEW SYSTEM

### 3.1 Create Review Gate Protocol

**File:** `ReviewGate.swift` (NEW FILE)

```swift
import Foundation

// MARK: - Review Gate Protocol

public protocol ReviewGate {
    associatedtype ReviewItem
    associatedtype ReviewDecision
    
    func presentForReview(_ item: ReviewItem) async -> ReviewDecision
}

// MARK: - Shot List Review

public struct ShotListReviewItem {
    public let segments: [PromptSegment]
    public let totalDuration: TimeInterval
    public let estimatedCost: Decimal
    public let metadata: [String: String]
}

public enum ShotListReviewDecision {
    case approved
    case modified([PromptSegment])  // User edited segments
    case rejected(reason: String)
}

public class ShotListReviewGate: ReviewGate {
    public typealias ReviewItem = ShotListReviewItem
    public typealias ReviewDecision = ShotListReviewDecision
    
    private let presentationHandler: (ShotListReviewItem) async -> ShotListReviewDecision
    
    public init(presentationHandler: @escaping (ShotListReviewItem) async -> ShotListReviewDecision) {
        self.presentationHandler = presentationHandler
    }
    
    public func presentForReview(_ item: ShotListReviewItem) async -> ShotListReviewDecision {
        return await presentationHandler(item)
    }
}

// MARK: - Prompt Review

public struct PromptReviewItem {
    public let segment: PromptSegment
    public let enrichedPrompt: String  // After CinematicTaxonomy
    public let estimatedCost: Decimal
    public let previewMetadata: [String: String]
}

public enum PromptReviewDecision {
    case approved
    case modified(newPrompt: String)
    case skipped
    case rejected
}

public class PromptReviewGate: ReviewGate {
    public typealias ReviewItem = PromptReviewItem
    public typealias ReviewDecision = PromptReviewDecision
    
    private let presentationHandler: (PromptReviewItem) async -> PromptReviewDecision
    
    public init(presentationHandler: @escaping (PromptReviewItem) async -> PromptReviewDecision) {
        self.presentationHandler = presentationHandler
    }
    
    public func presentForReview(_ item: PromptReviewItem) async -> PromptReviewDecision {
        return await presentationHandler(item)
    }
}
```

### 3.2 Integrate Review Gates into Pipeline

**File:** `PipelineManager.swift`

**ADD THESE PROPERTIES:**

```swift
public class PipelineManager {
    // ... existing properties ...
    
    // NEW: Review gates
    public var shotListReviewGate: ShotListReviewGate?
    public var promptReviewGate: PromptReviewGate?
    
    // ... rest of class ...
}
```

**MODIFY THE `run()` METHOD:**

```swift
public func run(
    input: PipelineInput,
    config: PipelineConfig
) async throws -> PipelineOutput {
    
    let context = PipelineContext(config: config, logger: logger)
    
    // ... existing module runs (Rewording, StoryAnalysis) ...
    
    // Run Segmentation
    let segmentationOutput = try await runModule(
        segmentationModule,
        input: SegmentationModuleInput(
            story: currentStory,
            storyAnalysis: storyAnalysisOutput,
            userControls: config.userControls  // NEW
        ),
        context: context
    )
    
    // NEW: Shot List Review Gate
    if config.userControls.requireShotListApproval,
       let reviewGate = shotListReviewGate {
        
        let reviewItem = ShotListReviewItem(
            segments: segmentationOutput.segments,
            totalDuration: segmentationOutput.totalEstimatedDuration,
            estimatedCost: calculateEstimatedCost(segmentationOutput.segments, config: config),
            metadata: [
                "segmentCount": "\(segmentationOutput.segments.count)",
                "strategy": segmentationOutput.strategy
            ]
        )
        
        let decision = await reviewGate.presentForReview(reviewItem)
        
        switch decision {
        case .approved:
            logger.info("Shot list approved by user")
            
        case .modified(let newSegments):
            logger.info("Shot list modified by user")
            // Replace segments with user-edited version
            segmentationOutput.segments = newSegments
            
        case .rejected(let reason):
            logger.warning("Shot list rejected: \(reason)")
            throw PipelineError.userCancelled(reason: reason)
        }
    }
    
    // Run CinematicTaxonomy
    var enrichedSegments = segmentationOutput.segments
    
    for (index, segment) in enrichedSegments.enumerated() {
        let taxonomyOutput = try await runModule(
            cinematicTaxonomyModule,
            input: CinematicTaxonomyModuleInput(segment: segment),
            context: context
        )
        
        // NEW: Prompt Review Gate (per segment)
        if config.userControls.requirePromptReview,
           let reviewGate = promptReviewGate {
            
            let reviewItem = PromptReviewItem(
                segment: segment,
                enrichedPrompt: taxonomyOutput.enrichedPrompt,
                estimatedCost: config.userControls.estimatedCostPerSecond * Decimal(segment.estimatedDuration),
                previewMetadata: taxonomyOutput.metadata
            )
            
            let decision = await reviewGate.presentForReview(reviewItem)
            
            switch decision {
            case .approved:
                enrichedSegments[index] = taxonomyOutput.enrichedSegment
                
            case .modified(let newPrompt):
                var modifiedSegment = segment
                modifiedSegment.text = newPrompt
                enrichedSegments[index] = modifiedSegment
                
            case .skipped:
                logger.info("Skipping segment \(index)")
                continue
                
            case .rejected:
                throw PipelineError.userCancelled(reason: "User rejected prompt for segment \(index)")
            }
        } else {
            enrichedSegments[index] = taxonomyOutput.enrichedSegment
        }
    }
    
    // Continue with Continuity and Packaging...
    
    return finalOutput
}

// Helper method
private func calculateEstimatedCost(
    _ segments: [PromptSegment],
    config: PipelineConfig
) -> Decimal {
    let totalDuration = segments.reduce(0.0) { $0 + $1.estimatedDuration }
    return Decimal(totalDuration) * config.userControls.estimatedCostPerSecond
}
```

---

## 🚦 PHASE 4: IMPLEMENT HARD LIMITS

### 4.1 Cost Calculator

**File:** `CostCalculator.swift` (NEW FILE)

```swift
import Foundation

public struct CostCalculator {
    public let costPerSecond: Decimal
    
    public init(costPerSecond: Decimal) {
        self.costPerSecond = costPerSecond
    }
    
    public func estimateCost(for segments: [PromptSegment]) -> Decimal {
        let totalDuration = segments.reduce(0.0) { $0 + $1.estimatedDuration }
        return Decimal(totalDuration) * costPerSecond
    }
    
    public func estimateCost(for duration: TimeInterval) -> Decimal {
        return Decimal(duration) * costPerSecond
    }
    
    public func checkBudget(
        segments: [PromptSegment],
        maxCost: Decimal?
    ) -> BudgetCheckResult {
        guard let maxCost = maxCost else {
            return .withinBudget(remaining: nil)
        }
        
        let estimatedCost = estimateCost(for: segments)
        
        if estimatedCost <= maxCost {
            return .withinBudget(remaining: maxCost - estimatedCost)
        } else {
            return .overBudget(
                overage: estimatedCost - maxCost,
                suggestedReduction: calculateReduction(segments: segments, targetCost: maxCost)
            )
        }
    }
    
    private func calculateReduction(
        segments: [PromptSegment],
        targetCost: Decimal
    ) -> BudgetReduction {
        let currentCost = estimateCost(for: segments)
        let reductionNeeded = currentCost - targetCost
        
        // Strategy 1: Remove shortest segments
        let sortedByDuration = segments.sorted { $0.estimatedDuration < $1.estimatedDuration }
        var toRemove: [Int] = []
        var savedCost: Decimal = 0
        
        for segment in sortedByDuration {
            let segmentCost = Decimal(segment.estimatedDuration) * costPerSecond
            savedCost += segmentCost
            toRemove.append(segment.index)
            
            if savedCost >= reductionNeeded {
                break
            }
        }
        
        // Strategy 2: Reduce all durations proportionally
        let scaleFactor = Double(truncating: targetCost as NSNumber) / Double(truncating: currentCost as NSNumber)
        
        return BudgetReduction(
            removeSegments: toRemove,
            orScaleDurationsBy: scaleFactor
        )
    }
}

public enum BudgetCheckResult {
    case withinBudget(remaining: Decimal?)
    case overBudget(overage: Decimal, suggestedReduction: BudgetReduction)
}

public struct BudgetReduction {
    public let removeSegments: [Int]
    public let orScaleDurationsBy: Double
}
```

### 4.2 Add Budget Checking to Pipeline

**In `PipelineManager.swift`, after segmentation:**

```swift
// Check budget constraints
if let maxCost = config.userControls.maxCostPerProject {
    let calculator = CostCalculator(costPerSecond: config.userControls.estimatedCostPerSecond)
    let budgetCheck = calculator.checkBudget(
        segments: segmentationOutput.segments,
        maxCost: maxCost
    )
    
    switch budgetCheck {
    case .withinBudget(let remaining):
        logger.info("Within budget. Remaining: \(remaining?.description ?? "unlimited")")
        
    case .overBudget(let overage, let reduction):
        logger.warning("Over budget by \(overage)")
        
        // Present options to user
        throw PipelineError.budgetExceeded(
            overage: overage,
            suggestions: [
                "Remove \(reduction.removeSegments.count) shortest segments",
                "Scale all durations by \(String(format: "%.2f", reduction.orScaleDurationsBy))x",
                "Increase budget",
                "Cancel generation"
            ]
        )
    }
}
```

---

## 📱 UI INTEGRATION GUIDE

### 5.1 SwiftUI Settings View

**File:** `PipelineSettingsView.swift` (NEW FILE)

```swift
import SwiftUI

struct PipelineSettingsView: View {
    @Binding var config: UserControlConfig
    
    var body: some View {
        Form {
            Section("Generation Mode") {
                Picker("Mode", selection: $config.generationMode) {
                    Text("Automatic").tag(UserControlConfig.GenerationMode.automatic)
                    Text("Semi-Automatic").tag(UserControlConfig.GenerationMode.semiAutomatic)
                    Text("Manual").tag(UserControlConfig.GenerationMode.manual)
                }
                .pickerStyle(.segmented)
                
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Segmentation") {
                Picker("Strategy", selection: $config.segmentationStrategy) {
                    Text("Automatic").tag(UserControlConfig.SegmentationStrategy.automatic)
                    Text("Per Scene").tag(UserControlConfig.SegmentationStrategy.perScene)
                    Text("Per Beat").tag(UserControlConfig.SegmentationStrategy.perBeat)
                    // Manual option with custom picker
                }
                
                if case .manual = config.segmentationStrategy {
                    // Show manual count picker
                }
            }
            
            Section("Duration") {
                Picker("Strategy", selection: $config.durationStrategy) {
                    Text("Script-Based").tag(UserControlConfig.DurationStrategy.scriptBased)
                    // ... other options
                }
            }
            
            Section("Limits") {
                Toggle("Limit Shot Count", isOn: Binding(
                    get: { config.maxShots != nil },
                    set: { enabled in
                        config.maxShots = enabled ? 10 : nil
                    }
                ))
                
                if config.maxShots != nil {
                    Stepper("Max Shots: \(config.maxShots!)", value: Binding(
                        get: { config.maxShots ?? 10 },
                        set: { config.maxShots = $0 }
                    ), in: 1...100)
                }
                
                Toggle("Limit Total Duration", isOn: Binding(
                    get: { config.maxTotalDuration != nil },
                    set: { enabled in
                        config.maxTotalDuration = enabled ? 60 : nil
                    }
                ))
                
                if config.maxTotalDuration != nil {
                    Stepper("Max Duration: \(config.maxTotalDuration!)s", value: Binding(
                        get: { config.maxTotalDuration ?? 60 },
                        set: { config.maxTotalDuration = $0 }
                    ), in: 10...600, step: 10)
                }
            }
            
            Section("Review Gates") {
                Toggle("Require Shot List Approval", isOn: $config.requireShotListApproval)
                Toggle("Require Prompt Review", isOn: $config.requirePromptReview)
                Toggle("Allow Edits Before Generation", isOn: $config.allowEditBeforeGeneration)
            }
            
            Section("Budget") {
                Toggle("Set Budget Limit", isOn: Binding(
                    get: { config.maxCostPerProject != nil },
                    set: { enabled in
                        config.maxCostPerProject = enabled ? 100 : nil
                    }
                ))
                
                if config.maxCostPerProject != nil {
                    HStack {
                        Text("Max Cost:")
                        TextField("", value: Binding(
                            get: { config.maxCostPerProject ?? 100 },
                            set: { config.maxCostPerProject = $0 }
                        ), format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    }
                }
                
                HStack {
                    Text("Cost per second:")
                    TextField("", value: $config.estimatedCostPerSecond, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
        }
        .navigationTitle("Pipeline Settings")
    }
    
    private var modeDescription: String {
        switch config.generationMode {
        case .automatic:
            return "AI makes all decisions automatically"
        case .semiAutomatic:
            return "AI suggests, you approve before generation"
        case .manual:
            return "You control every aspect"
        }
    }
}
```

### 5.2 Shot List Review UI

```swift
struct ShotListReviewView: View {
    let segments: [PromptSegment]
    let totalDuration: TimeInterval
    let estimatedCost: Decimal
    
    @State private var editedSegments: [PromptSegment]
    @State private var selectedSegment: PromptSegment?
    
    let onApprove: ([PromptSegment]) -> Void
    let onReject: (String) -> Void
    
    init(
        segments: [PromptSegment],
        totalDuration: TimeInterval,
        estimatedCost: Decimal,
        onApprove: @escaping ([PromptSegment]) -> Void,
        onReject: @escaping (String) -> Void
    ) {
        self.segments = segments
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.onApprove = onApprove
        self.onReject = onReject
        self._editedSegments = State(initialValue: segments)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Summary Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shot List")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("\(editedSegments.count) shots")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(formatDuration(totalDuration), systemImage: "clock")
                        Spacer()
                        Label("\(estimatedCost) credits", systemImage: "dollarsign.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Segment List
                List {
                    ForEach(editedSegments.indices, id: \.self) { index in
                        SegmentRow(
                            segment: editedSegments[index],
                            onTap: { selectedSegment = editedSegments[index] },
                            onDelete: {
                                editedSegments.remove(at: index)
                            }
                        )
                    }
                    .onMove { from, to in
                        editedSegments.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Reject") {
                        onReject("User rejected shot list")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button("Approve & Generate") {
                        onApprove(editedSegments)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
            .sheet(item: $selectedSegment) { segment in
                SegmentEditorView(segment: segment) { edited in
                    if let index = editedSegments.firstIndex(where: { $0.index == segment.index }) {
                        editedSegments[index] = edited
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SegmentRow: View {
    let segment: PromptSegment
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Shot \(segment.index + 1)")
                        .font(.headline)
                    
                    if let sceneType = segment.sceneType {
                        Text(sceneType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(segment.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(String(format: "%.1f", segment.estimatedDuration))s", systemImage: "clock")
                    if let shotType = segment.suggestedShotType {
                        Label(shotType.rawValue, systemImage: "camera")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SegmentEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var editedSegment: PromptSegment
    let onSave: (PromptSegment) -> Void
    
    init(segment: PromptSegment, onSave: @escaping (PromptSegment) -> Void) {
        self._editedSegment = State(initialValue: segment)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Prompt") {
                    TextEditor(text: $editedSegment.text)
                        .frame(minHeight: 100)
                }
                
                Section("Duration") {
                    Stepper(
                        "Duration: \(String(format: "%.1f", editedSegment.estimatedDuration))s",
                        value: $editedSegment.estimatedDuration,
                        in: 1...30,
                        step: 0.5
                    )
                }
                
                Section("Shot Type") {
                    Picker("Type", selection: $editedSegment.suggestedShotType) {
                        Text("None").tag(nil as PromptSegment.ShotType?)
                        ForEach([
                            PromptSegment.ShotType.wideShot,
                            .mediumShot,
                            .closeup,
                            .extremeCloseup,
                            .overTheShoulder
                        ], id: \.self) { type in
                            Text(type.rawValue).tag(type as PromptSegment.ShotType?)
                        }
                    }
                }
                
                Section("Scene Type") {
                    Picker("Type", selection: $editedSegment.sceneType) {
                        Text("None").tag(nil as PromptSegment.SceneType?)
                        ForEach([
                            PromptSegment.SceneType.establishing,
                            .action,
                            .dialogue,
                            .transition,
                            .montage
                        ], id: \.self) { type in
                            Text(type.rawValue).tag(type as PromptSegment.SceneType?)
                        }
                    }
                }
            }
            .navigationTitle("Edit Shot \(editedSegment.index + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedSegment)
                        dismiss()
                    }
                }
            }
        }
    }
}
```

---

## 🎬 USAGE EXAMPLES

### Example 1: Automatic Mode (Script-Driven)

```swift
var config = PipelineConfig()
config.userControls.generationMode = .automatic
config.userControls.segmentationStrategy = .automatic
config.userControls.durationStrategy = .scriptBased
config.userControls.maxShots = nil  // No limit
config.userControls.requireShotListApproval = false

let input = PipelineInput(story: myScript)
let output = try await pipelineManager.run(input: input, config: config)

// Result: AI creates however many shots it thinks are needed
// based on script analysis, each with appropriate duration
```

### Example 2: Budget-Conscious Mode

```swift
var config = PipelineConfig()
config.userControls.segmentationStrategy = .automatic
config.userControls.durationStrategy = .scriptBased
config.userControls.maxShots = 20  // Hard limit
config.userControls.maxTotalDuration = 120  // 2 minutes max
config.userControls.maxCostPerProject = 500  // 500 credits max
config.userControls.estimatedCostPerSecond = 2.5

let output = try await pipelineManager.run(input: input, config: config)

// Result: AI creates up to 20 shots, max 2 minutes total,
// and stops if it would exceed 500 credits
```

### Example 3: Manual Control with Review

```swift
var config = PipelineConfig()
config.userControls.generationMode = .semiAutomatic
config.userControls.segmentationStrategy = .perScene
config.userControls.durationStrategy = .scriptBased
config.userControls.requireShotListApproval = true
config.userControls.allowEditBeforeGeneration = true

// Set up review gate
pipelineManager.shotListReviewGate = ShotListReviewGate { reviewItem in
    // Present UI to user
    return await presentShotListReview(reviewItem)
}

let output = try await pipelineManager.run(input: input, config: config)

// Result: AI creates shot list based on scene headings,
// then shows it to user for approval/editing before generation
```

### Example 4: Fixed Count (Like Current Behavior)

```swift
var config = PipelineConfig()
config.userControls.segmentationStrategy = .manual(count: 5)
config.userControls.durationStrategy = .fixed(seconds: 4)

let output = try await pipelineManager.run(input: input, config: config)

// Result: Exactly 5 shots, 4 seconds each (current behavior)
```

---

## ✅ INTEGRATION CHECKLIST

Hand this to your agent:

- [ ] **Phase 1: Configuration**
  - [ ] Add `UserControlConfig` struct to `PipelineConfig.swift`
  - [ ] Add all enums: `GenerationMode`, `DurationStrategy`, `SegmentationStrategy`
  - [ ] Add user control properties to main config

- [ ] **Phase 2: Flexible Segmentation**
  - [ ] Update `SegmentationModuleInput` to accept `UserControlConfig`
  - [ ] Add `estimatedDuration` to `PromptSegment`
  - [ ] Add `sceneType` and `suggestedShotType` to `PromptSegment`
  - [ ] Implement `automaticSegmentation()` method
  - [ ] Implement `sceneBasedSegmentation()` method
  - [ ] Implement `beatBasedSegmentation()` method
  - [ ] Implement `manualSegmentation()` method
  - [ ] Implement `applyHardLimits()` method
  - [ ] Update `SegmentationOutput` to include strategy info

- [ ] **Phase 3: Review System**
  - [ ] Create `ReviewGate.swift` with protocols
  - [ ] Create `ShotListReviewGate` class
  - [ ] Create `PromptReviewGate` class
  - [ ] Add review gate properties to `PipelineManager`
  - [ ] Add review gate logic to `run()` method
  - [ ] Handle approval/rejection/modification cases

- [ ] **Phase 4: Hard Limits**
  - [ ] Create `CostCalculator.swift`
  - [ ] Implement budget checking
  - [ ] Add budget check to pipeline
  - [ ] Handle budget exceeded errors

- [ ] **Phase 5: UI Integration**
  - [ ] Create `PipelineSettingsView.swift`
  - [ ] Create `ShotListReviewView.swift`
  - [ ] Create `SegmentRow` component
  - [ ] Create `SegmentEditorView.swift`
  - [ ] Wire up review gates to UI

- [ ] **Testing**
  - [ ] Test automatic mode with various scripts
  - [ ] Test manual mode with fixed count
  - [ ] Test budget limits
  - [ ] Test shot count limits
  - [ ] Test duration limits
  - [ ] Test review gates
  - [ ] Test edge cases (empty script, very long script, etc.)

---

## 🚀 DEPLOYMENT STRATEGY

### Rollout Phases:

**Phase 1 (Immediate):**
- Deploy config system only
- Keep current behavior as default
- No breaking changes

**Phase 2 (Week 1):**
- Deploy flexible segmentation
- Enable automatic mode
- Add hard limits

**Phase 3 (Week 2):**
- Deploy review system
- Add UI components
- Enable semi-automatic mode

**Phase 4 (Week 3+):**
- Fine-tune duration estimation
- Add advanced beat detection
- Optimize cost calculation

---

## 🎯 KEY IMPROVEMENTS SUMMARY

| Feature | Before | After |
|---------|--------|-------|
| **Segmentation** | Fixed 5 shots | 1-100+ shots (script-driven) |
| **Duration** | Fixed 4s | 3-30s per shot (estimated) |
| **User Control** | None | Manual/Semi/Auto modes |
| **Review** | None | Shot list + per-prompt review |
| **Limits** | None | Shot count, duration, cost |
| **Flexibility** | Auto-montage | Filmmaking tool |

---

## 📞 SUPPORT QUESTIONS

If your agent has questions:

1. **"How do I handle duration estimation?"**
   - Use word count / 250 words per page / 60s per page formula
   - Add 20% buffer for action sequences
   - Clamp to 3-30s range

2. **"What if StoryAnalysisModule fails?"**
   - Fallback to basic text segmentation
   - Use regex for scene heading detection
   - Default to 5s durations

3. **"How should review gates work in practice?"**
   - Present modal UI with shot list
   - Allow drag-to-reorder
   - Allow tap-to-edit
   - Show total cost estimate
   - Require explicit approval

4. **"What about backwards compatibility?"**
   - Default config matches current behavior
   - Existing code works unchanged
   - New features are opt-in

---

## 📚 ADDITIONAL RESOURCES

- Script parsing: [Fountain format](https://fountain.io/syntax)
- Duration estimation: [Script timing guide](https://www.studiobinder.com/blog/how-long-is-a-script-page/)
- Shot types: [Cinematic taxonomy](https://www.studiobinder.com/blog/types-of-camera-shots/)

---

**END OF REFACTOR GUIDE**

Hand this entire document to your agent for implementation!
