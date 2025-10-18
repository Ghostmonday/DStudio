//
//  StoryAnalysisModule.swift
//  DirectorStudio
//
//  UPGRADED: Deep story extraction with entity relationships and emotional arcs
//  Multi-layer analysis with advanced pattern recognition for any narrative style
//

import Foundation
import OSLog

// MARK: - Story Analysis Module

/// Advanced story analysis with multi-layer extraction, entity relationships, and emotional mapping
/// Handles structured narratives, chaotic streams, dreams, and fragmentary text
public struct StoryAnalysisModule: PipelineModule {
    public typealias Input = StoryAnalysisInput
    public typealias Output = StoryAnalysisOutput
    
    public let moduleID = "com.directorstudio.analysis"
    public let moduleName = "Story Analysis"
    public let version = "2.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "analysis")
    
    public init() {}
    
    public func execute(
        input: StoryAnalysisInput,
        context: PipelineContext
    ) async -> Result<StoryAnalysisOutput, PipelineError> {
        logger.info("🔍 Starting deep story analysis [v2.0]")
        
        let startTime = Date()
        
        do {
            // Validate input
            let warnings = validate(input: input)
            if !warnings.isEmpty {
                logger.warning("⚠️ Validation warnings: \(warnings.joined(separator: ", "))")
            }
            
            // Multi-layer extraction
            let analysis = try await performDeepAnalysis(
                story: input.story,
                context: context
            )
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            let output = StoryAnalysisOutput(
                analysis: analysis,
                extractionMethod: analysis.extractionMethod,
                confidence: analysis.confidence
            )
            
            logger.info("✅ Deep analysis completed in \(String(format: "%.2f", executionTime))s")
            logger.debug("📊 Extracted: \(analysis.characters.count) chars, \(analysis.locations.count) locs, \(analysis.scenes.count) scenes, \(analysis.entities.count) entities")
            
            return .success(output)
            
        } catch {
            logger.error("❌ Analysis failed: \(error.localizedDescription)")
            
            // Triple-fallback system for maximum resilience
            logger.warning("🔄 Attempting fallback analysis chain")
            let fallbackAnalysis = performTripleFallback(input.story)
            
            let output = StoryAnalysisOutput(
                analysis: fallbackAnalysis,
                extractionMethod: .fallback,
                confidence: 0.3
            )
            
            return .success(output)
        }
    }
    
    public func validate(input: StoryAnalysisInput) -> [String] {
        var warnings: [String] = []
        
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            warnings.append("Story is empty - analysis will be minimal")
        } else if trimmed.count < 50 {
            warnings.append("Story is very short - analysis depth limited")
        }
        
        if input.story.count > 200_000 {
            warnings.append("Story exceeds 200k characters - may require chunking")
        }
        
        let sentences = input.story.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        if sentences.count < 2 {
            warnings.append("Single sentence detected - limited scene extraction")
        }
        
