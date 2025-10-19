//
//  SegmentationModule.swift
//  DirectorStudio
//
//  FLEXIBLE SEGMENTATION: Script-driven shot list generation
//  Supports automatic, scene-based, beat-based, and manual segmentation
//

import Foundation
import OSLog

// MARK: - Enhanced Segmentation Module

/// Flexible segmentation with user control and script-driven generation
/// Supports multiple strategies: automatic, scene-based, beat-based, and manual
public struct SegmentationModule: PipelineModule {
    public typealias Input = SegmentationModuleInput
    public typealias Output = SegmentationOutput
    
    public let moduleID = "com.directorstudio.segmentation"
    public let moduleName = "Segmentation"
    public let version = "3.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "segmentation")
    
    public init() {}
    
    public func execute(
        input: SegmentationModuleInput,
        context: PipelineContext
    ) async -> Result<SegmentationOutput, PipelineError> {
        logger.info("✂️ Starting flexible segmentation [v3.0] (strategy: \(input.userControls.segmentationStrategy))")
        
        let startTime = Date()
        
        do {
            // Validate input
            let warnings = validate(input: input)
            if !warnings.isEmpty {
                logger.warning("⚠️ Validation warnings: \(warnings.joined(separator: ", "))")
            }
            
            // Determine segmentation strategy
            let segments: [PromptSegment]
            
            switch input.userControls.segmentationStrategy {
            case .automatic:
                segments = try await automaticSegmentation(input, context)
                
            case .perScene:
                segments = try await sceneBasedSegmentation(input, context)
                
            case .perBeat:
                segments = try await beatBasedSegmentation(input, context)
                
            case .manual:
                segments = try await manualSegmentation(input, context, targetCount: input.userControls.manualShotCount)
            }
            
            // Apply hard limits if specified
            let limitedSegments = applyHardLimits(segments, config: input.userControls)
            
            // Calculate quality metrics
            let metrics = calculateQualityMetrics(limitedSegments)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            let output = SegmentationOutput(
                segments: limitedSegments,
                strategy: input.userControls.segmentationStrategy,
                totalEstimatedDuration: limitedSegments.reduce(0) { $0 + $1.estimatedDuration },
                qualityMetrics: metrics
            )
            
            logger.info("✅ Flexible segmentation completed in \(String(format: "%.2f", executionTime))s")
            logger.debug("📈 Created \(limitedSegments.count) segments (total: \(String(format: "%.1f", output.totalEstimatedDuration))s)")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Segmentation failed: \(error.localizedDescription)")
            
            // Fallback segmentation
            logger.warning("🔄 Attempting fallback segmentation")
            let fallbackSegments = performFallbackSegmentation(
                story: input.story,
                userControls: input.userControls
            )
            
            let output = SegmentationOutput(
                segments: fallbackSegments,
                strategy: input.userControls.segmentationStrategy,
                totalEstimatedDuration: fallbackSegments.reduce(0) { $0 + $1.estimatedDuration },
                qualityMetrics: [:]
            )
            
            return .success(output)
        }
    }
    
    public func validate(input: SegmentationModuleInput) -> [String] {
        var warnings: [String] = []
        
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            warnings.append("Story is empty - cannot segment")
        }
        
        if input.userControls.minShotDuration > input.userControls.maxShotDuration {
            warnings.append("Min shot duration cannot be greater than max shot duration")
        }
        
        if input.userControls.manualShotCount <= 0 {
            warnings.append("Manual shot count must be positive")
        }
        
        if let maxShots = input.userControls.maxShots, maxShots <= 0 {
            warnings.append("Max shots must be positive")
        }
        
        if let maxDuration = input.userControls.maxTotalDuration, maxDuration <= 0 {
            warnings.append("Max total duration must be positive")
        }
        
        return warnings
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
            
        case .fixed:
            return TimeInterval(input.userControls.fixedDurationSeconds)
            
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
            
        case .fixed:
            return TimeInterval(input.userControls.fixedDurationSeconds)
            
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
    
