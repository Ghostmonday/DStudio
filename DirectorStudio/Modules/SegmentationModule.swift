//
//  SegmentationModule.swift
//  DirectorStudio
//
//  UPGRADED: Intelligent segmentation with adaptive pacing and cinematic flow
//  Handles any narrative structure with smart boundary detection
//

import Foundation
import OSLog

// MARK: - Segmentation Module

/// Advanced segmentation with intelligent pacing, scene transitions, and adaptive chunking
/// Creates video-ready segments optimized for visual storytelling
public struct SegmentationModule: PipelineModule {
    public typealias Input = SegmentationInput
    public typealias Output = SegmentationOutput
    
    public let moduleID = "com.directorstudio.segmentation"
    public let moduleName = "Segmentation"
    public let version = "2.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "segmentation")
    
    public init() {}
    
    public func execute(
        input: SegmentationInput,
        context: PipelineContext
    ) async -> Result<SegmentationOutput, PipelineError> {
        logger.info("✂️ Starting intelligent segmentation [v2.0] (target: \(input.maxDuration)s)")
        
        let startTime = Date()
        
        do {
            // Validate input
            let warnings = validate(input: input)
            if !warnings.isEmpty {
                logger.warning("⚠️ Validation warnings: \(warnings.joined(separator: ", "))")
            }
            
            // Analyze story structure for optimal segmentation
            let analysis = analyzeSegmentationOpportunities(input.story)
            logger.debug("📊 Analysis: \(analysis.naturalBreaks.count) natural breaks, \(analysis.paragraphs.count) paragraphs")
            
            // Perform intelligent segmentation
            let segments = try await performIntelligentSegmentation(
                story: input.story,
                maxDuration: input.maxDuration,
                analysis: analysis,
                context: context
            )
            
            // Enhance segments with pacing metadata
            let enhancedSegments = enhanceWithPacingMetadata(segments, analysis: analysis)
            
            // Calculate quality metrics
            let metrics = calculateSegmentationMetrics(enhancedSegments, targetDuration: input.maxDuration)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            let output = SegmentationOutput(
                segments: enhancedSegments,
                totalSegments: enhancedSegments.count,
                averageDuration: metrics.averageDuration,
                metrics: metrics
            )
            
            logger.info("✅ Intelligent segmentation completed in \(String(format: "%.2f", executionTime))s")
            logger.debug("📈 Created \(enhancedSegments.count) segments (avg: \(String(format: "%.1f", metrics.averageDuration))s, quality: \(String(format: "%.2f", metrics.qualityScore)))")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Segmentation failed: \(error.localizedDescription)")
            
            // Fallback segmentation
            logger.warning("🔄 Attempting fallback segmentation")
            let fallbackSegments = performFallbackSegmentation(
                story: input.story,
                maxDuration: input.maxDuration
            )
            
            let output = SegmentationOutput(
                segments: fallbackSegments,
                totalSegments: fallbackSegments.count,
                averageDuration: input.maxDuration,
                metrics: SegmentationMetrics(
                    averageDuration: input.maxDuration,
                    minDuration: input.maxDuration * 0.8,
                    maxDuration: input.maxDuration,
                    standardDeviation: 0,
                    qualityScore: 0.5,
                    boundaryQuality: 0.5,
                    pacingConsistency: 0.5
                )
            )
            
            return .success(output)
        }
    }
    
    public func validate(input: SegmentationInput) -> [String] {
        var warnings: [String] = []
        
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            warnings.append("Story is empty - cannot segment")
        }
        
        if input.maxDuration <= 0 {
            warnings.append("Max duration must be positive")
        } else if input.maxDuration < 5 {
            warnings.append("Max duration < 5s may create too many fragments")
        } else if input.maxDuration > 60 {
            warnings.append("Max duration > 60s may create very long segments")
        }
        
