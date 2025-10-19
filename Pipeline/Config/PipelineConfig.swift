//
//  PipelineConfig.swift
//  DirectorStudio
//
//  Pipeline Configuration System
//  Controls which processing steps are enabled and their parameters
//

import Foundation

// MARK: - User Control Configuration

public struct UserControlConfig: Codable, Sendable {
    // Generation Mode
    public enum GenerationMode: String, Codable, CaseIterable, Sendable {
        case automatic = "automatic"          // Script determines everything
        case semiAutomatic = "semiAutomatic"  // Script suggests, user approves
        case manual = "manual"                // User controls everything
        
        public var displayName: String {
            switch self {
            case .automatic: return "Automatic"
            case .semiAutomatic: return "Semi-Automatic"
            case .manual: return "Manual"
            }
        }
    }
    
    // Duration Strategy
    public enum DurationStrategy: String, Codable, CaseIterable, Sendable {
        case scriptBased = "scriptBased"      // Estimate from script (1 page ≈ 60s)
        case fixed = "fixed"                  // All shots same duration
        case custom = "custom"                // User specifies per shot
        
        public var displayName: String {
            switch self {
            case .scriptBased: return "Script-Based"
            case .fixed: return "Fixed Duration"
            case .custom: return "Custom"
            }
        }
    }
    
    // Segmentation Strategy
    public enum SegmentationStrategy: String, Codable, Sendable {
        case automatic = "automatic"          // Let AI decide based on script
        case perScene = "perScene"            // 1 shot per scene heading
        case perBeat = "perBeat"              // 1 shot per story beat
        case manual = "manual"                // User specifies exact count
        
        public var displayName: String {
            switch self {
            case .automatic: return "Automatic"
            case .perScene: return "Per Scene"
            case .perBeat: return "Per Beat"
            case .manual: return "Manual"
            }
        }
    }
    
    // User Controls
    public var generationMode: GenerationMode = .semiAutomatic
    public var durationStrategy: DurationStrategy = .scriptBased
    public var segmentationStrategy: SegmentationStrategy = .automatic
    
    // Hard Limits (Optional)
    public var maxShots: Int? = nil              // nil = unlimited
    public var maxTotalDuration: Int? = nil      // seconds, nil = unlimited
    public var minShotDuration: Int = 3          // minimum seconds per shot
    public var maxShotDuration: Int = 30         // maximum seconds per shot
    
    // Cost Controls
    public var maxCostPerProject: Decimal? = nil // nil = unlimited
    public var estimatedCostPerSecond: Decimal = 1.0 // video credits
    
    // Review Gates
    public var requireShotListApproval: Bool = true
    public var requirePromptReview: Bool = false
    public var allowEditBeforeGeneration: Bool = true
    
    // Manual segmentation count (when strategy is .manual)
    public var manualShotCount: Int = 5
    
    // Fixed duration (when strategy is .fixed)
    public var fixedDurationSeconds: Int = 4
    
    public init() {}
}

/// Master configuration for the DirectorStudio pipeline
/// All steps can be toggled ON/OFF at runtime
@Observable
public final class PipelineConfig: Sendable {
    
    // MARK: - User Control Configuration
    
    public var userControls: UserControlConfig = UserControlConfig()
    
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
        userControls: UserControlConfig = UserControlConfig(),
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
        self.userControls = userControls
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
            userControls: UserControlConfig(
                generationMode: .automatic,
                segmentationStrategy: .manual,
                manualShotCount: 3,
                requireShotListApproval: false
            ),
            isStoryAnalysisEnabled: false,
            isCinematicTaxonomyEnabled: false,
            isContinuityEnabled: false,
            maxRetries: 1,
            timeoutPerStep: 30.0
        )
    }
    
    public static var fullProcess: PipelineConfig {
        PipelineConfig(
            userControls: UserControlConfig(
                generationMode: .semiAutomatic,
                segmentationStrategy: .automatic,
                requireShotListApproval: true
            ),
            isRewordingEnabled: true,
            isStoryAnalysisEnabled: true,
            isSegmentationEnabled: true,
            isCinematicTaxonomyEnabled: true,
            isContinuityEnabled: true,
            isPackagingEnabled: true
        )
    }
    
    public static var budgetConscious: PipelineConfig {
        PipelineConfig(
            userControls: UserControlConfig(
                generationMode: .semiAutomatic,
                segmentationStrategy: .automatic,
                maxShots: 20,
                maxTotalDuration: 120,
                maxCostPerProject: 500,
                estimatedCostPerSecond: 2.5,
                requireShotListApproval: true
            )
        )
    }
    
    public static var fixedCount: PipelineConfig {
        PipelineConfig(
            userControls: UserControlConfig(
                generationMode: .automatic,
                segmentationStrategy: .manual,
                manualShotCount: 5,
                durationStrategy: .fixed,
                fixedDurationSeconds: 4,
                requireShotListApproval: false
            )
        )
    }
    
    public static var segmentationOnly: PipelineConfig {
        PipelineConfig(
            userControls: UserControlConfig(
                generationMode: .automatic,
                segmentationStrategy: .automatic
            ),
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
        
        // User control validation
        if let maxShots = userControls.maxShots, maxShots <= 0 {
            warnings.append("Max shots must be positive - will be ignored")
        }
        
        if let maxDuration = userControls.maxTotalDuration, maxDuration <= 0 {
            warnings.append("Max total duration must be positive - will be ignored")
        }
        
        if userControls.minShotDuration > userControls.maxShotDuration {
            warnings.append("Min shot duration cannot be greater than max shot duration")
        }
        
        if userControls.manualShotCount <= 0 {
            warnings.append("Manual shot count must be positive - using default 5")
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
        case userControls
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
