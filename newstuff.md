 **[2025-10-15 | 04:10:57 PM PDT]**

All good, Boss. You’ve had a day. I’ve got you.

Below is your **Cheetah handoff package**—copy/paste straight into Cursor. It includes: the **handbook**, the **three Swift files**, Core Data schema, telemetry opt-in, and StoreKit mapping. Ship it.

# CHEETAH_HANDBOOK.md — DirectorStudio (iOS)

## Objective

Wire continuity validation + Sora generation into existing D-Studio iOS app with opt-in telemetry and StoreKit (subscription + clip credits). iOS only.

## Files to add

Add these three to your project (target: iOS app):

* `Sources/Engine/ContinuityEngine.swift`  (new)
* `Sources/Services/SoraService.swift`     (new)
* `Views/TimelineView.swift`               (demo UI or integrate into your `StudioView.swift`)

## Core Data (DirectorStudio.xcdatamodeld)

Create/extend model with **Transformable** arrays using `NSSecureUnarchiveFromData`:

* **SceneState**: `id:Int32`, `location:String`, `characters:[String]`, `props:[String]`, `prompt:String`, `tone:String`
* **ContinuityLog**: `scene_id:Int32`, `confidence:Double`, `issues:[String]`
* **Telemetry**: `word:String`, `attempts:Int32`, `successes:Int32`

If you already have a model: make a **new version**, set it current.

## Wire points (minimal)

In the screen where you list scene segments (your `StudioView.swift`), inject:

```swift
@Environment(\.managedObjectContext) private var context
@StateObject private var engine = ContinuityEngine(context: PersistenceController.shared.container.viewContext)
@StateObject private var sora   = SoraService(apiKey: ProcessInfo.processInfo.environment["POLLO_API_KEY"] ?? "SET_ME")
@AppStorage("shareTelemetry") private var shareTelemetry = false
@AppStorage("clipBalance") private var clipBalance = 0
```

Per scene cell:

```swift
let scene = SceneModel(/* map from your segment */)
let result = engine.validate(scene)
let ok = (result["ok"] as? Bool) ?? false
// show green check if ok, warning if not
```

Generate action:

```swift
guard ok, clipBalance > 0 else { return }
clipBalance -= 1
let enhanced = engine.enhancePrompt(for: scene)
if let taskId = try await sora.generate(prompt: enhanced) {
    try await Task.sleep(nanoseconds: 4_000_000_000) // quick poll MVP
    let status = try await sora.checkStatus(taskId: taskId)
    if shareTelemetry { engine.updateTelemetry(word: "wand", appeared: true) } // example
}
```

## StoreKit products (App Store Connect)

* **Auto-renewable**: `studio.subscription.base` — $7.99/month (unlimited validations, reports)
* **Consumables**:

  * `studio.clips.25`  — $9.99
  * `studio.clips.70`  — $24.99
  * `studio.clips.150` — $49.99
  * `studio.clips.350` — $99.99

Client: maintain `@AppStorage("clipBalance")`. Increment on purchase. Decrement on each **Generate**.

## Telemetry (opt-in only)

Onboarding/Settings:

```swift
@AppStorage("shareTelemetry") var shareTelemetry = false
Toggle("Share anonymized performance data", isOn: $shareTelemetry)
```

App Privacy / Privacy Manifest: “Product Improvement”; Diagnostics & Usage Data; **non-linked, no tracking**.

## Sora/Pollo API key

Xcode Scheme → Run → Environment Variables:
`POLLO_API_KEY = <your key>`

## Build checklist (fast)

1. Add files (below).
2. Update Core Data.
3. Set `POLLO_API_KEY`.
4. Add telemetry toggle.
5. (Option) Add `TimelineView` as a temp tab to verify.
6. Run: scene with `wand` → next scene without → see continuity warning.
7. Buy/seed clips; generate 4s clip; poll; confirm preview/telemetry.

---

## File 1 — ContinuityEngine.swift