        return warnings
    }
    
    // MARK: - Structure Analysis
    
    /// Analyzes story for optimal segmentation opportunities
    private func analyzeSegmentationOpportunities(_ story: String) -> SegmentationAnalysis {
        let paragraphs = story.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let sentences = story.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Detect natural breaks (paragraph boundaries, scene transitions)
        var naturalBreaks: [NaturalBreak] = []
        
        // Paragraph boundaries are natural breaks
        var currentPosition = 0
        for (index, paragraph) in paragraphs.enumerated() {
            if index > 0 {
                naturalBreaks.append(NaturalBreak(
                    position: currentPosition,
                    type: .paragraph,
                    strength: 0.8
                ))
            }
            currentPosition += paragraph.count + 2 // +2 for \n\n
        }
        
        // Detect scene transitions (time markers, location changes)
        let transitionMarkers = ["Meanwhile", "Later", "The next day", "Suddenly", "Then"]
        for marker in transitionMarkers {
            if let range = story.range(of: marker, options: .caseInsensitive) {
                let position = story.distance(from: story.startIndex, to: range.lowerBound)
                naturalBreaks.append(NaturalBreak(
                    position: position,
                    type: .sceneTransition,
                    strength: 1.0
                ))
            }
        }
        
        // Detect dialogue transitions (speaker changes)
        let dialoguePattern = "\""
        var lastQuotePosition = -100
        for (index, char) in story.enumerated() {
            if char == "\"" {
                if index - lastQuotePosition > 50 { // New dialogue block
                    naturalBreaks.append(NaturalBreak(
                        position: index,
                        type: .dialogueShift,
                        strength: 0.6
                    ))
                }
                lastQuotePosition = index
            }
        }
        
        // Sort breaks by position
        naturalBreaks.sort { $0.position < $1.position }
        
        return SegmentationAnalysis(
            paragraphs: paragraphs,
            sentences: sentences,
            naturalBreaks: naturalBreaks,
            averageParagraphLength: paragraphs.isEmpty ? 0 : 
                paragraphs.reduce(0) { $0 + $1.count } / paragraphs.count,
            hasDialogue: story.contains("\""),
            narrativeStyle: detectNarrativeStyle(paragraphs, sentences: sentences)
        )
    }
    
    // MARK: - Intelligent Segmentation
    
    /// Performs segmentation respecting narrative flow and natural boundaries
    private func performIntelligentSegmentation(
        story: String,
        maxDuration: TimeInterval,
        analysis: SegmentationAnalysis,
        context: PipelineContext
    ) async throws -> [PromptSegment] {
        
        var segments: [PromptSegment] = []
        
        // Choose segmentation strategy based on narrative style
        switch analysis.narrativeStyle {
        case .structured:
            segments = segmentByParagraphs(story, analysis: analysis, maxDuration: maxDuration)
        case .dialogue:
            segments = segmentByDialogue(story, analysis: analysis, maxDuration: maxDuration)
        case .stream:
            segments = segmentBySentences(story, analysis: analysis, maxDuration: maxDuration)
        case .fragmented:
            segments = segmentByNaturalPauses(story, analysis: analysis, maxDuration: maxDuration)
        }
        
        // Ensure segments meet duration constraints
        segments = enforceMaxDuration(segments, maxDuration: maxDuration)
        
        // Optimize segment boundaries
        segments = optimizeBoundaries(segments, story: story, analysis: analysis)
        
        return segments
    }
    
    // MARK: - Segmentation Strategies
    
    /// Segments by paragraph boundaries (ideal for structured narratives)
    private func segmentByParagraphs(
        _ story: String,
        analysis: SegmentationAnalysis,
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        var segments: [PromptSegment] = []
        var currentSegment = ""
        var order = 1
        
        for paragraph in analysis.paragraphs {
            let testSegment = currentSegment.isEmpty ? paragraph : "\(currentSegment)\n\n\(paragraph)"
            let estimatedDuration = estimateDuration(for: testSegment)
            
            if estimatedDuration <= maxDuration {
                currentSegment = testSegment
            } else {
                // Save current and start new
                if !currentSegment.isEmpty {
                    segments.append(createSegment(
                        text: currentSegment,
                        order: order,
                        duration: estimateDuration(for: currentSegment)
                    ))
                    order += 1
                }
                currentSegment = paragraph
            }
        }
        
        // Add final segment
        if !currentSegment.isEmpty {
            segments.append(createSegment(
                text: currentSegment,
                order: order,
                duration: estimateDuration(for: currentSegment)
            ))
        }
        
        return segments
    }
    
    /// Segments by dialogue exchanges (ideal for dialogue-heavy stories)
    private func segmentByDialogue(
        _ story: String,
        analysis: SegmentationAnalysis,
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        var segments: [PromptSegment] = []
        
        // Split on dialogue markers
        let lines = story.components(separatedBy: "\n")
        var currentSegment = ""
        var order = 1
        
        for line in lines {
            let hasQuote = line.contains("\"")
            let testSegment = currentSegment.isEmpty ? line : "\(currentSegment)\n\(line)"
            let estimatedDuration = estimateDuration(for: testSegment)
            
            if estimatedDuration <= maxDuration {
                currentSegment = testSegment
            } else {
                if !currentSegment.isEmpty {
                    segments.append(createSegment(
                        text: currentSegment,
                        order: order,
                        duration: estimateDuration(for: currentSegment)
                    ))
                    order += 1
                }
                currentSegment = line
            }
            
            // Break after dialogue exchanges
            if hasQuote && estimatedDuration > maxDuration * 0.5 {
                if !currentSegment.isEmpty {
                    segments.append(createSegment(
                        text: currentSegment,
                        order: order,
                        duration: estimateDuration(for: currentSegment)
                    ))
                    order += 1
                    currentSegment = ""
                }
            }
        }
        
        if !currentSegment.isEmpty {
            segments.append(createSegment(
                text: currentSegment,
                order: order,
                duration: estimateDuration(for: currentSegment)
            ))
        }
        
        return segments
    }
    
    /// Segments by sentence boundaries (ideal for stream-of-consciousness)
    private func segmentBySentences(
        _ story: String,
        analysis: SegmentationAnalysis,
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        var segments: [PromptSegment] = []
        var currentSegment = ""
        var order = 1
        
        for sentence in analysis.sentences {
            let testSegment = currentSegment.isEmpty ? sentence : "\(currentSegment) \(sentence)"
            let estimatedDuration = estimateDuration(for: testSegment)
            
            if estimatedDuration <= maxDuration {
                currentSegment = testSegment
            } else {
                if !currentSegment.isEmpty {
                    segments.append(createSegment(
                        text: currentSegment,
                        order: order,
                        duration: estimateDuration(for: currentSegment)
                    ))
                    order += 1
                }
                currentSegment = sentence
            }
        }
        
        if !currentSegment.isEmpty {
            segments.append(createSegment(
                text: currentSegment,
                order: order,
                duration: estimateDuration(for: currentSegment)
            ))
        }
        
        return segments
    }
    
    /// Segments by natural pauses and breaks (ideal for fragmented text)
    private func segmentByNaturalPauses(
        _ story: String,
        analysis: SegmentationAnalysis,
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        // For fragmented text, use short sentences as natural break points
        return segmentBySentences(story, analysis: analysis, maxDuration: maxDuration)
    }
    
    // MARK: - Duration Management
    
    /// Enforces maximum duration by splitting long segments
    private func enforceMaxDuration(
        _ segments: [PromptSegment],
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        var result: [PromptSegment] = []
        var order = 1
        
        for segment in segments {
            if segment.duration <= maxDuration {
                var adjusted = segment
                adjusted.order = order
                result.append(adjusted)
                order += 1
            } else {
                // Split oversized segment
                let words = segment.text.components(separatedBy: .whitespacesAndNewlines)
                let targetWordCount = Int(Double(words.count) * (maxDuration / segment.duration))
                
                var currentChunk = ""
                var currentWords: [String] = []
                
                for word in words {
                    currentWords.append(word)
                    currentChunk = currentWords.joined(separator: " ")
                    
                    if estimateDuration(for: currentChunk) >= maxDuration * 0.9 {
                        result.append(createSegment(
                            text: currentChunk,
                            order: order,
                            duration: estimateDuration(for: currentChunk)
                        ))
                        order += 1
                        currentWords = []
                        currentChunk = ""
                    }
                }
                
                if !currentChunk.isEmpty {
                    result.append(createSegment(
                        text: currentChunk,
                        order: order,
                        duration: estimateDuration(for: currentChunk)
                    ))
                    order += 1
                }
            }
        }
        
        return result
    }
    
    /// Optimizes segment boundaries for better flow
    private func optimizeBoundaries(
        _ segments: [PromptSegment],
        story: String,
        analysis: SegmentationAnalysis
    ) -> [PromptSegment] {
        // For now, return as-is
        // Future: smart boundary adjustment based on natural breaks
        return segments
    }
    
    // MARK: - Enhancement
    
    /// Enhances segments with pacing and transition metadata
    private func enhanceWithPacingMetadata(
        _ segments: [PromptSegment],
        analysis: SegmentationAnalysis
    ) -> [PromptSegment] {
        return segments.enumerated().map { index, segment in
            var enhanced = segment
            
            // Calculate pacing
            let pacing = calculatePacing(segment, index: index, total: segments.count)
            
            // Detect transition type
            let transitionType = detectTransitionType(segment, previousSegment: index > 0 ? segments[index - 1] : nil)
            
            // Add metadata
            enhanced.metadata = [
                "pacing": pacing.rawValue,
                "transitionType": transitionType.rawValue,
                "relativePosition": String(format: "%.2f", Double(index) / Double(max(segments.count - 1, 1)))
            ]
            
            return enhanced
        }
    }
    
    // MARK: - Helper Methods
    
    /// Estimates reading/viewing duration for text
    private func estimateDuration(for text: String) -> TimeInterval {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Reading rate: ~150 words per minute = 2.5 words per second
        // But for video, we want slightly slower pacing
        let wordsPerSecond = 2.0
        
        return Double(words.count) / wordsPerSecond
    }
    
    /// Creates a segment with proper formatting
    private func createSegment(
        text: String,
        order: Int,
        duration: TimeInterval
    ) -> PromptSegment {
        PromptSegment(
            id: UUID(),
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            order: order,
            metadata: [:]
        )
    }
    
    /// Detects narrative style from structure
    private func detectNarrativeStyle(
        _ paragraphs: [String],
        sentences: [String]
    ) -> NarrativeStyle {
        let avgParagraphLength = paragraphs.isEmpty ? 0 : 
            paragraphs.reduce(0) { $0 + $1.count } / paragraphs.count
        
        let hasDialogue = paragraphs.contains { $0.contains("\"") }
        let avgSentenceLength = sentences.isEmpty ? 0 : 
            sentences.reduce(0) { $0 + $1.count } / sentences.count
        
        if hasDialogue && paragraphs.filter({ $0.contains("\"") }).count > paragraphs.count / 2 {
            return .dialogue
        } else if avgSentenceLength < 30 {
            return .fragmented
        } else if avgParagraphLength < 200 {
            return .stream
        } else {
            return .structured
        }
    }
    
    /// Calculates pacing for a segment
    private func calculatePacing(
        _ segment: PromptSegment,
        index: Int,
        total: Int
    ) -> SegmentPacing {
        let position = Double(index) / Double(max(total - 1, 1))
        let wordCount = segment.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        // Fast pacing: short, punchy
        if wordCount < 20 {
            return .fast
        }
        
        // Slow pacing: descriptive, contemplative
        if wordCount > 60 {
            return .slow
        }
        
        // Building tension (middle of story)
        if position > 0.3 && position < 0.7 {
            return .building
        }
        
        return .moderate
    }
    
    /// Detects transition type between segments
    private func detectTransitionType(
        _ segment: PromptSegment,
        previousSegment: PromptSegment?
    ) -> TransitionType {
        guard let previous = previousSegment else { return .hard }
        
        let currentStart = String(segment.text.prefix(50)).lowercased()
        
        // Check for temporal transitions
        if currentStart.contains("meanwhile") || currentStart.contains("later") {
            return .temporal
        }
        
        // Check for location changes
        if currentStart.contains("at ") || currentStart.contains("in the") {
            return .spatial
        }
        
        // Check for dialogue
        if segment.text.contains("\"") && previous.text.contains("\"") {
            return .dialogue
        }
        
        // Default to cut
        return .cut
    }
    
    /// Calculates segmentation quality metrics
    private func calculateSegmentationMetrics(
        _ segments: [PromptSegment],
        targetDuration: TimeInterval
    ) -> SegmentationMetrics {
        guard !segments.isEmpty else {
            return SegmentationMetrics(
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                standardDeviation: 0,
                qualityScore: 0,
                boundaryQuality: 0,
                pacingConsistency: 0
            )
        }
        
        let durations = segments.map { $0.duration }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0
        
        // Calculate standard deviation
        let variance = durations.reduce(0.0) { sum, duration in
            sum + pow(duration - avgDuration, 2)
        } / Double(durations.count)
        let stdDev = sqrt(variance)
        
        // Quality score (how close to target duration)
        let avgDeviation = abs(avgDuration - targetDuration) / targetDuration
        let qualityScore = max(0.0, 1.0 - avgDeviation)
        
        // Boundary quality (consistency of segment lengths)
        let boundaryQuality = max(0.0, 1.0 - (stdDev / avgDuration))
        
        // Pacing consistency
        let pacingConsistency = boundaryQuality // Simplified for now
        
        return SegmentationMetrics(
            averageDuration: avgDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            standardDeviation: stdDev,
            qualityScore: qualityScore,
            boundaryQuality: boundaryQuality,
            pacingConsistency: pacingConsistency
        )
    }
    
    // MARK: - Fallback
    
    /// Simple fallback segmentation
    private func performFallbackSegmentation(
        story: String,
        maxDuration: TimeInterval
    ) -> [PromptSegment] {
        let charsPerSecond = 150 // Rough estimate
        let maxChars = Int(maxDuration * Double(charsPerSecond))
        
        var segments: [PromptSegment] = []
        var remaining = story
        var order = 1
        
        while !remaining.isEmpty {
            var chunk: String
            
            if remaining.count <= maxChars {
                chunk = remaining
                remaining = ""
            } else {
                // Try to break at sentence
                if let lastPeriod = remaining[..<remaining.index(remaining.startIndex, offsetBy: maxChars)].lastIndex(of: ".") {
                    chunk = String(remaining[..<remaining.index(after: lastPeriod)])
                    remaining = String(remaining[remaining.index(after: lastPeriod)...])
                } else {
                    chunk = String(remaining.prefix(maxChars))
                    remaining = String(remaining.dropFirst(maxChars))
                }
            }
            
            segments.append(createSegment(
                text: chunk.trimmingCharacters(in: .whitespacesAndNewlines),
                order: order,
                duration: maxDuration
            ))
            order += 1
        }
        
        return segments
    }
}

