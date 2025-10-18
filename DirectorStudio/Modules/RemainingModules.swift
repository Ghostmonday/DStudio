//
//  RemainingModules.swift
//  DirectorStudio
//
//  UPGRADED: Enhanced Cinematic Taxonomy and Packaging modules
//  Cinematic Taxonomy adds rich visual metadata, Packaging creates comprehensive output
//

import Foundation
import OSLog

// MARK: - Cinematic Taxonomy Module

/// Advanced cinematic enrichment with shot types, camera movements, lighting, and mood
/// Transforms segments into production-ready visual specifications
public struct CinematicTaxonomyModule: PipelineModule {
    public typealias Input = CinematicTaxonomyInput
    public typealias Output = CinematicTaxonomyOutput
    
    public let moduleID = "com.directorstudio.taxonomy"
    public let moduleName = "Cinematic Taxonomy"
    public let version = "2.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "taxonomy")
    
    public init() {}
    
    public func execute(
        input: CinematicTaxonomyInput,
        context: PipelineContext
    ) async -> Result<CinematicTaxonomyOutput, PipelineError> {
        logger.info("🎬 Starting cinematic taxonomy enrichment [v2.0] for \(input.segments.count) segments")
        
        let startTime = Date()
        var enrichedSegments: [PromptSegment] = []
        
        // Analyze overall narrative arc for consistent visual treatment
        let narrativeArc = analyzeNarrativeArc(input.segments)
        logger.debug("📊 Narrative arc: \(narrativeArc.summary)")
        
        // Enrich each segment with cinematic metadata
        for (index, segment) in input.segments.enumerated() {
            let position = Double(index) / Double(max(input.segments.count - 1, 1))
            
            // Determine cinematic treatment based on content and position
            let treatment = determineCinematicTreatment(
                segment: segment,
                position: position,
                narrativeArc: narrativeArc
            )
            
            // Apply cinematic metadata
            var enriched = segment
            enriched.text = enhanceWithCinematicDescription(
                segment.text,
                treatment: treatment
            )
            
            // Add structured metadata
            enriched.metadata = buildCinematicMetadata(
                treatment: treatment,
                position: position,
                originalMetadata: segment.metadata
            )
            
            enrichedSegments.append(enriched)
            
            logger.debug("🎥 Segment \(index + 1): \(treatment.shotType.rawValue), \(treatment.cameraMovement.rawValue), \(treatment.lighting.rawValue)")
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = CinematicTaxonomyOutput(
            enrichedSegments: enrichedSegments,
            totalProcessed: enrichedSegments.count,
            narrativeArc: narrativeArc
        )
        
        logger.info("✅ Cinematic enrichment completed in \(String(format: "%.2f", executionTime))s")
        
        return .success(output)
    }
    
    public func validate(input: CinematicTaxonomyInput) -> [String] {
        var warnings: [String] = []
        
        if input.segments.isEmpty {
            warnings.append("No segments provided for cinematic enrichment")
        }
        
        return warnings
    }
    
    // MARK: - Narrative Arc Analysis
    
    /// Analyzes the overall narrative structure for visual consistency
    private func analyzeNarrativeArc(_ segments: [PromptSegment]) -> NarrativeArc {
        let totalSegments = segments.count
        
        // Detect act structure
        let act1End = totalSegments / 4
        let act2End = (totalSegments * 3) / 4
        
        // Analyze emotional progression
        var emotionalCurve: [Double] = []
        for segment in segments {
            let intensity = detectEmotionalIntensity(segment.text)
            emotionalCurve.append(intensity)
        }
        
        // Detect climax position
        let climaxPosition = emotionalCurve.enumerated()
            .max(by: { $0.element < $1.element })?.offset ?? (totalSegments * 3) / 4
        
        // Determine overall tone
        let overallTone = determineOverallTone(segments)
        
        return NarrativeArc(
            totalSegments: totalSegments,
            act1End: act1End,
            act2End: act2End,
            climaxPosition: climaxPosition,
            emotionalCurve: emotionalCurve,
            overallTone: overallTone
        )
    }
    
    // MARK: - Cinematic Treatment
    
    /// Determines appropriate cinematic treatment for a segment
    private func determineCinematicTreatment(
        segment: PromptSegment,
        position: Double,
        narrativeArc: NarrativeArc
    ) -> CinematicTreatment {
        
        let text = segment.text.lowercased()
        let segmentIndex = segment.order - 1
        
        // Determine shot type based on content and position
        let shotType = determineShotType(
            text: text,
            position: position,
            narrativeArc: narrativeArc
        )
        
        // Determine camera movement
        let cameraMovement = determineCameraMovement(
            text: text,
            shotType: shotType,
            position: position
        )
        
        // Determine lighting style
        let lighting = determineLighting(
            text: text,
            position: position,
            tone: narrativeArc.overallTone
        )
        
        // Determine color palette
        let colorPalette = determineColorPalette(
            text: text,
            lighting: lighting,
            tone: narrativeArc.overallTone
        )
        
        // Determine mood/atmosphere
        let mood = determineMood(text: text, narrativeArc: narrativeArc)
        
        // Determine frame composition
        let composition = determineComposition(
            shotType: shotType,
            position: position
        )
        
        // Determine depth of field
        let depthOfField = determineDepthOfField(shotType: shotType)
        
        return CinematicTreatment(
            shotType: shotType,
            cameraMovement: cameraMovement,
            cameraAngle: determineCameraAngle(text: text, shotType: shotType),
            lighting: lighting,
            colorPalette: colorPalette,
            mood: mood,
            composition: composition,
            depthOfField: depthOfField,
            transitionSuggestion: determineTransition(position: position, text: text)
        )
    }
    
    // MARK: - Visual Element Determination
    
    private func determineShotType(
        text: String,
        position: Double,
        narrativeArc: NarrativeArc
    ) -> ShotType {
        // Opening and closing tend to be wider
        if position < 0.1 || position > 0.9 {
            return .wide
        }
        
        // Dialogue detection
        if text.contains("\"") || text.contains("said") || text.contains("asked") {
            return .medium
        }
        
        // Action detection
        if text.contains("ran") || text.contains("jumped") || text.contains("moved") {
            return .full
        }
        
        // Emotional moments
        let emotionalKeywords = ["tears", "smiled", "whispered", "stared"]
        if emotionalKeywords.contains(where: { text.contains($0) }) {
            return .closeUp
        }
        
        // Climax gets dramatic shots
        if abs(Double(narrativeArc.climaxPosition) / Double(narrativeArc.totalSegments) - position) < 0.1 {
            return .extreme Closeup
        }
        
        return .medium
    }
    
    private func determineCameraMovement(
        text: String,
        shotType: ShotType,
        position: Double
    ) -> CameraMovement {
        // Opening often has establishing movement
        if position < 0.05 {
            return .dollyIn
        }
        
        // Action sequences
        if text.contains("ran") || text.contains("chase") || text.contains("rushed") {
            return .tracking
        }
        
        // Revelation moments
        if text.contains("revealed") || text.contains("suddenly") || text.contains("appeared") {
            return .zoom
        }
        
        // Dramatic moments
        if text.contains("slowly") || text.contains("careful") {
            return .dolly
        }
        
        // Most shots are static for stability
        return .static
    }
    
    private func determineCameraAngle(text: String, shotType: ShotType) -> CameraAngle {
        // Power dynamics
        if text.contains("tower") || text.contains("above") || text.contains("looked down") {
            return .high
        }
        
        if text.contains("small") || text.contains("vulnerable") || text.contains("looked up") {
            return .low
        }
        
        // Disorientation
        if text.contains("dizzy") || text.contains("confused") || text.contains("dream") {
            return .dutch
        }
        
        // Default to eye level
        return .eyeLevel
    }
    
    private func determineLighting(
        text: String,
        position: Double,
        tone: String
    ) -> Lighting {
        // Time of day keywords
        if text.contains("night") || text.contains("dark") || text.contains("shadow") {
            return .lowKey
        }
        
        if text.contains("bright") || text.contains("sunlight") || text.contains("morning") {
            return .highKey
        }
        
        // Emotional tone
        if tone == "dark" || tone == "tense" {
            return .dramatic
        }
        
        // Dream sequences
        if text.contains("dream") || text.contains("surreal") {
            return .silhouette
        }
        
        return .natural
    }
    
    private func determineColorPalette(
        text: String,
        lighting: Lighting,
        tone: String
    ) -> String {
        if text.contains("warm") || text.contains("sunset") || text.contains("fire") {
            return "Warm (oranges, reds, yellows)"
        }
        
        if text.contains("cold") || text.contains("ice") || text.contains("blue") {
            return "Cool (blues, teals, silvers)"
        }
        
        if text.contains("dream") || text.contains("memory") {
            return "Desaturated (muted, nostalgic)"
        }
        
        if tone == "dark" {
            return "Dark (deep blues, blacks, minimal color)"
        }
        
        return "Natural (balanced, realistic)"
    }
    
    private func determineMood(text: String, narrativeArc: NarrativeArc) -> String {
        let moodKeywords: [String: String] = [
            "tense": "Tense, suspenseful",
            "peaceful": "Calm, serene",
            "chaotic": "Frenetic, overwhelming",
            "intimate": "Intimate, personal",
            "epic": "Epic, grand",
            "mysterious": "Mysterious, enigmatic",
            "joyful": "Joyful, uplifting",
            "melancholic": "Melancholic, bittersweet"
        ]
        
        for (keyword, mood) in moodKeywords {
            if text.contains(keyword) {
                return mood
            }
        }
        
        return "Neutral, observational"
    }
    
    private func determineComposition(
        shotType: ShotType,
        position: Double
    ) -> String {
        switch shotType {
        case .wide, .extreme Wide:
            return "Rule of thirds, subject in lower third or asymmetric"
        case .full, .medium:
            return "Centered or slightly off-center, balanced"
        case .closeUp, .extremeCloseup:
            return "Face/subject fills frame, minimal negative space"
        case .twoShot:
            return "Two subjects balanced in frame"
        case .overShoulder:
            return "Over-shoulder perspective, depth layering"
        }
    }
    
    private func determineDepthOfField(shotType: ShotType) -> String {
        switch shotType {
        case .wide, .extremeWide:
            return "Deep focus (f/8-f/16)"
        case .medium, .full:
            return "Moderate depth (f/4-f/5.6)"
        case .closeUp, .extremeCloseup:
            return "Shallow focus (f/1.8-f/2.8)"
        default:
            return "Moderate depth (f/4-f/5.6)"
        }
    }
    
    private func determineTransition(position: Double, text: String) -> String {
        // Opening
        if position < 0.05 {
            return "Fade in from black"
        }
        
        // Closing
        if position > 0.95 {
            return "Fade to black"
        }
        
        // Scene transitions
        if text.contains("meanwhile") || text.contains("elsewhere") {
            return "Cross-dissolve"
        }
        
        if text.contains("suddenly") || text.contains("then") {
            return "Hard cut"
        }
        
        return "Standard cut"
    }
    
    // MARK: - Enhancement
    
    /// Enhances segment text with cinematic description
    private func enhanceWithCinematicDescription(
        _ text: String,
        treatment: CinematicTreatment
    ) -> String {
        // Build cinematic prefix
        let prefix = """
        [SHOT: \(treatment.shotType.rawValue) | CAMERA: \(treatment.cameraMovement.rawValue), \(treatment.cameraAngle.rawValue) | LIGHTING: \(treatment.lighting.rawValue) | MOOD: \(treatment.mood)]
        
        """
        
        return prefix + text
    }
    
    /// Builds structured cinematic metadata
    private func buildCinematicMetadata(
        treatment: CinematicTreatment,
        position: Double,
        originalMetadata: [String: String]
    ) -> [String: String] {
        var metadata = originalMetadata
        
        metadata["shotType"] = treatment.shotType.rawValue
        metadata["cameraMovement"] = treatment.cameraMovement.rawValue
        metadata["cameraAngle"] = treatment.cameraAngle.rawValue
        metadata["lighting"] = treatment.lighting.rawValue
        metadata["colorPalette"] = treatment.colorPalette
        metadata["mood"] = treatment.mood
        metadata["composition"] = treatment.composition
        metadata["depthOfField"] = treatment.depthOfField
        metadata["transition"] = treatment.transitionSuggestion
        metadata["narrativePosition"] = String(format: "%.2f", position)
        
        return metadata
    }
    
    // MARK: - Helper Methods
    
    private func detectEmotionalIntensity(_ text: String) -> Double {
        let intensityMarkers = text.filter { "!?".contains($0) }.count
        let emphasisWords = ["very", "extremely", "incredibly", "absolutely"]
        let emphasisCount = emphasisWords.filter { text.lowercased().contains($0) }.count
        
        return min((Double(intensityMarkers) + Double(emphasisCount) * 0.5) / 5.0, 1.0)
    }
    
    private func determineOverallTone(_ segments: [PromptSegment]) -> String {
        let allText = segments.map { $0.text.lowercased() }.joined(separator: " ")
        
        if allText.contains("dark") || allText.contains("scary") || allText.contains("fear") {
            return "dark"
        }
        
        if allText.contains("happy") || allText.contains("joy") || allText.contains("laugh") {
            return "light"
        }
        
        if allText.contains("dream") || allText.contains("surreal") {
            return "dreamlike"
        }
        
        return "neutral"
    }
}

// MARK: - Packaging Module

/// Final packaging module that assembles all pipeline outputs into comprehensive deliverable
/// Creates production-ready screenplay format with full metadata
public struct PackagingModule: PipelineModule {
    public typealias Input = PackagingInput
    public typealias Output = PackagingOutput
    
