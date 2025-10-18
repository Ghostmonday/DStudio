//
//  PipelineModule.swift
//  DirectorStudio
//
//  Core protocol for all pipeline processing modules
//

import Foundation
import OSLog

// MARK: - Pipeline Module Protocol

/// Protocol that all pipeline modules must conform to
/// Ensures consistent interface, error handling, and logging
public protocol PipelineModule: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    
    /// Unique identifier for this module
    var moduleID: String { get }
    
    /// Human-readable module name
    var moduleName: String { get }
    
    /// Module version for tracking
    var version: String { get }
    
    /// Execute the module's processing logic
    /// - Parameters:
    ///   - input: The input data for this module
    ///   - context: Pipeline execution context with config and shared state
    /// - Returns: A result containing either the output or an error
    func execute(
        input: Input,
        context: PipelineContext
    ) async -> Result<Output, PipelineError>
    
    /// Validate that the input is suitable for processing
    /// - Parameter input: The input to validate
    /// - Returns: Array of validation warnings (empty if valid)
    func validate(input: Input) -> [String]
    
    /// Check if this module can be skipped safely
    /// - Returns: True if the module can be skipped without breaking the pipeline
    func canSkip() -> Bool
}

// MARK: - Default Implementations

public extension PipelineModule {
    var version: String { "1.0.0" }
    
    func canSkip() -> Bool { true }
    
    func validate(input: Input) -> [String] { [] }
}

// MARK: - Pipeline Context

/// Shared context passed through the pipeline
/// Contains configuration, logger, and shared state
public struct PipelineContext: Sendable {
    public let config: PipelineConfig
    public let logger: Logger
    public let sessionID: UUID
    public let startTime: Date
    public var metadata: [String: String]
    
    public init(
        config: PipelineConfig,
        logger: Logger = Logger(subsystem: "com.directorstudio.pipeline", category: "execution"),
        sessionID: UUID = UUID(),
        startTime: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.config = config
        self.logger = logger
        self.sessionID = sessionID
        self.startTime = startTime
        self.metadata = metadata
    }
}

// MARK: - Pipeline Error

/// Comprehensive error type for pipeline execution
public enum PipelineError: Error, Sendable {
    case moduleNotEnabled(String)
    case validationFailed(module: String, warnings: [String])
    case executionFailed(module: String, reason: String)
    case timeout(module: String, duration: TimeInterval)
    case invalidInput(module: String, reason: String)
    case apiError(module: String, statusCode: Int?, message: String)
    case dependencyMissing(module: String, dependency: String)
    case chaoticInputDetected(module: String, reason: String)
    case jsonParsingFailed(module: String, raw: String)
    case unexpectedFormat(module: String, expected: String, got: String)
    case retryLimitExceeded(module: String, attempts: Int)
    case cancelled(module: String)
    
    public var localizedDescription: String {
        switch self {
        case .moduleNotEnabled(let name):
            return "Module '\(name)' is not enabled in configuration"
        case .validationFailed(let module, let warnings):
            return "Validation failed for '\(module)': \(warnings.joined(separator: ", "))"
        case .executionFailed(let module, let reason):
            return "Execution failed for '\(module)': \(reason)"
        case .timeout(let module, let duration):
            return "Module '\(module)' timed out after \(duration)s"
        case .invalidInput(let module, let reason):
            return "Invalid input for '\(module)': \(reason)"
        case .apiError(let module, let code, let message):
            let codeStr = code.map { " (HTTP \($0))" } ?? ""
            return "API error in '\(module)'\(codeStr): \(message)"
        case .dependencyMissing(let module, let dependency):
            return "Module '\(module)' requires '\(dependency)' which was not executed"
        case .chaoticInputDetected(let module, let reason):
            return "Chaotic input detected in '\(module)': \(reason)"
        case .jsonParsingFailed(let module, let raw):
            let preview = String(raw.prefix(100))
            return "JSON parsing failed in '\(module)'. Preview: \(preview)"
        case .unexpectedFormat(let module, let expected, let got):
            return "Unexpected format in '\(module)'. Expected: \(expected), Got: \(got)"
        case .retryLimitExceeded(let module, let attempts):
            return "Retry limit exceeded for '\(module)' after \(attempts) attempts"
        case .cancelled(let module):
            return "Execution cancelled for '\(module)'"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .moduleNotEnabled, .validationFailed, .cancelled:
            return true
        case .timeout, .retryLimitExceeded:
            return false
        case .apiError(_, let code, _):
            // 5xx errors are potentially recoverable, 4xx are not
            if let code = code {
                return code >= 500
            }
            return true
        case .chaoticInputDetected, .jsonParsingFailed, .unexpectedFormat:
            return true // Can try with fallback strategies
        default:
            return true
        }
    }
}

// MARK: - Module Result

/// Result of a module execution with metadata
public struct ModuleResult<T: Sendable>: Sendable {
    public let output: T
    public let executionTime: TimeInterval
    public let warnings: [String]
    public let metadata: [String: String]
    
    public init(
        output: T,
        executionTime: TimeInterval,
        warnings: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.output = output
        self.executionTime = executionTime
        self.warnings = warnings
        self.metadata = metadata
    }
}

// MARK: - Module Status

/// Execution status for pipeline steps
public enum ModuleStatus: Sendable, Equatable {
    case pending
    case running
    case completed
    case skipped(reason: String)
    case failed(error: String)
    case cancelled
    
    public var isTerminal: Bool {
        switch self {
        case .completed, .skipped, .failed, .cancelled:
            return true
        case .pending, .running:
            return false
        }
    }
    
    public var displayString: String {
        switch self {
        case .pending: return "Pending"
        case .running: return "Running"
        case .completed: return "Completed"
        case .skipped(let reason): return "Skipped: \(reason)"
        case .failed(let error): return "Failed: \(error)"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Pipeline Step Info

/// Information about a pipeline step for UI display
public struct PipelineStepInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let stepNumber: Int
    public var status: ModuleStatus
    public var progress: Double
    public var startTime: Date?
    public var endTime: Date?
    public var warnings: [String]
    
    public init(
        id: String,
        name: String,
        description: String,
        stepNumber: Int,
        status: ModuleStatus = .pending,
        progress: Double = 0.0,
        startTime: Date? = nil,
        endTime: Date? = nil,
        warnings: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.stepNumber = stepNumber
        self.status = status
        self.progress = progress
        self.startTime = startTime
        self.endTime = endTime
        self.warnings = warnings
    }
    
    public var executionTime: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
}
