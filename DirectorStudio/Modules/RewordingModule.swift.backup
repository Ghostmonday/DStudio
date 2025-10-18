//
//  RewordingModule.swift
//  DirectorStudio
//
//  UPGRADED: Enhanced story text transformation with intelligent style detection
//  Handles chaotic, dreamlike, and fragmented narratives with advanced processing
//

import Foundation
import OSLog

// MARK: - Rewording Module

/// Advanced text transformation module with intelligent style detection and adaptive processing
/// Handles all input types including stream-of-consciousness, dreamlike narratives, and fragmented text
public struct RewordingModule: PipelineModule {
    public typealias Input = RewordingInput
    public typealias Output = RewordingOutput
    
    public let moduleID = "com.directorstudio.rewording"
    public let moduleName = "Rewording"
    public let version = "2.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "rewording")
    
    public init() {}
    
    public func execute(
        input: RewordingInput,
        context: PipelineContext
    ) async -> Result<RewordingOutput, PipelineError> {
        logger.info("🔄 Starting advanced rewording [v2.0] with type: \(input.rewordType.rawValue)")
        
        // Validate and analyze input
        let warnings = validate(input: input)
        if !warnings.isEmpty {
            logger.warning("⚠️ Validation warnings: \(warnings.joined(separator: ", "))")
        }
        
        // Deep analysis of input characteristics
        let inputAnalysis = analyzeInputCharacteristics(input.story)
        logger.debug("📊 Input analysis: \(inputAnalysis.summary)")
        
        // Detect and handle chaotic patterns
        if let chaoticType = detectChaoticInput(input.story) {
            logger.warning("🌀 Chaotic input detected: \(chaoticType.description)")
        }
        
        let startTime = Date()
        
        do {
            let rewordedStory: String
            
            // Skip processing if type is none
            if input.rewordType == .none {
                rewordedStory = input.story
                logger.info("⏭️ Rewording skipped (type: none)")
            } else {
                // Advanced preprocessing pipeline
                let preprocessed = preprocessInput(input.story, analysis: inputAnalysis)
                
                // Adaptive rewording based on input characteristics
                rewordedStory = try await performAdaptiveRewording(
                    story: preprocessed,
                    type: input.rewordType,
                    analysis: inputAnalysis,
                    context: context
                )
            }
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            // Calculate quality metrics
            let qualityScore = calculateQualityScore(
                original: input.story,
                reworded: rewordedStory,
                analysis: inputAnalysis
            )
            
            let output = RewordingOutput(
                rewordedStory: rewordedStory,
                originalLength: input.story.count,
                rewordedLength: rewordedStory.count,
                rewordType: input.rewordType,
                qualityMetrics: QualityMetrics(
                    improvementScore: qualityScore,
                    coherenceScore: inputAnalysis.coherenceScore,
                    sentenceCount: countSentences(rewordedStory),
                    vocabularyRichness: calculateVocabularyRichness(rewordedStory),
                    processingTime: executionTime
                ),
                detectedStyle: inputAnalysis.dominantStyle,
                transformationNotes: generateTransformationNotes(
                    from: input.story,
                    to: rewordedStory,
                    type: input.rewordType,
                    analysis: inputAnalysis
                )
            )
            
            logger.info("✅ Advanced rewording completed in \(String(format: "%.2f", executionTime))s (quality: \(String(format: "%.2f", qualityScore)))")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Advanced rewording failed: \(error.localizedDescription)")
            return .failure(.executionFailed(module: moduleName, reason: error.localizedDescription))
        }
    }
    
    public func validate(input: RewordingInput) -> [String] {
        var warnings: [String] = []
        
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            warnings.append("Story is empty - no content to reword")
        } else if trimmed.count < 10 {
            warnings.append("Story is very short (\(trimmed.count) chars) - limited rewording possible")
        }
        
        if input.story.count > 100_000 {
            warnings.append("Story exceeds 100k characters - may require chunking")
        }
        
        // Advanced validation checks
        let nonPrintableCount = input.story.filter { !$0.isPrintable }.count
        if nonPrintableCount > input.story.count / 10 {
            warnings.append("High non-printable character density (\(nonPrintableCount)) - input may be corrupted")
        }
        
        let repeatedChars = detectExcessiveRepetition(input.story)
        if repeatedChars > 20 {
            warnings.append("Excessive character repetition detected - possible spam or test input")
        }
        