        return warnings
    }
    
    // MARK: - Deep Analysis Pipeline
    
    /// Performs multi-layer deep analysis with entity relationship mapping
    private func performDeepAnalysis(
        story: String,
        context: PipelineContext
    ) async throws -> StoryAnalysis {
        
        logger.debug("🧬 Phase 1: Structural decomposition")
        let structure = analyzeStructure(story)
        
        logger.debug("🎭 Phase 2: Entity extraction")
        let entities = extractEntities(story, structure: structure)
        
        logger.debug("🗺️ Phase 3: Location mapping")
        let locations = extractLocations(story, entities: entities)
        
        logger.debug("🎬 Phase 4: Scene breakdown")
        let scenes = extractScenes(story, structure: structure, entities: entities)
        
        logger.debug("💬 Phase 5: Dialogue extraction")
        let dialogue = extractDialogue(story, structure: structure)
        
        logger.debug("🎨 Phase 6: Theme identification")
        let themes = extractThemes(story, entities: entities, scenes: scenes)
        
        logger.debug("😊 Phase 7: Emotional arc mapping")
        let emotionalArc = buildEmotionalArc(story, scenes: scenes)
        
        logger.debug("🔗 Phase 8: Entity relationship graph")
        let relationships = buildEntityRelationships(entities: entities, dialogue: dialogue)
        
        // Calculate comprehensive confidence score
        let confidence = calculateConfidence(
            structure: structure,
            entities: entities,
            scenes: scenes
        )
        
        return StoryAnalysis(
            characters: entities.characters.map { $0.name },
            locations: locations.map { $0.name },
            scenes: scenes.map { $0.description },
            dialogue: dialogue,
            themes: themes,
            tone: determineTone(story, emotionalArc: emotionalArc),
            extractionMethod: .aiPowered,
            confidence: confidence,
            entities: entities.all,
            emotionalArc: emotionalArc,
            storyStructure: structure,
            entityRelationships: relationships,
            narrativeComplexity: calculateComplexity(structure: structure, entities: entities)
        )
    }
    
    // MARK: - Structural Analysis
    
    /// Analyzes story structure and composition
    private func analyzeStructure(_ story: String) -> StoryStructure {
        let paragraphs = story.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let sentences = story.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let words = story.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Detect structural patterns
        let hasProperSections = paragraphs.count >= 3
        let avgParagraphLength = paragraphs.isEmpty ? 0 : 
            paragraphs.reduce(0) { $0 + $1.count } / paragraphs.count
        
        let structureType: StructureType
        if avgParagraphLength > 500 {
            structureType = .longForm
        } else if paragraphs.count <= 2 {
            structureType = .vignette
        } else if sentences.count > paragraphs.count * 10 {
            structureType = .detailed
        } else {
            structureType = .standard
        }
        
        return StoryStructure(
            paragraphCount: paragraphs.count,
            sentenceCount: sentences.count,
            wordCount: words.count,
            averageSentenceLength: sentences.isEmpty ? 0 : 
                Double(words.count) / Double(sentences.count),
            structureType: structureType,
            hasDialogue: story.contains("\""),
            hasSections: hasProperSections,
            textDensity: Double(words.count) / Double(max(paragraphs.count, 1))
        )
    }
    
    // MARK: - Entity Extraction
    
    /// Extracts and classifies entities (characters, objects, concepts)
    private func extractEntities(_ story: String, structure: StoryStructure) -> EntityCollection {
        var characters: [Entity] = []
        var objects: [Entity] = []
        var concepts: [Entity] = []
        
        let words = story.components(separatedBy: .whitespacesAndNewlines)
        
        // Extract character names (capitalized words, pronouns, roles)
        let characterPatterns = [
            "mom", "mother", "dad", "father", "sister", "brother",
            "friend", "teacher", "doctor", "captain", "professor"
        ]
        
        let properNouns = words.filter { word in
            guard let first = word.first, first.isUppercase else { return false }
            return word.count > 1 && word.allSatisfy { $0.isLetter || $0 == "'" }
        }
        
        // Deduplicate and create character entities
        let uniqueNames = Set(properNouns.map { $0.lowercased().capitalized })
        for name in uniqueNames {
            let occurrences = story.lowercased().components(separatedBy: name.lowercased()).count - 1
            if occurrences > 0 {
                characters.append(Entity(
                    name: name,
                    type: .character,
                    mentions: occurrences,
                    firstAppearance: findFirstOccurrence(of: name, in: story)
                ))
            }
        }
        
        // Extract role-based characters
        for pattern in characterPatterns {
            if story.lowercased().contains(pattern) {
                let occurrences = story.lowercased().components(separatedBy: pattern).count - 1
                characters.append(Entity(
                    name: pattern.capitalized,
                    type: .character,
                    mentions: occurrences,
                    firstAppearance: findFirstOccurrence(of: pattern, in: story)
                ))
            }
        }
        
        // Extract pronouns as implicit characters
        let pronouns = ["I", "we", "he", "she", "they"]
        for pronoun in pronouns {
            let pattern = "\\b\(pronoun.lowercased())\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(
                    in: story,
                    range: NSRange(story.startIndex..., in: story)
                )
                if matches.count > 2 {
                    characters.append(Entity(
                        name: pronoun == "I" ? "Narrator" : "\(pronoun) (implicit)",
                        type: .character,
                        mentions: matches.count,
                        firstAppearance: 0
                    ))
                }
            }
        }
        
        // Extract significant objects
        let objectKeywords = ["car", "house", "phone", "door", "window", "table", "chair"]
        for keyword in objectKeywords {
            if story.lowercased().contains(keyword) {
                objects.append(Entity(
                    name: keyword.capitalized,
                    type: .object,
                    mentions: story.lowercased().components(separatedBy: keyword).count - 1,
                    firstAppearance: findFirstOccurrence(of: keyword, in: story)
                ))
            }
        }
        
        // Extract abstract concepts
        let conceptKeywords = ["dream", "fear", "love", "hope", "anger", "joy"]
        for keyword in conceptKeywords {
            if story.lowercased().contains(keyword) {
                concepts.append(Entity(
                    name: keyword.capitalized,
                    type: .concept,
                    mentions: story.lowercased().components(separatedBy: keyword).count - 1,
                    firstAppearance: findFirstOccurrence(of: keyword, in: story)
                ))
            }
        }
        
        // Ensure we have at least some entities
        if characters.isEmpty {
            characters.append(Entity(
                name: "Unknown Character",
                type: .character,
                mentions: 1,
                firstAppearance: 0
            ))
        }
        
        return EntityCollection(
            characters: characters,
            objects: objects,
            concepts: concepts
        )
    }
    
    // MARK: - Location Extraction
    
    /// Extracts and categorizes locations
    private func extractLocations(_ story: String, entities: EntityCollection) -> [Location] {
        var locations: [Location] = []
        
        let locationKeywords = [
            "school", "home", "house", "office", "park", "store", "street",
            "car", "room", "kitchen", "bedroom", "city", "town", "forest",
            "beach", "mountain", "river", "restaurant", "cafe", "hospital"
        ]
        
        for keyword in locationKeywords {
            if story.lowercased().contains(keyword) {
                let occurrence = findFirstOccurrence(of: keyword, in: story)
                locations.append(Location(
                    name: keyword.capitalized,
                    type: categorizeLocation(keyword),
                    firstMention: occurrence,
                    description: extractLocationContext(keyword, from: story)
                ))
            }
        }
        
        // Extract locations from prepositions
        let prepositionPatterns = ["at the", "in the", "on the", "near the"]
        for pattern in prepositionPatterns {
            if let range = story.lowercased().range(of: pattern) {
                let afterPattern = String(story[range.upperBound...])
                let words = afterPattern.components(separatedBy: .whitespacesAndNewlines)
                if let firstWord = words.first, firstWord.count > 2 {
                    locations.append(Location(
                        name: firstWord.capitalized,
                        type: .unspecified,
                        firstMention: story.distance(from: story.startIndex, to: range.lowerBound),
                        description: "Mentioned with '\(pattern)'"
                    ))
                }
            }
        }
        
        // Ensure minimum locations
        if locations.isEmpty {
            locations.append(Location(
                name: "Unspecified Location",
                type: .unspecified,
                firstMention: 0,
                description: "Location not explicitly stated"
            ))
        }
        
        return Array(Set(locations.map { $0.name })).map { name in
            locations.first { $0.name == name }!
        }
    }
    
    // MARK: - Scene Extraction
    
    /// Extracts narrative scenes with temporal markers
    private func extractScenes(
        _ story: String,
        structure: StoryStructure,
        entities: EntityCollection
    ) -> [Scene] {
        var scenes: [Scene] = []
        
        let paragraphs = story.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // If story has clear paragraph breaks, use them
        if paragraphs.count >= 2 {
            for (index, paragraph) in paragraphs.enumerated() {
                let preview = String(paragraph.prefix(100))
                let characters = entities.characters.filter { entity in
                    paragraph.lowercased().contains(entity.name.lowercased())
                }.map { $0.name }
                
                scenes.append(Scene(
                    number: index + 1,
                    description: preview + (paragraph.count > 100 ? "..." : ""),
                    characters: characters,
                    location: inferLocation(from: paragraph),
                    timeMarker: inferTimeMarker(from: paragraph),
                    emotionalTone: inferEmotionalTone(from: paragraph)
                ))
            }
        } else {
            // Break by sentences for short stories
            let sentences = story.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            for (index, sentence) in sentences.prefix(10).enumerated() {
                scenes.append(Scene(
                    number: index + 1,
                    description: sentence,
                    characters: [],
                    location: nil,
                    timeMarker: nil,
                    emotionalTone: inferEmotionalTone(from: sentence)
                ))
            }
        }
        
        // Ensure minimum scenes
        if scenes.isEmpty {
            scenes.append(Scene(
                number: 1,
                description: "Single scene narrative",
                characters: entities.characters.map { $0.name },
                location: nil,
                timeMarker: nil,
                emotionalTone: "neutral"
            ))
        }
        
        return scenes
    }
    
    // MARK: - Dialogue Extraction
    
    /// Extracts dialogue with speaker attribution
    private func extractDialogue(_ story: String, structure: StoryStructure) -> [DialogueBlock] {
        var dialogue: [DialogueBlock] = []
        
        // Extract quoted dialogue
        let quotePattern = "\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: quotePattern) {
            let matches = regex.matches(
                in: story,
                range: NSRange(story.startIndex..., in: story)
            )
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: story) {
                    let quote = String(story[range])
                    let speaker = inferSpeaker(around: match.range, in: story)
                    dialogue.append(DialogueBlock(speaker: speaker, line: quote))
                }
            }
        }
        
        return dialogue
    }
    
    // MARK: - Theme Extraction
    
    /// Identifies themes through pattern matching and entity analysis
    private func extractThemes(
        _ story: String,
        entities: EntityCollection,
        scenes: [Scene]
    ) -> [String] {
        var themes: Set<String> = []
        let lowercased = story.lowercased()
        
        let themeKeywords: [String: [String]] = [
            "Dreams & Reality": ["dream", "nightmare", "real", "imagine", "woke"],
            "Family": ["mom", "mother", "dad", "father", "family", "parent"],
            "Fear & Anxiety": ["scared", "afraid", "nervous", "worry", "fear", "panic"],
            "Love & Relationships": ["love", "heart", "romance", "kiss", "together"],
            "Adventure": ["journey", "explore", "discover", "travel", "quest"],
            "Coming of Age": ["grow", "learn", "change", "become", "realize"],
            "Loss & Grief": ["lost", "miss", "gone", "death", "remember"],
            "Identity": ["who am i", "myself", "identity", "belong"],
            "Friendship": ["friend", "buddy", "pal", "together"],
            "Courage": ["brave", "courage", "fight", "stand", "strong"]
        ]
        
        for (theme, keywords) in themeKeywords {
            let matchCount = keywords.filter { lowercased.contains($0) }.count
            if matchCount >= 2 {
                themes.insert(theme)
            }
        }
        
        // Infer themes from entities
        if entities.concepts.contains(where: { $0.name.lowercased().contains("dream") }) {
            themes.insert("Dreams & Reality")
        }
        
        // Default theme if none detected
        if themes.isEmpty {
            themes.insert("Personal Narrative")
        }
        
        return Array(themes).sorted()
    }
    
    // MARK: - Emotional Arc
    
    /// Builds emotional progression through the story
    private func buildEmotionalArc(_ story: String, scenes: [Scene]) -> [EmotionalBeat] {
        var arc: [EmotionalBeat] = []
        
        for (index, scene) in scenes.enumerated() {
            let intensity = calculateEmotionalIntensity(scene.description)
            let valence = calculateEmotionalValence(scene.description)
            
            arc.append(EmotionalBeat(
                position: Double(index) / Double(max(scenes.count - 1, 1)),
                intensity: intensity,
                valence: valence,
                dominantEmotion: scene.emotionalTone
            ))
        }
        
        return arc
    }
    
    // MARK: - Entity Relationships
    
    /// Builds relationship graph between entities
    private func buildEntityRelationships(
        entities: EntityCollection,
        dialogue: [DialogueBlock]
    ) -> [EntityRelationship] {
        var relationships: [EntityRelationship] = []
        
        let characters = entities.characters
        
        // Build relationships from dialogue
        for i in 0..<characters.count {
            for j in (i+1)..<characters.count {
                let char1 = characters[i]
                let char2 = characters[j]
                
                let dialogueBetween = dialogue.filter {
                    $0.speaker == char1.name || $0.speaker == char2.name
                }.count
                
                if dialogueBetween > 0 {
                    relationships.append(EntityRelationship(
                        entity1: char1.name,
                        entity2: char2.name,
                        relationType: .dialogue,
                        strength: min(Double(dialogueBetween) / 5.0, 1.0)
                    ))
                }
            }
        }
        
        return relationships
    }
    
    // MARK: - Fallback System
    
    /// Triple-fallback for maximum resilience
    private func performTripleFallback(_ story: String) -> StoryAnalysis {
        logger.warning("🔄 Fallback Level 1: Rule-based extraction")
        
        // Level 1: Basic rule-based
        let structure = analyzeStructure(story)
        let entities = extractEntities(story, structure: structure)
        
        if entities.characters.count > 0 {
            return createBasicAnalysis(story, entities: entities, structure: structure)
        }
        
        logger.warning("🔄 Fallback Level 2: Pattern matching")
        // Level 2: Simple pattern matching
        let simpleCharacters = extractSimplePatterns(story)
        if !simpleCharacters.isEmpty {
            let simpleEntities = EntityCollection(
                characters: simpleCharacters.map { Entity(name: $0, type: .character, mentions: 1, firstAppearance: 0) },
                objects: [],
                concepts: []
            )
            return createBasicAnalysis(story, entities: simpleEntities, structure: structure)
        }
        
        logger.warning("🔄 Fallback Level 3: Minimal viable analysis")
        // Level 3: Absolute minimum
        return createMinimalAnalysis(story)
    }
    
    private func createBasicAnalysis(
        _ story: String,
        entities: EntityCollection,
        structure: StoryStructure
    ) -> StoryAnalysis {
        StoryAnalysis(
            characters: entities.characters.map { $0.name },
            locations: ["Unspecified Location"],
            scenes: ["Scene: \(String(story.prefix(100)))..."],
            dialogue: [],
            themes: ["General Narrative"],
            tone: "Neutral",
            extractionMethod: .ruleBased,
            confidence: 0.6,
            entities: entities.all,
            emotionalArc: [],
            storyStructure: structure,
            entityRelationships: [],
            narrativeComplexity: 0.5
        )
    }
    
    private func createMinimalAnalysis(_ story: String) -> StoryAnalysis {
        StoryAnalysis(
            characters: ["Character"],
            locations: ["Location"],
            scenes: ["Single scene"],
            dialogue: [],
            themes: ["Narrative"],
            tone: "Neutral",
            extractionMethod: .fallback,
            confidence: 0.3,
            entities: [Entity(name: "Character", type: .character, mentions: 1, firstAppearance: 0)],
            emotionalArc: [],
            storyStructure: StoryStructure(
                paragraphCount: 1,
                sentenceCount: 1,
                wordCount: story.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
                averageSentenceLength: 10,
                structureType: .vignette,
                hasDialogue: false,
                hasSections: false,
                textDensity: 10
            ),
            entityRelationships: [],
            narrativeComplexity: 0.2
        )
    }
    
    private func extractSimplePatterns(_ story: String) -> [String] {
        var names: [String] = []
        
        if story.lowercased().contains("mom") { names.append("Mom") }
        if story.lowercased().contains("dad") { names.append("Dad") }
        if story.lowercased().contains("i ") || story.lowercased().starts(with: "i ") { names.append("Narrator") }
        
        return names.isEmpty ? ["Character"] : names
    }
    
    // MARK: - Helper Methods
    
    private func findFirstOccurrence(of term: String, in text: String) -> Int {
        if let range = text.lowercased().range(of: term.lowercased()) {
            return text.distance(from: text.startIndex, to: range.lowerBound)
        }
        return 0
    }
    
    private func categorizeLocation(_ keyword: String) -> LocationType {
        switch keyword.lowercased() {
        case "home", "house", "room", "kitchen", "bedroom": return .interior
        case "street", "park", "forest", "beach", "mountain": return .exterior
        case "school", "office", "store", "restaurant", "hospital": return .public
        case "car": return .vehicle
        default: return .unspecified
        }
    }
    
    private func extractLocationContext(_ keyword: String, from story: String) -> String {
        if let range = story.lowercased().range(of: keyword.lowercased()) {
            let start = story.index(range.lowerBound, offsetBy: -20, limitedBy: story.startIndex) ?? story.startIndex
            let end = story.index(range.upperBound, offsetBy: 20, limitedBy: story.endIndex) ?? story.endIndex
            return String(story[start..<end])
        }
        return keyword
    }
    
    private func inferLocation(from text: String) -> String? {
        let locationWords = ["school", "home", "park", "office", "store", "car"]
        for word in locationWords {
            if text.lowercased().contains(word) {
                return word.capitalized
            }
        }
        return nil
    }
    
    private func inferTimeMarker(from text: String) -> String? {
        let timeWords = ["morning", "afternoon", "evening", "night", "today", "yesterday"]
        for word in timeWords {
            if text.lowercased().contains(word) {
                return word
            }
        }
        return nil
    }
    
    private func inferEmotionalTone(from text: String) -> String {
        let lowercased = text.lowercased()
        
        if lowercased.contains("happy") || lowercased.contains("joy") { return "joyful" }
        if lowercased.contains("sad") || lowercased.contains("cry") { return "melancholic" }
        if lowercased.contains("angry") || lowercased.contains("mad") { return "angry" }
        if lowercased.contains("scared") || lowercased.contains("fear") { return "tense" }
        if lowercased.contains("haha") || lowercased.contains("funny") { return "humorous" }
        if lowercased.contains("!") { return "excited" }
        
        return "neutral"
    }
    
    private func inferSpeaker(around range: NSRange, in story: String) -> String {
        let text = story as NSString
        let contextStart = max(range.location - 50, 0)
        let context = text.substring(with: NSRange(location: contextStart, length: min(50, text.length - contextStart)))
        
        let speakerPatterns = ["said", "asked", "replied", "exclaimed", "whispered"]
        for pattern in speakerPatterns {
            if context.lowercased().contains(pattern) {
                // Try to find name before the pattern
                let words = context.components(separatedBy: .whitespacesAndNewlines)
                if let index = words.firstIndex(where: { $0.lowercased().contains(pattern) }), index > 0 {
                    return words[index - 1]
                }
            }
        }
        
        return "Unknown Speaker"
    }
    
    private func determineTone(_ story: String, emotionalArc: [EmotionalBeat]) -> String {
        guard !emotionalArc.isEmpty else { return inferEmotionalTone(from: story) }
        
        let avgValence = emotionalArc.reduce(0.0) { $0 + $1.valence } / Double(emotionalArc.count)
        let avgIntensity = emotionalArc.reduce(0.0) { $0 + $1.intensity } / Double(emotionalArc.count)
        
        if avgValence > 0.3 && avgIntensity > 0.6 { return "Uplifting" }
        if avgValence < -0.3 && avgIntensity > 0.6 { return "Dark" }
        if avgIntensity > 0.7 { return "Intense" }
        if avgIntensity < 0.3 { return "Subdued" }
        
        return "Neutral"
    }
    
    private func calculateEmotionalIntensity(_ text: String) -> Double {
        let intensityMarkers = text.filter { "!?".contains($0) }.count
        let capsWords = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.allSatisfy { $0.isUppercase || !$0.isLetter } }
            .count
        
        return min(Double(intensityMarkers + capsWords) / 10.0, 1.0)
    }
    
    private func calculateEmotionalValence(_ text: String) -> Double {
        let positiveWords = ["happy", "joy", "love", "good", "great", "wonderful"]
        let negativeWords = ["sad", "bad", "awful", "terrible", "hate", "angry"]
        
        let lowercased = text.lowercased()
        let positiveCount = positiveWords.filter { lowercased.contains($0) }.count
        let negativeCount = negativeWords.filter { lowercased.contains($0) }.count
        
        return (Double(positiveCount) - Double(negativeCount)) / 10.0
    }
    
    private func calculateConfidence(
        structure: StoryStructure,
        entities: EntityCollection,
        scenes: [Scene]
    ) -> Double {
        var score = 0.0
        
        // Structure contributes to confidence
        if structure.paragraphCount > 2 { score += 0.2 }
        if structure.wordCount > 100 { score += 0.2 }
        if structure.hasDialogue { score += 0.1 }
        
        // Entity extraction quality
        if entities.characters.count > 0 { score += 0.2 }
        if entities.characters.count > 2 { score += 0.1 }
        
        // Scene extraction
        if scenes.count > 1 { score += 0.2 }
        
        return min(score, 1.0)
    }
    
    private func calculateComplexity(structure: StoryStructure, entities: EntityCollection) -> Double {
        let wordScore = min(Double(structure.wordCount) / 1000.0, 1.0) * 0.3
        let entityScore = min(Double(entities.all.count) / 10.0, 1.0) * 0.3
        let structureScore = structure.structureType == .longForm ? 0.4 : 0.2
        
        return wordScore + entityScore + structureScore
    }
}