```swift
import Foundation
import CoreData
import NaturalLanguage

public struct SceneModel: Codable, Identifiable, Equatable {
    public let id: Int
    public let location: String
    public let characters: [String]
    public let props: [String]
    public let prompt: String
    public let tone: String
}

@MainActor
public final class ContinuityEngine: ObservableObject {
    @Published public var state: SceneModel?
    @Published public var issuesLog: [[String: Any]] = []
    @Published public var manifestationScores: [String: [String: Int]] = [:]
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) { self.context = context }

    @discardableResult
    public func validate(_ scene: SceneModel) -> [String: Any] {
        guard let prev = state else {
            state = scene; persistState(scene)
            return ["ok": true, "confidence": 1.0, "issues": [], "ask_human": false]
        }
        var confidence = 1.0
        var issues: [String] = []

        for prop in prev.props where !scene.props.contains(prop) {
            confidence *= 0.7
            issues.append("❌ \(prop) disappeared (was in scene \(prev.id))")
        }
        if prev.location == scene.location {
            for char in prev.characters where !scene.characters.contains(char) {
                confidence *= 0.5
                issues.append("❌ \(char) vanished from \(scene.location)")
            }
        }
        if toneDistance(prev.tone, scene.tone) > 0.8 {
            confidence *= 0.6
            issues.append("⚠️ Tone jumped: \(prev.tone) → \(scene.tone)")
        }

        state = scene; persistState(scene)
        if !issues.isEmpty {
            let entry: [String: Any] = ["scene_id": scene.id, "confidence": confidence, "issues": issues]
            issuesLog.append(entry); persistLog(entry)
        }
        return ["ok": confidence >= 0.6, "confidence": confidence, "issues": issues, "ask_human": confidence < 0.6]
    }

    public func enhancePrompt(for scene: SceneModel) -> String {
        var out = scene.prompt
        for prop in scene.props where manifestationRate(for: prop) < 0.5 {
            out += ", CLEARLY SHOWING \(prop)"
        }
        if let prev = state {
            for char in scene.characters where prev.characters.contains(char) {
                out += ", \(char) with same appearance as previous scene"
            }
        }
        return out
    }

    public func updateTelemetry(word: String, appeared: Bool) {
        var d = manifestationScores[word] ?? ["attempts": 0, "successes": 0]
        d["attempts", default: 0] += 1
        if appeared { d["successes", default: 0] += 1 }
        manifestationScores[word] = d
        persistTelemetry(word: word, data: d)
    }

    public func manifestationRate(for word: String) -> Double {
        guard let d = manifestationScores[word], let a = d["attempts"], a > 0 else { return 0.8 }
        return Double(d["successes"] ?? 0) / Double(a)
    }

    public func report() -> [String: Any] {
        ["total_conflicts": issuesLog.count, "conflicts": issuesLog, "manifestation_data": manifestationScores]
    }

    private func toneDistance(_ t1: String, _ t2: String) -> Double {
        func sentiment(_ s: String) -> Double {
            let tagger = NLTagger(tagSchemes: [.sentimentScore]); tagger.string = s
            var score: Double = 0
            tagger.enumerateTags(in: s.startIndex..<s.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
                score = Double(tag?.rawValue ?? "0") ?? 0; return false
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
        try? context.save()
    }
    private func persistLog(_ entry: [String: Any]) {
        let e = NSEntityDescription.insertNewObject(forEntityName: "ContinuityLog", into: context)
        e.setValue(entry["scene_id"] as? Int, forKey: "scene_id")
        e.setValue(entry["confidence"] as? Double, forKey: "confidence")
        e.setValue(entry["issues"] as? [String], forKey: "issues")
        try? context.save()
    }
    private func persistTelemetry(word: String, data: [String: Int]) {
        let e = NSEntityDescription.insertNewObject(forEntityName: "Telemetry", into: context)
        e.setValue(word, forKey: "word")
        e.setValue(data["attempts"], forKey: "attempts")
        e.setValue(data["successes"], forKey: "successes")
        try? context.save()
    }
}
```

## File 2 — SoraService.swift

```swift
import Foundation

@MainActor
public final class SoraService: ObservableObject {
    @Published public var previewURL: URL?
    private let apiKey: String
    private let baseURL = URL(string: "https://pollo.ai/api/platform")!

    public init(apiKey: String) { self.apiKey = apiKey }

    public struct SoraResponse: Codable {
        public struct DataObj: Codable { public let taskId: String }
        public let data: DataObj
    }

    public func generate(prompt: String, length: Int = 4) async throws -> String? {
        var req = URLRequest(url: baseURL.appendingPathComponent("generation/sora/sora-2-pro"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        let body: [String: Any] = ["input": ["prompt": prompt, "length": length, "aspectRatio": "16:9"]]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let resp = try JSONDecoder().decode(SoraResponse.self, from: data)
        return resp.data.taskId
    }

    public func checkStatus(taskId: String) async throws -> [String: Any] {
        var req = URLRequest(url: baseURL.appendingPathComponent("task/\(taskId)"))
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
}
```

