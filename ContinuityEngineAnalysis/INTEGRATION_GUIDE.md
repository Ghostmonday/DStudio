# Continuity Engine Integration Guide

## 🚀 Quick Start

### **Basic Integration**
```swift
import Foundation
import SwiftUI

// Initialize the continuity engine
let continuityEngine = ContinuityEngine(context: managedObjectContext)
let anchorModule = ContinuityAnchorModule(service: DeepSeekService())

// Generate continuity anchors
await anchorModule.generateAnchors(story: storyText)

// Validate scene
let validationResult = continuityEngine.validate(sceneModel)

// Enhance prompt
let enhancedPrompt = continuityEngine.enhancePrompt(for: sceneModel)
```

## 🔧 Configuration

### **Service Configuration**
```swift
// Custom AI service
let customService = YourAIService()
let anchorModule = ContinuityAnchorModule(service: customService)

// Default DeepSeek service
let anchorModule = ContinuityAnchorModule() // Uses DeepSeekService()
```

### **Engine Configuration**
```swift
// With CoreData context
let context = persistentContainer.viewContext
let engine = ContinuityEngine(context: context)

// Debug mode (bypasses heavy validation)
// Set bypassValidation = true in ContinuityEngine.swift
```

## 📊 Usage Patterns

### **1. Character Continuity Extraction**

#### **Basic Usage**
```swift
let anchorModule = ContinuityAnchorModule()

// Generate anchors from story
await anchorModule.generateAnchors(story: storyText)

// Access results
let anchors = anchorModule.anchors
for anchor in anchors {
    print("Character: \(anchor.characterName)")
    print("Description: \(anchor.visualDescription)")
    print("Costumes: \(anchor.costumes)")
    print("Props: \(anchor.props)")
    print("Scenes: \(anchor.sceneReferences)")
}
```

#### **Error Handling**
```swift
await anchorModule.generateAnchors(story: storyText)

if let error = anchorModule.errorMessage {
    print("Error: \(error)")
} else {
    print("Success: \(anchorModule.anchors.count) anchors generated")
}
```

### **2. Scene Validation**

#### **Basic Validation**
```swift
let engine = ContinuityEngine(context: context)

// Validate a scene
let result = engine.validate(sceneModel)

// Check validation result
if result["ok"] as? Bool == true {
    print("Scene validated successfully")
} else {
    print("Validation issues detected")
    let issues = result["issues"] as? [String] ?? []
    for issue in issues {
        print("- \(issue)")
    }
}
```

#### **Confidence Scoring**
```swift
let result = engine.validate(sceneModel)
let confidence = result["confidence"] as? Double ?? 0.0

if confidence < 0.6 {
    print("⚠️ Low confidence: \(confidence)")
    print("Consider human review")
} else {
    print("✅ High confidence: \(confidence)")
}
```

### **3. Prompt Enhancement**

#### **Automatic Enhancement**
```swift
let engine = ContinuityEngine(context: context)

// Enhance prompt based on telemetry
let enhancedPrompt = engine.enhancePrompt(for: sceneModel)

print("Original: \(sceneModel.prompt)")
print("Enhanced: \(enhancedPrompt)")
```

#### **Telemetry Integration**
```swift
// Update telemetry when element appears/disappears
engine.updateTelemetry(word: "red car", appeared: true)
engine.updateTelemetry(word: "blue hat", appeared: false)

// Check manifestation rate
let rate = engine.manifestationRate(for: "red car")
print("Red car success rate: \(rate)")
```

## 🎯 Advanced Usage

### **Custom Validation Rules**

#### **Extending Validation**
```swift
extension ContinuityEngine {
    func customValidate(_ scene: SceneModel) -> [String: Any] {
        var result = validate(scene)
        
        // Add custom validation logic
        if scene.characters.count > 10 {
            result["custom_warning"] = "Too many characters in scene"
        }
        
        return result
    }
}
```

#### **Custom Enhancement**
```swift
extension ContinuityEngine {
    func customEnhancePrompt(for scene: SceneModel) -> String {
        var prompt = enhancePrompt(for: scene)
        
        // Add custom enhancements
        if scene.tone == "dramatic" {
            prompt += ", DRAMATIC LIGHTING"
        }
        
        return prompt
    }
}
```

### **Batch Processing**

#### **Multiple Scenes**
```swift
let engine = ContinuityEngine(context: context)
var results: [[String: Any]] = []

for scene in scenes {
    let result = engine.validate(scene)
    results.append(result)
}

// Analyze batch results
let totalConfidence = results.compactMap { $0["confidence"] as? Double }.reduce(0, +)
let averageConfidence = totalConfidence / Double(results.count)
```

#### **Anchor Generation for Multiple Stories**
```swift
let anchorModule = ContinuityAnchorModule()
var allAnchors: [ContinuityAnchor] = []

for story in stories {
    await anchorModule.generateAnchors(story: story)
    allAnchors.append(contentsOf: anchorModule.anchors)
}

// Process all anchors
let uniqueCharacters = Set(allAnchors.map { $0.characterName })
```

## 🔄 State Management

### **Persistent State**

#### **Scene State Persistence**
```swift
let engine = ContinuityEngine(context: context)

// State is automatically persisted
let result = engine.validate(scene1)
let result2 = engine.validate(scene2) // Uses scene1 as previous state
```

#### **Telemetry Persistence**
```swift
// Telemetry is automatically persisted
engine.updateTelemetry(word: "prop", appeared: true)

// Restart app - telemetry persists
let rate = engine.manifestationRate(for: "prop") // Still available
```

