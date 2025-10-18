# 🎬 DirectorStudio - Production Implementation Guide

## App Store Feature-Worthy Architecture

**A professional AI-powered filmmaking studio for iOS**

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Module Documentation](#module-documentation)
3. [Integration Guide](#integration-guide)
4. [Database Schema](#database-schema)
5. [Setup Instructions](#setup-instructions)
6. [App Store Checklist](#app-store-checklist)
7. [Performance & Optimization](#performance--optimization)

---

## 🏗️ Architecture Overview

DirectorStudio follows a clean, modular architecture designed for production-quality iOS apps:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  SwiftUI Views + ViewModels + Coordinators                  │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│  Business Logic + Use Cases + Protocols                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│                      DATA LAYER                              │
│  Repositories + Storage + Sync Engine                        │
└───────────────────┬─────────────────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ Core Data    │      │  Supabase    │
│ (Offline)    │      │  (Cloud)     │
└──────────────┘      └──────────────┘
```

### Key Principles

- ✅ **Offline-First**: Full functionality without network
- ✅ **Type-Safe**: Swift 6 concurrency with Sendable conformance
- ✅ **Testable**: Protocol-based dependencies
- ✅ **Modular**: Each component can be independently tested/replaced
- ✅ **Scalable**: Designed for thousands of scenes per project

---

## 📦 Module Documentation

### 1. LocalStorageModule

**Purpose**: Offline-first Core Data persistence layer

**Files**:
- `LocalStorageModule.swift` - Main storage manager
- `CoreDataEntities.swift` - Entity definitions

**Key Features**:
- ✅ Thread-safe Core Data operations
- ✅ Automatic background saving
- ✅ Encrypted storage (FileProtection.complete)
- ✅ Migration support
- ✅ Export/import for backups

**Usage**:
```swift
let storage = LocalStorageManager.shared

// Save scene
try await storage.saveSceneDraft(draft)

// Load scenes
let scenes = try await storage.loadSceneDrafts(for: projectId)

// Delete scene
try await storage.deleteSceneDraft(id)
```

**Data Models**:
- `SceneDraft` - Individual video scenes
- `Screenplay` - Full scripts with sections
- `ContinuityLog` - Scene-to-scene validation logs
- `VideoClipMetadata` - Generated video metadata

---

### 2. SupabaseSyncEngine

**Purpose**: Cloud synchronization with offline queue and conflict resolution

**Files**:
- `SupabaseSyncEngine.swift` - Main sync engine

**Key Features**:
- ✅ Automatic sync every 5 minutes
- ✅ Offline queue with retry logic
- ✅ Exponential backoff for failed requests
- ✅ Last-write-wins conflict resolution
- ✅ Batch processing for efficiency
- ✅ Network monitoring

**Usage**:
```swift
let sync = SupabaseSyncEngine.shared

// Manual sync
await sync.syncNow()

// Queue item for sync
await sync.queueForSync(item)

// Check credits
let credits = try await sync.syncCredits()

// Generate video
let jobId = try await sync.submitClipJob(prompt: "...")
```

**Sync Flow**:
```
1. Detect changes locally
2. Queue for sync
3. Wait for network availability
4. Upload in batches (10 items)
5. Retry up to 3 times on failure
6. Mark as synced on success
```

---

### 3. SceneControlSheet (UI)

**Purpose**: Premium user interface for scene configuration

**Files**:
- `SceneControlSheet.swift` - SwiftUI implementation

**Key Features**:
- ✅ Responsive iPad/iPhone layouts
- ✅ Automatic vs Manual modes
- ✅ Scene count stepper (1-30)
- ✅ Duration slider (2-20s)
- ✅ Budget limits
- ✅ Real-time cost estimation

**UI Components**:
- Auto Scene Detection toggle
- Target Scene Count stepper
- Duration slider with presets
- Budget limit field
- Estimation display

---

### 4. Pipeline Integration

**Purpose**: Connects UI → Pipeline → Storage → Sync

**Files**:
- `CompletePipelineIntegration.swift` - Full integration layer

**Key Components**:

#### DirectorStudioCoordinator
Main app coordinator that orchestrates all components:

```swift
@MainActor
class DirectorStudioCoordinator: ObservableObject {
    // Dependencies
    private let storage: LocalStorageManager
    private let syncEngine: SupabaseSyncEngine
    private let pipelineManager: PipelineManager
    
    // State
    @Published var currentProject: Project?
    @Published var sceneControlConfig: SceneControlConfig
    @Published var isGenerating: Bool
    @Published var credits: Int
    
    // Actions
    func createNewProject(title: String, script: String)
    func generateScenes()
    func generateVideo(for scene: SceneDraft)
    func updateScene(_ scene: SceneDraft)
}
```

---

## 🗄️ Database Schema

### Local Storage (Core Data)

```
SceneDraftEntity
├── id: UUID (Primary Key)
├── projectId: String
├── orderIndex: Int32
├── promptText: String
├── duration: Double
├── sceneType: String?
├── shotType: String?
├── createdAt: Date
├── updatedAt: Date
├── needsSync: Bool
└── lastSyncedAt: Date?

ScreenplayEntity
├── id: UUID (Primary Key)
├── title: String
├── content: String
├── version: Int32
├── createdAt: Date
├── updatedAt: Date
├── needsSync: Bool
├── lastSyncedAt: Date?
└── sections: [ScreenplaySectionEntity]

ScreenplaySectionEntity
├── id: UUID (Primary Key)
├── heading: String
├── content: String
├── orderIndex: Int32
└── screenplay: ScreenplayEntity

ContinuityLogEntity
├── id: UUID (Primary Key)
├── sceneId: Int32
├── confidence: Double
├── issuesJSON: String
├── passed: Bool
├── timestamp: Date
├── needsSync: Bool
└── lastSyncedAt: Date?

VideoClipEntity
├── id: UUID (Primary Key)
├── projectId: String
├── jobId: String?
├── orderIndex: Int32
├── status: String
├── localURL: String?
├── remoteURL: String?
├── duration: Double
├── thumbnailData: Data?
├── createdAt: Date
├── updatedAt: Date
├── needsSync: Bool
└── lastSyncedAt: Date?
```

### Cloud Storage (Supabase)

```sql
-- Credits Ledger
CREATE TABLE credits_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_key TEXT NOT NULL,
    credits INTEGER NOT NULL DEFAULT 0,
    first_clip_granted BOOLEAN DEFAULT false,
    first_clip_consumed BOOLEAN DEFAULT false,
    granted_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Clip Jobs
CREATE TABLE clip_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_key TEXT NOT NULL,
    prompt TEXT NOT NULL,
    status TEXT NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    download_url TEXT
);

-- Continuity Logs
CREATE TABLE continuity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    scene_id INTEGER NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    issues JSONB NOT NULL DEFAULT '[]'::jsonb,
    passed BOOLEAN NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Video Uploads
CREATE TABLE video_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id TEXT,
    order_index INTEGER,
    filename TEXT,
    uploaded_at TIMESTAMP DEFAULT now()
);
```

---

## 🚀 Setup Instructions

### 1. Xcode Project Setup

```bash
# Clone repository
git clone https://github.com/yourorg/directorstudio.git
cd directorstudio

# Install dependencies (if using SPM)
xcodebuild -resolvePackageDependencies

# Open project
open DirectorStudio.xcodeproj
```

### 2. Environment Configuration

Create `Config.xcconfig`:

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your_anon_key_here
```

Add to Info.plist:
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

### 3. Core Data Model Setup

1. Create new Data Model: `DirectorStudio.xcdatamodeld`
2. Add entities as defined in `CoreDataEntities.swift`
3. Set Codegen to "Manual/None"
4. Build project

### 4. Supabase Setup

```sql
-- Run migrations
psql -h db.your-project.supabase.co -U postgres -d postgres -f migrations/001_initial.sql

-- Create storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('video-clips', 'video-clips', true);

-- Set up RLS policies
ALTER TABLE credits_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE clip_jobs ENABLE ROW LEVEL SECURITY;
```

### 5. In-App Purchases Setup

1. Create products in App Store Connect:
   - `com.directorstudio.credits.100` - $4.99
   - `com.directorstudio.credits.500` - $19.99
   - `com.directorstudio.credits.1000` - $34.99

2. Add StoreKit Configuration file to project

3. Test in sandbox environment

---

## ✅ App Store Checklist

### Before Submission

#### Code Quality
- [ ] All compiler warnings resolved
- [ ] No force unwraps in production code
- [ ] Swift 6 concurrency enabled
- [ ] Memory leaks checked (Instruments)
- [ ] Performance profiled

#### Privacy & Security
- [ ] PrivacyInfo.xcprivacy added
- [ ] Data encryption enabled
- [ ] API keys in Keychain
- [ ] Privacy policy URL
- [ ] Terms of service

#### Features
- [ ] Offline mode works completely
- [ ] Sync tested thoroughly
- [ ] Error handling comprehensive
- [ ] Credits purchase flow tested
- [ ] Video generation tested

#### Assets
- [ ] App icons (all sizes)
- [ ] Launch screen
- [ ] Screenshots (6.7", 6.5", 5.5" displays)
- [ ] App preview video
- [ ] Localized strings

#### Accessibility
- [ ] VoiceOver labels
- [ ] Dynamic Type support
- [ ] High contrast tested
- [ ] Minimum 44pt touch targets

#### Testing
- [ ] iPhone 15 Pro Max tested
- [ ] iPhone SE tested
- [ ] iPad Pro tested
- [ ] iOS 17.0 minimum tested
- [ ] Offline functionality verified
- [ ] Low battery mode tested

---

## ⚡ Performance & Optimization

### Memory Management

```swift
// ✅ Use weak references in closures
class ViewModel {
    func loadData() {
        Task { [weak self] in
            await self?.processData()
        }
    }
}

// ✅ Limit cache size
actor ImageCache {
    private var cache: [UUID: UIImage] = [:]
    private let maxSize = 50
    
    func store(_ image: UIImage, for id: UUID) {
        if cache.count >= maxSize {
            cache.removeFirst()
        }
        cache[id] = image
    }
}
```

### Network Optimization

```swift
// ✅ Batch requests
let items = try await storage.getItemsNeedingSync()
for batch in items.chunked(into: 10) {
    try await syncBatch(batch)
}

// ✅ Request deduplication
actor RequestDeduplicator {
    private var ongoing: [String: Task<Data, Error>] = [:]
    
    func fetch(_ url: URL) async throws -> Data {
        let key = url.absoluteString
        
        if let task = ongoing[key] {
            return try await task.value
        }
        
        let task = Task {
            try await URLSession.shared.data(from: url).0
        }
        
        ongoing[key] = task
        defer { ongoing[key] = nil }
        
        return try await task.value
    }
}
```

### Core Data Optimization

```swift
// ✅ Batch operations
func deleteOldLogs() async throws {
    try await storage.performBackgroundTask { context in
        let fetchRequest = ContinuityLogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp < %@",
            cutoffDate as NSDate
        )
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
    }
}

// ✅ Faulting for large datasets
let fetchRequest = SceneDraftEntity.fetchRequest()
fetchRequest.returnsObjectsAsFaults = true
fetchRequest.fetchBatchSize = 20
```

---

## 🎯 Best Practices

### Error Handling

```swift
// ✅ Structured error types
enum DirectorStudioError: LocalizedError {
    case storage(StorageError)
    case network(NetworkError)
    case pipeline(PipelineError)
    
    var errorDescription: String? {
        // Localized descriptions
    }
    
    var recoverySuggestion: String? {
        // Actionable suggestions
    }
}

// ✅ Graceful degradation
func loadWithFallback() async -> Data? {
    if let cached = await cache.load() { return cached }
    if let local = try? await storage.load() { return local }
    if let remote = try? await sync.fetch() { return remote }
    return nil
}
```

### Async/Await Patterns

```swift
// ✅ Structured concurrency
await withTaskGroup(of: VideoClip.self) { group in
    for scene in scenes {
        group.addTask {
            try await generateVideo(for: scene)
        }
    }
    
    for await clip in group {
        clips.append(clip)
    }
}

// ✅ Actor isolation
@MainActor
class ViewModel: ObservableObject {
    @Published var state: State = .idle
    
    func updateState(_ newState: State) {
        // Guaranteed on main thread
        self.state = newState
    }
}
```

---

## 📊 Monitoring & Analytics

### Logging Strategy

```swift
import OSLog

extension Logger {
    static let storage = Logger(subsystem: "com.directorstudio", category: "Storage")
    static let network = Logger(subsystem: "com.directorstudio", category: "Network")
    static let pipeline = Logger(subsystem: "com.directorstudio", category: "Pipeline")
}

// Usage
Logger.storage.info("Scene saved: \(sceneId)")
Logger.network.error("Sync failed: \(error)")
```

### Analytics Events

```swift
enum AnalyticsEvent {
    case appLaunched
    case projectCreated
    case scenesGenerated(count: Int)
    case videoGenerated(duration: Double)
    case creditsPurchased(amount: Int)
    case syncCompleted
}

// Track in coordinator
await analytics.track(.scenesGenerated(count: scenes.count))
```

---

## 🔄 Development Workflow

### Git Workflow

```bash
# Feature branch
git checkout -b feature/new-scene-type

# Commit with conventional commits
git commit -m "feat(scenes): add montage scene type"

# Push and create PR
git push origin feature/new-scene-type
```

### Testing

```swift
// Unit tests
@Test func testSceneSaving() async throws {
    let storage = TestStorageManager()
    let draft = SceneDraft(...)
    
    try await storage.save(draft)
    let loaded = try await storage.load(id: draft.id)
    
    #expect(loaded.id == draft.id)
}

// Integration tests
@Test func testSyncFlow() async throws {
    let coordinator = DirectorStudioCoordinator()
    
    await coordinator.createNewProject(title: "Test", script: "...")
    try await coordinator.generateScenes()
    
    #expect(coordinator.currentProject?.scenes.isEmpty == false)
}
```

---

## 📱 Device Support

| Device | Support | Notes |
|--------|---------|-------|
| iPhone SE (3rd gen) | ✅ Full | Optimized layout |
| iPhone 15 | ✅ Full | Standard layout |
| iPhone 15 Pro Max | ✅ Full | Enhanced visuals |
| iPad (10th gen) | ✅ Full | Responsive grid |
| iPad Pro 12.9" | ✅ Full | Premium experience |

**Minimum**: iOS 17.0  
**Recommended**: iOS 18.0+

---

## 🎨 Design System

### Colors

```swift
extension Color {
    static let dsAccent = Color.blue
    static let dsBackground = Color(.systemGroupedBackground)
    static let dsCard = Color(.systemBackground)
    static let dsSecondary = Color(.secondaryLabel)
}
```

### Typography

```swift
extension Font {
    static let dsTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let dsHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let dsBody = Font.system(.body, design: .default)
    static let dsCaption = Font.system(.caption, design: .default)
}
```

---

## 🚨 Troubleshooting

### Common Issues

**Sync not working?**
- Check network connection
- Verify Supabase credentials
- Check Console logs for errors

**Core Data migration failed?**
- Delete app and reinstall
- Check entity definitions match
- Verify migration mapping

**Credits not updating?**
- Refresh sync manually
- Check Supabase connection
- Verify transaction completion

---

## 📚 Additional Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Supabase Swift Client](https://github.com/supabase-community/supabase-swift)

---

## 📄 License

Copyright © 2024 DirectorStudio. All rights reserved.

---

## 👥 Contributors

- Architecture: AI-Assisted Design
- Implementation: Production-Ready Swift
- Quality: App Store Featured Standards

---

**Built with ❤️ for filmmakers everywhere**