    public let moduleID = "com.directorstudio.packaging"
    public let moduleName = "Packaging"
    public let version = "2.0.0"
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "packaging")
    
    public init() {}
    
    public func execute(
        input: PackagingInput,
        context: PipelineContext
    ) async -> Result<PackagingOutput, PipelineError> {
        logger.info("📦 Starting comprehensive packaging [v2.0]")
        
        let startTime = Date()
        
        // Build execution summary
        let executionSummary = buildExecutionSummary(input: input, context: context)
        
        // Build quality metrics
        let qualityMetrics = calculateQualityMetrics(input: input)
        
        // Build production notes
        let productionNotes = generateProductionNotes(input: input)
        
        // Package everything into final output
        let packagedOutput = PipelineOutput(
            projectTitle: input.projectTitle,
            originalStory: input.originalStory,
            processedStory: input.rewordedStory,
            segments: input.segments,
            analysis: input.analysis,
            continuityAnchors: input.continuityAnchors,
            executionMetadata: buildMetadata(
                summary: executionSummary,
                metrics: qualityMetrics,
                sessionID: context.sessionID
            ),
            qualityScore: qualityMetrics.overallScore,
            productionNotes: productionNotes,
            exportFormats: generateExportFormats(input: input)
        )
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = PackagingOutput(
            packagedOutput: packagedOutput,
            summary: executionSummary
        )
        
        logger.info("✅ Packaging completed in \(String(format: "%.2f", executionTime))s")
        logger.info("📊 Quality Score: \(String(format: "%.2f", qualityMetrics.overallScore)) | Segments: \(input.segments.count) | Processing: \(executionSummary)")
        
        return .success(output)
    }
    
