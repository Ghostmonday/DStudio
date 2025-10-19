//
//  ReviewGate.swift
//  DirectorStudio
//
//  Manual Review System for Pipeline Control
//  Allows users to approve, modify, or reject pipeline outputs
//

import Foundation

// MARK: - Review Gate Protocol

public protocol ReviewGate {
    associatedtype ReviewItem
    associatedtype ReviewDecision
    
    func presentForReview(_ item: ReviewItem) async -> ReviewDecision
}

// MARK: - Shot List Review

public struct ShotListReviewItem: Sendable {
    public let segments: [PromptSegment]
    public let totalDuration: TimeInterval
    public let estimatedCost: Decimal
    public let metadata: [String: String]
    
    public init(
        segments: [PromptSegment],
        totalDuration: TimeInterval,
        estimatedCost: Decimal,
        metadata: [String: String] = [:]
    ) {
        self.segments = segments
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.metadata = metadata
    }
}

public enum ShotListReviewDecision: Sendable {
    case approved
    case modified([PromptSegment])  // User edited segments
    case rejected(reason: String)
}

public class ShotListReviewGate: ReviewGate {
    public typealias ReviewItem = ShotListReviewItem
    public typealias ReviewDecision = ShotListReviewDecision
    
    private let presentationHandler: (ShotListReviewItem) async -> ShotListReviewDecision
    
    public init(presentationHandler: @escaping (ShotListReviewItem) async -> ShotListReviewDecision) {
        self.presentationHandler = presentationHandler
    }
    
    public func presentForReview(_ item: ShotListReviewItem) async -> ShotListReviewDecision {
        return await presentationHandler(item)
    }
}

// MARK: - Prompt Review

public struct PromptReviewItem: Sendable {
    public let segment: PromptSegment
    public let enrichedPrompt: String  // After CinematicTaxonomy
    public let estimatedCost: Decimal
    public let previewMetadata: [String: String]
    
    public init(
        segment: PromptSegment,
        enrichedPrompt: String,
        estimatedCost: Decimal,
        previewMetadata: [String: String] = [:]
    ) {
        self.segment = segment
        self.enrichedPrompt = enrichedPrompt
        self.estimatedCost = estimatedCost
        self.previewMetadata = previewMetadata
    }
}

public enum PromptReviewDecision: Sendable {
    case approved
    case modified(newPrompt: String)
    case skipped
    case rejected
}

public class PromptReviewGate: ReviewGate {
    public typealias ReviewItem = PromptReviewItem
    public typealias ReviewDecision = PromptReviewDecision
    
    private let presentationHandler: (PromptReviewItem) async -> PromptReviewDecision
    
    public init(presentationHandler: @escaping (PromptReviewItem) async -> PromptReviewDecision) {
        self.presentationHandler = presentationHandler
    }
    
    public func presentForReview(_ item: PromptReviewItem) async -> PromptReviewDecision {
        return await presentationHandler(item)
    }
}

// MARK: - Budget Review

public struct BudgetReviewItem: Sendable {
    public let estimatedCost: Decimal
    public let maxBudget: Decimal
    public let overage: Decimal
    public let suggestions: [String]
    public let segments: [PromptSegment]
    
    public init(
        estimatedCost: Decimal,
        maxBudget: Decimal,
        overage: Decimal,
        suggestions: [String],
        segments: [PromptSegment]
    ) {
        self.estimatedCost = estimatedCost
        self.maxBudget = maxBudget
        self.overage = overage
        self.suggestions = suggestions
        self.segments = segments
    }
}

public enum BudgetReviewDecision: Sendable {
    case approved
    case modified([PromptSegment])  // User edited segments to reduce cost
    case increaseBudget(newBudget: Decimal)
    case rejected(reason: String)
}

public class BudgetReviewGate: ReviewGate {
    public typealias ReviewItem = BudgetReviewItem
    public typealias ReviewDecision = BudgetReviewDecision
    
    private let presentationHandler: (BudgetReviewItem) async -> BudgetReviewDecision
    
    public init(presentationHandler: @escaping (BudgetReviewItem) async -> BudgetReviewDecision) {
        self.presentationHandler = presentationHandler
    }
    
    public func presentForReview(_ item: BudgetReviewItem) async -> BudgetReviewDecision {
        return await presentationHandler(item)
    }
}

// MARK: - Review Gate Manager

public class ReviewGateManager: Sendable {
    public var shotListReviewGate: ShotListReviewGate?
    public var promptReviewGate: PromptReviewGate?
    public var budgetReviewGate: BudgetReviewGate?
    
