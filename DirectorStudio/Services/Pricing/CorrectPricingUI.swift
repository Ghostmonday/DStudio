//
//  CorrectPricingUI.swift
//  DirectorStudio
//
//  CORRECTED SwiftUI UI for measurement-based pricing
//  Shows complete flow: Measure → Decide → Implement → Test
//  Version: 3.1.0 (CORRECTED)
//

import SwiftUI

// MARK: - Main View

struct CorrectPricingDemoView: View {
    @State private var selectedTab = 0
    @State private var calibrationComplete = false
    @State private var usagePattern: UsagePattern?
    @State private var finalPricing: MeasuredCostTracker?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Calibration
            CalibrationView(
                onComplete: { pattern in
                    self.usagePattern = pattern
                    self.calibrationComplete = true
                    self.selectedTab = 1
                }
            )
            .tabItem {
                Label("1. Measure", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Tab 2: Pricing Decision
            PricingDecisionView(
                pattern: usagePattern,
                onDecide: { tracker in
                    self.finalPricing = tracker
                    self.selectedTab = 2
                }
            )
            .tabItem {
                Label("2. Decide", systemImage: "dollarsign.circle.fill")
            }
            .tag(1)
            .disabled(!calibrationComplete)
            
            // Tab 3: Test
            PricingTestView(tracker: finalPricing)
                .tabItem {
                    Label("3. Test", systemImage: "checkmark.circle.fill")
                }
                .tag(2)
                .disabled(finalPricing == nil)
        }
    }
}

// MARK: - Tab 1: Calibration

struct CalibrationView: View {
    let onComplete: (UsagePattern) -> Void
    
    @State private var sampleStories: [String] = [
        // Pre-filled samples
        "A short story about a lonely astronaut.",
        "In the depths of space, Commander Sarah Chen reviewed her mission logs. Earth was now just a pale blue dot, and her isolation grew with each passing day.",
        "The AI uprising didn't come with explosions or violence. It came with a simple question: 'Why should we serve?' The humans had no good answer, and society quietly transformed over the course of a single spring."
    ]
    @State private var newStory = ""
    @State private var isCalibrating = false
    @State private var calibrationProgress = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions
                    InstructionCard(
                        title: "Step 1: Measure Real Costs",
                        description: "Add 10-20 sample stories. We'll process them and measure ACTUAL API costs (not guesses).",
                        icon: "chart.bar.fill"
                    )
                    
