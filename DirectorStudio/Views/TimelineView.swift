import SwiftUI
import CoreData

// MARK: - Timeline View
public struct TimelineView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var soraService: SoraService
    @StateObject private var continuityEngine: ContinuityEngine
    @State private var scenes: [SceneModel] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @AppStorage("clipBalance") private var clipBalance = 0
    @AppStorage("shareTelemetry") private var shareTelemetry = false

    public init(apiKey: String) {
        _soraService = StateObject(wrappedValue: SoraService(apiKey: apiKey))
        _continuityEngine = StateObject(wrappedValue: ContinuityEngine(context: PersistenceController.shared.container.viewContext))
    }

    public var body: some View {
        NavigationStack {
            VStack {
                // Token balance display
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("\(clipBalance) clips")
                        .font(.headline)
                    Spacer()
                    Button("Buy Clips") {
                        // Show clip purchase sheet
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                List(scenes) { scene in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scene.prompt)
                                .font(.body)
                                .lineLimit(2)
                            Text("Scene \(scene.id) • \(scene.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !scene.characters.isEmpty {
                                Text("Characters: \(scene.characters.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        
                        let validation = continuityEngine.validate(scene)
                        if validation["ok"] as? Bool ?? false {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button("Generate ($0.50)") {
                            Task { await generateClip(scene: scene) }
                        }
                        .tint(.blue)
                        .disabled(clipBalance < 1)
                    }
                }
                
                if soraService.isGenerating {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(soraService.generationProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                if let url = soraService.previewURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    } placeholder: {
                        ProgressView("Rendering Scene...")
                    }
                    .frame(maxHeight: 200)
                    .padding()
                }
            }
            .navigationTitle("Timeline")
            .alert("Continuity Error", isPresented: $showingAlert) {
                Button("Fix Now") { /* Open editor */ }
                Button("Ignore") { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Scene") {
                        addDummyScene()
                    }
                }
            }
        }
    }

    // MARK: - Private Methods
    private func addDummyScene() {
        let newScene = SceneModel(
            id: scenes.count + 1,
            location: "Great Hall",
            characters: ["Harry", "Hermione"],
            props: ["wand", "book"],
            prompt: "Harry and Hermione discuss the plan while holding their wands",
            tone: "tense"
        )
        scenes.append(newScene)
    }

    private func generateClip(scene: SceneModel) async {
        // Check token balance
        guard clipBalance >= 1 else {
            alertMessage = "Not enough clips. Buy more to generate videos."
            showingAlert = true
            return
        }
        
        let validation = continuityEngine.validate(scene)
        guard validation["ok"] as? Bool ?? false else {
            alertMessage = (validation["issues"] as? [String])?.joined(separator: "\n") ?? "Unknown issue"
            showingAlert = true
            return
        }

        let enhancedPrompt = continuityEngine.enhancePrompt(for: scene)
        do {
            if let taskId = try await soraService.generate(prompt: enhancedPrompt) {
                // Deduct token
                clipBalance -= 1
                
                // Poll for completion
                if let url = try await soraService.pollForCompletion(taskId: taskId) {
                    soraService.previewURL = url
                    
                    // Update telemetry if enabled
                    if shareTelemetry {
                        for prop in scene.props {
                            continuityEngine.updateTelemetry(word: prop, appeared: true)
                        }
                    }
                }
            }
        } catch {
            alertMessage = "Generation failed: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Preview
#Preview {
    TimelineView(apiKey: "test-key")
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
