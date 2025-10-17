import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Stack
class PersistenceController: ObservableObject {
    // BugScan: CoreData ClipJob stability noop touch for analysis
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DirectorStudio")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure for background saves
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Preview Context
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleSceneState = SceneState(context: viewContext)
        sampleSceneState.id = 1
        sampleSceneState.location = "Forest"
        sampleSceneState.characters = ["Wizard", "Dragon"]
        sampleSceneState.props = ["wand", "crystal"]
        sampleSceneState.prompt = "Wizard casts spell with wand"
        sampleSceneState.tone = "mystical"
        sampleSceneState.timestamp = Date()
        
        let sampleContinuityLog = ContinuityLog(context: viewContext)
        sampleContinuityLog.scene_id = 1
        sampleContinuityLog.confidence = 0.8
        sampleContinuityLog.issues = ["Prop disappeared: sword"]
        sampleContinuityLog.timestamp = Date()
        
        let sampleTelemetry = Telemetry(context: viewContext)
        sampleTelemetry.word = "wand"
        sampleTelemetry.attempts = 5
        sampleTelemetry.successes = 4
        sampleTelemetry.timestamp = Date()
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}

// MARK: - Core Data Extensions
extension NSManagedObjectContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        
        do {
            try save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Scene State Entity
@objc(SceneState)
public class SceneState: NSManagedObject {
    @NSManaged public var id: Int32
    @NSManaged public var location: String
    @NSManaged public var characters: [String]
    @NSManaged public var props: [String]
    @NSManaged public var prompt: String
    @NSManaged public var tone: String
    @NSManaged public var timestamp: Date
}

extension SceneState: Identifiable {
    public var wrappedId: Int32 { id }
    public var wrappedLocation: String { location }
    public var wrappedCharacters: [String] { characters }
    public var wrappedProps: [String] { props }
    public var wrappedPrompt: String { prompt }
    public var wrappedTone: String { tone }
    public var wrappedTimestamp: Date { timestamp }
}

// MARK: - Continuity Log Entity
@objc(ContinuityLog)
public class ContinuityLog: NSManagedObject {
    @NSManaged public var scene_id: Int32
    @NSManaged public var confidence: Double
    @NSManaged public var issues: [String]
    @NSManaged public var timestamp: Date
}

extension ContinuityLog: Identifiable {
    public var wrappedSceneId: Int32 { scene_id }
    public var wrappedConfidence: Double { confidence }
    public var wrappedIssues: [String] { issues }
    public var wrappedTimestamp: Date { timestamp }
}

// MARK: - Telemetry Entity
@objc(Telemetry)
public class Telemetry: NSManagedObject {
    @NSManaged public var word: String
    @NSManaged public var attempts: Int32
    @NSManaged public var successes: Int32
    @NSManaged public var timestamp: Date
}

extension Telemetry: Identifiable {
    public var wrappedWord: String { word }
    public var wrappedAttempts: Int32 { attempts }
    public var wrappedSuccesses: Int32 { successes }
    public var wrappedTimestamp: Date { timestamp }
}

// MARK: - Clip Job Entity
@objc(ClipJob)
public class ClipJob: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var scene_id: Int32
    @NSManaged public var taskId: String
    @NSManaged public var status: String
    @NSManaged public var videoURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension ClipJob: Identifiable {
    public var wrappedId: UUID { id }
    public var wrappedSceneId: Int32 { scene_id }
    public var wrappedTaskId: String { taskId }
    public var wrappedStatus: String { status }
    public var wrappedVideoURL: String? { videoURL }
    public var wrappedCreatedAt: Date { createdAt }
    public var wrappedUpdatedAt: Date { updatedAt }
}