## File 3 — TimelineView.swift (demo UI, optional)

```swift
import SwiftUI
import CoreData

public struct TimelineView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var sora = SoraService(apiKey: ProcessInfo.processInfo.environment["POLLO_API_KEY"] ?? "SET_ME")
    @StateObject private var engine: ContinuityEngine
    @State private var scenes: [SceneModel] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @AppStorage("clipBalance") private var clipBalance = 0
    @AppStorage("shareTelemetry") private var shareTelemetry = false

    public init(context: NSManagedObjectContext) {
        _engine = StateObject(wrappedValue: ContinuityEngine(context: context))
    }

    public var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(scenes) { scene in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(scene.prompt).font(.headline)
                                Text("\(scene.location) · \(scene.characters.joined(separator: \", \"))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            let v = engine.validate(scene)
                            Image(systemName: ((v["ok"] as? Bool) ?? false) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(((v["ok"] as? Bool) ?? false) ? .green : .orange)
                        }
                        .swipeActions {
                            Button("Generate") { Task { await generate(scene) } }.tint(.blue)
                        }
                    }
                }

                if let url = sora.previewURL {
                    AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fit) }
                        placeholder: { ProgressView("Rendering…") }
                }
            }
            .navigationTitle("Timeline")
            .toolbar { ToolbarItem { Button("Add Scene") { addDummyScene() } } }
            .alert("Continuity", isPresented: $showingAlert) {
                Button("Fix") {}
                Button("Ignore") {}
            } message: { Text(alertMessage) }
        }
    }

    private func addDummyScene() {
        scenes.append(SceneModel(id: scenes.count + 1, location: "Great Hall",
                                 characters: ["Harry"], props: ["wand"],
                                 prompt: "Harry holds wand", tone: "tense"))
    }

    private func generate(_ scene: SceneModel) async {
        let validation = engine.validate(scene)
        guard (validation["ok"] as? Bool) == true else {
            alertMessage = (validation["issues"] as? [String])?.joined(separator: "\n") ?? "Unknown issue"
            showingAlert = true; return
        }
        guard clipBalance > 0 else {
            alertMessage = "You’re out of clip credits."; showingAlert = true; return
        }
        clipBalance -= 1

        let enhanced = engine.enhancePrompt(for: scene)
        do {
            if let taskId = try await sora.generate(prompt: enhanced) {
                try await Task.sleep(nanoseconds: 4_000_000_000)
                let status = try await sora.checkStatus(taskId: taskId)
                if let urlStr = (status["video_url"] as? String)
                    ?? (status["data"] as? [String: Any])?["video_url"] as? String,
                   let url = URL(string: urlStr) { sora.previewURL = url }
                if shareTelemetry { engine.updateTelemetry(word: "wand", appeared: true) } // example
            }
        } catch {
            alertMessage = "Generation failed: \(error.localizedDescription)"; showingAlert = true
        }
    }
}
```

---

## App Store compliance quick hits

* **StoreKit only** for purchases.
* **Telemetry opt-in** toggle; **non-linked** diagnostics in Privacy.
* Position as **prompt composer + continuity validator** with optional generation.

---

Need me to wire these into specific files of your repo (by path) next? I can produce a line-edited diff against `StudioView.swift` without asking for anything else.

# 🎯 YES - HERE'S ALL THE CODE FOR YOUR AGENT

**Copy this entire message and paste it to your coding agent (Cursor/Copilot):**

---

## 📦 DIRECTORSTUDIO CONTINUITY ENGINE - SWIFT IMPLEMENTATION

**Monetization Model:**
- $8/month subscription for unlimited script validation
- Pay-per-clip for video generation: $0.50 per 4s clip
- Token packs: $10 = 25 clips, $25 = 70 clips, $50 = 150 clips

**Free Tier:**
- 3 script validations/month
- NO video generation
- See continuity reports only

---

## 📁 FILE 1: `ContinuityEngine.swift`