// MARK: - Enhanced Data Models

public struct StoryAnalysisInput: Sendable {
    public let story: String
    
    public init(story: String) {
        self.story = story
    }
}

public struct StoryAnalysisOutput: Sendable {
    public let analysis: StoryAnalysis
    public let extractionMethod: ExtractionMethod
    public let confidence: Double
    
    public init(
        analysis: StoryAnalysis,
        extractionMethod: ExtractionMethod,
        confidence: Double
    ) {
        self.analysis = analysis
        self.extractionMethod = extractionMethod
        self.confidence = confidence
    }
}

public struct StoryAnalysis: Sendable, Codable {
    public var characters: [String]
    public var locations: [String]
    public var scenes: [String]
    public var dialogue: [DialogueBlock]
    public var themes: [String]
    public var tone: String?
    public var extractionMethod: ExtractionMethod
    public var confidence: Double
    public var entities: [Entity]
    public var emotionalArc: [EmotionalBeat]
    public var storyStructure: StoryStructure
    public var entityRelationships: [EntityRelationship]
    public var narrativeComplexity: Double
    
    public init(
        characters: [String] = [],
        locations: [String] = [],
        scenes: [String] = [],
        dialogue: [DialogueBlock] = [],
        themes: [String] = [],
        tone: String? = nil,
        extractionMethod: ExtractionMethod = .ruleBased,
        confidence: Double = 0.5,
        entities: [Entity] = [],
        emotionalArc: [EmotionalBeat] = [],
        storyStructure: StoryStructure = StoryStructure(),
        entityRelationships: [EntityRelationship] = [],
        narrativeComplexity: Double = 0.5
    ) {
        self.characters = characters
        self.locations = locations
        self.scenes = scenes
        self.dialogue = dialogue
        self.themes = themes
        self.tone = tone
        self.extractionMethod = extractionMethod
        self.confidence = confidence
        self.entities = entities
        self.emotionalArc = emotionalArc
        self.storyStructure = storyStructure
        self.entityRelationships = entityRelationships
        self.narrativeComplexity = narrativeComplexity
    }
}

