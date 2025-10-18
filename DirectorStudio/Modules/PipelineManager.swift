//
//  PipelineManager.swift
//  DirectorStudio
//
//  Central orchestrator for the pipeline execution
//  Manages module execution, state, and error handling
//

import Foundation
import OSLog
import Observation

// MARK: - Pipeline Manager

/// Central manager that orchestrates pipeline execution
/// Handles module sequencing, state management, and error recovery
@Observable
@MainActor
public final class PipelineManager {
    
    // MARK: - Properties
    
    public private(set) var config: PipelineConfig
    public private(set) var isRunning: Bool = false
    public private(set) var currentStep: Int = 0
    public private(set) var steps: [PipelineStepInfo] = []
    public private(set) var sessionID: UUID = UUID()
    public private(set) var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.directorstudio.pipeline", category: "manager")
    private var cancellationToken: Bool = false
    
    // Module instances
    private var rewordingModule: RewordingModule?
    private var storyAnalysisModule: StoryAnalysisModule?
    private var segmentationModule: SegmentationModule?
    private var taxonomyModule: CinematicTaxonomyModule?
    private var continuityModule: ContinuityModule?
    private var packagingModule: PackagingModule?
    
    // Shared state between modules
    private var pipelineState: PipelineState
    
    // MARK: - Initialization
    
    public init(config: PipelineConfig = .default) {
        self.config = config
        self.pipelineState = PipelineState()
        self.steps = Self.createStepInfo()
    }
    
    // MARK: - Public API
    
    /// Execute the full pipeline with given input
    /// - Parameters:
    ///   - input: The pipeline input containing story and settings
    /// - Returns: The final packaged output
    public func execute(input: PipelineInput) async throws -> PipelineOutput {
        // Reset state
        resetPipeline()
        
        // Validate configuration
        let configWarnings = config.validate()
        if !configWarnings.isEmpty {
            logger.warning("Configuration warnings: \(configWarnings.joined(separator: ", "))")
        }
        
        // Initialize modules
        try await initializeModules()
        
        // Create context
        let context = PipelineContext(
            config: config,
            logger: logger,
            sessionID: sessionID,
            startTime: Date(),
            metadata: ["projectTitle": input.projectTitle]
        )
        
        // Execute pipeline stages
        isRunning = true
        defer { isRunning = false }
        
        do {
            // Stage 1: Rewording
            if config.isRewordingEnabled {
                try await executeStep(
                    stepNumber: 1,
                    name: "Rewording"
                ) {
                    try await self.executeRewording(
                        story: input.story,
                        rewordType: input.rewordType,
                        context: context
                    )
                }
            }
            
            // Stage 2: Story Analysis
            if config.isStoryAnalysisEnabled {
                try await executeStep(
                    stepNumber: 2,
                    name: "Story Analysis"
                ) {
                    try await self.executeStoryAnalysis(
                        story: pipelineState.rewordedStory ?? input.story,
                        context: context
                    )
                }
            }
            
            // Stage 3: Segmentation
            if config.isSegmentationEnabled {
                try await executeStep(
                    stepNumber: 3,
                    name: "Segmentation"
                ) {
                    try await self.executeSegmentation(
                        story: pipelineState.rewordedStory ?? input.story,
                        context: context
                    )
                }
            }
            
            // Stage 4: Cinematic Taxonomy
            if config.isCinematicTaxonomyEnabled && pipelineState.segments != nil {
                try await executeStep(
                    stepNumber: 4,
                    name: "Cinematic Taxonomy"
                ) {
                    try await self.executeCinematicTaxonomy(
                        segments: pipelineState.segments!,
                        context: context
                    )
                }
            }
            
            // Stage 5: Continuity
            if config.isContinuityEnabled {
                try await executeStep(
                    stepNumber: 5,
                    name: "Continuity"
                ) {
                    try await self.executeContinuity(
                        story: pipelineState.rewordedStory ?? input.story,
                        analysis: pipelineState.storyAnalysis,
                        context: context
                    )
                }
            }
            
            // Stage 6: Packaging (always run if enabled)
            if config.isPackagingEnabled {
                try await executeStep(
                    stepNumber: 6,
                    name: "Packaging"
                ) {
                    try await self.executePackaging(
                        input: input,
                        context: context
                    )
                }
            }
            
            // Build final output
            guard let output = pipelineState.finalOutput else {
                throw PipelineError.executionFailed(
                    module: "PipelineManager",
                    reason: "No output generated - check enabled modules"
                )
            }
            
            logger.info("Pipeline execution completed successfully")
            return output
            
        } catch {
            let errorMsg = "Pipeline execution failed: \(error.localizedDescription)"
            logger.error("\(errorMsg)")
            errorMessage = errorMsg
            throw error
        }
    }
    