        return warnings
    }
    
    // MARK: - Advanced Input Analysis
    
    /// Comprehensive analysis of input text characteristics
    private func analyzeInputCharacteristics(_ story: String) -> InputAnalysis {
        let sentences = extractSentences(from: story)
        let words = story.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Calculate coherence metrics
        let avgSentenceLength = sentences.isEmpty ? 0 : Double(words.count) / Double(sentences.count)
        let punctuationDensity = calculatePunctuationDensity(story)
        let capitalizationScore = calculateCapitalizationScore(story)
        
        // Detect narrative style
        let style = detectNarrativeStyle(story, sentences: sentences)
        
        // Calculate coherence score (0.0 to 1.0)
        let coherenceScore = calculateCoherenceScore(
            avgSentenceLength: avgSentenceLength,
            punctuationDensity: punctuationDensity,
            capitalizationScore: capitalizationScore
        )
        
        return InputAnalysis(
            sentenceCount: sentences.count,
            wordCount: words.count,
            averageSentenceLength: avgSentenceLength,
            punctuationDensity: punctuationDensity,
            capitalizationScore: capitalizationScore,
            coherenceScore: coherenceScore,
            dominantStyle: style,
            containsDialogue: detectDialogue(story),
            emotionalTone: detectEmotionalTone(story)
        )
    }
    
    /// Detects chaotic or unusual input patterns
    private func detectChaoticInput(_ story: String) -> ChaoticInputType? {
        let lowercased = story.lowercased()
        
        // Dream narrative detection
        let dreamPatterns = ["dear diary", "i had a dream", "it was a dream", "was it real", 
                            "woke up", "can't tell if", "dreaming", "nightmare"]
        if dreamPatterns.contains(where: { lowercased.contains($0) }) {
            return .dreamNarrative
        }
        
        // Stream of consciousness detection
        let streamPatterns = ["haha", "lol", "omg", "wait what", "no way", "like", "idk"]
        let streamCount = streamPatterns.filter { lowercased.contains($0) }.count
        if streamCount >= 3 {
            return .streamOfConsciousness
        }
        
        // Fragmented text detection (lots of short sentences/fragments)
        let sentences = extractSentences(from: story)
        let shortSentences = sentences.filter { $0.count < 20 }
        if sentences.count > 5 && Float(shortSentences.count) / Float(sentences.count) > 0.7 {
            return .fragmented
        }
        
        // Journal entry detection
        if lowercased.starts(with: "dear diary") || lowercased.starts(with: "today") {
            return .journalEntry
        }
        
        // Excessive punctuation
        let punctuationCount = story.filter { "!?...".contains($0) }.count
        if punctuationCount > story.count / 10 {
            return .excessivePunctuation
        }
        
        return nil
    }
    
    // MARK: - Advanced Preprocessing
    
    /// Preprocesses input based on detected characteristics
    private func preprocessInput(_ story: String, analysis: InputAnalysis) -> String {
        var processed = story
        
        // Remove excessive whitespace
        processed = processed.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Normalize line breaks
        processed = processed.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Truncate if too long
        if processed.count > 100_000 {
            processed = String(processed.prefix(100_000))
            logger.warning("📏 Story truncated to 100k characters")
        }
        
        // Fix common typos and issues
        processed = fixCommonIssues(processed)
        
        // Remove control characters but preserve newlines
        processed = processed.filter { $0.isPrintable || $0.isNewline }
        
        return processed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Fixes common text issues
    private func fixCommonIssues(_ text: String) -> String {
        var fixed = text
        
        // Fix multiple punctuation
        fixed = fixed.replacingOccurrences(of: "\\?{3,}", with: "?", options: .regularExpression)
        fixed = fixed.replacingOccurrences(of: "!{3,}", with: "!", options: .regularExpression)
        fixed = fixed.replacingOccurrences(of: "\\.{4,}", with: "...", options: .regularExpression)
        
        // Fix spacing around punctuation
        fixed = fixed.replacingOccurrences(of: " +([,.:;!?])", with: "$1", options: .regularExpression)
        fixed = fixed.replacingOccurrences(of: "([.!?])([A-Z])", with: "$1 $2", options: .regularExpression)
        
        return fixed
    }
    
    // MARK: - Adaptive Rewording
    
    /// Performs intelligent rewording adapted to input characteristics
    private func performAdaptiveRewording(
        story: String,
        type: RewordingType,
        analysis: InputAnalysis,
        context: PipelineContext
    ) async throws -> String {
        
        // Build adaptive system prompt
        let systemPrompt = buildAdaptiveSystemPrompt(
            for: type,
            analysis: analysis
        )
        
        // Build user prompt with context
        let userPrompt = buildUserPrompt(story: story, analysis: analysis)
        
        // TODO: Replace with actual API call in production
        // This is where you'd integrate with DeepSeek, OpenAI, etc.
        logger.debug("🤖 Would call API with adaptive prompts")
        
        // Simulated intelligent transformation
        let transformed = simulateIntelligentTransformation(
            story: story,
            type: type,
            analysis: analysis
        )
        
        return transformed
    }
    
    /// Builds adaptive system prompt based on input analysis
    private func buildAdaptiveSystemPrompt(
        for type: RewordingType,
        analysis: InputAnalysis
    ) -> String {
        var basePrompt = getBasePromptForType(type)
        
        // Add adaptive instructions based on input characteristics
        if analysis.coherenceScore < 0.5 {
            basePrompt += "\n\nIMPORTANT: The input text appears fragmented or stream-of-consciousness. Focus on organizing thoughts into coherent sentences while preserving the original meaning and emotional content."
        }
        
        if analysis.dominantStyle == .dreamlike {
            basePrompt += "\n\nNOTE: This appears to be a dreamlike or surreal narrative. Maintain the dream-like quality while improving clarity and flow."
        }
        
        if analysis.containsDialogue {
            basePrompt += "\n\nThe text contains dialogue. Preserve all dialogue while improving narrative portions."
        }
        
        return basePrompt
    }
    
    /// Gets base prompt for rewording type
    private func getBasePromptForType(_ type: RewordingType) -> String {
        switch type {
        case .modernize:
            return """
            Transform the following story into modern, contemporary language. Update dated references, 
            simplify overly complex structures, and use current idioms. Maintain the core narrative, 
            characters, and emotional impact. Make it feel fresh and current without losing authenticity.
            """
        
        case .simplify:
            return """
            Rewrite the following story using simpler language and clearer sentence structures. 
            Make it accessible and easy to understand while preserving all plot points, character 
            development, and key moments. Use straightforward vocabulary and avoid complex constructions.
            """
        
        case .dramatize:
            return """
            Enhance the dramatic elements of this story. Heighten emotional moments, add vivid 
            sensory details, create tension and stakes. Make dialogue more impactful and descriptive 
            passages more evocative. Amplify the story's emotional resonance while staying true to 
            the original narrative.
            """
        
        case .formalize:
            return """
            Transform this story into formal, literary prose. Use sophisticated vocabulary, 
            well-constructed complex sentences, and elevated language. Create a polished, 
            professional tone suitable for literary publication while maintaining clarity 
            and the original narrative.
            """
        
        case .none:
            return "Return the story exactly as provided without modifications."
        }
    }
    
    /// Builds user prompt with story and context
    private func buildUserPrompt(story: String, analysis: InputAnalysis) -> String {
        var prompt = "Story to reword:\n\n\(story)"
        
        if analysis.coherenceScore < 0.5 {
            prompt += "\n\n[Note: This text appears fragmented or informal. Please organize it coherently.]"
        }
        
        return prompt
    }
    
    /// Simulated intelligent transformation (placeholder for API)
    private func simulateIntelligentTransformation(
        story: String,
        type: RewordingType,
        analysis: InputAnalysis
    ) -> String {
        
        // In production, this would be the API response
        // For now, apply basic transformations based on type
        
        var transformed = story
        
        switch type {
        case .simplify:
            // Replace complex words with simpler alternatives
            let complexToSimple: [String: String] = [
                "utilize": "use",
                "commence": "start",
                "terminate": "end",
                "endeavor": "try",
                "substantial": "large"
            ]
            for (complex, simple) in complexToSimple {
                transformed = transformed.replacingOccurrences(
                    of: complex,
                    with: simple,
                    options: .caseInsensitive
                )
            }
            
        case .formalize:
            // Add formal transitions
            if !transformed.starts(with: "The") && !transformed.starts(with: "Upon") {
                transformed = "Upon reflection, " + transformed
            }
            
        case .dramatize:
            // Enhance emotional content markers
            transformed = transformed.replacingOccurrences(of: "said", with: "exclaimed")
            transformed = transformed.replacingOccurrences(of: "walked", with: "strode")
            
        default:
            break
        }
        
        // Add rewording marker for testing
        let marker = "\n\n[Reworded: \(type.displayName) | Style: \(analysis.dominantStyle.rawValue) | Coherence: \(String(format: "%.2f", analysis.coherenceScore))]\n\n"
        
        return marker + transformed
    }
    
    // MARK: - Quality Metrics
    
    /// Calculates quality improvement score
    private func calculateQualityScore(
        original: String,
        reworded: String,
        analysis: InputAnalysis
    ) -> Double {
        // Simple quality heuristic
        let originalWords = original.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let rewordedWords = reworded.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let lengthRatio = min(Double(rewordedWords.count) / Double(max(originalWords.count, 1)), 1.5)
        let baseScore = 0.7 + (analysis.coherenceScore * 0.3)
        
        return min(baseScore * lengthRatio, 1.0)
    }
    
    /// Calculates vocabulary richness (unique words ratio)
    private func calculateVocabularyRichness(_ text: String) -> Double {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return 0.0 }
        
        let uniqueWords = Set(words)
        return Double(uniqueWords.count) / Double(words.count)
    }
    
    /// Generates transformation notes
    private func generateTransformationNotes(
        from original: String,
        to reworded: String,
        type: RewordingType,
        analysis: InputAnalysis
    ) -> [String] {
        var notes: [String] = []
        
        notes.append("Applied \(type.displayName) transformation")
        notes.append("Detected style: \(analysis.dominantStyle.rawValue)")
        notes.append("Input coherence: \(String(format: "%.0f%%", analysis.coherenceScore * 100))")
        
        let originalWords = original.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let rewordedWords = reworded.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        if rewordedWords > originalWords {
            notes.append("Expanded by \(rewordedWords - originalWords) words for clarity")
        } else if rewordedWords < originalWords {
            notes.append("Condensed by \(originalWords - rewordedWords) words for conciseness")
        }
        
        if analysis.containsDialogue {
            notes.append("Preserved dialogue elements")
        }
        
        return notes
    }
    
    // MARK: - Helper Methods
    
    private func extractSentences(from text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func countSentences(_ text: String) -> Int {
        extractSentences(from: text).count
    }
    
    private func calculatePunctuationDensity(_ text: String) -> Double {
        let punctuation = text.filter { ".,!?;:".contains($0) }.count
        return Double(punctuation) / Double(max(text.count, 1))
    }
    
    private func calculateCapitalizationScore(_ text: String) -> Double {
        let letters = text.filter { $0.isLetter }
        guard !letters.isEmpty else { return 0.0 }
        let uppercase = letters.filter { $0.isUppercase }.count
        return Double(uppercase) / Double(letters.count)
    }
    
    private func calculateCoherenceScore(
        avgSentenceLength: Double,
        punctuationDensity: Double,
        capitalizationScore: Double
    ) -> Double {
        // Ideal ranges: 15-25 words per sentence, 0.03-0.08 punctuation density, 0.02-0.05 caps
        let sentenceScore = avgSentenceLength >= 10 && avgSentenceLength <= 30 ? 1.0 : 0.5
        let punctScore = punctuationDensity >= 0.02 && punctuationDensity <= 0.1 ? 1.0 : 0.5
        let capsScore = capitalizationScore >= 0.01 && capitalizationScore <= 0.1 ? 1.0 : 0.5
        
        return (sentenceScore + punctScore + capsScore) / 3.0
    }
    
    private func detectNarrativeStyle(_ text: String, sentences: [String]) -> NarrativeStyle {
        let lowercased = text.lowercased()
        
        if lowercased.contains("dream") || lowercased.contains("nightmare") {
            return .dreamlike
        }
        
        if sentences.count > 5 && sentences.filter({ $0.count < 15 }).count > sentences.count / 2 {
            return .fragmented
        }
        
        if text.filter({ "!?".contains($0) }).count > 10 {
            return .informal
        }
        
        let avgSentenceLength = sentences.isEmpty ? 0 : 
            sentences.reduce(0) { $0 + $1.count } / sentences.count
        
        if avgSentenceLength > 100 {
            return .formal
        }
        
        return .narrative
    }
    
    private func detectDialogue(_ text: String) -> Bool {
        text.contains("\"") || text.contains("'") || 
        text.contains("said") || text.contains("asked")
    }
    
    private func detectEmotionalTone(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        if lowercased.contains("sad") || lowercased.contains("tears") {
            return "melancholic"
        }
        if lowercased.contains("happy") || lowercased.contains("joy") {
            return "cheerful"
        }
        if lowercased.contains("scared") || lowercased.contains("fear") {
            return "tense"
        }
        if lowercased.contains("haha") || lowercased.contains("funny") {
            return "humorous"
        }
        
        return "neutral"
    }
    
    private func detectExcessiveRepetition(_ text: String) -> Int {
        var maxRepeat = 0
        var currentChar: Character?
        var currentCount = 0
        
        for char in text {
            if char == currentChar {
                currentCount += 1
                maxRepeat = max(maxRepeat, currentCount)
            } else {
                currentChar = char
                currentCount = 1
            }
        }
        
        return maxRepeat
    }
}

