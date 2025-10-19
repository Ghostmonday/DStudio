//
//  ToneRestorationModule.swift
//  DirectorStudio
//
//  PHASE 2: Post-continuity tone restoration
//  Uses tone memory from Phase 1 to restore emotional depth
//  Version: 1.0.0
//

import Foundation
import OSLog

// MARK: - Module Protocol Conformance

public struct ToneRestorationModule: PipelineModule {
    public typealias Input = ToneRestorationInput
    public typealias Output = ToneRestorationOutput
    
    public let moduleID = "com.directorstudio.tone_restoration"
    public let moduleName = "Tone Restoration (Post-Continuity)"
    public let version = "1.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "tone_restoration")
    private let aiService: AIServiceProtocol?
    
    public init(aiService: AIServiceProtocol? = nil) {
        self.aiService = aiService
    }
    
    public func execute(
        input: Input,
        context: PipelineContext
    ) async -> Result<Output, PipelineError> {
        
        logger.info("🎨 Starting tone restoration (post-continuity)")
        let startTime = Date()
        
        do {
            var restoredSegments: [TonallyRestoredSegment] = []
            
            for (index, segment) in input.processedSegments.enumerated() {
                // STEP 1: Match segment to original story section
                let matchedSection = matchToSection(
                    segment: segment,
                    segmentIndex: index,
                    toneMemory: input.toneMemory
                )
                
                // STEP 2: Calculate tone drift
                let toneDrift = calculateToneDrift(
                    segment: segment,
                    targetTone: input.toneMemory.globalToneProfile,
                    section: matchedSection
                )
                
                // STEP 3: Find relevant emotional beats
                let matchedBeats = findRelevantBeats(
                    segment: segment,
                    beats: input.toneMemory.emotionalBeats
                )
                
                // STEP 4: Find relevant carrier phrases
                let matchedPhrases = findRelevantCarrierPhrases(
                    segment: segment,
                    phrases: input.toneMemory.toneCarrierPhrases
                )
                
                // STEP 5: Restore tone if needed
                if toneDrift > context.config.toneDriftThreshold {
                    logger.debug("Scene \(index): High drift (\(String(format: "%.2f", toneDrift))), restoring tone...")
                    
                    let restored = try await restoreSegmentTone(
                        segment: segment,
                        toneMemory: input.toneMemory,
                        matchedSection: matchedSection,
                        matchedBeats: matchedBeats,
                        matchedPhrases: matchedPhrases,
                        aiService: aiService,
                        config: context.config
                    )
                    restoredSegments.append(restored)
                } else {
                    logger.debug("Scene \(index): Low drift (\(String(format: "%.2f", toneDrift))), no restoration needed")
                    
                    // No restoration needed
                    let restored = TonallyRestoredSegment(
                        originalSegment: segment,
                        restoredText: segment.text,
                        toneDrift: toneDrift,
                        restorationInterventions: [],
                        matchedSection: matchedSection,
                        matchedBeats: matchedBeats,
                        confidenceScore: 1.0
                    )
                    restoredSegments.append(restored)
                }
            }
            
            // Build metadata
            let segmentsRestored = restoredSegments.filter { !$0.restorationInterventions.isEmpty }.count
            let totalDrift = restoredSegments.map { $0.toneDrift }.reduce(0, +)
            let totalConfidence = restoredSegments.map { $0.confidenceScore }.reduce(0, +)
            
            let metadata = RestorationMetadata(
                totalSegments: input.processedSegments.count,
                segmentsRestored: segmentsRestored,
                averageToneDrift: totalDrift / Double(restoredSegments.count),
                averageConfidence: totalConfidence / Double(restoredSegments.count),
                restorationDuration: Date().timeIntervalSince(startTime),
                interventionBreakdown: calculateInterventionBreakdown(restoredSegments)
            )
            
            let output = ToneRestorationOutput(
                restoredSegments: restoredSegments,
                restorationMetadata: metadata
            )
            
            logger.info("✅ Tone restoration complete: \(segmentsRestored)/\(metadata.totalSegments) restored, avg drift: \(String(format: "%.2f", metadata.averageToneDrift))")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Tone restoration failed: \(error.localizedDescription)")
            return .failure(.executionFailed(module: moduleName, reason: error.localizedDescription))
        }
    }
    
