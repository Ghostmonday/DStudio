//
//  LocalStorageModule.swift
//  DirectorStudio
//
//  Production-Ready Offline-First Storage Layer
//  Designed for App Store Featured Section Quality
//

import Foundation
import CoreData
import Combine

// MARK: - Storage Protocol

public protocol StorageProvider {
    func save<T: Encodable>(_ object: T, for key: String) async throws
    func load<T: Decodable>(for key: String, as type: T.Type) async throws -> T?
    func delete(for key: String) async throws
    func exists(for key: String) async -> Bool
}

// MARK: - Local Storage Manager

@MainActor
public class LocalStorageManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = LocalStorageManager()
    
    // MARK: - Published State
    
    @Published public private(set) var isReady: Bool = false
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var pendingSyncCount: Int = 0
    
    // MARK: - Core Data Stack
    
    private let persistentContainer: NSPersistentContainer
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Configuration
    
    private let containerName = "DirectorStudio"
    private let modelVersion = "1.0.0"
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Core Data stack
        persistentContainer = NSPersistentContainer(name: containerName)
        
        // Configure persistent store
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(containerName).sqlite")
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        
        // Load persistent stores
        persistentContainer.loadPersistentStores { [weak self] description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
            
            Task { @MainActor in
                self?.isReady = true
                self?.setupAutoSave()
                await self?.calculatePendingSyncCount()
            }
        }
        
        // Configure view context
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // Performance optimization
    }
    
    // MARK: - Auto-Save
    
    private func setupAutoSave() {
        // Auto-save every 30 seconds if there are changes
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.saveContext()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Context Management
    
    public func saveContext() async {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Error saving context: \(error)")
            viewContext.rollback()
        }
    }
    
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Scene Draft Management
    
    public func saveSceneDraft(_ draft: SceneDraft) async throws {
        try await performBackgroundTask { context in
            let entity: SceneDraftEntity
            
            // Fetch or create
            let fetchRequest = SceneDraftEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", draft.id.uuidString)
            fetchRequest.fetchLimit = 1
            
            if let existing = try context.fetch(fetchRequest).first {
                entity = existing
            } else {
                entity = SceneDraftEntity(context: context)
                entity.id = draft.id
                entity.createdAt = Date()
            }
            
            // Update properties
            entity.projectId = draft.projectId
            entity.orderIndex = Int32(draft.orderIndex)
            entity.promptText = draft.promptText
            entity.duration = draft.duration
            entity.sceneType = draft.sceneType
            entity.shotType = draft.shotType
            entity.updatedAt = Date()
            entity.needsSync = true
        }
        
        await calculatePendingSyncCount()
    }
    
    public func loadSceneDrafts(for projectId: String) async throws -> [SceneDraft] {
        return try await performBackgroundTask { context in
            let fetchRequest = SceneDraftEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "projectId == %@", projectId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { SceneDraft(from: $0) }
        }
    }
    
    public func deleteSceneDraft(_ id: UUID) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = SceneDraftEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)
            
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
            }
        }
        
        await calculatePendingSyncCount()
    }
    
    // MARK: - Screenplay Management
    
    public func saveScreenplay(_ screenplay: Screenplay) async throws {
        try await performBackgroundTask { context in
            let entity: ScreenplayEntity
            
            let fetchRequest = ScreenplayEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", screenplay.id.uuidString)
            fetchRequest.fetchLimit = 1
            
            if let existing = try context.fetch(fetchRequest).first {
                entity = existing
            } else {
                entity = ScreenplayEntity(context: context)
                entity.id = screenplay.id
                entity.createdAt = Date()
            }
            
            entity.title = screenplay.title
            entity.content = screenplay.content
            entity.version = Int32(screenplay.version)
            entity.updatedAt = Date()
            entity.needsSync = true
            
            // Save sections
            entity.sections?.forEach { context.delete($0 as! NSManagedObject) }
            
            for section in screenplay.sections {
                let sectionEntity = ScreenplaySectionEntity(context: context)
                sectionEntity.id = section.id
                sectionEntity.heading = section.heading
                sectionEntity.content = section.content
                sectionEntity.orderIndex = Int32(section.orderIndex)
                sectionEntity.screenplay = entity
            }
        }
        
        await calculatePendingSyncCount()
    }
    
    public func loadScreenplay(id: UUID) async throws -> Screenplay? {
        return try await performBackgroundTask { context in
            let fetchRequest = ScreenplayEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }
            
            return Screenplay(from: entity)
        }
    }
    
    public func loadAllScreenplays() async throws -> [Screenplay] {
        return try await performBackgroundTask { context in
            let fetchRequest = ScreenplayEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { Screenplay(from: $0) }
        }
    }
    
    // MARK: - Continuity Logs
    
    public func saveContinuityLog(_ log: ContinuityLog) async throws {
        try await performBackgroundTask { context in
            let entity = ContinuityLogEntity(context: context)
            entity.id = log.id
            entity.sceneId = Int32(log.sceneId)
            entity.confidence = log.confidence
            entity.passed = log.passed
            entity.timestamp = log.timestamp
            entity.needsSync = true
            
            // Encode issues as JSON
            if let issuesData = try? JSONEncoder().encode(log.issues) {
                entity.issuesJSON = String(data: issuesData, encoding: .utf8)
            }
        }
        
        await calculatePendingSyncCount()
    }
    
    public func loadContinuityLogs(limit: Int = 100) async throws -> [ContinuityLog] {
        return try await performBackgroundTask { context in
            let fetchRequest = ContinuityLogEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { ContinuityLog(from: $0) }
        }
    }
    
    // MARK: - Video Clip Metadata
    
    public func saveVideoClip(_ clip: VideoClipMetadata) async throws {
        try await performBackgroundTask { context in
            let entity: VideoClipEntity
            
            let fetchRequest = VideoClipEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", clip.id.uuidString)
            fetchRequest.fetchLimit = 1
            
            if let existing = try context.fetch(fetchRequest).first {
                entity = existing
            } else {
                entity = VideoClipEntity(context: context)
                entity.id = clip.id
                entity.createdAt = Date()
            }
            
            entity.projectId = clip.projectId
            entity.jobId = clip.jobId
            entity.orderIndex = Int32(clip.orderIndex)
            entity.status = clip.status.rawValue
            entity.localURL = clip.localURL?.absoluteString
            entity.remoteURL = clip.remoteURL?.absoluteString
            entity.duration = clip.duration
            entity.thumbnailData = clip.thumbnailData
            entity.updatedAt = Date()
            entity.needsSync = true
        }
        
        await calculatePendingSyncCount()
    }
    
    public func loadVideoClips(for projectId: String) async throws -> [VideoClipMetadata] {
        return try await performBackgroundTask { context in
            let fetchRequest = VideoClipEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "projectId == %@", projectId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { VideoClipMetadata(from: $0) }
        }
    }
    
    public func updateVideoClipStatus(id: UUID, status: VideoClipStatus, remoteURL: URL? = nil) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = VideoClipEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)
            
            if let entity = try context.fetch(fetchRequest).first {
                entity.status = status.rawValue
                if let remoteURL = remoteURL {
                    entity.remoteURL = remoteURL.absoluteString
                }
                entity.updatedAt = Date()
                entity.needsSync = true
            }
        }
    }
    
    // MARK: - Sync Queue Management
    
    public func getItemsNeedingSync() async throws -> [SyncableItem] {
        return try await performBackgroundTask { context in
            var items: [SyncableItem] = []
            
            // Scene drafts
            let draftRequest = SceneDraftEntity.fetchRequest()
            draftRequest.predicate = NSPredicate(format: "needsSync == YES")
            let drafts = try context.fetch(draftRequest)
            items.append(contentsOf: drafts.compactMap { SyncableItem(draft: $0) })
            
            // Screenplays
            let screenplayRequest = ScreenplayEntity.fetchRequest()
            screenplayRequest.predicate = NSPredicate(format: "needsSync == YES")
            let screenplays = try context.fetch(screenplayRequest)
            items.append(contentsOf: screenplays.compactMap { SyncableItem(screenplay: $0) })
            
            // Continuity logs
            let logRequest = ContinuityLogEntity.fetchRequest()
            logRequest.predicate = NSPredicate(format: "needsSync == YES")
            let logs = try context.fetch(logRequest)
            items.append(contentsOf: logs.compactMap { SyncableItem(log: $0) })
            
            // Video clips
            let clipRequest = VideoClipEntity.fetchRequest()
            clipRequest.predicate = NSPredicate(format: "needsSync == YES")
            let clips = try context.fetch(clipRequest)
            items.append(contentsOf: clips.compactMap { SyncableItem(clip: $0) })
            
            return items
        }
    }
    
    public func markAsSynced(_ item: SyncableItem) async throws {
        try await performBackgroundTask { context in
            switch item.type {
            case .sceneDraft:
                let request = SceneDraftEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", item.id.uuidString)
                if let entity = try context.fetch(request).first {
                    entity.needsSync = false
                    entity.lastSyncedAt = Date()
                }
                
            case .screenplay:
                let request = ScreenplayEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", item.id.uuidString)
                if let entity = try context.fetch(request).first {
                    entity.needsSync = false
                    entity.lastSyncedAt = Date()
                }
                
            case .continuityLog:
                let request = ContinuityLogEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", item.id.uuidString)
                if let entity = try context.fetch(request).first {
                    entity.needsSync = false
                    entity.lastSyncedAt = Date()
                }
                
            case .videoClip:
                let request = VideoClipEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", item.id.uuidString)
                if let entity = try context.fetch(request).first {
                    entity.needsSync = false
                    entity.lastSyncedAt = Date()
                }
            }
        }
        
        await calculatePendingSyncCount()
    }
    
    private func calculatePendingSyncCount() async {
        do {
            let items = try await getItemsNeedingSync()
            pendingSyncCount = items.count
        } catch {
            pendingSyncCount = 0
        }
    }
    
    // MARK: - Cleanup
    
    public func deleteOldData(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        try await performBackgroundTask { context in
            // Delete old continuity logs
            let logRequest = ContinuityLogEntity.fetchRequest()
            logRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
            let logs = try context.fetch(logRequest)
            logs.forEach { context.delete($0) }
            
            // Delete completed video clips older than cutoff
            let clipRequest = VideoClipEntity.fetchRequest()
            clipRequest.predicate = NSPredicate(format: "status == %@ AND updatedAt < %@", 
                                                VideoClipStatus.completed.rawValue, 
                                                cutoffDate as NSDate)
            let clips = try context.fetch(clipRequest)
            clips.forEach { context.delete($0) }
        }
    }
    
    // MARK: - Export/Import (for backup)
    
    public func exportAllData() async throws -> Data {
        let export = DataExport(
            version: modelVersion,
            exportDate: Date(),
            screenplays: try await loadAllScreenplays(),
            continuityLogs: try await loadContinuityLogs(limit: 1000)
        )
        
        return try JSONEncoder().encode(export)
    }
    
    public func importData(_ data: Data) async throws {
        let export = try JSONDecoder().decode(DataExport.self, from: data)
        
        // Import screenplays
        for screenplay in export.screenplays {
            try await saveScreenplay(screenplay)
        }
        
        // Import continuity logs
        for log in export.continuityLogs {
            try await saveContinuityLog(log)
        }
    }
}

