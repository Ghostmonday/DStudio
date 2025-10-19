//
//  ToneAnalysisModule.swift
//  DirectorStudio
//
//  PHASE 1: Pre-segmentation tone analysis
//  Scans full story and creates "tone memory" for later restoration
//  Version: 1.0.0
//

import Foundation
import OSLog

// MARK: - Module Protocol Conformance

public struct ToneAnalysisModule: PipelineModule {
    public typealias Input = ToneAnalysisInput
    public typealias Output = ToneAnalysisOutput
    
    public let moduleID = "com.directorstudio.tone_analysis"
    public let moduleName = "Tone Analysis (Pre-Segmentation)"
    public let version = "1.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "tone_analysis")
    private let aiService: AIServiceProtocol?
    
    public init(aiService: AIServiceProtocol? = nil) {
        self.aiService = aiService
    }
    
    public func execute(
        input: Input,
        context: PipelineContext
    ) async -> Result<Output, PipelineError> {
        
        logger.info("📊 Starting tone analysis (pre-segmentation)")
        let startTime = Date()
        
        do {
            // STEP 1: Extract global tone profile
            logger.debug("Extracting global tone profile...")
            let globalTone = try await extractGlobalTone(
                story: input.originalStory,
                context: context
            )
            
            // STEP 2: Identify story sections with local tones
            logger.debug("Identifying story sections...")
            let sections = await identifySections(
                story: input.originalStory,
                globalTone: globalTone
            )
            
            // STEP 3: Extract emotional beats
            logger.debug("Extracting emotional beats...")
            let beats = await extractEmotionalBeats(
                story: input.originalStory,
                sections: sections
            )
            
            // STEP 4: Find tone carrier phrases
            logger.debug("Finding tone carrier phrases...")
            let carrierPhrases = await extractToneCarrierPhrases(
                story: input.originalStory,
                globalTone: globalTone
            )
            
            // STEP 5: Generate stylistic fingerprint
            logger.debug("Generating stylistic fingerprint...")
            let fingerprint = analyzeStylisticFingerprint(input.originalStory)
            
            // Build tone memory
            let storyHash = String(input.originalStory.hashValue)
            let toneMemory = ToneMemory(
                globalToneProfile: globalTone,
                sectionTones: sections,
                emotionalBeats: beats,
                toneCarrierPhrases: carrierPhrases,
                stylisticFingerprint: fingerprint,
                storyHash: storyHash
            )
            
            let metadata = ToneExtractionMetadata(
                totalSections: sections.count,
                totalBeats: beats.count,
                totalCarrierPhrases: carrierPhrases.count,
                extractionDuration: Date().timeIntervalSince(startTime),
                analysisMethod: aiService != nil ? .aiPowered : .heuristic,
                confidence: globalTone.confidence
            )
            
            let output = ToneAnalysisOutput(
                toneMemory: toneMemory,
                extractionMetadata: metadata
            )
            
            logger.info("✅ Tone analysis complete: \(sections.count) sections, \(beats.count) beats, confidence: \(String(format: "%.2f", globalTone.confidence))")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Tone analysis failed: \(error.localizedDescription)")
            return .failure(.executionFailed(module: moduleName, reason: error.localizedDescription))
        }
    }
    
    // MARK: - Validation
    
    public func validate(input: Input) -> [String] {
        var warnings: [String] = []
        
        if input.originalStory.isEmpty {
            warnings.append("Original story is empty")
        }
        
        if input.originalStory.count < 100 {
            warnings.append("Story is very short (\(input.originalStory.count) chars), tone analysis may be unreliable")
        }
        
        return warnings
    }
    
    // MARK: - Extraction Methods
    
    private func extractGlobalTone(
        story: String,
        context: PipelineContext
    ) async throws -> GlobalToneProfile {
        
        if let aiService = aiService {
            // AI-powered analysis
            return try await extractGlobalToneViaAI(story: story, aiService: aiService)
        } else {
            // Heuristic fallback
            return extractGlobalToneHeuristic(story: story)
        }
    }
    
