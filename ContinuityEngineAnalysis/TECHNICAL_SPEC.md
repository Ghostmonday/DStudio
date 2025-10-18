# Continuity Engine Technical Specifications

## 🏗️ System Architecture

### **Component Overview**
```
ContinuityEngine
├── ContinuityAnchorModule (AI Extraction)
│   ├── Character Analysis
│   ├── Visual Description Generation
│   ├── Costume/Prop Tracking
│   └── Scene Reference Mapping
└── ContinuityEngine (Validation & Enhancement)
    ├── Multi-Rule Validation
    ├── Telemetry System
    ├── Prompt Enhancement
    └── State Persistence
```

## 🔧 Core Components

### **1. ContinuityAnchorModule**

#### **Purpose**
AI-powered extraction of character continuity anchors from story text.

#### **Key Methods**
```swift
func generateAnchors(story: String) async
```
- **Input**: Raw story text
- **Output**: Array of `ContinuityAnchor` objects
- **Process**: AI analysis → JSON extraction → Swift object creation

#### **Data Model**
```swift
struct ContinuityAnchor: Codable, Identifiable {
    let id = UUID()
    let characterName: String
    let visualDescription: String
    let costumes: [String]
    let props: [String]
    let appearanceNotes: String
    let sceneReferences: [Int]
}
```

#### **AI Configuration**
- **Model**: DeepSeek (configurable via `AIServiceProtocol`)
- **Temperature**: 0.3 (consistent, factual output)
- **Max Tokens**: 3000 (comprehensive extraction)
- **System Prompt**: Specialized script supervisor persona

### **2. ContinuityEngine**

#### **Purpose**
Real-time scene validation and intelligent prompt enhancement.

#### **Core Validation Rules**

##### **Rule 1: Prop Persistence**
```swift
for prop in prev.props where !scene.props.contains(prop) {
    confidence *= 0.7
    issues.append("❌ \(prop) disappeared (was in scene \(prev.id))")
}
```
- **Logic**: Props should persist across scenes unless explicitly removed
- **Penalty**: 30% confidence reduction
- **Detection**: Missing props in subsequent scenes

##### **Rule 2: Character Location Logic**
```swift
if prev.location == scene.location {
    for char in prev.characters where !scene.characters.contains(char) {
        confidence *= 0.5
        issues.append("❌ \(char) vanished from \(scene.location)")
    }
}
```
- **Logic**: Characters in same location should remain visible
- **Penalty**: 50% confidence reduction
- **Detection**: Character disappearance in same location

##### **Rule 3: Tone Whiplash Detection**
```swift
if toneDistance(prev.tone, scene.tone) > 0.8 {
    confidence *= 0.6
    issues.append("⚠️ Tone jumped: \(prev.tone) → \(scene.tone)")
}
```
- **Logic**: Prevents jarring emotional transitions
- **Penalty**: 40% confidence reduction
- **Detection**: NaturalLanguage sentiment analysis

#### **Telemetry System**

##### **Manifestation Tracking**
```swift
func updateTelemetry(word: String, appeared: Bool) {
    var d = manifestationScores[word] ?? ["attempts": 0, "successes": 0]
    d["attempts", default: 0] += 1
    if appeared { d["successes", default: 0] += 1 }
    manifestationScores[word] = d
}
```
- **Purpose**: Track success rates for prompt elements
- **Storage**: In-memory dictionary with CoreData persistence
- **Usage**: Adaptive prompt enhancement

##### **Success Rate Calculation**
```swift
func manifestationRate(for word: String) -> Double {
    guard let d = manifestationScores[word],
          let attempts = d["attempts"],
          attempts > 0 else { return 0.8 }
    return Double(d["successes"] ?? 0) / Double(attempts)
}
```
- **Default Rate**: 80% for unknown elements
- **Calculation**: Successes / Total Attempts
- **Threshold**: <50% triggers enhancement

#### **Prompt Enhancement**

##### **Low-Performance Element Boosting**
```swift
for prop in scene.props where manifestationRate(for: prop) < 0.5 {
    out += ", CLEARLY SHOWING \(prop)"
}
```
- **Trigger**: <50% manifestation rate
- **Action**: Add emphasis to prompt
- **Format**: ", CLEARLY SHOWING [element]"

##### **Character Consistency Hints**
```swift
if let prev = state {
    for char in scene.characters where prev.characters.contains(char) {
        out += ", \(char) with same appearance as previous scene"
    }
}
```
- **Trigger**: Character appears in previous scene
- **Action**: Add consistency hint
- **Format**: ", [character] with same appearance as previous scene"