    public func validate(input: PackagingInput) -> [String] {
        var warnings: [String] = []
        
        if input.segments.isEmpty {
            warnings.append("No segments to package - output will be minimal")
        }
        
        if input.originalStory.isEmpty {
            warnings.append("Original story is empty")
        }
        
        return warnings
    }
    
    public func canSkip() -> Bool {
        false // Packaging should always run
    }
    
    // MARK: - Summary Generation
    
    private func buildExecutionSummary(
        input: PackagingInput,
        context: PipelineContext
    ) -> String {
        var components: [String] = []
        
        if input.rewordedStory != nil {
            components.append("Reworded")
        }
        
        if input.analysis != nil {
            components.append("Analyzed")
        }
        
        components.append("\(input.segments.count) segments")
        
        if !input.continuityAnchors.isEmpty {
            components.append("\(input.continuityAnchors.count) continuity anchors")
        }
        
        return components.joined(separator: " | ")
    }
    
    // MARK: - Quality Metrics
    
    private func calculateQualityMetrics(input: PackagingInput) -> QualityMetrics {
        var scores: [Double] = []
        
        // Segmentation quality (based on count and consistency)
        let segmentScore = calculateSegmentationScore(input.segments)
        scores.append(segmentScore)
        
        // Analysis quality (if available)
        if let analysis = input.analysis {
            let analysisScore = calculateAnalysisScore(analysis)
            scores.append(analysisScore)
        }
        
        // Continuity quality (if available)
        if !input.continuityAnchors.isEmpty {
            let continuityScore = Double(min(input.continuityAnchors.count, 10)) / 10.0
            scores.append(continuityScore)
        }
        
        // Processing quality (rewording applied)
        if input.rewordedStory != nil {
            scores.append(0.8)
        }
        
        let overallScore = scores.isEmpty ? 0.5 : scores.reduce(0, +) / Double(scores.count)
        
        return QualityMetrics(
            overallScore: overallScore,
            segmentationScore: segmentScore,
            analysisScore: input.analysis != nil ? calculateAnalysisScore(input.analysis!) : nil,
            continuityScore: !input.continuityAnchors.isEmpty ? Double(min(input.continuityAnchors.count, 10)) / 10.0 : nil
        )
    }
    