```swift
import Foundation
import CoreData
import NaturalLanguage

struct Scene: Codable, Identifiable {
    let id: Int
    let location: String
    let characters: [String]
    let props: [String]
    let prompt: String
    let tone: String
}

@MainActor
class ContinuityEngine: ObservableObject {
    @Published var state: Scene?
    @Published var log: [[String: Any]] = []
    @Published var manifestationScores: [String: [String: Int]] = [:]
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func validate(scene: Scene) -> [String: Any] {
        guard let currentState = state else {
            state = scene
            saveState()
            return ["ok": true, "confidence": 1.0, "issues": [], "ask_human": false]
        }

        var confidence = 1.0
        var issues: [String] = []

        // Rule 1: Prop persistence
        for prop in currentState.props {
            if !scene.props.contains(prop) {
                confidence *= 0.7
                issues.append("❌ \(prop) disappeared (was in scene \(currentState.id))")
            }
        }

        // Rule 2: Character location logic
        if currentState.location == scene.location {
            for char in currentState.characters {
                if !scene.characters.contains(char) {
                    confidence *= 0.5
                    issues.append("❌ \(char) vanished from \(scene.location)")
                }
            }
        }

        // Rule 3: Tone whiplash detection
        let toneDistance = toneDistance(currentState.tone, scene.tone)
        if toneDistance > 0.8 {
            confidence *= 0.6
            issues.append("⚠️ Tone jumped: \(currentState.tone) → \(scene.tone)")
        }

        // Update state
        state = scene
        saveState()

        // Log issues
        if !issues.isEmpty {
            let logEntry: [String: Any] = [
                "scene_id": scene.id,
                "confidence": confidence,
                "issues": issues
            ]
            log.append(logEntry)
            saveLog(logEntry)
        }

        return [
            "ok": confidence >= 0.6,
            "confidence": confidence,
            "issues": issues,
            "ask_human": confidence < 0.6
        ]
    }

    private func toneDistance(_ t1: String, _ t2: String) -> Double {
        let embedder = NLTagger(tagSchemes: [.sentimentScore])
        var score1: Double = 0
        var score2: Double = 0
        embedder.string = t1
        embedder.enumerateTags(in: t1.startIndex..<t1.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let rawValue = tag?.rawValue, let score = Double(rawValue) {
                score1 = score
            }
            return true
        }
        embedder.string = t2
        embedder.enumerateTags(in: t2.startIndex..<t2.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let rawValue = tag?.rawValue, let score = Double(rawValue) {
                score2 = score
            }
            return true
        }
        return abs(score1 - score2)
    }

    func updateTelemetry(word: String, appeared: Bool) {
        var data = manifestationScores[word] ?? ["attempts": 0, "successes": 0]
        data["attempts"]! += 1
        if appeared {
            data["successes"]! += 1
        }
        manifestationScores[word] = data
        saveTelemetry(word: word, data: data)
    }

    func getManifestationRate(word: String) -> Double {
        guard let data = manifestationScores[word], data["attempts"]! > 0 else {
            return 0.8
        }
        return Double(data["successes"]!) / Double(data["attempts"]!)
    }

    func enhancePrompt(scene: Scene) -> String {
        var enhanced = scene.prompt
        for prop in scene.props {
            if getManifestationRate(word: prop) < 0.5 {
                enhanced += ", CLEARLY SHOWING \(prop)"
            }
        }
        if let prevState = state {
            for char in scene.characters {
                if prevState.characters.contains(char) {
                    enhanced += ", \(char) with same appearance as previous scene"
                }
            }
        }
        return enhanced
    }

    func report() -> [String: Any] {
        return [
            "total_conflicts": log.count,
            "conflicts": log,
            "manifestation_data": manifestationScores
        ]
    }

    private func saveState() {
        guard let scene = state else { return }
        let entity = NSEntityDescription.insertNewObject(forEntityName: "SceneState", into: context)
        entity.setValue(scene.id, forKey: "id")
        entity.setValue(scene.location, forKey: "location")
        entity.setValue(scene.characters, forKey: "characters")
        entity.setValue(scene.props, forKey: "props")
        entity.setValue(scene.prompt, forKey: "prompt")
        entity.setValue(scene.tone, forKey: "tone")
        try? context.save()
    }

    private func saveLog(_ logEntry: [String: Any]) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ContinuityLog", into: context)
        entity.setValue(logEntry["scene_id"] as? Int, forKey: "scene_id")
        entity.setValue(logEntry["confidence"] as? Double, forKey: "confidence")
        entity.setValue(logEntry["issues"] as? [String], forKey: "issues")
        try? context.save()
    }

    private func saveTelemetry(word: String, data: [String: Int]) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Telemetry", into: context)
        entity.setValue(word, forKey: "word")
        entity.setValue(data["attempts"], forKey: "attempts")
        entity.setValue(data["successes"], forKey: "successes")
        try? context.save()
    }
}
```

---

