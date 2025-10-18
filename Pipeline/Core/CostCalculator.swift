//
//  CostCalculator.swift
//  DirectorStudio
//
//  Cost calculation and budget management for pipeline
//  Handles cost estimation, budget checking, and cost optimization
//

import Foundation

// MARK: - Cost Calculator

public struct CostCalculator {
    public let costPerSecond: Decimal
    
    public init(costPerSecond: Decimal) {
        self.costPerSecond = costPerSecond
    }
    
    public func estimateCost(for segments: [PromptSegment]) -> Decimal {
        let totalDuration = segments.reduce(0.0) { $0 + $1.estimatedDuration }
        return estimateCost(for: totalDuration)
    }
    
    public func estimateCost(for duration: TimeInterval) -> Decimal {
        return Decimal(duration) * costPerSecond
    }
    
    public func checkBudget(
        segments: [PromptSegment],
        maxCost: Decimal?
    ) -> BudgetCheckResult {
        guard let maxCost = maxCost else {
            return .withinBudget(remaining: nil)
        }
        
        let estimatedCost = estimateCost(for: segments)
        
        if estimatedCost <= maxCost {
            return .withinBudget(remaining: maxCost - estimatedCost)
        } else {
            return .overBudget(
                overage: estimatedCost - maxCost,
                suggestedReduction: calculateReduction(segments: segments, targetCost: maxCost)
            )
        }
    }
    
    private func calculateReduction(
        segments: [PromptSegment],
        targetCost: Decimal
    ) -> BudgetReduction {
        let currentCost = estimateCost(for: segments)
        let reductionNeeded = currentCost - targetCost
        
        // Strategy 1: Remove shortest segments
        let sortedByDuration = segments.sorted { $0.estimatedDuration < $1.estimatedDuration }
        var toRemove: [Int] = []
        var savedCost: Decimal = 0
        
        for segment in sortedByDuration {
            let segmentCost = Decimal(segment.estimatedDuration) * costPerSecond
            savedCost += segmentCost
            toRemove.append(segment.index)
            
            if savedCost >= reductionNeeded {
                break
            }
        }
        
        // Strategy 2: Reduce all durations proportionally
        let scaleFactor = Double(truncating: targetCost as NSNumber) / Double(truncating: currentCost as NSNumber)
        
        return BudgetReduction(
            removeSegments: toRemove,
            orScaleDurationsBy: scaleFactor
        )
    }
}

// MARK: - Budget Check Result

public enum BudgetCheckResult: Sendable {
    case withinBudget(remaining: Decimal?)
    case overBudget(overage: Decimal, suggestedReduction: BudgetReduction)
}

public struct BudgetReduction: Sendable {
    public let removeSegments: [Int]
    public let orScaleDurationsBy: Double
    
    public init(removeSegments: [Int], orScaleDurationsBy: Double) {
        self.removeSegments = removeSegments
        self.orScaleDurationsBy = orScaleDurationsBy
    }
}

// MARK: - Cost Analysis

public struct CostAnalysis: Sendable {
    public let totalCost: Decimal
    public let costPerSegment: [Int: Decimal]
    public let costBreakdown: CostBreakdown
    public let recommendations: [CostRecommendation]
    
    public init(
        totalCost: Decimal,
        costPerSegment: [Int: Decimal],
        costBreakdown: CostBreakdown,
        recommendations: [CostRecommendation]
    ) {
        self.totalCost = totalCost
        self.costPerSegment = costPerSegment
        self.costBreakdown = costBreakdown
        self.recommendations = recommendations
    }
}

public struct CostBreakdown: Sendable {
    public let baseCost: Decimal
    public let durationCost: Decimal
    public let complexityCost: Decimal
    public let qualityCost: Decimal
    
    public init(
        baseCost: Decimal,
        durationCost: Decimal,
        complexityCost: Decimal,
        qualityCost: Decimal
    ) {
        self.baseCost = baseCost
        self.durationCost = durationCost
        self.complexityCost = complexityCost
        self.qualityCost = qualityCost
    }
}