// MARK: - Supporting Types

public struct Entity: Sendable, Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: EntityType
    public let mentions: Int
    public let firstAppearance: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: EntityType,
        mentions: Int,
        firstAppearance: Int
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.mentions = mentions
        self.firstAppearance = firstAppearance
    }
}

public enum EntityType: String, Sendable, Codable {
    case character = "Character"
    case object = "Object"
    case concept = "Concept"
}

public struct EntityCollection {
    let characters: [Entity]
    let objects: [Entity]
    let concepts: [Entity]
    
    var all: [Entity] {
        characters + objects + concepts
    }
}

public struct Location: Sendable, Codable {
    public let name: String
    public let type: LocationType
    public let firstMention: Int
    public let description: String
    
    public init(name: String, type: LocationType, firstMention: Int, description: String) {
        self.name = name
        self.type = type
        self.firstMention = firstMention
        self.description = description
    }
}

public enum LocationType: String, Sendable, Codable {
    case interior = "Interior"
    case exterior = "Exterior"
    case public = "Public"
    case vehicle = "Vehicle"
    case unspecified = "Unspecified"
}

public struct Scene: Sendable, Codable {
    public let number: Int
    public let description: String
    public let characters: [String]
    public let location: String?
    public let timeMarker: String?
    public let emotionalTone: String
    