## 📁 FILE 2: `SoraService.swift`

```swift
import Foundation

@MainActor
class SoraService: ObservableObject {
    @Published var previewURL: URL?
    private let apiKey: String
    private let baseURL = "https://pollo.ai/api/platform"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generate(prompt: String, length: Int = 4) async throws -> String? {
        let url = URL(string: "\(baseURL)/generation/sora/sora-2-pro")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        let body: [String: Any] = [
            "input": [
                "prompt": prompt,
                "length": length,
                "aspectRatio": "16:9"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SoraResponse.self, from: data)
        return response.data.taskId
    }

    func checkStatus(taskId: String) async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/task/\(taskId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

struct SoraResponse: Codable {
    struct Data: Codable {
        let taskId: String
    }
    let data: Data
}
```

---

## 📁 FILE 3: `TimelineView.swift`

```swift
import SwiftUI
import CoreData

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var soraService: SoraService
    @StateObject private var continuityEngine: ContinuityEngine
    @State private var scenes: [Scene] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var tokenBalance: Int = 0

    init(apiKey: String) {
        _soraService = StateObject(wrappedValue: SoraService(apiKey: apiKey))
        _continuityEngine = StateObject(wrappedValue: ContinuityEngine(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Token balance display
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("\(tokenBalance) tokens")
                    Spacer()
                    Button("Buy Tokens") {
                        // Show token purchase sheet
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                List(scenes) { scene in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(scene.prompt)
                                .font(.body)
                            Text("Scene \(scene.id) • \(scene.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if continuityEngine.validate(scene: scene)["ok"] as? Bool ?? false {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        }
                    }
                    .swipeActions {
                        Button("Generate ($0.50)") {
                            Task { await generateClip(scene: scene) }
                        }
                        .tint(.blue)
                        .disabled(tokenBalance < 1)
                    }
                }
                
                if let url = soraService.previewURL {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView("Rendering Scene...")
                    }
                }
            }
            .navigationTitle("Director Studio")
            .alert("Continuity Error", isPresented: $showingAlert) {
                Button("Fix Now") { /* Open editor */ }
                Button("Ignore") { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem {
                    Button("Add Scene") {
                        let newScene = Scene(
                            id: scenes.count + 1,
                            location: "Forest",
                            characters: ["Wizard"],
                            props: ["wand"],
                            prompt: "Wizard holds wand",
                            tone: "tense"
                        )
                        scenes.append(newScene)
                    }
                }
            }
        }
    }

    func generateClip(scene: Scene) async {
        // Check token balance
        guard tokenBalance >= 1 else {
            alertMessage = "Not enough tokens. Buy more to generate videos."
            showingAlert = true
            return
        }
        
        let validation = continuityEngine.validate(scene: scene)
        guard validation["ok"] as? Bool ?? false else {
            alertMessage = (validation["issues"] as? [String])?.joined(separator: "\n") ?? "Unknown issue"
            showingAlert = true
            return
        }

        let enhancedPrompt = continuityEngine.enhancePrompt(scene: scene)
        do {
            if let taskId = try await soraService.generate(prompt: enhancedPrompt) {
                // Deduct token
                tokenBalance -= 1
                
                // Poll for status
                try await Task.sleep(nanoseconds: 5_000_000_000)
                let status = try await soraService.checkStatus(taskId: taskId)
                if let urlString = status["video_url"] as? String, let url = URL(string: urlString) {
                    soraService.previewURL = url
                    continuityEngine.updateTelemetry(word: "wand", appeared: true)
                }
            }
        } catch {
            alertMessage = "Generation failed: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
```

---

## 📋 CORE DATA SETUP

**Add these entities to `DirectorStudio.xcdatamodeld`:**

1. **SceneState**
   - id: Int32
   - location: String
   - characters: Transformable (Array)
   - props: Transformable (Array)
   - prompt: String
   - tone: String

2. **ContinuityLog**
   - scene_id: Int32
   - confidence: Double
   - issues: Transformable (Array)

3. **Telemetry**
   - word: String
   - attempts: Int32
   - successes: Int32

---

## 🚀 INTEGRATION INSTRUCTIONS

1. Add these 3 files to your Xcode project under `Sources/Modules/` or `Sources/Services/`
2. Update Core Data model with the entities above
3. Replace `"pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn"` with your actual API key
4. Build and run on iOS Simulator
5. Test with 3-scene sequence to verify continuity validation works

---

**END OF CODE PACKAGE** 🎬 