    private func calculateSegmentationScore(_ segments: [PromptSegment]) -> Double {
        guard !segments.isEmpty else { return 0.0 }
        
        // Score based on reasonable segment count and consistency
        let countScore = min(Double(segments.count) / 20.0, 1.0)
        
        // Check duration consistency
        let durations = segments.map { $0.duration }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.reduce(0.0) { sum, duration in
            sum + pow(duration - avgDuration, 2)
        } / Double(durations.count)
        let consistencyScore = max(0.0, 1.0 - (sqrt(variance) / avgDuration))
        
        return (countScore + consistencyScore) / 2.0
    }
    
    private func calculateAnalysisScore(_ analysis: StoryAnalysis) -> Double {
        var score = 0.0
        
        if !analysis.characters.isEmpty { score += 0.25 }
        if !analysis.locations.isEmpty { score += 0.25 }
        if !analysis.scenes.isEmpty { score += 0.25 }
        if !analysis.themes.isEmpty { score += 0.25 }
        
        // Bonus for confidence
        score *= analysis.confidence
        
        return score
    }
    
    // MARK: - Production Notes
    
    private func generateProductionNotes(input: PackagingInput) -> [String] {
        var notes: [String] = []
        
        // Segment count note
        notes.append("Project contains \(input.segments.count) video segments")
        
        // Story length note
        let wordCount = input.originalStory.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        notes.append("Original story: \(wordCount) words")
        
        // Analysis insights
        if let analysis = input.analysis {
            if !analysis.characters.isEmpty {
                notes.append("Main characters: \(analysis.characters.prefix(3).joined(separator: ", "))")
            }
            if !analysis.themes.isEmpty {
                notes.append("Themes: \(analysis.themes.joined(separator: ", "))")
            }
        }
        
        // Segment duration note
        if !input.segments.isEmpty {
            let totalDuration = input.segments.reduce(0.0) { $0 + $1.duration }
            notes.append("Total runtime: \(String(format: "%.1f", totalDuration)) seconds")
        }
        
        // Continuity note
        if !input.continuityAnchors.isEmpty {
            notes.append("Continuity anchors: \(input.continuityAnchors.count) visual consistency markers")
        }
        
        return notes
    }
    
