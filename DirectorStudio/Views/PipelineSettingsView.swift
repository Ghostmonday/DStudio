//
//  PipelineSettingsView.swift
//  DirectorStudio
//
//  SwiftUI Settings View for Pipeline Configuration
//  Allows users to configure generation mode, segmentation, and limits
//

import SwiftUI

struct PipelineSettingsView: View {
    @Binding var config: UserControlConfig
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Generation Mode") {
                    Picker("Mode", selection: $config.generationMode) {
                        Text("Automatic").tag(UserControlConfig.GenerationMode.automatic)
                        Text("Semi-Automatic").tag(UserControlConfig.GenerationMode.semiAutomatic)
                        Text("Manual").tag(UserControlConfig.GenerationMode.manual)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Segmentation") {
                    Picker("Strategy", selection: $config.segmentationStrategy) {
                        Text("Automatic").tag(UserControlConfig.SegmentationStrategy.automatic)
                        Text("Per Scene").tag(UserControlConfig.SegmentationStrategy.perScene)
                        Text("Per Beat").tag(UserControlConfig.SegmentationStrategy.perBeat)
                        Text("Manual").tag(UserControlConfig.SegmentationStrategy.manual)
                    }
                    
                    if case .manual = config.segmentationStrategy {
                        Stepper("Shot Count: \(config.manualShotCount)", 
                               value: $config.manualShotCount, 
                               in: 1...100)
                    }
                }
                
                Section("Duration") {
                    Picker("Strategy", selection: $config.durationStrategy) {
                        Text("Script-Based").tag(UserControlConfig.DurationStrategy.scriptBased)
                        Text("Fixed Duration").tag(UserControlConfig.DurationStrategy.fixed)
                        Text("Custom").tag(UserControlConfig.DurationStrategy.custom)
                    }
                    
                    if case .fixed = config.durationStrategy {
                        Stepper("Duration: \(config.fixedDurationSeconds)s", 
                               value: $config.fixedDurationSeconds, 
                               in: 1...60)
                    }
                }
                
                Section("Limits") {
                    Toggle("Limit Shot Count", isOn: Binding(
                        get: { config.maxShots != nil },
                        set: { enabled in
                            config.maxShots = enabled ? 10 : nil
                        }
                    ))
                    
                    if config.maxShots != nil {
                        Stepper("Max Shots: \(config.maxShots!)", 
                               value: Binding(
                                get: { config.maxShots ?? 10 },
                                set: { config.maxShots = $0 }
                               ), 
                               in: 1...100)
                    }
                    
                    Toggle("Limit Total Duration", isOn: Binding(
                        get: { config.maxTotalDuration != nil },
                        set: { enabled in
                            config.maxTotalDuration = enabled ? 60 : nil
                        }
                    ))
                    
                    if config.maxTotalDuration != nil {
                        Stepper("Max Duration: \(config.maxTotalDuration!)s", 
                               value: Binding(
                                get: { config.maxTotalDuration ?? 60 },
                                set: { config.maxTotalDuration = $0 }
                               ), 
                               in: 10...600, 
                               step: 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shot Duration Range")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Min:")
                            Stepper("\(config.minShotDuration)s", 
                                   value: $config.minShotDuration, 
                                   in: 1...30)
                        }
                        
                        HStack {
                            Text("Max:")
                            Stepper("\(config.maxShotDuration)s", 
                                   value: $config.maxShotDuration, 
                                   in: 1...60)
                        }
                    }
                }
                
                Section("Review Gates") {
                    Toggle("Require Shot List Approval", isOn: $config.requireShotListApproval)
                    Toggle("Require Prompt Review", isOn: $config.requirePromptReview)
                    Toggle("Allow Edits Before Generation", isOn: $config.allowEditBeforeGeneration)
                }
                
                Section("Budget") {
                    Toggle("Set Budget Limit", isOn: Binding(
                        get: { config.maxCostPerProject != nil },
                        set: { enabled in
                            config.maxCostPerProject = enabled ? 100 : nil
                        }
                    ))
                    
                    if config.maxCostPerProject != nil {
                        HStack {
                            Text("Max Cost:")
                            TextField("", value: Binding(
                                get: { config.maxCostPerProject ?? 100 },
                                set: { config.maxCostPerProject = $0 }
                            ), format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                        }
                    }
                    
                    HStack {
                        Text("Cost per second:")
                        TextField("", value: $config.estimatedCostPerSecond, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Presets") {
                    VStack(spacing: 12) {
                        Button("Quick Process") {
                            config = UserControlConfig(
                                generationMode: .automatic,
                                segmentationStrategy: .manual,
                                manualShotCount: 3,
                                requireShotListApproval: false
                            )
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Budget Conscious") {
                            config = UserControlConfig(
                                generationMode: .semiAutomatic,
                                segmentationStrategy: .automatic,
                                maxShots: 20,
                                maxTotalDuration: 120,
                                maxCostPerProject: 500,
                                estimatedCostPerSecond: 2.5,
                                requireShotListApproval: true
                            )
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Fixed Count (Current)") {
                            config = UserControlConfig(
                                generationMode: .automatic,
                                segmentationStrategy: .manual,
                                manualShotCount: 5,
                                durationStrategy: .fixed,
                                fixedDurationSeconds: 4,
                                requireShotListApproval: false
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Pipeline Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var modeDescription: String {
        switch config.generationMode {
        case .automatic:
            return "AI makes all decisions automatically"
        case .semiAutomatic:
            return "AI suggests, you approve before generation"
        case .manual:
            return "You control every aspect"
        }
    }
}

#Preview {
    PipelineSettingsView(config: .constant(UserControlConfig()))
}
