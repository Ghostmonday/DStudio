//
//  SceneControlSheet.swift
//  DirectorStudio
//
//  Premium Scene Control Settings Sheet
//  Responsive for iPad and iPhone
//

import SwiftUI

// MARK: - Scene Control Configuration Model

struct SceneControlConfig {
    var automaticMode: Bool = true
    var targetSceneCount: Int = 5
    var targetDurationPerScene: Double = 4.0
    var maxBudget: Int? = nil
    
    var estimatedTotalDuration: Double {
        Double(targetSceneCount) * targetDurationPerScene
    }
    
    var estimatedCost: Int {
        let costPerSecond = 2.5
        return Int(estimatedTotalDuration * costPerSecond)
    }
}

// MARK: - Main Scene Control Sheet

struct SceneControlSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Binding var config: SceneControlConfig
    @State private var showBudgetField: Bool = false
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .padding(.horizontal, isIPad ? 32 : 20)
                        .padding(.top, isIPad ? 32 : 20)
                        .padding(.bottom, 24)
                    
                    // Main Content
                    VStack(spacing: isIPad ? 28 : 24) {
                        automaticModeSection
                        
                        if !config.automaticMode {
                            manualControlsSection
                        }
                        
                        budgetSection
                        
                        estimationSection
                    }
                    .padding(.horizontal, isIPad ? 32 : 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: isIPad ? 48 : 40, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Scene Control")
                .font(.system(size: isIPad ? 34 : 28, weight: .bold, design: .rounded))
            
            Text("Configure how your script is segmented into video scenes")
                .font(.system(size: isIPad ? 17 : 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Automatic Mode Section
    
    private var automaticModeSection: some View {
        ControlCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(config.automaticMode ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: config.automaticMode ? "sparkles" : "sparkles")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(config.automaticMode ? .accentColor : .secondary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Auto Scene Detection")
                                .font(.system(size: isIPad ? 19 : 17, weight: .semibold))
                            
                            Spacer()
                            
                            Toggle("", isOn: $config.automaticMode)
                                .labelsHidden()
                        }
                        
                        Text("DirectorStudio analyzes your script and determines the optimal number of scenes needed to tell your story.")
                            .font(.system(size: isIPad ? 15 : 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if config.automaticMode {
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Intelligent Segmentation")
                                .font(.system(size: isIPad ? 14 : 13, weight: .medium))
                            
                            Text("Based on scene headings, story beats, and pacing")
                                .font(.system(size: isIPad ? 13 : 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(isIPad ? 24 : 20)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: config.automaticMode)
    }
    
    // MARK: - Manual Controls Section
    
    private var manualControlsSection: some View {
        VStack(spacing: isIPad ? 20 : 16) {
            // Scene Count Control
            ControlCard {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Scene Count")
                                .font(.system(size: isIPad ? 17 : 16, weight: .semibold))
                            
                            Text("How many video scenes to generate")
                                .font(.system(size: isIPad ? 14 : 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: isIPad ? 24 : 16) {
                        // Stepper controls
                        Button {
                            if config.targetSceneCount > 1 {
                                config.targetSceneCount -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: isIPad ? 32 : 28))
                                .foregroundColor(config.targetSceneCount > 1 ? .accentColor : .secondary.opacity(0.3))
                        }
                        .disabled(config.targetSceneCount <= 1)
                        
                        // Center display
                        VStack(spacing: 4) {
                            Text("\(config.targetSceneCount)")
                                .font(.system(size: isIPad ? 52 : 44, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            
                            Text(config.targetSceneCount == 1 ? "scene" : "scenes")
                                .font(.system(size: isIPad ? 15 : 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                        .frame(minWidth: isIPad ? 140 : 100)
                        
                        Button {
                            if config.targetSceneCount < 30 {
                                config.targetSceneCount += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: isIPad ? 32 : 28))
                                .foregroundColor(config.targetSceneCount < 30 ? .accentColor : .secondary.opacity(0.3))
                        }
                        .disabled(config.targetSceneCount >= 30)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Range indicator
                    HStack {
                        Text("1")
                            .font(.system(size: isIPad ? 13 : 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 1)
                        
                        Text("30")
                            .font(.system(size: isIPad ? 13 : 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(isIPad ? 24 : 20)
            }
            
            // Duration Slider Control
            ControlCard {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Duration per Scene")
                            .font(.system(size: isIPad ? 17 : 16, weight: .semibold))
                        
                        Text("Length of each generated video scene")
                            .font(.system(size: isIPad ? 14 : 13))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        // Current value display
                        HStack {
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", config.targetDurationPerScene))
                                    .font(.system(size: isIPad ? 36 : 32, weight: .semibold, design: .rounded))
                                    .contentTransition(.numericText())
                                
                                Text("sec")
                                    .font(.system(size: isIPad ? 16 : 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Slider
                        VStack(spacing: 8) {
                            Slider(
                                value: $config.targetDurationPerScene,
                                in: 2...20,
                                step: 0.5
                            )
                            .tint(.accentColor)
                            
                            // Range labels
                            HStack {
                                Text("2s")
                                    .font(.system(size: isIPad ? 13 : 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Quick")
                                    .font(.system(size: isIPad ? 12 : 11))
                                    .foregroundColor(.secondary.opacity(0.8))
                                
                                Spacer()
                                
                                Text("Standard")
                                    .font(.system(size: isIPad ? 12 : 11))
                                    .foregroundColor(.secondary.opacity(0.8))
                                
                                Spacer()
                                
                                Text("Cinematic")
                                    .font(.system(size: isIPad ? 12 : 11))
                                    .foregroundColor(.secondary.opacity(0.8))
                                
                                Spacer()
                                
                                Text("20s")
                                    .font(.system(size: isIPad ? 13 : 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(isIPad ? 24 : 20)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Budget Section
    
    private var budgetSection: some View {
        ControlCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(showBudgetField ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(showBudgetField ? .orange : .secondary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Budget Limit")
                                .font(.system(size: isIPad ? 19 : 17, weight: .semibold))
                            
                            Spacer()
                            
                            Toggle("", isOn: $showBudgetField)
                                .labelsHidden()
                        }
                        
                        Text("Set a maximum number of credits the system can use for this script.")
                            .font(.system(size: isIPad ? 15 : 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if showBudgetField {
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                        
                        TextField("e.g., 500", value: $config.maxBudget, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: isIPad ? 16 : 15, weight: .medium, design: .rounded))
                        
                        Text("credits")
                            .font(.system(size: isIPad ? 15 : 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(isIPad ? 24 : 20)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showBudgetField)
    }
    
    // MARK: - Estimation Section
    
    private var estimationSection: some View {
        VStack(spacing: 12) {
            Text("ESTIMATED OUTPUT")
                .font(.system(size: isIPad ? 13 : 12, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ControlCard {
                HStack(spacing: isIPad ? 24 : 16) {
                    // Total Duration
                    EstimationItem(
                        icon: "clock.fill",
                        value: formatDuration(config.estimatedTotalDuration),
                        label: "Total Duration",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 50)
                    
                    // Estimated Cost
                    EstimationItem(
                        icon: "sparkles",
                        value: "\(config.estimatedCost)",
                        label: "Est. Credits",
                        color: .purple
                    )
                }
                .padding(isIPad ? 24 : 20)
            }
            
            if !config.automaticMode {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    
                    Text("Actual cost may vary based on video quality and duration")
                        .font(.system(size: isIPad ? 13 : 12))
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Supporting Views

struct ControlCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

struct EstimationItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 24 : 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: isIPad ? 28 : 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: isIPad ? 13 : 12, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("iPhone") {
    SceneControlSheet(config: .constant(SceneControlConfig()))
}

#Preview("iPad") {
    SceneControlSheet(config: .constant(SceneControlConfig()))
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
}

#Preview("Manual Mode") {
    SceneControlSheet(config: .constant(SceneControlConfig(automaticMode: false)))
}

#Preview("With Budget") {
    SceneControlSheet(config: .constant(SceneControlConfig(automaticMode: false, maxBudget: 500)))
}