    /// Execute a single step independently
    /// - Parameters:
    ///   - stepNumber: The step number (1-6)
    ///   - input: Input data for the step
    /// - Returns: The step output
    public func executeIndividualStep(
        stepNumber: Int,
        input: Any
    ) async throws -> Any {
        guard (1...6).contains(stepNumber) else {
            throw PipelineError.invalidInput(
                module: "PipelineManager",
                reason: "Invalid step number: \(stepNumber)"
            )
        }
        
        try await initializeModules()
        
        let context = PipelineContext(
            config: config,
            logger: logger,
            sessionID: UUID(),
            startTime: Date()
        )
        
        isRunning = true
        defer { isRunning = false }
        
        currentStep = stepNumber
        updateStepStatus(stepNumber, status: .running)
        
        let result: Any
        
        switch stepNumber {
        case 1:
            guard let story = input as? String else {
                throw PipelineError.invalidInput(module: "Rewording", reason: "Expected String")
            }
            result = try await executeRewording(story: story, rewordType: nil, context: context)
            
        case 2:
            guard let story = input as? String else {
                throw PipelineError.invalidInput(module: "StoryAnalysis", reason: "Expected String")
            }
            result = try await executeStoryAnalysis(story: story, context: context)
            
        case 3:
            guard let story = input as? String else {
                throw PipelineError.invalidInput(module: "Segmentation", reason: "Expected String")
            }
            result = try await executeSegmentation(story: story, context: context)
            
        case 4:
            guard let segments = input as? [PromptSegment] else {
                throw PipelineError.invalidInput(module: "CinematicTaxonomy", reason: "Expected [PromptSegment]")
            }
            result = try await executeCinematicTaxonomy(segments: segments, context: context)
            
        case 5:
            guard let story = input as? String else {
                throw PipelineError.invalidInput(module: "Continuity", reason: "Expected String")
            }
            result = try await executeContinuity(story: story, analysis: nil, context: context)
            
        case 6:
            throw PipelineError.invalidInput(
                module: "Packaging",
                reason: "Packaging requires full pipeline state"
            )
            
        default:
            throw PipelineError.invalidInput(module: "PipelineManager", reason: "Unknown step")
        }
        
        updateStepStatus(stepNumber, status: .completed)
        return result
    }
    
    /// Cancel the current pipeline execution
    public func cancel() {
        cancellationToken = true
        logger.info("Pipeline execution cancelled")
    }
    
    /// Update the pipeline configuration
    /// - Parameter config: New configuration
    public func updateConfig(_ config: PipelineConfig) {
        self.config = config
        steps = Self.createStepInfo()
        logger.info("Configuration updated")
    }
    
    // MARK: - Private Methods
    
    private func resetPipeline() {
        currentStep = 0
        errorMessage = nil
        cancellationToken = false
        sessionID = UUID()
        pipelineState = PipelineState()
        steps = Self.createStepInfo()
        logger.info("Pipeline reset for new execution")
    }
    
    private func initializeModules() async throws {
        // Initialize API service (placeholder - needs actual implementation)
        // let apiService = DeepSeekService()
        
        rewordingModule = RewordingModule()
        storyAnalysisModule = StoryAnalysisModule()
        segmentationModule = SegmentationModule()
        taxonomyModule = CinematicTaxonomyModule()
        continuityModule = ContinuityModule()
        packagingModule = PackagingModule()
        
        logger.debug("Modules initialized")
    }
    