// MARK: - Supporting Types

public struct SegmentationInput: Sendable {
    public let story: String
    public let maxDuration: TimeInterval
    
    public init(story: String, maxDuration: TimeInterval) {
        self.story = story
        self.maxDuration = maxDuration
    }
}

public struct SegmentationOutput: Sendable {
    public let segments: [PromptSegment]
    public let totalSegments: Int
    public let averageDuration: TimeInterval
    public let metrics: SegmentationMetrics
    
    public init(
        segments: [PromptSegment],
        totalSegments: Int,
        averageDuration: TimeInterval,
        metrics: SegmentationMetrics = SegmentationMetrics()
    ) {
        self.segments = segments
        self.totalSegments = totalSegments
        self.averageDuration = averageDuration
        self.metrics = metrics
    }
}

public struct PromptSegment: Sendable, Identifiable, Codable {
    public let id: UUID
    public var text: String
    public var duration: TimeInterval
    public var order: Int
    public var metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        text: String,
        duration: TimeInterval,
        order: Int,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.text = text
        self.duration = duration
        self.order = order
        self.metadata = metadata
    }
}

public struct SegmentationMetrics: Sendable, Codable {
    public let averageDuration: TimeInterval
    public let minDuration: TimeInterval
    public let maxDuration: TimeInterval
    public let standardDeviation: TimeInterval
    public let qualityScore: Double // 0.0 to 1.0
    public let boundaryQuality: Double // 0.0 to 1.0
    public let pacingConsistency: Double // 0.0 to 1.0
    