    // MARK: - Metadata Building
    
    private func buildMetadata(
        summary: String,
        metrics: QualityMetrics,
        sessionID: UUID
    ) -> [String: String] {
        [
            "sessionID": sessionID.uuidString,
            "completionTime": ISO8601DateFormatter().string(from: Date()),
            "summary": summary,
            "overallQuality": String(format: "%.2f", metrics.overallScore),
            "pipelineVersion": "2.0.0"
        ]
    }
    
    // MARK: - Export Formats
    
    private func generateExportFormats(input: PackagingInput) -> [String: String] {
        var formats: [String: String] = [:]
        
        // JSON format
        formats["json"] = "Structured JSON with all segments and metadata"
        
        // Screenplay format
        formats["screenplay"] = "Traditional screenplay format with scene descriptions"
        
        // Shot list format
        formats["shotList"] = "Production shot list with technical details"
        
        // Storyboard format
        formats["storyboard"] = "Segment-by-segment storyboard layout"
        
        return formats
    }
}

// MARK: - Supporting Types

public struct CinematicTaxonomyInput: Sendable {
    public let segments: [PromptSegment]
    
    public init(segments: [PromptSegment]) {
        self.segments = segments
    }
}

public struct CinematicTaxonomyOutput: Sendable {
    public let enrichedSegments: [PromptSegment]
    public let totalProcessed: Int
    public let narrativeArc: NarrativeArc
    
    public init(
        enrichedSegments: [PromptSegment],
        totalProcessed: Int,
        narrativeArc: NarrativeArc = NarrativeArc()
    ) {
        self.enrichedSegments = enrichedSegments
        self.totalProcessed = totalProcessed
        self.narrativeArc = narrativeArc
    }
}

public struct PackagingInput: Sendable {
    public let originalStory: String
    public let rewordedStory: String?
    public let analysis: StoryAnalysis?
    public let segments: [PromptSegment]
    public let continuityAnchors: [ContinuityAnchor]
    public let projectTitle: String
    
    public init(
        originalStory: String,
        rewordedStory: String?,
        analysis: StoryAnalysis?,
        segments: [PromptSegment],
        continuityAnchors: [ContinuityAnchor],
        projectTitle: String
    ) {
        self.originalStory = originalStory
        self.rewordedStory = rewordedStory
        self.analysis = analysis
        self.segments = segments
        self.continuityAnchors = continuityAnchors
        self.projectTitle = projectTitle
    }
}