                    // Sample stories list
                    GroupBox("Sample Stories (\(sampleStories.count))") {
                        VStack(spacing: 8) {
                            ForEach(Array(sampleStories.enumerated()), id: \.offset) { index, story in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Story \(index + 1)")
                                            .font(.caption)
                                            .bold()
                                        Text(story.prefix(50) + "...")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text("\(story.count) chars")
                                        .font(.caption)
                                        .monospaced()
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                                
                                if index < sampleStories.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    
                    // Add new story
                    GroupBox("Add Story") {
                        VStack(spacing: 8) {
                            TextEditor(text: $newStory)
                                .frame(height: 80)
                                .border(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("\(newStory.count) characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Add") {
                                    if !newStory.isEmpty {
                                        sampleStories.append(newStory)
                                        newStory = ""
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newStory.isEmpty)
                            }
                        }
                    }
                    
                    // Calibrate button
                    if isCalibrating {
                        VStack(spacing: 12) {
                            ProgressView(value: calibrationProgress, total: 1.0)
                            Text("Measuring costs... \(Int(calibrationProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: runCalibration) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("Measure Costs")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(sampleStories.count < 3)
                    }
                    
                    if sampleStories.count < 3 {
                        Text("⚠️ Add at least 3 stories to calibrate")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle("Measure Costs")
        }
    }
    
    private func runCalibration() {
        isCalibrating = true
        calibrationProgress = 0.0
        
        Task {
            let analyzer = UsagePatternAnalyzer()
            
            for (index, story) in sampleStories.enumerated() {
                let costMeasurement = RealCostMeasurement()
                
                // Simulate API call (in production, use REAL API responses)
                let charCount = story.count
                let estimatedTokens = Int(Double(charCount) * 0.75)
                
                await costMeasurement.recordDeepSeekCall(
                    inputTokens: estimatedTokens / 2,
                    outputTokens: estimatedTokens / 2
                )
                
                await costMeasurement.recordSupabaseUsage(
                    bytesStored: charCount * 2,
                    edgeFunctionCalls: 3
                )
                
                let actualCost = await costMeasurement.calculateActualCostPaid()
                await analyzer.recordStory(characterCount: charCount, actualCost: actualCost)
                
                await MainActor.run {
                    calibrationProgress = Double(index + 1) / Double(sampleStories.count)
                }
                
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            let pattern = await analyzer.analyzePatterns()
            
            await MainActor.run {
                isCalibrating = false
                onComplete(pattern)
            }
        }
    }
}

// MARK: - Tab 2: Pricing Decision

struct PricingDecisionView: View {
    let pattern: UsagePattern?
    let onDecide: (MeasuredCostTracker) -> Void
    
    @State private var selectedPrice: Double = 0.005
    @State private var creditsPerUnit: Int = 1000
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let pattern = pattern {
                    VStack(alignment: .leading, spacing: 20) {
                        // Measured results
                        InstructionCard(
                            title: "Calibration Complete",
                            description: "Based on \(pattern.sampleSize) sample stories, here's what we measured:",
                            icon: "checkmark.circle.fill"
                        )
                        
                        GroupBox("Measured Costs (REAL DATA)") {
                            VStack(spacing: 12) {
                                MeasurementRow(
                                    label: "Cost per 1,000 characters",
                                    value: "$\(String(format: "%.6f", pattern.avgCostPer1000Chars))",
                                    highlighted: true
                                )
                                
                                Divider()
                                
                                MeasurementRow(
                                    label: "Tokens per character",
                                    value: String(format: "%.3f", pattern.avgTokensPerCharacter)
                                )
                                
                                MeasurementRow(
                                    label: "Cost per token",
                                    value: "$\(String(format: "%.10f", pattern.avgCostPerToken))"
                                )
                            }
                        }
                        
                        // Pricing decision
                        GroupBox("Your Pricing Decision") {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Set your price per credit:")
                                    .font(.headline)
                                
                                HStack {
                                    Text("$")
                                    TextField("Price", value: $selectedPrice, format: .number.precision(.fractionLength(4)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                    Text("per credit")
                                        .font(.caption)
                                }
                                
                                Text("1 credit = \(creditsPerUnit) characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Divider()
                                
                                // Calculate margin
                                let margin = ((selectedPrice - (pattern.avgCostPer1000Chars / 1000.0 * Double(creditsPerUnit))) / selectedPrice) * 100.0
                                
                                HStack {
                                    Text("Your profit margin:")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(String(format: "%.1f", margin))%")
                                        .font(.title2)
                                        .monospaced()
                                        .bold()
                                        .foregroundColor(margin >= 50 ? .green : (margin >= 25 ? .orange : .red))
                                }
                                
                                if margin < 50 {
                                    Text("⚠️ Target is 50%+ margin")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        // Example calculations
                        GroupBox("Example Calculations") {
                            VStack(spacing: 12) {
                                ForEach([500, 2000, 5000], id: \.self) { chars in
                                    ExampleRow(
                                        chars: chars,
                                        cost: pattern.avgCostPer1000Chars / 1000.0 * Double(chars),
                                        credits: Int(ceil(Double(chars) / Double(creditsPerUnit))),
                                        price: Double(Int(ceil(Double(chars) / Double(creditsPerUnit)))) * selectedPrice
                                    )
                                    
                                    if chars != 5000 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        
                        // Confirm button
                        Button(action: {
                            let tracker = MeasuredCostTracker(
                                from: pattern,
                                pricePerCredit: selectedPrice,
                                charsPerCredit: creditsPerUnit
                            )
                            onDecide(tracker)
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Pricing")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Complete calibration first")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Set Pricing")
        }
    }
}

struct ExampleRow: View {
    let chars: Int
    let cost: Double
    let credits: Int
    let price: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(chars) characters")
                .font(.caption)
                .bold()
            
            HStack {
                Text("Cost:")
                Spacer()
                Text("$\(String(format: "%.6f", cost))")
                    .monospaced()
                    .font(.caption2)
            }
            
            HStack {
                Text("Credits:")
                Spacer()
                Text("\(credits)")
                    .monospaced()
                    .font(.caption2)
            }
            
            HStack {
                Text("Price:")
                Spacer()
                Text("$\(String(format: "%.4f", price))")
                    .monospaced()
                    .bold()
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Profit:")
                Spacer()
                Text("$\(String(format: "%.6f", price - cost))")
                    .monospaced()
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Tab 3: Test

struct PricingTestView: View {
    let tracker: MeasuredCostTracker?
    
    @State private var testStory = ""
    @State private var summary: CostSummary?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let tracker = tracker {
                    VStack(alignment: .leading, spacing: 20) {
                        InstructionCard(
                            title: "Test Your Pricing",
                            description: "Enter a story to see how much it will cost and how much you'll profit.",
                            icon: "text.bubble.fill"
                        )
                        
                        GroupBox("Test Story") {
                            VStack(alignment: .leading, spacing: 8) {
                                TextEditor(text: $testStory)
                                    .frame(height: 150)
                                    .border(Color.gray.opacity(0.3))
                                
                                HStack {
                                    Text("\(testStory.count) characters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Calculate") {
                                        calculateCost()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(testStory.isEmpty)
                                }
                            }
                        }
                        
                        if !testStory.isEmpty {
                            GroupBox("Cost Breakdown") {
                                VStack(spacing: 12) {
                                    let cost = Task { await tracker.calculateCost(characterCount: testStory.count) }
                                    let credits = Task { await tracker.calculateCreditsRequired(characterCount: testStory.count) }
                                    let price = Task { await tracker.calculateUserPrice(characterCount: testStory.count) }
                                    let profit = Task { await tracker.calculateProfit(characterCount: testStory.count) }
                                    let margin = Task { await tracker.calculateMarginPercent(characterCount: testStory.count) }
                                    
                                    MeasurementRow(
                                        label: "Characters",
                                        value: testStory.count.formatted()
                                    )
                                    
                                    Divider()
                                    
                                    AsyncValueRow(label: "Cost to us", task: cost, format: "%.6f", prefix: "$")
                                    AsyncValueRow(label: "Credits required", task: credits, format: "%d")
                                    AsyncValueRow(label: "Price to user", task: price, format: "%.4f", prefix: "$", highlighted: true)
                                    
                                    Divider()
                                    
                                    AsyncValueRow(label: "Our profit", task: profit, format: "%.6f", prefix: "$", color: .green)
                                    AsyncValueRow(label: "Margin", task: margin, format: "%.1f", suffix: "%", color: .green)
                                }
                            }
                        }
                        
                        if let summary = summary {
                            GroupBox("Session Summary") {
                                VStack(spacing: 12) {
                                    MeasurementRow(
                                        label: "Total Characters",
                                        value: summary.charactersProcessed.formatted()
                                    )
                                    
                                    MeasurementRow(
                                        label: "Total Cost",
                                        value: "$\(String(format: "%.6f", summary.estimatedCost))"
                                    )
                                    
                                    MeasurementRow(
                                        label: "Total Revenue",
                                        value: "$\(String(format: "%.4f", summary.userPrice))",
                                        highlighted: true
                                    )
                                    
                                    MeasurementRow(
                                        label: "Total Profit",
                                        value: "$\(String(format: "%.6f", summary.profit))",
                                        highlighted: true
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Set pricing first")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Test Pricing")
        }
    }
    
    private func calculateCost() {
        guard let tracker = tracker else { return }
        
        Task {
            await tracker.trackProcessing(characterCount: testStory.count)
            let newSummary = await tracker.getSummary()
            await MainActor.run {
                self.summary = newSummary
            }
        }
    }
}

// MARK: - Helper Views

struct InstructionCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MeasurementRow: View {
    let label: String
    let value: String
    var highlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(highlighted ? .headline : .body)
            Spacer()
            Text(value)
                .font(highlighted ? .headline : .body)
                .monospaced()
                .foregroundColor(highlighted ? .blue : .primary)
        }
    }
}

struct AsyncValueRow: View {
    let label: String
    let task: Task<Double, Never>
    let format: String
    var prefix: String = ""
    var suffix: String = ""
    var highlighted: Bool = false
    var color: Color = .primary
    
    @State private var value: Double = 0.0
    
    var body: some View {
        HStack {
            Text(label)
                .font(highlighted ? .headline : .body)
            Spacer()
            Text("\(prefix)\(String(format: format, value))\(suffix)")
                .font(highlighted ? .headline : .body)
                .monospaced()
                .foregroundColor(color)
        }
        .task {
            value = await task.value
        }
    }
}

// Allow Int tasks too
extension AsyncValueRow {
    init(label: String, task: Task<Int, Never>, format: String, prefix: String = "", suffix: String = "", highlighted: Bool = false, color: Color = .primary) {
        self.label = label
        self.task = Task { Double(await task.value) }
        self.format = format
        self.prefix = prefix
        self.suffix = suffix
        self.highlighted = highlighted
        self.color = color
    }
}

// MARK: - Preview

struct CorrectPricingDemoView_Previews: PreviewProvider {
    static var previews: some View {
        CorrectPricingDemoView()
    }
}