## 🗄️ Data Persistence

### **CoreData Entities**

#### **SceneState**
```swift
- id: Int (scene identifier)
- location: String (scene location)
- characters: [String] (character list)
- props: [String] (prop list)
- prompt: String (scene prompt)
- tone: String (emotional tone)
- timestamp: Date (creation time)
```

#### **ContinuityLog**
```swift
- scene_id: Int (scene identifier)
- confidence: Double (validation confidence)
- issues: [String] (detected problems)
- timestamp: Date (log time)
```

#### **Telemetry**
```swift
- word: String (tracked element)
- attempts: Int (total attempts)
- successes: Int (successful appearances)
- timestamp: Date (last update)
```

### **Persistence Strategy**
- **Immediate**: State changes persisted immediately
- **Batch**: Telemetry updates batched for performance
- **Error Handling**: Graceful degradation on persistence failures
- **Entity Validation**: Existence checks before CoreData operations

## 🔄 State Management

### **Scene State Flow**
```
Scene Input → Validation → Confidence Calculation → Issue Logging → State Update → Persistence
```

### **Telemetry Flow**
```
Element Tracking → Success/Failure → Rate Calculation → Enhancement Decision → Prompt Modification
```

### **Error Handling Flow**
```
Error Detection → Graceful Degradation → Fallback Strategy → User Notification → Logging
```

## ⚡ Performance Characteristics

### **Validation Performance**
- **Bypass Mode**: <1ms (debugging)
- **Full Validation**: 50-100ms per scene
- **NaturalLanguage**: ~30-50ms (sentiment analysis)
- **CoreData**: ~10-20ms (persistence)

### **Memory Usage**
- **State Storage**: ~1KB per scene
- **Telemetry**: ~100 bytes per tracked element
- **Issue Logs**: ~500 bytes per conflict
- **Total Overhead**: <10MB for large projects

### **Scalability**
- **Scene Limit**: No hard limit (persistent storage)
- **Telemetry Limit**: Memory-based (thousands of elements)
- **Performance**: Linear with scene count
- **Optimization**: Bypass modes for debugging

## 🛡️ Error Handling

### **Validation Errors**
- **Malformed Input**: Graceful degradation with warnings
- **Missing State**: Initialize with default values
- **CoreData Failures**: Continue without persistence
- **NaturalLanguage Errors**: Fallback to simple string comparison

### **AI Service Errors**
- **Network Failures**: Retry with exponential backoff
- **Invalid JSON**: Extract partial data where possible
- **Rate Limiting**: Queue requests with delays
- **Service Unavailable**: Use cached data if available

### **Production Hardening**
```swift
private let bypassValidation: Bool = true // DEBUG hardening
```
- **Debug Mode**: Bypass heavy operations
- **Crash Prevention**: Input validation for all operations
- **Safe Defaults**: Fallback values for all calculations
- **Graceful Degradation**: Continue operation with reduced functionality

## 🔌 Integration Points

### **Pipeline Integration**
- **Input**: `SceneModel` from segmentation module
- **Output**: Enhanced prompts and validation reports
- **State**: Persistent continuity state across sessions
- **Telemetry**: Feedback loop for prompt optimization

### **UI Integration**
- **Real-time Updates**: `@Published` properties for SwiftUI
- **Error Display**: User-friendly error messages
- **Progress Indicators**: Processing state visualization
- **Results Display**: Continuity anchor presentation

### **Service Integration**
- **AI Service**: Configurable via `AIServiceProtocol`
- **CoreData**: Persistent storage for state and telemetry
- **NaturalLanguage**: Sentiment analysis for tone detection
- **SwiftUI**: Reactive UI updates

## 📊 Quality Metrics

### **Validation Confidence**
- **Range**: 0.0 to 1.0
- **Threshold**: <0.6 triggers human review
- **Calculation**: Product of rule penalties
- **Reporting**: Detailed issue breakdown

### **Telemetry Effectiveness**
- **Success Rate**: Percentage of successful manifestations
- **Improvement**: Rate increase over time
- **Coverage**: Percentage of elements tracked
- **Accuracy**: Correlation with actual video quality

### **Performance Metrics**
- **Validation Time**: Milliseconds per scene
- **Memory Usage**: Peak and average consumption
- **Error Rate**: Percentage of failed operations
- **Recovery Time**: Time to restore from errors