public struct PackagingOutput: Sendable {
    public let packagedOutput: PipelineOutput
    public let summary: String
    
    public init(packagedOutput: PipelineOutput, summary: String = "") {
        self.packagedOutput = packagedOutput
        self.summary = summary
    }
}

public struct PipelineOutput: Sendable {
    public let projectTitle: String
    public let originalStory: String
    public let processedStory: String?
    public let segments: [PromptSegment]
    public let analysis: StoryAnalysis?
    public let continuityAnchors: [ContinuityAnchor]
    public let executionMetadata: [String: String]
    public let qualityScore: Double
    public let productionNotes: [String]
    public let exportFormats: [String: String]
    
    public init(
        projectTitle: String,
        originalStory: String,
        processedStory: String?,
        segments: [PromptSegment],
        analysis: StoryAnalysis?,
        continuityAnchors: [ContinuityAnchor],
        executionMetadata: [String: String],
        qualityScore: Double = 0.0,
        productionNotes: [String] = [],
        exportFormats: [String: String] = [:]
    ) {
        self.projectTitle = projectTitle
        self.originalStory = originalStory
        self.processedStory = processedStory
        self.segments = segments
        self.analysis = analysis
        self.continuityAnchors = continuityAnchors
        self.executionMetadata = executionMetadata
        self.qualityScore = qualityScore
        self.productionNotes = productionNotes
        self.exportFormats = exportFormats
    }
}

public struct ContinuityAnchor: Sendable, Codable {
    public let id: UUID
    public var characterName: String
    public var description: String
    
    public init(id: UUID = UUID(), characterName: String, description: String) {
        self.id = id
        self.characterName = characterName
        self.description = description
    }
}

// MARK: - Cinematic Types

private struct CinematicTreatment {
    let shotType: ShotType
    let cameraMovement: CameraMovement
    let cameraAngle: CameraAngle
    let lighting: Lighting
    let colorPalette: String
    let mood: String
    let composition: String
    let depthOfField: String
    let transitionSuggestion: String
}

private enum ShotType: String {
    case extremeWide = "Extreme Wide Shot (EWS)"
    case wide = "Wide Shot (WS)"
    case full = "Full Shot (FS)"
    case medium = "Medium Shot (MS)"
    case closeUp = "Close-Up (CU)"
    case extremeCloseup = "Extreme Close-Up (ECU)"
    case twoShot = "Two Shot"
    case overShoulder = "Over-the-Shoulder (OTS)"
}

private enum CameraMovement: String {
    case `static` = "Static"
    case pan = "Pan"
    case tilt = "Tilt"
    case dolly = "Dolly"
    case dollyIn = "Dolly In"
    case dollyOut = "Dolly Out"
    case tracking = "Tracking"
    case crane = "Crane"
    case steadicam = "Steadicam"
    case handheld = "Handheld"
    case zoom = "Zoom"
}

private enum CameraAngle: String {
    case eyeLevel = "Eye Level"
    case high = "High Angle"
    case low = "Low Angle"
    case dutch = "Dutch Angle"
    case overhead = "Overhead"
    case aerial = "Aerial"
}

private enum Lighting: String {
    case natural = "Natural"
    case highKey = "High Key"
    case lowKey = "Low Key"
    case dramatic = "Dramatic"
    case silhouette = "Silhouette"
    case backlit = "Backlit"
    case practical = "Practical"
}

public struct NarrativeArc: Sendable {
    let totalSegments: Int
    let act1End: Int
    let act2End: Int
    let climaxPosition: Int
    let emotionalCurve: [Double]
    let overallTone: String
    
    init(
        totalSegments: Int = 0,
        act1End: Int = 0,
        act2End: Int = 0,
        climaxPosition: Int = 0,
        emotionalCurve: [Double] = [],
        overallTone: String = "neutral"
    ) {
        self.totalSegments = totalSegments
        self.act1End = act1End
        self.act2End = act2End
        self.climaxPosition = climaxPosition
        self.emotionalCurve = emotionalCurve
        self.overallTone = overallTone
    }
    
    var summary: String {
        "total=\(totalSegments), climax@\(climaxPosition), tone=\(overallTone)"
    }
}

private struct QualityMetrics {
    let overallScore: Double
    let segmentationScore: Double
    let analysisScore: Double?
    let continuityScore: Double?
}
