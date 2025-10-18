//
//  ToneSystemModels.swift
//  DirectorStudio
//
//  Shared data models for tone analysis and restoration system
//  Version: 1.0.0
//

import Foundation

// MARK: - Tone Memory (Context Carrier Between Phases)

/// The "memory" passed from ToneAnalysisModule to ToneRestorationModule
/// Contains all extracted tone information from the original story
public struct ToneMemory: Sendable, Codable {
    public let globalToneProfile: GlobalToneProfile
    public let sectionTones: [StorySection]
    public let emotionalBeats: [EmotionalBeat]
    public let toneCarrierPhrases: [ToneCarrierPhrase]
    public let stylisticFingerprint: StylisticFingerprint
    public let extractedAt: Date
    public let storyHash: String
    
    public init(
        globalToneProfile: GlobalToneProfile,
        sectionTones: [StorySection],
        emotionalBeats: [EmotionalBeat],
        toneCarrierPhrases: [ToneCarrierPhrase],
        stylisticFingerprint: StylisticFingerprint,
        storyHash: String
    ) {
        self.globalToneProfile = globalToneProfile
        self.sectionTones = sectionTones
        self.emotionalBeats = emotionalBeats
        self.toneCarrierPhrases = toneCarrierPhrases
        self.stylisticFingerprint = stylisticFingerprint
        self.extractedAt = Date()
        self.storyHash = storyHash
    }
}

// MARK: - Global Tone Profile

public struct GlobalToneProfile: Sendable, Codable {
    public let primaryTone: ToneType
    public let secondaryTones: [ToneType]
    public let emotionalRegister: EmotionalRegister
    public let narrativeStyle: NarrativeStyle
    public let pacingStyle: PacingStyle
    public let confidence: Double
    
    public enum ToneType: String, Sendable, Codable, CaseIterable {
        case absurdist, melancholic, nostalgic, haunting
        case tragicomic, whimsical, dark, philosophical
        case hopeful, cynical, poignant, surreal
        case dramatic, comedic, satirical, existential
    }
    
    public enum EmotionalRegister: String, Sendable, Codable {
        case high       // Intense emotions
        case medium     // Balanced
        case low        // Understated
    }
    
    public enum NarrativeStyle: String, Sendable, Codable {
        case lyrical    // Poetic, flowing
        case sparse     // Hemingway-esque
        case baroque    // Ornate, complex
        case clinical   // Detached, precise
        case conversational
    }
    
    public enum PacingStyle: String, Sendable, Codable {
        case frenetic   // Fast, urgent
        case measured   // Deliberate
        case languid    // Slow, dreamlike
        case staccato   // Short, punchy
    }
    
    public init(
        primaryTone: ToneType,
        secondaryTones: [ToneType],
        emotionalRegister: EmotionalRegister,
        narrativeStyle: NarrativeStyle,
        pacingStyle: PacingStyle,
        confidence: Double
    ) {
        self.primaryTone = primaryTone
        self.secondaryTones = secondaryTones
        self.emotionalRegister = emotionalRegister
        self.narrativeStyle = narrativeStyle
        self.pacingStyle = pacingStyle
        self.confidence = confidence
    }
}

// MARK: - Story Section

public struct StorySection: Sendable, Codable, Identifiable {
    public let id: UUID
    public let startIndex: Int
    public let endIndex: Int
    public let text: String
    public let localTone: GlobalToneProfile.ToneType
    public let emotionalArc: EmotionalArc
    public let keyThemes: [String]
    
    public enum EmotionalArc: String, Sendable, Codable {
        case rising     // Building tension
        case falling    // Release/resolution
        case stable     // Steady state
        case oscillating // Back and forth
    }
    
    public init(
        startIndex: Int,
        endIndex: Int,
        text: String,
        localTone: GlobalToneProfile.ToneType,
        emotionalArc: EmotionalArc,
        keyThemes: [String]
    ) {
        self.id = UUID()
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.text = text
        self.localTone = localTone
        self.emotionalArc = emotionalArc
        self.keyThemes = keyThemes
    }
}

// MARK: - Emotional Beat

public struct EmotionalBeat: Sendable, Codable, Identifiable {
    public let id: UUID
    public let position: Int
    public let type: BeatType
    public let intensity: Double
    public let text: String
    public let context: String
    
    public enum BeatType: String, Sendable, Codable {
        case revelation      // Character learns something
        case reversal        // Fortune changes
        case recognition     // Character realizes truth
        case catharsis       // Emotional release
        case irony           // Dramatic irony moment
        case tension         // Conflict escalates
        case tenderness      // Intimate moment
    }
    
