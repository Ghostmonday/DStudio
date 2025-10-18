//
//  PipelineConfig.swift
//  DirectorStudio
//
//  Pipeline Configuration System
//  Controls which processing steps are enabled and their parameters
//

import Foundation

/// Master configuration for the DirectorStudio pipeline
/// All steps can be toggled ON/OFF at runtime
@Observable
public final class PipelineConfig: Sendable {
    
    // MARK: - Step Toggle Configuration
    
    public var isRewordingEnabled: Bool
    public var isStoryAnalysisEnabled: Bool
    public var isSegmentationEnabled: Bool
    public var isCinematicTaxonomyEnabled: Bool
    public var isContinuityEnabled: Bool
    public var isPackagingEnabled: Bool
    
    // MARK: - Step-Specific Settings
    
    public var rewordingType: RewordingType?
    public var maxSegmentDuration: TimeInterval
    public var enableDetailedLogging: Bool
    public var continueOnError: Bool
    public var maxRetries: Int
    public var timeoutPerStep: TimeInterval
    
    // MARK: - API Configuration
    
    public var apiTemperature: Double
    public var apiMaxTokens: Int
    public var enableRateLimiting: Bool
    public var maxConcurrentRequests: Int
    
    // MARK: - Initialization
    
    public init(
        isRewordingEnabled: Bool = true,
        isStoryAnalysisEnabled: Bool = true,
        isSegmentationEnabled: Bool = true,
        isCinematicTaxonomyEnabled: Bool = true,
        isContinuityEnabled: Bool = true,
        isPackagingEnabled: Bool = true,
        rewordingType: RewordingType? = nil,
        maxSegmentDuration: TimeInterval = 15.0,
        enableDetailedLogging: Bool = true,
        continueOnError: Bool = true,
        maxRetries: Int = 3,
        timeoutPerStep: TimeInterval = 60.0,
        apiTemperature: Double = 0.7,
        apiMaxTokens: Int = 4096,
        enableRateLimiting: Bool = true,
        maxConcurrentRequests: Int = 3
    ) {
        self.isRewordingEnabled = isRewordingEnabled
        self.isStoryAnalysisEnabled = isStoryAnalysisEnabled
        self.isSegmentationEnabled = isSegmentationEnabled
        self.isCinematicTaxonomyEnabled = isCinematicTaxonomyEnabled
        self.isContinuityEnabled = isContinuityEnabled
        self.isPackagingEnabled = isPackagingEnabled
        self.rewordingType = rewordingType
        self.maxSegmentDuration = maxSegmentDuration
        self.enableDetailedLogging = enableDetailedLogging
        self.continueOnError = continueOnError
        self.maxRetries = maxRetries
        self.timeoutPerStep = timeoutPerStep
        self.apiTemperature = apiTemperature
        self.apiMaxTokens = apiMaxTokens
        self.enableRateLimiting = enableRateLimiting
        self.maxConcurrentRequests = maxConcurrentRequests
    }
    
    // MARK: - Presets
    
    public static var `default`: PipelineConfig {
        PipelineConfig()
    }
    
    public static var quickProcess: PipelineConfig {
        PipelineConfig(
            isStoryAnalysisEnabled: false,
            isCinematicTaxonomyEnabled: false,
            isContinuityEnabled: false,
            maxRetries: 1,
            timeoutPerStep: 30.0
        )
    }
    
    public static var fullProcess: PipelineConfig {
        PipelineConfig(
            isRewordingEnabled: true,
            isStoryAnalysisEnabled: true,
            isSegmentationEnabled: true,
            isCinematicTaxonomyEnabled: true,
            isContinuityEnabled: true,
            isPackagingEnabled: true
        )
    }
    
    public static var segmentationOnly: PipelineConfig {
        PipelineConfig(
            isRewordingEnabled: false,
            isStoryAnalysisEnabled: false,
            isSegmentationEnabled: true,
            isCinematicTaxonomyEnabled: false,
            isContinuityEnabled: false,
            isPackagingEnabled: true
        )
    }
    
    // MARK: - Validation
    
    public func validate() -> [String] {
        var warnings: [String] = []
        
        if !isPackagingEnabled {
            warnings.append("Packaging step is disabled - no final output will be generated")
        }
        
        if !isSegmentationEnabled && isCinematicTaxonomyEnabled {
            warnings.append("Cinematic taxonomy requires segmentation - will be skipped")
        }
        
        if maxRetries < 0 {
            warnings.append("Max retries is negative - will be set to 0")
        }
        
        if timeoutPerStep <= 0 {
            warnings.append("Timeout per step must be positive - using default 60s")
        }
        
        return warnings
    }
    
    // MARK: - Step Count
    
    public var enabledStepsCount: Int {
        var count = 0
        if isRewordingEnabled { count += 1 }
        if isStoryAnalysisEnabled { count += 1 }
        if isSegmentationEnabled { count += 1 }
        if isCinematicTaxonomyEnabled { count += 1 }
        if isContinuityEnabled { count += 1 }
        if isPackagingEnabled { count += 1 }
        return count
    }
    
    public var totalSteps: Int { 6 }
}

// MARK: - Supporting Types

public enum RewordingType: String, Codable, CaseIterable, Sendable {
    case modernize = "Modernize"
    case simplify = "Simplify"
    case dramatize = "Dramatize"
    case formalize = "Formalize"
    case none = "None"
    
    public var displayName: String { rawValue }
}

// MARK: - Codable Conformance

extension PipelineConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case isRewordingEnabled
        case isStoryAnalysisEnabled
        case isSegmentationEnabled
        case isCinematicTaxonomyEnabled
        case isContinuityEnabled
        case isPackagingEnabled
        case rewordingType
        case maxSegmentDuration
        case enableDetailedLogging
        case continueOnError
        case maxRetries
        case timeoutPerStep
        case apiTemperature
        case apiMaxTokens
        case enableRateLimiting
        case maxConcurrentRequests
    }
}