    private func executeStep<T>(
        stepNumber: Int,
        name: String,
        operation: () async throws -> T
    ) async throws {
        guard !cancellationToken else {
            throw PipelineError.cancelled(name)
        }
        
        currentStep = stepNumber
        updateStepStatus(stepNumber, status: .running)
        
        let startTime = Date()
        
        do {
            _ = try await withTimeout(config.timeoutPerStep) {
                try await operation()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            updateStepStatus(stepNumber, status: .completed)
            logger.info("\(name) completed in \(String(format: "%.2f", duration))s")
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            updateStepStatus(stepNumber, status: .failed(error: error.localizedDescription))
            logger.error("\(name) failed after \(String(format: "%.2f", duration))s: \(error.localizedDescription)")
            
            if !config.continueOnError {
                throw error
            }
        }
    }
    
    private func updateStepStatus(_ stepNumber: Int, status: ModuleStatus) {
        guard stepNumber > 0 && stepNumber <= steps.count else { return }
        steps[stepNumber - 1].status = status
        
        if status == .running {
            steps[stepNumber - 1].startTime = Date()
        } else if status.isTerminal {
            steps[stepNumber - 1].endTime = Date()
        }
    }
    
    private static func createStepInfo() -> [PipelineStepInfo] {
        [
            PipelineStepInfo(
                id: "rewording",
                name: "Rewording",
                description: "Transform and refine story text",
                stepNumber: 1
            ),
            PipelineStepInfo(
                id: "analysis",
                name: "Story Analysis",
                description: "Extract characters, locations, and scenes",
                stepNumber: 2
            ),
            PipelineStepInfo(
                id: "segmentation",
                name: "Segmentation",
                description: "Break story into video segments",
                stepNumber: 3
            ),
            PipelineStepInfo(
                id: "taxonomy",
                name: "Cinematic Taxonomy",
                description: "Add camera angles and visual details",
                stepNumber: 4
            ),
            PipelineStepInfo(
                id: "continuity",
                name: "Continuity",
                description: "Generate visual consistency markers",
                stepNumber: 5
            ),
            PipelineStepInfo(
                id: "packaging",
                name: "Packaging",
                description: "Package final screenplay output",
                stepNumber: 6
            )
        ]
    }
    
    // MARK: - Module Execution Methods
    
    private func executeRewording(
        story: String,
        rewordType: RewordingType?,
        context: PipelineContext
    ) async throws -> String {
        guard let module = rewordingModule else {
            throw PipelineError.executionFailed(module: "Rewording", reason: "Module not initialized")
        }
        
        let input = RewordingInput(story: story, rewordType: rewordType ?? .none)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.rewordedStory = output.rewordedStory
            return output.rewordedStory
        case .failure(let error):
            throw error
        }
    }
    