public enum CostRecommendation: Sendable {
    case reduceDuration(segmentIndex: Int, currentDuration: TimeInterval, suggestedDuration: TimeInterval)
    case removeSegment(segmentIndex: Int, savings: Decimal)
    case combineSegments(segmentIndices: [Int], savings: Decimal)
    case optimizeQuality(segmentIndex: Int, currentQuality: String, suggestedQuality: String)
}

// MARK: - Cost Optimizer

public class CostOptimizer {
    private let calculator: CostCalculator
    private let maxCost: Decimal?
    
    public init(calculator: CostCalculator, maxCost: Decimal? = nil) {
        self.calculator = calculator
        self.maxCost = maxCost
    }
    
    public func optimizeSegments(
        _ segments: [PromptSegment],
        targetCost: Decimal? = nil
    ) -> OptimizedSegments {
        let budget = targetCost ?? maxCost
        
        guard let budget = budget else {
            return OptimizedSegments(
                segments: segments,
                totalCost: calculator.estimateCost(for: segments),
                optimizations: []
            )
        }
        
        let currentCost = calculator.estimateCost(for: segments)
        
        if currentCost <= budget {
            return OptimizedSegments(
                segments: segments,
                totalCost: currentCost,
                optimizations: []
            )
        }
        
        // Apply optimizations
        var optimizedSegments = segments
        var optimizations: [Optimization] = []
        
        // Strategy 1: Remove least important segments
        let sortedByImportance = segments.enumerated().sorted { first, second in
            let firstImportance = calculateImportance(first.element)
            let secondImportance = calculateImportance(second.element)
            return firstImportance < secondImportance
        }
        
        var currentCost = calculator.estimateCost(for: optimizedSegments)
        var removedIndices: [Int] = []
        
        for (originalIndex, segment) in sortedByImportance {
            if currentCost <= budget {
                break
            }
            
            let segmentCost = calculator.estimateCost(for: segment.estimatedDuration)
            if currentCost - segmentCost >= budget {
                optimizedSegments.removeAll { $0.index == segment.index }
                currentCost -= segmentCost
                removedIndices.append(originalIndex)
                
                optimizations.append(.removedSegment(
                    index: segment.index,
                    savings: segmentCost
                ))
            }
        }
        
        // Strategy 2: Reduce durations proportionally
        if currentCost > budget {
            let scaleFactor = Double(truncating: budget as NSNumber) / Double(truncating: currentCost as NSNumber)
            
            optimizedSegments = optimizedSegments.map { segment in
                var modified = segment
                modified.estimatedDuration *= scaleFactor
                return modified
            }
            
            optimizations.append(.scaledDurations(
                scaleFactor: scaleFactor,
                savings: currentCost - budget
            ))
        }
        
        return OptimizedSegments(
            segments: optimizedSegments,
            totalCost: calculator.estimateCost(for: optimizedSegments),
            optimizations: optimizations
        )
    }
    
    private func calculateImportance(_ segment: PromptSegment) -> Double {
        var importance = 1.0
        
        // Scene type importance
        switch segment.sceneType {
        case .establishing:
            importance += 0.5
        case .action:
            importance += 0.3
        case .dialogue:
            importance += 0.2
        case .transition:
            importance -= 0.2
        case .montage:
            importance -= 0.1
        case .none:
            break
        }
        
        // Duration importance (longer segments are more important)
        importance += Double(segment.estimatedDuration) / 30.0
        
        // Text length importance
        let wordCount = segment.text.components(separatedBy: .whitespacesAndNewlines).count
        importance += Double(wordCount) / 100.0
        
        return importance
    }
}

// MARK: - Optimization Results

public struct OptimizedSegments: Sendable {
    public let segments: [PromptSegment]
    public let totalCost: Decimal
    public let optimizations: [Optimization]
    
    public init(
        segments: [PromptSegment],
        totalCost: Decimal,
        optimizations: [Optimization]
    ) {
        self.segments = segments
        self.totalCost = totalCost
        self.optimizations = optimizations
    }
}

public enum Optimization: Sendable {
    case removedSegment(index: Int, savings: Decimal)
    case scaledDurations(scaleFactor: Double, savings: Decimal)
    case combinedSegments(indices: [Int], savings: Decimal)
    case reducedQuality(index: Int, savings: Decimal)
}