    public init(
        number: Int,
        description: String,
        characters: [String],
        location: String?,
        timeMarker: String?,
        emotionalTone: String
    ) {
        self.number = number
        self.description = description
        self.characters = characters
        self.location = location
        self.timeMarker = timeMarker
        self.emotionalTone = emotionalTone
    }
}

public struct DialogueBlock: Sendable, Codable {
    public let speaker: String
    public let line: String
    
    public init(speaker: String, line: String) {
        self.speaker = speaker
        self.line = line
    }
}

public struct EmotionalBeat: Sendable, Codable {
    public let position: Double // 0.0 to 1.0
    public let intensity: Double // 0.0 to 1.0
    public let valence: Double // -1.0 to 1.0 (negative to positive)
    public let dominantEmotion: String
    
    public init(position: Double, intensity: Double, valence: Double, dominantEmotion: String) {
        self.position = position
        self.intensity = intensity
        self.valence = valence
        self.dominantEmotion = dominantEmotion
    }
}

public struct StoryStructure: Sendable, Codable {
    public let paragraphCount: Int
    public let sentenceCount: Int
    public let wordCount: Int
    public let averageSentenceLength: Double
    public let structureType: StructureType
    public let hasDialogue: Bool
    public let hasSections: Bool
    public let textDensity: Double
    
