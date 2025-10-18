# Pipeline Technical Specification

## Architecture Overview

The DirectorStudio pipeline is a sequential processing system that transforms user stories into video-ready content through 6 distinct steps. Each step is modular, optional, and provides full transparency.

## Core Components

### 1. Pipeline Coordinator (`DirectorStudioPipeline.swift`)

**Purpose**: Orchestrates the entire pipeline execution
**Responsibilities**:
- Step sequencing and execution
- State management and progress tracking
- Error handling and recovery
- Module coordination

**Key Properties**:
```swift
@Published var currentStep: Int = 0
@Published var isRunning: Bool = false
@Published var completedSteps: Set<Int> = []
@Published var errorMessage: String?
```

**Key Methods**:
```swift
func runFullPipeline(story: String, rewordType: RewordingType?, projectTitle: String, enableTransform: Bool, enableCinematic: Bool, enableBreakdown: Bool) async
```

### 2. Individual Modules

#### RewordingModule
- **Input**: Raw story text
- **Process**: AI-powered text transformation
- **Output**: Enhanced story text
- **API**: DeepSeek with custom system prompts
- **Optional**: Yes

#### StoryAnalyzerModule
- **Input**: Story text
- **Process**: Extract structured data (characters, locations, scenes)
- **Output**: StoryAnalysis object
- **API**: DeepSeek with JSON extraction
- **Optional**: No (currently - needs to be made optional)

#### PromptSegmentationModule
- **Input**: Story text
- **Process**: Break into 15-second video segments
- **Output**: Array of PromptSegment objects
- **API**: DeepSeek with segmentation logic
- **Optional**: Yes

#### CinematicTaxonomyModule
- **Input**: Individual scene segments
- **Process**: Add cinematic details (camera angles, lighting)
- **Output**: CinematicTaxonomy objects
- **API**: DeepSeek per segment
- **Optional**: Yes

#### ContinuityAnchorModule
- **Input**: Story text
- **Process**: Generate visual continuity markers
- **Output**: Array of ContinuityAnchor objects
- **API**: DeepSeek with continuity analysis
- **Optional**: No (currently - needs to be made optional)

#### PromptPackagingModule
- **Input**: All previous outputs
- **Process**: Package into final format
- **Output**: Final packaged content
- **API**: Local processing
- **Optional**: No (final step)

## Data Models

### PromptSegment
```swift
struct PromptSegment: Identifiable, Codable {
    let id: UUID
    let content: String
    let duration: Int
    let order: Int
}
```

### CinematicTaxonomy
```swift
struct CinematicTaxonomy: Codable {
    let shotType: String
    let cameraAngle: String
    let framing: String
    let lighting: String
    let colorPalette: String
    let lensType: String
    let cameraMovement: String
    let emotionalTone: String
    let visualStyle: String
    let actionCues: [String]
}
```

### ContinuityAnchor
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

### StoryAnalysis
```swift
struct StoryAnalysis: Codable {
    let characters: [Character]
    let locations: [Location]
    let scenes: [Scene]
    let dialogueBlocks: [DialogueBlock]
}
```

## API Integration

### DeepSeek Service
- **Base URL**: Configured via SecretsManager
- **Authentication**: API key via x-api-key header
- **Rate Limiting**: Built-in retry logic
- **Error Handling**: Comprehensive error types

### Request Pattern
```swift
func sendRequest(
    systemPrompt: String,
    userPrompt: String,
    temperature: Double,
    maxTokens: Int?
) async throws -> String
```

## State Management

### Pipeline State
- **Current Step**: Tracks active step
- **Running Status**: Boolean for UI updates
- **Completed Steps**: Set of completed step numbers
- **Error Messages**: String for error display

### Module State
Each module maintains its own state:
- **Processing Status**: Boolean for loading states
- **Results**: Typed output data
- **Error Messages**: String for error display
- **Debug Information**: Additional context

## Error Handling

### Error Types
```swift
enum AIModuleError: Error, LocalizedError {
    case networkError(String)
    case apiError(String)
    case parsingError(String)
    case validationError(String)
}
```

### Error Recovery
- **Step Failures**: Continue to next step or abort based on configuration
- **API Failures**: Retry with exponential backoff
- **Validation Errors**: Provide user-friendly messages
- **Network Issues**: Graceful degradation

## Performance Considerations

### Async/Await
- All API calls are properly async
- UI updates happen on MainActor
- No blocking operations on main thread

### Memory Management
- Large inputs are processed in chunks
- Results are stored efficiently
- Memory is released after processing

### Caching
- API responses can be cached
- Intermediate results are stored
- Project data is persisted

## Security

### API Key Management
- Keys stored securely via SecretsManager
- No keys in source code
- Environment-based configuration

### Data Privacy
- User content is processed temporarily
- No persistent storage of user stories
- Secure API communication

## Testing Strategy

### Unit Tests
- Individual module functionality
- Error handling scenarios
- Data model validation
- API integration

### Integration Tests
- Full pipeline execution
- UI state management
- Project saving/loading
- Video generation flow

### Performance Tests
- Large input handling
- Memory usage monitoring
- API response times
- UI responsiveness

## Monitoring & Analytics

### Metrics to Track
- Pipeline execution time
- Step success/failure rates
- API response times
- User engagement

### Error Tracking
- Step failure reasons
- API error patterns
- User error reports
- Performance bottlenecks

## Future Enhancements

### Planned Features
1. **Individual Step Execution**: Run steps independently
2. **Step Result Visibility**: Show detailed outputs
3. **Advanced Error Recovery**: Smart retry logic
4. **Performance Optimization**: Caching and batching
5. **Custom Step Configuration**: User-defined parameters

### Scalability Considerations
- **Horizontal Scaling**: Multiple API endpoints
- **Load Balancing**: Distribute API calls
- **Caching Strategy**: Reduce API usage
- **Queue Management**: Handle high volume

## Dependencies

### External Libraries
- **SwiftUI**: UI framework
- **Foundation**: Core functionality
- **Combine**: Reactive programming
- **os.log**: Logging

### Internal Dependencies
- **SecretsManager**: API key management
- **AppState**: Global state management
- **CoreData**: Data persistence
- **KeychainService**: Secure storage

## Configuration

### Environment Variables
- `DEEPSEEK_API_KEY`: API authentication
- `API_BASE_URL`: Service endpoint
- `DEBUG_MODE`: Development flags

### Build Settings
- API key configuration
- Debug/Release modes
- Feature flags

## Deployment

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Network connectivity

### Build Process
1. Configure API keys
2. Set build settings
3. Run tests
4. Build and deploy

### Rollback Plan
- Keep original files
- Feature flags for new pipeline
- Gradual rollout strategy
- Monitoring and alerts

This technical specification provides the foundation for implementing a robust, scalable, and maintainable pipeline system for DirectorStudio.
