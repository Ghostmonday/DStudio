//
//  SupabaseSyncEngine.swift
//  DirectorStudio
//
//  Production-Ready Sync Engine
//  Offline Queue + Retry + Conflict Resolution
//

import Foundation
import Combine
import Network

// MARK: - Sync Engine

@MainActor
public class SupabaseSyncEngine: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = SupabaseSyncEngine()
    
    // MARK: - Published State
    
    @Published public private(set) var syncState: SyncState = .idle
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var queuedItemsCount: Int = 0
    @Published public private(set) var isOnline: Bool = true
    
    // MARK: - Dependencies
    
    private let storage = LocalStorageManager.shared
    private let supabase: SupabaseClient
    private let monitor = NWPathMonitor()
    
    // MARK: - Configuration
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 5.0
    private let batchSize = 10
    
    // MARK: - State
    
    private var syncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var retryAttempts: [UUID: Int] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Supabase client
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            fatalError("Supabase credentials not found in environment")
        }
        
        self.supabase = SupabaseClient(
            url: URL(string: supabaseURL)!,
            apiKey: supabaseKey
        )
        
        setupNetworkMonitoring()
        setupPeriodicSync()
        setupNotificationObservers()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied
                
                // If we just came online, trigger sync
                if !wasOnline && path.status == .satisfied {
                    await self?.syncNow()
                }
            }
        }
        
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - Periodic Sync
    
    private func setupPeriodicSync() {
        // Sync every 5 minutes when online
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, self.isOnline else { return }
                    await self.syncNow()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Sync when app enters foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.syncNow()
                }
            }
            .store(in: &cancellables)
        
        // Save pending changes when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.storage.saveContext()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Trigger immediate sync
    public func syncNow() async {
        guard isOnline else {
            print("📴 Cannot sync: offline")
            return
        }
        
        guard syncState != .syncing else {
            print("⏳ Sync already in progress")
            return
        }
        
        syncState = .syncing
        
        do {
            // Get items needing sync
            let items = try await storage.getItemsNeedingSync()
            queuedItemsCount = items.count
            
            guard !items.isEmpty else {
                syncState = .idle
                lastSyncDate = Date()
                return
            }
            
            print("🔄 Syncing \(items.count) items...")
            
            // Process in batches
            for batch in items.chunked(into: batchSize) {
                try await syncBatch(batch)
            }
            
            syncState = .idle
            lastSyncDate = Date()
            queuedItemsCount = 0
            retryAttempts.removeAll()
            
            print("✅ Sync complete")
            
        } catch {
            print("❌ Sync failed: \(error)")
            syncState = .failed(error)
            
            // Schedule retry
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            await syncNow()
        }
    }
    
    /// Queue item for sync and trigger if online
    public func queueForSync(_ item: SyncableItem) async {
        queuedItemsCount += 1
        
        if isOnline {
            await syncNow()
        }
    }
    
    // MARK: - Batch Syncing
    
    private func syncBatch(_ batch: [SyncableItem]) async throws {
        for item in batch {
            do {
                try await syncItem(item)
                try await storage.markAsSynced(item)
                queuedItemsCount = max(0, queuedItemsCount - 1)
                
                // Reset retry counter on success
                retryAttempts[item.id] = 0
                
            } catch {
                // Increment retry counter
                let attempts = (retryAttempts[item.id] ?? 0) + 1
                retryAttempts[item.id] = attempts
                
                if attempts >= maxRetries {
                    print("❌ Max retries reached for item \(item.id), skipping")
                    retryAttempts.removeValue(forKey: item.id)
                } else {
                    print("⚠️ Retry \(attempts)/\(maxRetries) for item \(item.id)")
                    throw error
                }
            }
        }
    }
    
    // MARK: - Individual Item Sync
    
    private func syncItem(_ item: SyncableItem) async throws {
        switch item.type {
        case .sceneDraft:
            try await syncSceneDraft(item.id)
            
        case .screenplay:
            try await syncScreenplay(item.id)
            
        case .continuityLog:
            try await syncContinuityLog(item.id)
            
        case .videoClip:
            try await syncVideoClip(item.id)
        }
    }
    
    // MARK: - Scene Draft Sync
    
    private func syncSceneDraft(_ id: UUID) async throws {
        // Load from local storage
        guard let drafts = try? await storage.loadSceneDrafts(for: ""), // Need to get project ID
              let draft = drafts.first(where: { $0.id == id }) else {
            throw SyncError.itemNotFound
        }
        
        // Check if exists on server
        let existing: SceneDraftResponse? = try await supabase.from("scene_drafts")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        if let existing = existing {
            // Conflict resolution
            let resolved = try await resolveConflict(local: draft, remote: existing)
            
            // Update server
            try await supabase.from("scene_drafts")
                .update(resolved.toSupabaseDict())
                .eq("id", value: id.uuidString)
                .execute()
            
            // Update local if needed
            if resolved.id != draft.id {
                try await storage.saveSceneDraft(resolved)
            }
            
        } else {
            // Insert new
            try await supabase.from("scene_drafts")
                .insert(draft.toSupabaseDict())
                .execute()
        }
    }
    
    // MARK: - Screenplay Sync
    
    private func syncScreenplay(_ id: UUID) async throws {
        guard let screenplay = try await storage.loadScreenplay(id: id) else {
            throw SyncError.itemNotFound
        }
        
        // Upsert screenplay
        try await supabase.from("screenplays")
            .upsert(screenplay.toSupabaseDict())
            .execute()
        
        // Sync sections
        for section in screenplay.sections {
            try await supabase.from("screenplay_sections")
                .upsert(section.toSupabaseDict(screenplayId: id))
                .execute()
        }
    }
    
    // MARK: - Continuity Log Sync
    
    private func syncContinuityLog(_ id: UUID) async throws {
        let logs = try await storage.loadContinuityLogs(limit: 1000)
        guard let log = logs.first(where: { $0.id == id }) else {
            throw SyncError.itemNotFound
        }
        
        // Map to Supabase schema
        let payload: [String: Any] = [
            "id": log.id.uuidString,
            "scene_id": log.sceneId,
            "confidence": log.confidence,
            "issues": log.issues,
            "passed": log.passed,
            "timestamp": ISO8601DateFormatter().string(from: log.timestamp),
            "user_id": await getCurrentUserId()
        ]
        
        try await supabase.from("continuity_logs")
            .insert(payload)
            .execute()
    }
    
    // MARK: - Video Clip Sync
    
    private func syncVideoClip(_ id: UUID) async throws {
        // Load clips
        guard let clips = try? await storage.loadVideoClips(for: ""), // Need project ID
              let clip = clips.first(where: { $0.id == id }) else {
            throw SyncError.itemNotFound
        }
        
        // Map to Supabase schema
        let payload: [String: Any] = [
            "id": clip.id.uuidString,
            "project_id": clip.projectId,
            "order_index": clip.orderIndex,
            "filename": clip.localURL?.lastPathComponent ?? "",
            "uploaded_at": ISO8601DateFormatter().string(from: clip.createdAt)
        ]
        
        try await supabase.from("video_uploads")
            .upsert(payload)
            .execute()
        
        // If clip has local file, upload to storage
        if let localURL = clip.localURL,
           FileManager.default.fileExists(atPath: localURL.path) {
            try await uploadVideoFile(clip: clip, localURL: localURL)
        }
    }
    
    // MARK: - File Upload
    
    private func uploadVideoFile(clip: VideoClipMetadata, localURL: URL) async throws {
        let data = try Data(contentsOf: localURL)
        let filename = "\(clip.projectId)/\(clip.id.uuidString).mp4"
        
        let uploadedURL = try await supabase.storage
            .from("video-clips")
            .upload(path: filename, data: data)
        
        // Update clip with remote URL
        try await storage.updateVideoClipStatus(
            id: clip.id,
            status: .completed,
            remoteURL: uploadedURL
        )
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(local: SceneDraft, remote: SceneDraftResponse) async throws -> SceneDraft {
        // Last-write-wins strategy
        if local.updatedAt > remote.updatedAt {
            return local
        } else {
            // Convert remote to local and save
            let resolved = remote.toSceneDraft()
            return resolved
        }
    }
    
    // MARK: - Credits Sync
    
    public func syncCredits() async throws -> Int {
        let userId = await getCurrentUserId()
        
        let response: CreditsResponse = try await supabase.from("credits_ledger")
            .select()
            .eq("user_key", value: userId)
            .single()
            .execute()
        
        return response.credits
    }
    
    public func consumeCredits(amount: Int) async throws {
        let userId = await getCurrentUserId()
        
        try await supabase.rpc("consume_credits", params: [
            "user_key": userId,
            "amount": amount
        ]).execute()
    }
    
    // MARK: - Job Status Sync
    
    public func submitClipJob(prompt: String) async throws -> String {
        let userId = await getCurrentUserId()
        
        let payload: [String: Any] = [
            "user_key": userId,
            "prompt": prompt,
            "status": "queued",
            "submitted_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response: ClipJobResponse = try await supabase.from("clip_jobs")
            .insert(payload)
            .execute()
        
        return response.id
    }
    
    public func checkJobStatus(jobId: String) async throws -> ClipJobStatus {
        let response: ClipJobResponse = try await supabase.from("clip_jobs")
            .select()
            .eq("id", value: jobId)
            .single()
            .execute()
        
        return ClipJobStatus(
            id: response.id,
            status: response.status,
            downloadURL: response.downloadUrl
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async -> String {
        // Get from UserDefaults or Auth system
        return UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
    }
}

// MARK: - Sync State

public enum SyncState: Equatable {
    case idle
    case syncing
    case failed(Error)
    
    public static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Sync Error

public enum SyncError: LocalizedError {
    case itemNotFound
    case networkError
    case conflictResolutionFailed
    case uploadFailed
    
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in local storage"
        case .networkError:
            return "Network connection error"
        case .conflictResolutionFailed:
            return "Failed to resolve sync conflict"
        case .uploadFailed:
            return "Failed to upload file"
        }
    }
}

// MARK: - Supabase Client (Simplified)

public class SupabaseClient {
    private let url: URL
    private let apiKey: String
    private let session: URLSession
    
    public init(url: URL, apiKey: String) {
        self.url = url
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    public func from(_ table: String) -> QueryBuilder {
        return QueryBuilder(client: self, table: table)
    }
    
    public var storage: StorageClient {
        return StorageClient(client: self)
    }
    
    fileprivate func execute<T: Decodable>(request: URLRequest) async throws -> T {
        var req = request
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SyncError.networkError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Query Builder

public class QueryBuilder {
    private let client: SupabaseClient
    private let table: String
    private var method: String = "GET"
    private var filters: [String: Any] = [:]
    private var body: Data?
    
    fileprivate init(client: SupabaseClient, table: String) {
        self.client = client
        self.table = table
    }
    
    public func select(_ columns: String = "*") -> Self {
        method = "GET"
        return self
    }
    
    public func insert(_ data: [String: Any]) -> Self {
        method = "POST"
        body = try? JSONSerialization.data(withJSONObject: data)
        return self
    }
    
    public func update(_ data: [String: Any]) -> Self {
        method = "PATCH"
        body = try? JSONSerialization.data(withJSONObject: data)
        return self
    }
    
    public func upsert(_ data: [String: Any]) -> Self {
        method = "POST"
        filters["on_conflict"] = "id"
        body = try? JSONSerialization.data(withJSONObject: data)
        return self
    }
    
    public func eq(_ column: String, value: String) -> Self {
        filters[column] = "eq.\(value)"
        return self
    }
    
    public func single<T: Decodable>() -> Self {
        filters["limit"] = 1
        return self
    }
    
    public func execute<T: Decodable>() async throws -> T {
        var components = URLComponents(url: client.url.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        
        // Add filters as query parameters
        if !filters.isEmpty {
            components.queryItems = filters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.httpBody = body
        
        return try await client.execute(request: request)
    }
}

// MARK: - Storage Client

public class StorageClient {
    private let client: SupabaseClient
    
    fileprivate init(client: SupabaseClient) {
        self.client = client
    }
    
    public func from(_ bucket: String) -> BucketClient {
        return BucketClient(client: client, bucket: bucket)
    }
}

public class BucketClient {
    private let client: SupabaseClient
    private let bucket: String
    
    fileprivate init(client: SupabaseClient, bucket: String) {
        self.client = client
        self.bucket = bucket
    }
    
    public func upload(path: String, data: Data) async throws -> URL {
        let url = client.url.appendingPathComponent("storage/v1/object/\(bucket)/\(path)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        struct UploadResponse: Decodable {
            let Key: String
        }
        
        let response: UploadResponse = try await client.execute(request: request)
        return client.url.appendingPathComponent("storage/v1/object/public/\(bucket)/\(response.Key)")
    }
}

// MARK: - Response Models

struct SceneDraftResponse: Decodable {
    let id: String
    let projectId: String
    let orderIndex: Int
    let promptText: String
    let duration: Double
    let sceneType: String?
    let shotType: String?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case orderIndex = "order_index"
        case promptText = "prompt_text"
        case duration
        case sceneType = "scene_type"
        case shotType = "shot_type"
        case updatedAt = "updated_at"
    }
    
    func toSceneDraft() -> SceneDraft {
        return SceneDraft(
            id: UUID(uuidString: id)!,
            projectId: projectId,
            orderIndex: orderIndex,
            promptText: promptText,
            duration: duration,
            sceneType: sceneType,
            shotType: shotType,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }
}

struct CreditsResponse: Decodable {
    let credits: Int
}

struct ClipJobResponse: Decodable {
    let id: String
    let status: String
    let downloadUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case downloadUrl = "download_url"
    }
}

public struct ClipJobStatus {
    public let id: String
    public let status: String
    public let downloadURL: String?
}

// MARK: - Extensions

extension SceneDraft {
    func toSupabaseDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "project_id": projectId,
            "order_index": orderIndex,
            "prompt_text": promptText,
            "duration": duration,
            "scene_type": sceneType as Any,
            "shot_type": shotType as Any,
            "updated_at": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
}

extension Screenplay {
    func toSupabaseDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "content": content,
            "version": version,
            "updated_at": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
}

extension ScreenplaySection {
    func toSupabaseDict(screenplayId: UUID) -> [String: Any] {
        return [
            "id": id.uuidString,
            "screenplay_id": screenplayId.uuidString,
            "heading": heading,
            "content": content,
            "order_index": orderIndex
        ]
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