// MARK: - Data Models

public struct SceneDraft: Codable, Identifiable {
    public let id: UUID
    public let projectId: String
    public let orderIndex: Int
    public let promptText: String
    public let duration: Double
    public let sceneType: String?
    public let shotType: String?
    public let createdAt: Date
    public let updatedAt: Date
    
    init?(from entity: SceneDraftEntity) {
        guard let id = entity.id,
              let projectId = entity.projectId,
              let promptText = entity.promptText,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        self.id = id
        self.projectId = projectId
        self.orderIndex = Int(entity.orderIndex)
        self.promptText = promptText
        self.duration = entity.duration
        self.sceneType = entity.sceneType
        self.shotType = entity.shotType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Screenplay: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let content: String
    public let version: Int
    public let sections: [ScreenplaySection]
    public let createdAt: Date
    public let updatedAt: Date
    
    init?(from entity: ScreenplayEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let content = entity.content,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.content = content
        self.version = Int(entity.version)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Convert sections
        let sectionEntities = entity.sections?.allObjects as? [ScreenplaySectionEntity] ?? []
        self.sections = sectionEntities.compactMap { sectionEntity in
            guard let id = sectionEntity.id,
                  let heading = sectionEntity.heading,
                  let content = sectionEntity.content else {
                return nil
            }
            
            return ScreenplaySection(
                id: id,
                heading: heading,
                content: content,
                orderIndex: Int(sectionEntity.orderIndex)
            )
        }.sorted { $0.orderIndex < $1.orderIndex }
    }
}

public struct ScreenplaySection: Codable, Identifiable {
    public let id: UUID
    public let heading: String
    public let content: String
    public let orderIndex: Int
}

public struct ContinuityLog: Codable, Identifiable {
    public let id: UUID
    public let sceneId: Int
    public let confidence: Double
    public let issues: [String]
    public let passed: Bool
    public let timestamp: Date
    