    public func validate(input: Input) -> [String] {
        var warnings: [String] = []
        
        if input.processedSegments.isEmpty {
            warnings.append("No segments to restore")
        }
        
        if input.toneMemory.globalToneProfile.confidence < 0.5 {
            warnings.append("Low confidence tone profile (\(String(format: "%.2f", input.toneMemory.globalToneProfile.confidence)))")
        }
        
        return warnings
    }
    
    // MARK: - Section Matching
    
    private func matchToSection(
        segment: PromptSegment,
        segmentIndex: Int,
        toneMemory: ToneMemory
    ) -> StorySection? {
        
        var bestMatch: StorySection?
        var bestScore = 0.0
        
        for section in toneMemory.sectionTones {
            var score = 0.0
            
            // Text overlap (simple substring matching)
            let segmentWords = Set(segment.text.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let sectionWords = Set(section.text.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let overlap = segmentWords.intersection(sectionWords)
            let textOverlapScore = Double(overlap.count) / Double(max(segmentWords.count, 1))
            score += textOverlapScore * 0.7
            
            // Character overlap
            let characterOverlap = Set(segment.characters).intersection(Set(section.text.components(separatedBy: .whitespacesAndNewlines)))
            let characterScore = Double(characterOverlap.count) / Double(max(segment.characters.count, 1))
            score += characterScore * 0.3
            
            if score > bestScore {
                bestScore = score
                bestMatch = section
            }
        }
        
        return bestMatch
    }
    
    // MARK: - Tone Drift Calculation
    
    private func calculateToneDrift(
        segment: PromptSegment,
        targetTone: GlobalToneProfile,
        section: StorySection?
    ) -> Double {
        
        var drift = 0.0
        let segmentText = segment.text.lowercased()
        
        // Check for emotional descriptors matching target tone
        let targetKeywords = getToneKeywords(for: targetTone.primaryTone)
        let hasTargetTone = targetKeywords.contains { segmentText.contains($0) }
        
        if !hasTargetTone {
            drift += 0.4  // Missing target tone markers
        }
        
        // Check emotional register
        let highIntensityWords = ["never", "always", "everything", "nothing", "completely", "utterly"]
        let intensityCount = highIntensityWords.filter { segmentText.contains($0) }.count
        
        switch targetTone.emotionalRegister {
        case .high:
            if intensityCount < 1 { drift += 0.3 }
        case .low:
            if intensityCount > 2 { drift += 0.3 }
        case .medium:
            if intensityCount > 3 { drift += 0.2 }
        }
        
        // Check for stylistic elements
        if targetTone.narrativeStyle == .lyrical {
            let hasMetaphor = segmentText.contains(" like ") || segmentText.contains(" as if ")
            if !hasMetaphor { drift += 0.2 }
        }
        
        // Bonus: If matched section, compare directly
        if let section = section {
            let sectionHasTone = getToneKeywords(for: section.localTone).contains { section.text.lowercased().contains($0) }
            if sectionHasTone && !hasTargetTone {
                drift += 0.3
            }
        }
        
        return min(drift, 1.0)
    }
    
    private func getToneKeywords(for tone: GlobalToneProfile.ToneType) -> [String] {
        switch tone {
        case .melancholic: return ["lonely", "empty", "lost", "alone", "silent", "cold", "hollow", "void"]
        case .absurdist: return ["strange", "absurd", "bizarre", "meaningless", "surreal", "inexplicable"]
        case .philosophical: return ["existence", "meaning", "truth", "consciousness", "reality", "being"]
        case .dark: return ["death", "darkness", "shadow", "fear", "doom", "terror"]
        case .hopeful: return ["hope", "light", "future", "dream", "tomorrow", "possibility"]
        case .nostalgic: return ["remember", "past", "once", "used to", "memory", "ago"]
        case .haunting: return ["haunt", "ghost", "echo", "linger", "whisper", "fade"]
        case .tragicomic: return ["ironic", "bitter", "tragic", "laugh", "absurdly"]
        default: return []
        }
    }
    
    // MARK: - Beat & Phrase Matching
    
    private func findRelevantBeats(
        segment: PromptSegment,
        beats: [EmotionalBeat]
    ) -> [EmotionalBeat] {
        
        return beats.filter { beat in
            // Check if beat text appears in segment
            segment.text.lowercased().contains(beat.text.lowercased()) ||
            // Check if beat context overlaps
            beat.context.lowercased().components(separatedBy: .whitespacesAndNewlines)
                .contains(where: { segment.text.lowercased().contains($0) })
        }
    }
    
    private func findRelevantCarrierPhrases(
        segment: PromptSegment,
        phrases: [ToneCarrierPhrase]
    ) -> [ToneCarrierPhrase] {
        
        return phrases.filter { phrase in
            // Check for word overlap
            let phraseWords = Set(phrase.phrase.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let segmentWords = Set(segment.text.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let overlap = phraseWords.intersection(segmentWords)
            return overlap.count >= 3  // At least 3 words in common
        }
    }
    
    // MARK: - Restoration Logic
    
    private func restoreSegmentTone(
        segment: PromptSegment,
        toneMemory: ToneMemory,
        matchedSection: StorySection?,
        matchedBeats: [EmotionalBeat],
        matchedPhrases: [ToneCarrierPhrase],
        aiService: AIServiceProtocol?,
        config: PipelineConfig
    ) async throws -> TonallyRestoredSegment {
        
        if let aiService = aiService, config.useAIForToneRestoration {
            return try await restoreWithAI(
                segment: segment,
                toneMemory: toneMemory,
                matchedSection: matchedSection,
                matchedBeats: matchedBeats,
                matchedPhrases: matchedPhrases,
                aiService: aiService
            )
        } else {
            return restoreHeuristically(
                segment: segment,
                toneMemory: toneMemory,
                matchedSection: matchedSection,
                matchedBeats: matchedBeats,
                matchedPhrases: matchedPhrases
            )
        }
    }
    
    private func restoreWithAI(
        segment: PromptSegment,
        toneMemory: ToneMemory,
        matchedSection: StorySection?,
        matchedBeats: [EmotionalBeat],
        matchedPhrases: [ToneCarrierPhrase],
        aiService: AIServiceProtocol
    ) async throws -> TonallyRestoredSegment {
        
        let prompt = buildRestorationPrompt(
            segment: segment,
            toneMemory: toneMemory,
            matchedSection: matchedSection,
            matchedBeats: matchedBeats,
            matchedPhrases: matchedPhrases
        )
        
        let restoredText = try await aiService.complete(
            systemPrompt: prompt,
            temperature: 0.7,
            maxTokens: 300
        )
        
        let interventions = [
            RestorationIntervention(
                type: .aiEnhanced,
                description: "AI-powered tone restoration applied",
                addedElements: ["AI enhancement"],
                confidence: 0.85
            )
        ]
        
        return TonallyRestoredSegment(
            originalSegment: segment,
            restoredText: restoredText.trimmingCharacters(in: .whitespacesAndNewlines),
            toneDrift: 0.7,
            restorationInterventions: interventions,
            matchedSection: matchedSection,
            matchedBeats: matchedBeats,
            confidenceScore: 0.85
        )
    }
    
    private func buildRestorationPrompt(
        segment: PromptSegment,
        toneMemory: ToneMemory,
        matchedSection: StorySection?,
        matchedBeats: [EmotionalBeat],
        matchedPhrases: [ToneCarrierPhrase]
    ) -> String {
        
        var prompt = """
        You are restoring emotional tone to a scene prompt that has been flattened by visual processing.
        
        ORIGINAL STORY TONE:
        - Primary: \(toneMemory.globalToneProfile.primaryTone.rawValue)
        - Emotional Register: \(toneMemory.globalToneProfile.emotionalRegister.rawValue)
        - Narrative Style: \(toneMemory.globalToneProfile.narrativeStyle.rawValue)
        - Pacing: \(toneMemory.globalToneProfile.pacingStyle.rawValue)
        
        STYLISTIC FINGERPRINT:
        - Avg Sentence Length: \(String(format: "%.1f", toneMemory.stylisticFingerprint.avgSentenceLength)) words
        - Lexical Diversity: \(String(format: "%.2f", toneMemory.stylisticFingerprint.lexicalDiversity))
        - Metaphor Density: \(String(format: "%.2f", toneMemory.stylisticFingerprint.metaphorDensity))
        
        """
        
        if let section = matchedSection {
            prompt += """
            
            ORIGINAL SECTION (for reference):
            
            """
        }
        
        if !matchedBeats.isEmpty {
            prompt += """
            
            EMOTIONAL BEATS TO CONSIDER:
            
            """
        }
        
        if !matchedPhrases.isEmpty {
            prompt += """
            
            TONE CARRIER PHRASES:
            
            """
        }
        
        prompt += """
        
        CURRENT SEGMENT (FLATTENED BY VISUAL PROCESSING):
        \(segment.text)
        
        TASK:
        Rewrite this segment to match the original tone while preserving ALL visual details (characters, props, locations, actions).
        
        RULES:
        1. Keep all character names: \(segment.characters.joined(separator: ", "))
        2. Keep all props: \(segment.props.joined(separator: ", "))
        3. Keep location: \(segment.location)
        4. Match the \(toneMemory.globalToneProfile.primaryTone.rawValue) tone
        5. Use \(toneMemory.globalToneProfile.narrativeStyle.rawValue) narrative style
        6. Output ONLY the enhanced segment (no explanation)
        
        ENHANCED SEGMENT:
        """
        
        return prompt
    }
    
    private func restoreHeuristically(
        segment: PromptSegment,
        toneMemory: ToneMemory,
        matchedSection: StorySection?,
        matchedBeats: [EmotionalBeat],
        matchedPhrases: [ToneCarrierPhrase]
    ) -> TonallyRestoredSegment {
        
        var restoredText = segment.text
        var interventions: [RestorationIntervention] = []
        
        // Strategy 1: Add atmosphere based on primary tone
        let atmosphereAddition = getAtmosphereForTone(toneMemory.globalToneProfile.primaryTone)
        if !atmosphereAddition.isEmpty {
            restoredText += ". \(atmosphereAddition)"
            interventions.append(RestorationIntervention(
                type: .atmosphereAdded,
                description: "Added \(toneMemory.globalToneProfile.primaryTone.rawValue) atmosphere",
                addedElements: [atmosphereAddition],
                confidence: 0.7
            ))
        }
        
        // Strategy 2: Integrate carrier phrases if matched
        if let topPhrase = matchedPhrases.sorted(by: { $0.importance > $1.importance }).first {
            // Extract key descriptive words from carrier phrase
            let descriptiveWords = extractDescriptiveWords(from: topPhrase.phrase)
            if !descriptiveWords.isEmpty {
                restoredText += " \(descriptiveWords)"
                interventions.append(RestorationIntervention(
                    type: .carrierPhraseIntegrated,
                    description: "Integrated tone carrier phrase elements",
                    addedElements: [descriptiveWords],
                    confidence: 0.6
                ))
            }
        }
        
        // Strategy 3: Apply stylistic adjustments
        if toneMemory.stylisticFingerprint.metaphorDensity > 0.05 && !restoredText.contains(" like ") {
            // Story uses metaphors, but segment doesn't - consider adding one
            interventions.append(RestorationIntervention(
                type: .stylisticMatchApplied,
                description: "Applied metaphorical language (noted for review)",
                addedElements: [],
                confidence: 0.5
            ))
        }
        
        return TonallyRestoredSegment(
            originalSegment: segment,
            restoredText: restoredText,
            toneDrift: 0.5,
            restorationInterventions: interventions,
            matchedSection: matchedSection,
            matchedBeats: matchedBeats,
            confidenceScore: 0.65
        )
    }
    
    private func getAtmosphereForTone(_ tone: GlobalToneProfile.ToneType) -> String {
        switch tone {
        case .melancholic:
            return "The silence weighs heavy"
        case .absurdist:
            return "The mundane absurdity of the moment hangs in the air"
        case .philosophical:
            return "A question without an answer lingers"
        case .dark:
            return "Shadows gather at the edges"
        case .hopeful:
            return "A glimmer of possibility remains"
        case .nostalgic:
            return "The memory of something lost echoes"
        case .haunting:
            return "Something lingers, just out of reach"
        case .tragicomic:
            return "The irony is not lost on anyone"
        default:
            return ""
        }
    }
    
    private func extractDescriptiveWords(from phrase: String) -> String {
        // Simple extraction of adjectives and atmospheric words
        let words = phrase.components(separatedBy: .whitespacesAndNewlines)
        let descriptive = words.filter { word in
            word.count > 5 &&
            (word.hasSuffix("ing") || word.hasSuffix("ed") || 
             word.hasSuffix("ful") || word.hasSuffix("less"))
        }
        
    }
    
    private func calculateInterventionBreakdown(
        _ segments: [TonallyRestoredSegment]
    ) -> [RestorationIntervention.InterventionType: Int] {
        
        var breakdown: [RestorationIntervention.InterventionType: Int] = [:]
        
        for segment in segments {
            for intervention in segment.restorationInterventions {
                breakdown[intervention.type, default: 0] += 1
            }
        }
        
        return breakdown
    }
}

// MARK: - Input/Output Types

public struct ToneRestorationInput: Sendable {
    public let processedSegments: [PromptSegment]
    public let toneMemory: ToneMemory
    public let continuityAnchors: [ContinuityAnchor]?
    
    public init(
        processedSegments: [PromptSegment],
        toneMemory: ToneMemory,
        continuityAnchors: [ContinuityAnchor]? = nil
    ) {
        self.processedSegments = processedSegments
        self.toneMemory = toneMemory
        self.continuityAnchors = continuityAnchors
    }
}

public struct ToneRestorationOutput: Sendable {
    public let restoredSegments: [TonallyRestoredSegment]
    public let restorationMetadata: RestorationMetadata
    
    public init(
        restoredSegments: [TonallyRestoredSegment],
        restorationMetadata: RestorationMetadata
    ) {
        self.restoredSegments = restoredSegments
        self.restorationMetadata = restorationMetadata
    }
}

// MARK: - Restored Segment

public struct TonallyRestoredSegment: Sendable, Identifiable {
    public let id: UUID
    public let originalSegment: PromptSegment
    public let restoredText: String
    public let toneDrift: Double
    public let restorationInterventions: [RestorationIntervention]
    public let matchedSection: StorySection?
    public let matchedBeats: [EmotionalBeat]
    public let confidenceScore: Double
    
    public init(
        originalSegment: PromptSegment,
        restoredText: String,
        toneDrift: Double,
        restorationInterventions: [RestorationIntervention],
        matchedSection: StorySection?,
        matchedBeats: [EmotionalBeat],
        confidenceScore: Double
    ) {
        self.id = UUID()
        self.originalSegment = originalSegment
        self.restoredText = restoredText
        self.toneDrift = toneDrift
        self.restorationInterventions = restorationInterventions
        self.matchedSection = matchedSection
        self.matchedBeats = matchedBeats
        self.confidenceScore = confidenceScore
    }
}

public struct RestorationIntervention: Sendable {
    public let type: InterventionType
    public let description: String
    public let addedElements: [String]
    public let confidence: Double
    
    public enum InterventionType: String, Sendable {
        case atmosphereAdded
        case emotionalDepthRestored
        case stylisticMatchApplied
        case metaphorReintroduced
        case pacingAdjusted
        case carrierPhraseIntegrated
        case aiEnhanced
    }
    
    public init(type: InterventionType, description: String, addedElements: [String], confidence: Double) {
        self.type = type
        self.description = description
        self.addedElements = addedElements
        self.confidence = confidence
    }
}

public struct RestorationMetadata: Sendable {
    public let totalSegments: Int
    public let segmentsRestored: Int
    public let averageToneDrift: Double
    public let averageConfidence: Double
    public let restorationDuration: TimeInterval
    public let interventionBreakdown: [RestorationIntervention.InterventionType: Int]
    
    public init(
        totalSegments: Int,
        segmentsRestored: Int,
        averageToneDrift: Double,
        averageConfidence: Double,
        restorationDuration: TimeInterval,
        interventionBreakdown: [RestorationIntervention.InterventionType: Int]
    ) {
        self.totalSegments = totalSegments
        self.segmentsRestored = segmentsRestored
        self.averageToneDrift = averageToneDrift
        self.averageConfidence = averageConfidence
        self.restorationDuration = restorationDuration
        self.interventionBreakdown = interventionBreakdown
    }
}