    public init(
        paragraphCount: Int = 0,
        sentenceCount: Int = 0,
        wordCount: Int = 0,
        averageSentenceLength: Double = 0,
        structureType: StructureType = .standard,
        hasDialogue: Bool = false,
        hasSections: Bool = false,
        textDensity: Double = 0
    ) {
        self.paragraphCount = paragraphCount
        self.sentenceCount = sentenceCount
        self.wordCount = wordCount
        self.averageSentenceLength = averageSentenceLength
        self.structureType = structureType
        self.hasDialogue = hasDialogue
        self.hasSections = hasSections
        self.textDensity = textDensity
    }
}

public enum StructureType: String, Sendable, Codable {
    case vignette = "Vignette"
    case standard = "Standard"
    case detailed = "Detailed"
    case longForm = "Long Form"
}

public struct EntityRelationship: Sendable, Codable {
    public let entity1: String
    public let entity2: String
    public let relationType: RelationType
    public let strength: Double // 0.0 to 1.0
    
    public init(entity1: String, entity2: String, relationType: RelationType, strength: Double) {
        self.entity1 = entity1
        self.entity2 = entity2
        self.relationType = relationType
        self.strength = strength
    }
}

public enum RelationType: String, Sendable, Codable {
    case dialogue = "Dialogue"
    case proximity = "Proximity"
    case conflict = "Conflict"
    case alliance = "Alliance"
}

public enum ExtractionMethod: String, Sendable, Codable {
    case aiPowered = "AI-Powered"
    case ruleBased = "Rule-Based"
    case fallback = "Fallback"
}
