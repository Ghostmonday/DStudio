import Foundation
import CoreData
import NaturalLanguage
import SwiftUI

// MARK: - Continuity Engine
@MainActor
class ContinuityEngine: ObservableObject {
    @Published var state: SceneModel?
    @Published var issuesLog: [[String: Any]] = []
    @Published var manifestationScores: [String: [String: Int]] = [:]
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Validation
    @discardableResult
    func validate(_ scene: SceneModel) -> [String: Any] {
        guard let prev = state else {
            state = scene
            persistState(scene)
            return ["ok": true, "confidence": 1.0, "issues": [], "ask_human": false]
        }
        
        var confidence = 1.0
        var issues: [String] = []
        
        // Rule 1: Prop persistence
        for prop in prev.props where !scene.props.contains(prop) {
            confidence *= 0.7
            issues.append("❌ \(prop) disappeared (was in scene \(prev.id))")
        }
        
        // Rule 2: Character location logic
        if prev.location == scene.location {
            for char in prev.characters where !scene.characters.contains(char) {
                confidence *= 0.5
                issues.append("❌ \(char) vanished from \(scene.location)")
            }
        }
        
        // Rule 3: Tone whiplash detection
        if toneDistance(prev.tone, scene.tone) > 0.8 {
            confidence *= 0.6
            issues.append("⚠️ Tone jumped: \(prev.tone) → \(scene.tone)")
        }
        
        // Update state
        state = scene
        persistState(scene)
        
        // Log issues
        if !issues.isEmpty {
            let entry: [String: Any] = [
                "scene_id": scene.id,
                "confidence": confidence,
                "issues": issues
            ]
            issuesLog.append(entry)
            persistLog(entry)
        }
        
        return [
            "ok": confidence >= 0.6,
            "confidence": confidence,
            "issues": issues,
            "ask_human": confidence < 0.6
        ]
    }
    
    // MARK: - Prompt Enhancement
    func enhancePrompt(for scene: SceneModel) -> String {
        var out = scene.prompt
        
        // Enhance props with low manifestation rates
        for prop in scene.props where manifestationRate(for: prop) < 0.5 {
            out += ", CLEARLY SHOWING \(prop)"
        }
        
        // Add character consistency hints
        if let prev = state {
            for char in scene.characters where prev.characters.contains(char) {
                out += ", \(char) with same appearance as previous scene"
            }
        }
        
        return out
    }
    
    // MARK: - Telemetry
    func updateTelemetry(word: String, appeared: Bool) {
        var d = manifestationScores[word] ?? ["attempts": 0, "successes": 0]
        d["attempts", default: 0] += 1
        if appeared { d["successes", default: 0] += 1 }
        manifestationScores[word] = d
        persistTelemetry(word: word, data: d)
    }
    
    func manifestationRate(for word: String) -> Double {
        guard let d = manifestationScores[word],
              let attempts = d["attempts"],
              attempts > 0 else { return 0.8 }
        return Double(d["successes"] ?? 0) / Double(attempts)
    }
    
    // MARK: - Reporting
    func report() -> [String: Any] {
        return [
            "total_conflicts": issuesLog.count,
            "conflicts": issuesLog,
            "manifestation_data": manifestationScores
        ]
    }
    
    // MARK: - Private Methods
    private func toneDistance(_ t1: String, _ t2: String) -> Double {
        func sentiment(_ s: String) -> Double {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = s
            var score: Double = 0
            tagger.enumerateTags(in: s.startIndex..<s.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
                score = Double(tag?.rawValue ?? "0") ?? 0
                return false
            }
            return score
        }
        return abs(sentiment(t1) - sentiment(t2))
    }
    
    private func persistState(_ s: SceneModel) {
        let e = NSEntityDescription.insertNewObject(forEntityName: "SceneState", into: context)
        e.setValue(s.id, forKey: "id")
        e.setValue(s.location, forKey: "location")
        e.setValue(s.characters, forKey: "characters")
        e.setValue(s.props, forKey: "props")
        e.setValue(s.prompt, forKey: "prompt")
        e.setValue(s.tone, forKey: "tone")
        e.setValue(Date(), forKey: "timestamp")
        try? context.save()
    }
    
    private func persistLog(_ entry: [String: Any]) {
        let e = NSEntityDescription.insertNewObject(forEntityName: "ContinuityLog", into: context)
        e.setValue(entry["scene_id"] as? Int, forKey: "scene_id")
        e.setValue(entry["confidence"] as? Double, forKey: "confidence")
        e.setValue(entry["issues"] as? [String], forKey: "issues")
        e.setValue(Date(), forKey: "timestamp")
        try? context.save()
    }
    
    private func persistTelemetry(word: String, data: [String: Int]) {
        let e = NSEntityDescription.insertNewObject(forEntityName: "Telemetry", into: context)
        e.setValue(word, forKey: "word")
        e.setValue(data["attempts"], forKey: "attempts")
        e.setValue(data["successes"], forKey: "successes")
        e.setValue(Date(), forKey: "timestamp")
        try? context.save()
    }
}