    private func basicTextSegmentation(
        _ story: String,
        _ userControls: UserControlConfig
    ) async throws -> [PromptSegment] {
        // Simple fallback segmentation
        let words = story.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let segmentSize = max(1, words.count / 5) // Default to 5 segments
        
        var segments: [PromptSegment] = []
        
        for i in 0..<5 {
            let startIndex = i * segmentSize
            let endIndex = min((i + 1) * segmentSize, words.count)
            let segmentWords = Array(words[startIndex..<endIndex])
            let content = segmentWords.joined(separator: " ")
            
            let segment = PromptSegment(
                index: i,
                text: content.isEmpty ? "Scene \(i + 1) content" : content,
                estimatedDuration: estimateDuration(from: content, strategy: userControls.durationStrategy),
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
    
    private func performFallbackSegmentation(
        story: String,
        userControls: UserControlConfig
    ) -> [PromptSegment] {
        // Simple fallback segmentation
        let words = story.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let segmentSize = max(1, words.count / 5) // Default to 5 segments
        
        var segments: [PromptSegment] = []
        
        for i in 0..<5 {
            let startIndex = i * segmentSize
            let endIndex = min((i + 1) * segmentSize, words.count)
            let segmentWords = Array(words[startIndex..<endIndex])
            let content = segmentWords.joined(separator: " ")
            
            let segment = PromptSegment(
                index: i,
                text: content.isEmpty ? "Scene \(i + 1) content" : content,
                estimatedDuration: estimateDuration(from: content, strategy: userControls.durationStrategy),
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
}

// MARK: - Input/Output Structures

public struct SegmentationModuleInput: Sendable {
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

// MARK: - Enhanced PromptSegment

public struct PromptSegment: Codable, Sendable, Identifiable {
    public let id: UUID
    public let index: Int
    public let text: String
    public let estimatedDuration: TimeInterval  // NEW: Flexible duration
    public let sceneType: SceneType?            // NEW: Scene classification
    public let suggestedShotType: ShotType?     // NEW: Suggested framing
    public let pacing: String
    public let transitionHint: String?
    public let metadata: [String: String]
    
    public enum SceneType: String, Codable, CaseIterable {
        case establishing = "establishing"
        case action = "action"
        case dialogue = "dialogue"
        case transition = "transition"
        case montage = "montage"
        
        public var displayName: String {
            switch self {
            case .establishing: return "Establishing"
            case .action: return "Action"
            case .dialogue: return "Dialogue"
            case .transition: return "Transition"
            case .montage: return "Montage"
            }
        }
    }
    
    public enum ShotType: String, Codable, CaseIterable {
        case wideShot = "wideShot"
        case mediumShot = "mediumShot"
        case closeup = "closeup"
        case extremeCloseup = "extremeCloseup"
        case overTheShoulder = "overTheShoulder"
        
        public var displayName: String {
            switch self {
            case .wideShot: return "Wide Shot"
            case .mediumShot: return "Medium Shot"
            case .closeup: return "Close-up"
            case .extremeCloseup: return "Extreme Close-up"
            case .overTheShoulder: return "Over the Shoulder"
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        index: Int,
        text: String,
        estimatedDuration: TimeInterval,
        sceneType: SceneType? = nil,
        suggestedShotType: ShotType? = nil,
        pacing: String,
        transitionHint: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.index = index
        self.text = text
        self.estimatedDuration = estimatedDuration
        self.sceneType = sceneType
        self.suggestedShotType = suggestedShotType
        self.pacing = pacing
        self.transitionHint = transitionHint
        self.metadata = metadata
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

// MARK: - Supporting Types (Placeholder)

public struct StoryAnalysisOutput: Sendable {
    public struct Scene: Sendable {
        public let description: String
        public let characters: [String]
        public let location: String?
        public let timeOfDay: String?
        public let type: String
        public let dialogue: String?
        public let emotionalTone: String?
    }
    
    public let scenes: [Scene]
    
    public init(scenes: [Scene]) {
        self.scenes = scenes
    }
}