// MARK: - Cost Reporting

public struct CostReport: Sendable {
    public let analysis: CostAnalysis
    public let budgetStatus: BudgetStatus
    public let recommendations: [String]
    
    public init(
        analysis: CostAnalysis,
        budgetStatus: BudgetStatus,
        recommendations: [String]
    ) {
        self.analysis = analysis
        self.budgetStatus = budgetStatus
        self.recommendations = recommendations
    }
}

public enum BudgetStatus: Sendable {
    case withinBudget(remaining: Decimal)
    case overBudget(overage: Decimal)
    case noBudgetSet
}

// MARK: - Cost Calculator Extensions

public extension CostCalculator {
    
    /// Creates a detailed cost analysis for segments
    func analyzeCosts(for segments: [PromptSegment]) -> CostAnalysis {
        let totalCost = estimateCost(for: segments)
        var costPerSegment: [Int: Decimal] = [:]
        
        for segment in segments {
            costPerSegment[segment.index] = estimateCost(for: segment.estimatedDuration)
        }
        
        let breakdown = CostBreakdown(
            baseCost: Decimal(segments.count) * 0.1, // Base cost per segment
            durationCost: totalCost * 0.7, // 70% of cost is duration-based
            complexityCost: totalCost * 0.2, // 20% is complexity-based
            qualityCost: totalCost * 0.1  // 10% is quality-based
        )
        
        let recommendations = generateRecommendations(for: segments, totalCost: totalCost)
        
        return CostAnalysis(
            totalCost: totalCost,
            costPerSegment: costPerSegment,
            costBreakdown: breakdown,
            recommendations: recommendations
        )
    }
    
    private func generateRecommendations(
        for segments: [PromptSegment],
        totalCost: Decimal
    ) -> [CostRecommendation] {
        var recommendations: [CostRecommendation] = []
        
        // Find segments that are too long
        for segment in segments {
            if segment.estimatedDuration > 20 {
                recommendations.append(.reduceDuration(
                    segmentIndex: segment.index,
                    currentDuration: segment.estimatedDuration,
                    suggestedDuration: 15.0
                ))
            }
        }
        
        // Find segments that could be combined
        let shortSegments = segments.filter { $0.estimatedDuration < 5 }
        if shortSegments.count >= 2 {
            let savings = estimateCost(for: shortSegments.reduce(0) { $0 + $1.estimatedDuration }) * 0.2
            recommendations.append(.combineSegments(
                segmentIndices: shortSegments.map { $0.index },
                savings: savings
            ))
        }
        
        return recommendations
    }
    
    /// Generates a cost report
    func generateReport(
        for segments: [PromptSegment],
        maxBudget: Decimal? = nil
    ) -> CostReport {
        let analysis = analyzeCosts(for: segments)
        
        let budgetStatus: BudgetStatus
        if let maxBudget = maxBudget {
            if analysis.totalCost <= maxBudget {
                budgetStatus = .withinBudget(remaining: maxBudget - analysis.totalCost)
            } else {
                budgetStatus = .overBudget(overage: analysis.totalCost - maxBudget)
            }
        } else {
            budgetStatus = .noBudgetSet
        }
        
        let recommendations = analysis.recommendations.map { recommendation in
            switch recommendation {
            case .reduceDuration(let index, let current, let suggested):
                return "Reduce segment \(index + 1) duration from \(String(format: "%.1f", current))s to \(String(format: "%.1f", suggested))s"
            case .removeSegment(let index, let savings):
                return "Remove segment \(index + 1) to save \(savings) credits"
            case .combineSegments(let indices, let savings):
                return "Combine segments \(indices.map { $0 + 1 }.joined(separator: ", ")) to save \(savings) credits"
            case .optimizeQuality(let index, let current, let suggested):
                return "Optimize segment \(index + 1) quality from \(current) to \(suggested)"
            }
        }
        
        return CostReport(
            analysis: analysis,
            budgetStatus: budgetStatus,
            recommendations: recommendations
        )
    }
}