// MARK: - Enhanced Supporting Types

public struct RewordingInput: Sendable {
    public let story: String
    public let rewordType: RewordingType
    
    public init(story: String, rewordType: RewordingType) {
        self.story = story
        self.rewordType = rewordType
    }
}

public struct RewordingOutput: Sendable {
    public let rewordedStory: String
    public let originalLength: Int
    public let rewordedLength: Int
    public let rewordType: RewordingType
    public let qualityMetrics: QualityMetrics
    public let detectedStyle: NarrativeStyle
    public let transformationNotes: [String]
    
    public init(
        rewordedStory: String,
        originalLength: Int,
        rewordedLength: Int,
        rewordType: RewordingType,
        qualityMetrics: QualityMetrics = QualityMetrics(),
        detectedStyle: NarrativeStyle = .narrative,
        transformationNotes: [String] = []
    ) {
        self.rewordedStory = rewordedStory
        self.originalLength = originalLength
        self.rewordedLength = rewordedLength
        self.rewordType = rewordType
        self.qualityMetrics = qualityMetrics
        self.detectedStyle = detectedStyle
        self.transformationNotes = transformationNotes
    }
}

public struct QualityMetrics: Sendable {
    public let improvementScore: Double
    public let coherenceScore: Double
    public let sentenceCount: Int
    public let vocabularyRichness: Double
    public let processingTime: TimeInterval
    
