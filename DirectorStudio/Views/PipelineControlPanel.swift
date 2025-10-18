//
//  PipelineControlPanel.swift
//  DirectorStudio
//
//  SwiftUI interface for managing pipeline configuration
//  Allows users to toggle steps ON/OFF and view execution status
//

import SwiftUI

// MARK: - Pipeline Control Panel

public struct PipelineControlPanel: View {
    @Binding var config: PipelineConfig
    @State private var showingPresets = false
    
    public init(config: Binding<PipelineConfig>) {
        self._config = config
    }
    
    public var body: some View {
        Form {
            Section {
                headerView
            }
            
            Section("Processing Steps") {
                stepToggle(
                    isEnabled: $config.isRewordingEnabled,
                    title: "Rewording",
                    description: "Transform story text style",
                    icon: "text.word.spacing"
                )
                
                if config.isRewordingEnabled {
                    rewordingTypePicker
                }
                
                stepToggle(
                    isEnabled: $config.isStoryAnalysisEnabled,
                    title: "Story Analysis",
                    description: "Extract characters, locations, scenes",
                    icon: "chart.bar.doc.horizontal"
                )
                
                stepToggle(
                    isEnabled: $config.isSegmentationEnabled,
                    title: "Segmentation",
                    description: "Break into video segments",
                    icon: "scissors"
                )
                
                stepToggle(
                    isEnabled: $config.isCinematicTaxonomyEnabled,
                    title: "Cinematic Taxonomy",
                    description: "Add camera angles and visual details",
                    icon: "video"
                )
                
                stepToggle(
                    isEnabled: $config.isContinuityEnabled,
                    title: "Continuity",
                    description: "Generate visual consistency markers",
                    icon: "link"
                )
                
                stepToggle(
                    isEnabled: $config.isPackagingEnabled,
                    title: "Packaging",
                    description: "Final output preparation",
                    icon: "shippingbox"
                )
            }
            
            Section("Advanced Settings") {
                Toggle("Continue on Errors", isOn: $config.continueOnError)
                Toggle("Detailed Logging", isOn: $config.enableDetailedLogging)
                
                Stepper("Max Retries: \(config.maxRetries)", value: $config.maxRetries, in: 0...10)
                
                HStack {
                    Text("Timeout per Step")
                    Spacer()
                    Text("\(Int(config.timeoutPerStep))s")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("API Configuration") {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.1f", config.apiTemperature))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $config.apiTemperature, in: 0...1, step: 0.1)
                
                Stepper("Max Tokens: \(config.apiMaxTokens)", value: $config.apiMaxTokens, in: 1000...8000, step: 1000)
            }
            
            Section {
                presetsButton
            }
        }
        .navigationTitle("Pipeline Configuration")
        .sheet(isPresented: $showingPresets) {
            PresetsSheet(config: $config, isPresented: $showingPresets)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(config.enabledStepsCount) of \(config.totalSteps)", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Button("Validate") {
                    validateConfiguration()
                }
                .buttonStyle(.bordered)
            }
            
            if config.enabledStepsCount == 0 {
                Text("⚠️ No steps enabled - pipeline will not produce output")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    private var rewordingTypePicker: some View {
        Picker("Rewording Type", selection: $config.rewordingType) {
            ForEach(RewordingType.allCases, id: \.self) { type in
                Text(type.displayName).tag(type as RewordingType?)
            }
        }
    }
    
    private var presetsButton: some View {
        Button(action: { showingPresets = true }) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Load Preset Configuration")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func stepToggle(
        isEnabled: Binding<Bool>,
        title: String,
        description: String,
        icon: String
    ) -> some View {
        Toggle(isOn: isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isEnabled.wrappedValue ? .blue : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func validateConfiguration() {
        let warnings = config.validate()
        
        if warnings.isEmpty {
            print("✅ Configuration is valid")
        } else {
            print("⚠️ Configuration warnings:")
            warnings.forEach { print("  - \($0)") }
        }
    }
}

// MARK: - Presets Sheet

private struct PresetsSheet: View {
    @Binding var config: PipelineConfig
    @Binding var isPresented: Bool
    
    private let presets: [(String, String, PipelineConfig)] = [
        ("Default", "Balanced processing with all steps enabled", .default),
        ("Quick Process", "Fast processing with minimal steps", .quickProcess),
        ("Full Process", "Maximum quality with all enhancements", .fullProcess),
        ("Segmentation Only", "Just break story into segments", .segmentationOnly)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(presets, id: \.0) { preset in
                    Button {
                        config = preset.2
                        isPresented = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.0)
                                .font(.headline)
                            Text(preset.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Configuration Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Pipeline Execution View

public struct PipelineExecutionView: View {
    @ObservedObject var manager: PipelineManager
    @State private var story: String = ""
    @State private var projectTitle: String = "My Project"
    @State private var showingConfig = false
    
    public init(manager: PipelineManager) {
        self.manager = manager
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                inputSection
                
                Divider()
                
                stepsSection
                
                Divider()
                
                controlsSection
            }
            .padding()
            .navigationTitle("DirectorStudio Pipeline")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                NavigationStack {
                    PipelineControlPanel(config: .constant(manager.config))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingConfig = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input")
                .font(.headline)
            
            TextField("Project Title", text: $projectTitle)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $story)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if story.isEmpty {
                        Text("Enter your story here...")
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
        }
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline Steps")
                .font(.headline)
            
            ForEach(manager.steps) { step in
                PipelineStepRow(step: step)
            }
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button(action: executeFullPipeline) {
                HStack {
                    if manager.isRunning {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(manager.isRunning ? "Running..." : "Run Pipeline")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.isRunning || story.isEmpty)
            
            if manager.isRunning {
                Button("Cancel") {
                    manager.cancel()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            if let error = manager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private func executeFullPipeline() {
        Task {
            let input = PipelineInput(
                story: story,
                rewordType: manager.config.rewordingType,
                projectTitle: projectTitle
            )
            
            do {
                let output = try await manager.execute(input: input)
                print("Pipeline completed successfully!")
                print("Generated \(output.segments.count) segments")
            } catch {
                print("Pipeline failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Pipeline Step Row

private struct PipelineStepRow: View {
    let step: PipelineStepInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 24)
            
            // Step info
            VStack(alignment: .leading, spacing: 2) {
                Text(step.name)
                    .font(.body)
                
                if !step.warnings.isEmpty {
                    Text("⚠️ \(step.warnings.first!)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            // Execution time or progress
            if let executionTime = step.executionTime {
                Text(String(format: "%.1fs", executionTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if step.status == .running {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch step.status {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.gray)
        case .running:
            Image(systemName: "circle.fill")
                .foregroundStyle(.blue)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.orange)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .cancelled:
            Image(systemName: "stop.circle.fill")
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - Preview

#Preview("Control Panel") {
    NavigationStack {
        PipelineControlPanel(config: .constant(.default))
    }
}

#Preview("Execution View") {
    PipelineExecutionView(manager: PipelineManager())
}