    public init(
        position: Int,
        type: BeatType,
        intensity: Double,
        text: String,
        context: String
    ) {
        self.id = UUID()
        self.position = position
        self.type = type
        self.intensity = intensity
        self.text = text
        self.context = context
    }
}

// MARK: - Tone Carrier Phrase

public struct ToneCarrierPhrase: Sendable, Codable, Identifiable {
    public let id: UUID
    public let phrase: String
    public let toneSignature: String
    public let position: Int
    public let importance: Double
    public let category: PhraseCategory
    
    public enum PhraseCategory: String, Sendable, Codable {
        case metaphor
        case characterization
        case atmosphere
        case authorialVoice
        case motif
    }
    
    public init(
        phrase: String,
        toneSignature: String,
        position: Int,
        importance: Double,
        category: PhraseCategory
    ) {
        self.id = UUID()
        self.phrase = phrase
        self.toneSignature = toneSignature
        self.position = position
        self.importance = importance
        self.category = category
    }
}

// MARK: - Stylistic Fingerprint

public struct StylisticFingerprint: Sendable, Codable {
    public let avgSentenceLength: Double
    public let avgWordLength: Double
    public let lexicalDiversity: Double
    public let adjectiveRatio: Double
    public let adverbRatio: Double
    public let metaphorDensity: Double
    public let dialogueRatio: Double
    public let paragraphLengthVariance: Double
    public let punctuationProfile: PunctuationProfile
    
    public struct PunctuationProfile: Sendable, Codable {
        public let periodFrequency: Double
        public let commaFrequency: Double
        public let dashFrequency: Double
        public let ellipsisFrequency: Double
        public let exclamationFrequency: Double
        public let questionFrequency: Double
        
        public init(
            periodFrequency: Double,
            commaFrequency: Double,
            dashFrequency: Double,
            ellipsisFrequency: Double,
            exclamationFrequency: Double,
            questionFrequency: Double
        ) {
            self.periodFrequency = periodFrequency
            self.commaFrequency = commaFrequency
            self.dashFrequency = dashFrequency
            self.ellipsisFrequency = ellipsisFrequency
            self.exclamationFrequency = exclamationFrequency
            self.questionFrequency = questionFrequency
        }
    }
    
    public init(
        avgSentenceLength: Double,
        avgWordLength: Double,
        lexicalDiversity: Double,
        adjectiveRatio: Double,
        adverbRatio: Double,
        metaphorDensity: Double,
        dialogueRatio: Double,
        paragraphLengthVariance: Double,
        punctuationProfile: PunctuationProfile
    ) {
        self.avgSentenceLength = avgSentenceLength
        self.avgWordLength = avgWordLength
        self.lexicalDiversity = lexicalDiversity
        self.adjectiveRatio = adjectiveRatio
        self.adverbRatio = adverbRatio
        self.metaphorDensity = metaphorDensity
        self.dialogueRatio = dialogueRatio
        self.paragraphLengthVariance = paragraphLengthVariance
        self.punctuationProfile = punctuationProfile
    }
}

// MARK: - Metadata

public struct ToneExtractionMetadata: Sendable {
    public let totalSections: Int
    public let totalBeats: Int
    public let totalCarrierPhrases: Int
    public let extractionDuration: TimeInterval
    public let analysisMethod: AnalysisMethod
    public let confidence: Double
    
    public enum AnalysisMethod: String, Sendable {
        case aiPowered
        case heuristic
        case hybrid
    }
    
    public init(
        totalSections: Int,
        totalBeats: Int,
        totalCarrierPhrases: Int,
        extractionDuration: TimeInterval,
        analysisMethod: AnalysisMethod,
        confidence: Double
    ) {
        self.totalSections = totalSections
        self.totalBeats = totalBeats
        self.totalCarrierPhrases = totalCarrierPhrases
        self.extractionDuration = extractionDuration
        self.analysisMethod = analysisMethod
        self.confidence = confidence
    }
}

// MARK: - Pipeline Config Extension

extension PipelineConfig {
    // Tone system configuration
    public var isToneAnalysisEnabled: Bool {
        get { true }
        set { }
    }
    
    public var isToneRestorationEnabled: Bool {
        get { true }
        set { }
    }
    
    public var toneDriftThreshold: Double {
        get { 0.3 }
        set { }
    }
    
    public var useAIForToneRestoration: Bool {
        get { aiServiceKey != nil }
        set { }
    }
}