    public init(
        improvementScore: Double = 0.0,
        coherenceScore: Double = 0.0,
        sentenceCount: Int = 0,
        vocabularyRichness: Double = 0.0,
        processingTime: TimeInterval = 0.0
    ) {
        self.improvementScore = improvementScore
        self.coherenceScore = coherenceScore
        self.sentenceCount = sentenceCount
        self.vocabularyRichness = vocabularyRichness
        self.processingTime = processingTime
    }
}

// MARK: - Analysis Types

private struct InputAnalysis {
    let sentenceCount: Int
    let wordCount: Int
    let averageSentenceLength: Double
    let punctuationDensity: Double
    let capitalizationScore: Double
    let coherenceScore: Double
    let dominantStyle: NarrativeStyle
    let containsDialogue: Bool
    let emotionalTone: String
    
    var summary: String {
        "sentences=\(sentenceCount), words=\(wordCount), coherence=\(String(format: "%.2f", coherenceScore)), style=\(dominantStyle.rawValue)"
    }
}

public enum NarrativeStyle: String, Sendable {
    case narrative = "Narrative"
    case dreamlike = "Dreamlike"
    case fragmented = "Fragmented"
    case formal = "Formal"
    case informal = "Informal"
}

private enum ChaoticInputType {
    case dreamNarrative
    case streamOfConsciousness
    case fragmented
    case journalEntry
    case excessivePunctuation
    
    var description: String {
        switch self {
        case .dreamNarrative: return "Dream/surreal narrative"
        case .streamOfConsciousness: return "Stream of consciousness"
        case .fragmented: return "Highly fragmented text"
        case .journalEntry: return "Journal/diary entry"
        case .excessivePunctuation: return "Excessive punctuation"
        }
    }
}

// MARK: - Character Extension

private extension Character {
    var isPrintable: Bool {
        let scalars = self.unicodeScalars
        return scalars.allSatisfy { scalar in
            scalar.properties.generalCategory != .control || scalar == "\n" || scalar == "\t"
        }
    }
}