    init?(from entity: ContinuityLogEntity) {
        guard let id = entity.id,
              let timestamp = entity.timestamp else {
            return nil
        }
        
        self.id = id
        self.sceneId = Int(entity.sceneId)
        self.confidence = entity.confidence
        self.passed = entity.passed
        self.timestamp = timestamp
        
        // Decode issues from JSON
        if let issuesJSON = entity.issuesJSON,
           let data = issuesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.issues = decoded
        } else {
            self.issues = []
        }
    }
}

public struct VideoClipMetadata: Codable, Identifiable {
    public let id: UUID
    public let projectId: String
    public let jobId: String?
    public let orderIndex: Int
    public let status: VideoClipStatus
    public let localURL: URL?
    public let remoteURL: URL?
    public let duration: Double
    public let thumbnailData: Data?
    public let createdAt: Date
    public let updatedAt: Date
    
    init?(from entity: VideoClipEntity) {
        guard let id = entity.id,
              let projectId = entity.projectId,
              let statusString = entity.status,
              let status = VideoClipStatus(rawValue: statusString),
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        self.id = id
        self.projectId = projectId
        self.jobId = entity.jobId
        self.orderIndex = Int(entity.orderIndex)
        self.status = status
        self.localURL = entity.localURL.flatMap { URL(string: $0) }
        self.remoteURL = entity.remoteURL.flatMap { URL(string: $0) }
        self.duration = entity.duration
        self.thumbnailData = entity.thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum VideoClipStatus: String, Codable {
    case draft
    case queued
    case processing
    case completed
    case failed
}

// MARK: - Syncable Item

public struct SyncableItem: Identifiable {
    public let id: UUID
    public let type: SyncableType
    public let updatedAt: Date
    
    public enum SyncableType {
        case sceneDraft
        case screenplay
        case continuityLog
        case videoClip
    }
    
    init?(draft entity: SceneDraftEntity) {
        guard let id = entity.id, let updatedAt = entity.updatedAt else { return nil }
        self.id = id
        self.type = .sceneDraft
        self.updatedAt = updatedAt
    }
    
    init?(screenplay entity: ScreenplayEntity) {
        guard let id = entity.id, let updatedAt = entity.updatedAt else { return nil }
        self.id = id
        self.type = .screenplay
        self.updatedAt = updatedAt
    }
    
    init?(log entity: ContinuityLogEntity) {
        guard let id = entity.id, let timestamp = entity.timestamp else { return nil }
        self.id = id
        self.type = .continuityLog
        self.updatedAt = timestamp
    }
    
    init?(clip entity: VideoClipEntity) {
        guard let id = entity.id, let updatedAt = entity.updatedAt else { return nil }
        self.id = id
        self.type = .videoClip
        self.updatedAt = updatedAt
    }
}

// MARK: - Data Export

public struct DataExport: Codable {
    let version: String
    let exportDate: Date
    let screenplays: [Screenplay]
    let continuityLogs: [ContinuityLog]
}