    private func executeStoryAnalysis(
        story: String,
        context: PipelineContext
    ) async throws -> StoryAnalysis {
        guard let module = storyAnalysisModule else {
            throw PipelineError.executionFailed(module: "StoryAnalysis", reason: "Module not initialized")
        }
        
        let input = StoryAnalysisInput(story: story)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.storyAnalysis = output.analysis
            return output.analysis
        case .failure(let error):
            throw error
        }
    }
    
    private func executeSegmentation(
        story: String,
        context: PipelineContext
    ) async throws -> [PromptSegment] {
        guard let module = segmentationModule else {
            throw PipelineError.executionFailed(module: "Segmentation", reason: "Module not initialized")
        }
        
        let input = SegmentationInput(
            story: story,
            maxDuration: context.config.maxSegmentDuration
        )
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.segments = output.segments
            return output.segments
        case .failure(let error):
            throw error
        }
    }
    
    private func executeCinematicTaxonomy(
        segments: [PromptSegment],
        context: PipelineContext
    ) async throws -> [PromptSegment] {
        guard let module = taxonomyModule else {
            throw PipelineError.executionFailed(module: "CinematicTaxonomy", reason: "Module not initialized")
        }
        
        let input = CinematicTaxonomyInput(segments: segments)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.segments = output.enrichedSegments
            return output.enrichedSegments
        case .failure(let error):
            throw error
        }
    }
    
    private func executeContinuity(
        story: String,
        analysis: StoryAnalysis?,
        context: PipelineContext
    ) async throws -> [ContinuityAnchor] {
        guard let module = continuityModule else {
            throw PipelineError.executionFailed(module: "Continuity", reason: "Module not initialized")
        }
        
        let input = ContinuityInput(story: story, analysis: analysis)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.continuityAnchors = output.anchors
            return output.anchors
        case .failure(let error):
            throw error
        }
    }
    
    private func executePackaging(
        input: PipelineInput,
        context: PipelineContext
    ) async throws -> PipelineOutput {
        guard let module = packagingModule else {
            throw PipelineError.executionFailed(module: "Packaging", reason: "Module not initialized")
        }
        
        let packagingInput = PackagingInput(
            originalStory: input.story,
            rewordedStory: pipelineState.rewordedStory,
            analysis: pipelineState.storyAnalysis,
            segments: pipelineState.segments ?? [],
            continuityAnchors: pipelineState.continuityAnchors ?? [],
            projectTitle: input.projectTitle
        )
        
        let result = await module.execute(input: packagingInput, context: context)
        
        switch result {
        case .success(let output):
            pipelineState.finalOutput = output.packagedOutput
            return output.packagedOutput
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Supporting Types

/// Input for the entire pipeline
public struct PipelineInput: Sendable {
    public let story: String
    public let rewordType: RewordingType?
    public let projectTitle: String
    public let metadata: [String: String]
    
    public init(
        story: String,
        rewordType: RewordingType? = nil,
        projectTitle: String = "Untitled Project",
        metadata: [String: String] = [:]
    ) {
        self.story = story
        self.rewordType = rewordType
        self.projectTitle = projectTitle
        self.metadata = metadata
    }
}

/// Final output from the pipeline
public struct PipelineOutput: Sendable {
    public let projectTitle: String
    public let originalStory: String
    public let processedStory: String?
    public let segments: [PromptSegment]
    public let analysis: StoryAnalysis?
    public let continuityAnchors: [ContinuityAnchor]
    public let executionMetadata: [String: String]
    
    public init(
        projectTitle: String,
        originalStory: String,
        processedStory: String?,
        segments: [PromptSegment],
        analysis: StoryAnalysis?,
        continuityAnchors: [ContinuityAnchor],
        executionMetadata: [String: String]
    ) {
        self.projectTitle = projectTitle
        self.originalStory = originalStory
        self.processedStory = processedStory
        self.segments = segments
        self.analysis = analysis
        self.continuityAnchors = continuityAnchors
        self.executionMetadata = executionMetadata
    }
}

/// Internal state shared between pipeline modules
private struct PipelineState {
    var rewordedStory: String?
    var storyAnalysis: StoryAnalysis?
    var segments: [PromptSegment]?
    var continuityAnchors: [ContinuityAnchor]?
    var finalOutput: PipelineOutput?
}

// MARK: - Timeout Helper

private func withTimeout<T>(
    _ timeout: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw PipelineError.timeout(module: "Operation", duration: timeout)
        }
        
        guard let result = try await group.next() else {
            throw PipelineError.executionFailed(module: "Timeout", reason: "No result")
        }
        
        group.cancelAll()
        return result
    }
}

// MARK: - Placeholder Types (to be replaced with actual implementations)

public struct PromptSegment: Sendable, Identifiable, Codable {
    public let id: UUID
    public var text: String
    public var duration: TimeInterval
    public var order: Int
    
    public init(id: UUID = UUID(), text: String, duration: TimeInterval, order: Int) {
        self.id = id
        self.text = text
        self.duration = duration
        self.order = order
    }
}

public struct StoryAnalysis: Sendable, Codable {
    public var characters: [String]
    public var locations: [String]
    public var scenes: [String]
    
    public init(characters: [String] = [], locations: [String] = [], scenes: [String] = []) {
        self.characters = characters
        self.locations = locations
        self.scenes = scenes
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