    private func extractGlobalToneViaAI(
        story: String,
        aiService: AIServiceProtocol
    ) async throws -> GlobalToneProfile {
        
        let prompt = """
        Analyze the overall tone of this story. Respond with ONLY a JSON object (no markdown, no explanation):
        
        {
          "primaryTone": "absurdist|melancholic|nostalgic|haunting|tragicomic|whimsical|dark|philosophical|hopeful|cynical|poignant|surreal|dramatic|comedic|satirical|existential",
          "secondaryTones": ["tone1", "tone2"],
          "emotionalRegister": "high|medium|low",
          "narrativeStyle": "lyrical|sparse|baroque|clinical|conversational",
          "pacingStyle": "frenetic|measured|languid|staccato",
          "confidence": 0.85
        }
        
        Story (first 2000 chars):
        """
        
        let response = try await aiService.complete(
            systemPrompt: prompt,
            temperature: 0.3,
            maxTokens: 300
        )
        
        // Strip markdown if present
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse JSON response
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw PipelineError.executionFailed(module: moduleName, reason: "Failed to encode AI response")
        }
        
        let decoded = try JSONDecoder().decode(GlobalToneProfileDTO.self, from: data)
        
        return GlobalToneProfile(
            primaryTone: GlobalToneProfile.ToneType(rawValue: decoded.primaryTone) ?? .dramatic,
            secondaryTones: decoded.secondaryTones.compactMap { GlobalToneProfile.ToneType(rawValue: $0) },
            emotionalRegister: GlobalToneProfile.EmotionalRegister(rawValue: decoded.emotionalRegister) ?? .medium,
            narrativeStyle: GlobalToneProfile.NarrativeStyle(rawValue: decoded.narrativeStyle) ?? .conversational,
            pacingStyle: GlobalToneProfile.PacingStyle(rawValue: decoded.pacingStyle) ?? .measured,
            confidence: decoded.confidence
        )
    }
    
    private func extractGlobalToneHeuristic(story: String) -> GlobalToneProfile {
        let lowerStory = story.lowercased()
        
        // Tone keyword detection
        let toneKeywords: [GlobalToneProfile.ToneType: [String]] = [
            .melancholic: ["lonely", "empty", "cold", "silence", "forgotten", "lost", "void", "hollow"],
            .absurdist: ["meaningless", "absurd", "strange", "bizarre", "pointless", "surreal", "inexplicable"],
            .philosophical: ["existence", "meaning", "purpose", "consciousness", "reality", "truth", "being"],
            .dark: ["death", "darkness", "shadow", "night", "fear", "terror", "doom"],
            .hopeful: ["hope", "light", "future", "dream", "possibility", "tomorrow"]
        ]
        
        var toneScores: [GlobalToneProfile.ToneType: Int] = [:]
        for (tone, keywords) in toneKeywords {
            let count = keywords.filter { lowerStory.contains($0) }.count
            if count > 0 {
                toneScores[tone] = count
            }
        }
        
        let primaryTone = toneScores.max(by: { $0.value < $1.value })?.key ?? .dramatic
        
        // Emotional register (based on intensity words)
        let highIntensityWords = ["never", "always", "everything", "nothing", "completely", "utterly"]
        let intensityCount = highIntensityWords.filter { lowerStory.contains($0) }.count
        let emotionalRegister: GlobalToneProfile.EmotionalRegister = intensityCount > 3 ? .high : .medium
        
        // Narrative style (based on sentence structure)
        let sentences = story.components(separatedBy: ". ")
        let avgSentenceLength = story.count / max(sentences.count, 1)
        let narrativeStyle: GlobalToneProfile.NarrativeStyle = avgSentenceLength > 100 ? .baroque : .conversational
        
        return GlobalToneProfile(
            primaryTone: primaryTone,
            secondaryTones: secondaryTones.filter { $0 != primaryTone },
            emotionalRegister: emotionalRegister,
            narrativeStyle: narrativeStyle,
            pacingStyle: .measured,
            confidence: 0.6
        )
    }
    
    private func identifySections(
        story: String,
        globalTone: GlobalToneProfile
    ) async -> [StorySection] {
        
        // Split by double newlines (paragraph breaks)
        let paragraphs = story.components(separatedBy: "\n\n")
        var sections: [StorySection] = []
        var currentPosition = 0
        
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                currentPosition += paragraph.count + 2
                continue
            }
            
            // Detect local tone (simplified)
            let localTone = detectLocalTone(paragraph, globalTone: globalTone)
            let arc = detectEmotionalArc(paragraph)
            let themes = extractThemes(paragraph)
            
            let section = StorySection(
                startIndex: currentPosition,
                endIndex: currentPosition + paragraph.count,
                text: trimmed,
                localTone: localTone,
                emotionalArc: arc,
                keyThemes: themes
            )
            
            sections.append(section)
            currentPosition += paragraph.count + 2
        }
        
        return sections
    }
    
    private func detectLocalTone(
        _ text: String,
        globalTone: GlobalToneProfile
    ) -> GlobalToneProfile.ToneType {
        // Check if section matches any secondary tones
        let lowerText = text.lowercased()
        
        for tone in globalTone.secondaryTones {
            let keywords = getToneKeywords(for: tone)
            if keywords.contains(where: { lowerText.contains($0) }) {
                return tone
            }
        }
        
        return globalTone.primaryTone
    }
    
    private func detectEmotionalArc(_ text: String) -> StorySection.EmotionalArc {
        let lowerText = text.lowercased()
        
        if lowerText.contains("but") || lowerText.contains("however") || lowerText.contains("suddenly") {
            return .oscillating
        } else if lowerText.contains("finally") || lowerText.contains("at last") {
            return .falling
        } else if lowerText.contains("began") || lowerText.contains("started") {
            return .rising
        }
        
        return .stable
    }
    
    private func extractThemes(_ text: String) -> [String] {
        let themeKeywords = [
            "isolation", "connection", "time", "memory", "loss", 
            "hope", "despair", "identity", "mortality", "meaning"
        ]
        
        return themeKeywords.filter { text.lowercased().contains($0) }
    }
    
    private func getToneKeywords(for tone: GlobalToneProfile.ToneType) -> [String] {
        switch tone {
        case .melancholic: return ["sad", "empty", "lost", "alone"]
        case .absurdist: return ["strange", "absurd", "bizarre"]
        case .philosophical: return ["existence", "meaning", "truth"]
        case .dark: return ["death", "darkness", "shadow"]
        default: return []
        }
    }
    
    private func extractEmotionalBeats(
        story: String,
        sections: [StorySection]
    ) async -> [EmotionalBeat] {
        
        let beatKeywords: [EmotionalBeat.BeatType: [String]] = [
            .revelation: ["realized", "understood", "discovered", "saw", "knew"],
            .reversal: ["but", "however", "suddenly", "then", "instead"],
            .catharsis: ["finally", "at last", "released", "let go", "free"],
            .recognition: ["remembered", "recognized", "familiar", "again"],
            .tension: ["waited", "silence", "pause", "held breath"],
            .irony: ["ironic", "paradox", "contradiction"]
        ]
        
        var beats: [EmotionalBeat] = []
        
        for (type, keywords) in beatKeywords {
            for keyword in keywords {
                var searchRange = story.startIndex..<story.endIndex
                
                while let range = story.range(of: keyword, options: .caseInsensitive, range: searchRange) {
                    let position = story.distance(from: story.startIndex, to: range.lowerBound)
                    
                    // Extract context (50 chars before/after)
                    let contextStart = story.index(range.lowerBound, offsetBy: -50, limitedBy: story.startIndex) ?? story.startIndex
                    let contextEnd = story.index(range.upperBound, offsetBy: 50, limitedBy: story.endIndex) ?? story.endIndex
                    let context = String(story[contextStart..<contextEnd])
                    
                    let beat = EmotionalBeat(
                        position: position,
                        type: type,
                        intensity: 0.7,
                        text: String(story[range]),
                        context: context
                    )
                    beats.append(beat)
                    
                    // Move search forward
                    searchRange = range.upperBound..<story.endIndex
                    if searchRange.isEmpty { break }
                }
            }
        }
        
        return beats
    }
    
    private func extractToneCarrierPhrases(
        story: String,
        globalTone: GlobalToneProfile
    ) async -> [ToneCarrierPhrase] {
        
        let sentences = story.components(separatedBy: ". ")
        var phrases: [ToneCarrierPhrase] = []
        
        for (index, sentence) in sentences.enumerated() {
            // Detect metaphors
            if sentence.contains(" like ") || sentence.contains(" as if ") || sentence.contains(" as though ") {
                let phrase = ToneCarrierPhrase(
                    phrase: sentence,
                    toneSignature: globalTone.primaryTone.rawValue,
                    position: index,
                    importance: 0.8,
                    category: .metaphor
                )
                phrases.append(phrase)
            }
            
            // Detect atmospheric descriptions
            if sentence.lowercased().contains("air") || sentence.lowercased().contains("atmosphere") {
                let phrase = ToneCarrierPhrase(
                    phrase: sentence,
                    toneSignature: globalTone.primaryTone.rawValue,
                    position: index,
                    importance: 0.7,
                    category: .atmosphere
                )
                phrases.append(phrase)
            }
            
            // Detect unique authorial voice (sentences with unusual structure)
            if sentence.count > 150 || sentence.filter({ $0 == "," }).count > 4 {
                let phrase = ToneCarrierPhrase(
                    phrase: sentence,
                    toneSignature: globalTone.primaryTone.rawValue,
                    position: index,
                    importance: 0.6,
                    category: .authorialVoice
                )
                phrases.append(phrase)
            }
        }
        
        return phrases
    }
    
    private func analyzeStylisticFingerprint(_ story: String) -> StylisticFingerprint {
        let sentences = story.components(separatedBy: ". ")
        let words = story.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let paragraphs = story.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        // Average sentence length
        let avgSentenceLength = words.count > 0 ? Double(words.count) / Double(max(sentences.count, 1)) : 0.0
        
        // Average word length
        let totalWordChars = words.map { $0.count }.reduce(0, +)
        let avgWordLength = words.count > 0 ? Double(totalWordChars) / Double(words.count) : 0.0
        
        // Lexical diversity
        let uniqueWords = Set(words.map { $0.lowercased() })
        let lexicalDiversity = words.count > 0 ? Double(uniqueWords.count) / Double(words.count) : 0.0
        
        // Part of speech ratios (simplified heuristic)
        let adjectives = words.filter { $0.hasSuffix("ful") || $0.hasSuffix("less") || $0.hasSuffix("ous") || $0.hasSuffix("ive") }
        let adverbs = words.filter { $0.hasSuffix("ly") }
        let adjectiveRatio = words.count > 0 ? Double(adjectives.count) / Double(words.count) : 0.0
        let adverbRatio = words.count > 0 ? Double(adverbs.count) / Double(words.count) : 0.0
        
        // Metaphor density
        let metaphorMarkers = story.components(separatedBy: " like ").count + 
                             story.components(separatedBy: " as if ").count - 2
        let metaphorDensity = sentences.count > 0 ? Double(max(metaphorMarkers, 0)) / Double(sentences.count) : 0.0
        
        // Dialogue ratio (rough estimate based on quotes)
        let dialogueMarkers = story.filter { $0 == "\"" }.count / 2
        let dialogueRatio = words.count > 0 ? Double(dialogueMarkers * 10) / Double(words.count) : 0.0
        
        // Paragraph length variance
        let paragraphLengths = paragraphs.map { Double($0.count) }
        let avgParagraphLength = paragraphLengths.reduce(0, +) / Double(max(paragraphs.count, 1))
        let variance = paragraphLengths.map { pow($0 - avgParagraphLength, 2) }.reduce(0, +) / Double(max(paragraphs.count, 1))
        
        // Punctuation profile
        let punctuationProfile = StylisticFingerprint.PunctuationProfile(
            periodFrequency: Double(story.filter { $0 == "." }.count) / Double(max(story.count, 1)),
            commaFrequency: Double(story.filter { $0 == "," }.count) / Double(max(story.count, 1)),
            dashFrequency: Double(story.filter { $0 == "—" || $0 == "-" }.count) / Double(max(story.count, 1)),
            ellipsisFrequency: Double(story.components(separatedBy: "...").count - 1) / Double(max(story.count, 1)),
            exclamationFrequency: Double(story.filter { $0 == "!" }.count) / Double(max(story.count, 1)),
            questionFrequency: Double(story.filter { $0 == "?" }.count) / Double(max(story.count, 1))
        )
        
        return StylisticFingerprint(
            avgSentenceLength: avgSentenceLength,
            avgWordLength: avgWordLength,
            lexicalDiversity: lexicalDiversity,
            adjectiveRatio: adjectiveRatio,
            adverbRatio: adverbRatio,
            metaphorDensity: metaphorDensity,
            dialogueRatio: min(dialogueRatio, 1.0),
            paragraphLengthVariance: variance,
            punctuationProfile: punctuationProfile
        )
    }
}

// MARK: - Input/Output Types

public struct ToneAnalysisInput: Sendable {
    public let originalStory: String
    public let projectMetadata: [String: String]
    
    public init(originalStory: String, projectMetadata: [String: String] = [:]) {
        self.originalStory = originalStory
        self.projectMetadata = projectMetadata
    }
}

public struct ToneAnalysisOutput: Sendable {
    public let toneMemory: ToneMemory
    public let extractionMetadata: ToneExtractionMetadata
    
    public init(toneMemory: ToneMemory, extractionMetadata: ToneExtractionMetadata) {
        self.toneMemory = toneMemory
        self.extractionMetadata = extractionMetadata
    }
}

// MARK: - DTO for AI Response

private struct GlobalToneProfileDTO: Codable {
    let primaryTone: String
    let secondaryTones: [String]
    let emotionalRegister: String
    let narrativeStyle: String
    let pacingStyle: String
    let confidence: Double
}