    public init(
        averageDuration: TimeInterval = 0,
        minDuration: TimeInterval = 0,
        maxDuration: TimeInterval = 0,
        standardDeviation: TimeInterval = 0,
        qualityScore: Double = 0,
        boundaryQuality: Double = 0,
        pacingConsistency: Double = 0
    ) {
        self.averageDuration = averageDuration
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.standardDeviation = standardDeviation
        self.qualityScore = qualityScore
        self.boundaryQuality = boundaryQuality
        self.pacingConsistency = pacingConsistency
    }
}

private struct SegmentationAnalysis {
    let paragraphs: [String]
    let sentences: [String]
    let naturalBreaks: [NaturalBreak]
    let averageParagraphLength: Int
    let hasDialogue: Bool
    let narrativeStyle: NarrativeStyle
}

private struct NaturalBreak {
    let position: Int
    let type: BreakType
    let strength: Double // 0.0 to 1.0
}

private enum BreakType {
    case paragraph
    case sceneTransition
    case dialogueShift
}

private enum NarrativeStyle {
    case structured
    case dialogue
    case stream
    case fragmented
}

private enum SegmentPacing: String, Sendable {
    case fast = "Fast"
    case moderate = "Moderate"
    case slow = "Slow"
    case building = "Building"
}

private enum TransitionType: String, Sendable {
    case cut = "Cut"
    case fade = "Fade"
    case temporal = "Temporal"
    case spatial = "Spatial"
    case dialogue = "Dialogue"
    case hard = "Hard"
}