    public init() {}
    
    // MARK: - Shot List Review
    
    public func presentShotListForReview(
        segments: [PromptSegment],
        totalDuration: TimeInterval,
        estimatedCost: Decimal,
        metadata: [String: String] = [:]
    ) async -> ShotListReviewDecision {
        guard let gate = shotListReviewGate else {
            return .approved  // No gate = auto-approve
        }
        
        let item = ShotListReviewItem(
            segments: segments,
            totalDuration: totalDuration,
            estimatedCost: estimatedCost,
            metadata: metadata
        )
        
        return await gate.presentForReview(item)
    }
    
    // MARK: - Prompt Review
    
    public func presentPromptForReview(
        segment: PromptSegment,
        enrichedPrompt: String,
        estimatedCost: Decimal,
        previewMetadata: [String: String] = [:]
    ) async -> PromptReviewDecision {
        guard let gate = promptReviewGate else {
            return .approved  // No gate = auto-approve
        }
        
        let item = PromptReviewItem(
            segment: segment,
            enrichedPrompt: enrichedPrompt,
            estimatedCost: estimatedCost,
            previewMetadata: previewMetadata
        )
        
        return await gate.presentForReview(item)
    }
    
    // MARK: - Budget Review
    
    public func presentBudgetForReview(
        estimatedCost: Decimal,
        maxBudget: Decimal,
        overage: Decimal,
        suggestions: [String],
        segments: [PromptSegment]
    ) async -> BudgetReviewDecision {
        guard let gate = budgetReviewGate else {
            return .approved  // No gate = auto-approve
        }
        
        let item = BudgetReviewItem(
            estimatedCost: estimatedCost,
            maxBudget: maxBudget,
            overage: overage,
            suggestions: suggestions,
            segments: segments
        )
        
        return await gate.presentForReview(item)
    }
}

// MARK: - Default Review Gates

public extension ReviewGateManager {
    
    /// Creates a default shot list review gate that auto-approves
    static func autoApproveShotList() -> ShotListReviewGate {
        return ShotListReviewGate { _ in
            return .approved
        }
    }
    
    /// Creates a default prompt review gate that auto-approves
    static func autoApprovePrompts() -> PromptReviewGate {
        return PromptReviewGate { _ in
            return .approved
        }
    }
    
    /// Creates a default budget review gate that auto-approves
    static func autoApproveBudget() -> BudgetReviewGate {
        return BudgetReviewGate { _ in
            return .approved
        }
    }
    
    /// Creates a console-based shot list review gate for testing
    static func consoleShotListReview() -> ShotListReviewGate {
        return ShotListReviewGate { item in
            print("\n🎬 SHOT LIST REVIEW")
            print("==================")
            print("Segments: \(item.segments.count)")
            print("Total Duration: \(String(format: "%.1f", item.totalDuration))s")
            print("Estimated Cost: \(item.estimatedCost) credits")
            print("\nSegments:")
            for (index, segment) in item.segments.enumerated() {
                print("  \(index + 1). \(segment.text.prefix(50))... (\(String(format: "%.1f", segment.estimatedDuration))s)")
            }
            print("\nOptions:")
            print("1. Approve")
            print("2. Reject")
            print("Enter choice (1-2): ", terminator: "")
            
            if let input = readLine() {
                switch input.trimmingCharacters(in: .whitespacesAndNewlines) {
                case "1":
                    return .approved
                case "2":
                    return .rejected(reason: "User rejected via console")
                default:
                    return .approved
                }
            }
            
            return .approved
        }
    }
    
    /// Creates a console-based prompt review gate for testing
    static func consolePromptReview() -> PromptReviewGate {
        return PromptReviewGate { item in
            print("\n📝 PROMPT REVIEW")
            print("===============")
            print("Segment \(item.segment.index + 1): \(item.segment.text.prefix(100))...")
            print("Enriched Prompt: \(item.enrichedPrompt.prefix(100))...")
            print("Estimated Cost: \(item.estimatedCost) credits")
            print("\nOptions:")
            print("1. Approve")
            print("2. Skip")
            print("3. Reject")
            print("Enter choice (1-3): ", terminator: "")
            
            if let input = readLine() {
                switch input.trimmingCharacters(in: .whitespacesAndNewlines) {
                case "1":
                    return .approved
                case "2":
                    return .skipped
                case "3":
                    return .rejected
                default:
                    return .approved
                }
            }
            
            return .approved
        }
    }
}