### **State Reset**
```swift
// Reset engine state
engine.state = nil
engine.issuesLog = []
engine.manifestationScores = [:]

// Reset anchor module
anchorModule.anchors = []
anchorModule.errorMessage = nil
```

## 📊 Reporting and Analytics

### **Validation Reports**
```swift
let engine = ContinuityEngine(context: context)

// Get comprehensive report
let report = engine.report()

print("Total conflicts: \(report["total_conflicts"] ?? 0)")
print("Conflicts: \(report["conflicts"] ?? [])")
print("Manifestation data: \(report["manifestation_data"] ?? [:])")
```

### **Quality Metrics**
```swift
// Calculate quality metrics
let results = scenes.map { engine.validate($0) }
let confidences = results.compactMap { $0["confidence"] as? Double }
let averageConfidence = confidences.reduce(0, +) / Double(confidences.count)

print("Average confidence: \(averageConfidence)")
print("Scenes needing review: \(confidences.filter { $0 < 0.6 }.count)")
```

## 🛠️ Debugging and Testing

### **Debug Mode**
```swift
// Enable debug mode in ContinuityEngine.swift
private let bypassValidation: Bool = true

// This bypasses:
// - NaturalLanguage processing
// - Heavy CoreData operations
// - Complex validation rules
```

### **Testing Individual Components**
```swift
// Test anchor generation
let anchorModule = ContinuityAnchorModule()
await anchorModule.generateAnchors(story: testStory)
XCTAssertFalse(anchorModule.anchors.isEmpty)

// Test validation
let engine = ContinuityEngine(context: testContext)
let result = engine.validate(testScene)
XCTAssertTrue(result["ok"] as? Bool == true)
```

### **Performance Testing**
```swift
// Measure validation performance
let startTime = Date()
let result = engine.validate(scene)
let duration = Date().timeIntervalSince(startTime)
print("Validation took: \(duration * 1000)ms")
```

## 🔌 SwiftUI Integration

### **Reactive UI**
```swift
struct ContinuityView: View {
    @StateObject private var anchorModule = ContinuityAnchorModule()
    @StateObject private var engine = ContinuityEngine(context: context)
    
    var body: some View {
        VStack {
            if anchorModule.isProcessing {
                ProgressView("Generating anchors...")
            } else {
                ForEach(anchorModule.anchors) { anchor in
                    AnchorCard(anchor: anchor)
                }
            }
            
            if let error = anchorModule.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
    }
}
```

### **Real-time Updates**
```swift
struct SceneValidationView: View {
    @StateObject private var engine = ContinuityEngine(context: context)
    @State private var scene: SceneModel
    
    var body: some View {
        VStack {
            Text("Confidence: \(engine.state?.id == scene.id ? "Validated" : "Pending")")
            
            if !engine.issuesLog.isEmpty {
                List(engine.issuesLog, id: \.self) { issue in
                    Text(issue["issues"] as? String ?? "")
                }
            }
        }
        .onAppear {
            let result = engine.validate(scene)
            // UI automatically updates via @Published properties
        }
    }
}
```

## 🚨 Error Handling

### **Common Error Scenarios**

#### **AI Service Errors**
```swift
await anchorModule.generateAnchors(story: story)

if let error = anchorModule.errorMessage {
    switch error {
    case "Network error":
        // Handle network issues
        break
    case "Invalid JSON":
        // Handle malformed AI response
        break
    case "Rate limit exceeded":
        // Handle rate limiting
        break
    default:
        // Handle other errors
        break
    }
}
```

#### **Validation Errors**
```swift
let result = engine.validate(scene)

if result["ok"] as? Bool == false {
    let issues = result["issues"] as? [String] ?? []
    let confidence = result["confidence"] as? Double ?? 0.0
    
    if confidence < 0.3 {
        // Critical issues - stop processing
        print("Critical validation failure")
    } else if confidence < 0.6 {
        // Warning - continue with caution
        print("Validation warnings detected")
    }
}
```

### **Recovery Strategies**
```swift
// Retry with exponential backoff
func retryAnchorGeneration(story: String, maxRetries: Int = 3) async {
    for attempt in 1...maxRetries {
        await anchorModule.generateAnchors(story: story)
        
        if anchorModule.errorMessage == nil {
            break // Success
        }
        
        if attempt < maxRetries {
            let delay = pow(2.0, Double(attempt)) // Exponential backoff
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}
```

## 📈 Performance Optimization

### **Memory Management**
```swift
// Limit telemetry storage
if engine.manifestationScores.count > 1000 {
    // Remove oldest entries
    let sortedKeys = engine.manifestationScores.keys.sorted()
    for key in sortedKeys.prefix(500) {
        engine.manifestationScores.removeValue(forKey: key)
    }
}
```

### **Batch Operations**
```swift
// Process multiple scenes efficiently
let results = await withTaskGroup(of: [String: Any].self) { group in
    for scene in scenes {
        group.addTask {
            return engine.validate(scene)
        }
    }
    
    var results: [[String: Any]] = []
    for await result in group {
        results.append(result)
    }
    return results
}
```

## 🔒 Security Considerations

### **API Key Management**
```swift
// Use secure API key storage
let service = DeepSeekService(apiKey: KeychainService.shared.getAPIKey())
let anchorModule = ContinuityAnchorModule(service: service)
```

### **Data Privacy**
```swift
// Clear sensitive data
func clearSensitiveData() {
    engine.issuesLog = []
    engine.manifestationScores = [:]
    anchorModule.anchors = []
}
```
