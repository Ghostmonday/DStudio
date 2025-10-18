//
//  CoreDataEntities.swift
//  DirectorStudio
//
//  Core Data Entity Extensions
//  Companion to DirectorStudio.xcdatamodeld
//

import Foundation
import CoreData

// MARK: - Scene Draft Entity

@objc(SceneDraftEntity)
public class SceneDraftEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var projectId: String?
    @NSManaged public var orderIndex: Int32
    @NSManaged public var promptText: String?
    @NSManaged public var duration: Double
    @NSManaged public var sceneType: String?
    @NSManaged public var shotType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastSyncedAt: Date?
}

extension SceneDraftEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SceneDraftEntity> {
        return NSFetchRequest<SceneDraftEntity>(entityName: "SceneDraftEntity")
    }
}

// MARK: - Screenplay Entity

@objc(ScreenplayEntity)
public class ScreenplayEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var version: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var sections: NSSet?
}

extension ScreenplayEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScreenplayEntity> {
        return NSFetchRequest<ScreenplayEntity>(entityName: "ScreenplayEntity")
    }
}

// MARK: - Screenplay Section Entity

@objc(ScreenplaySectionEntity)
public class ScreenplaySectionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var heading: String?
    @NSManaged public var content: String?
    @NSManaged public var orderIndex: Int32
    @NSManaged public var screenplay: ScreenplayEntity?
}

extension ScreenplaySectionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScreenplaySectionEntity> {
        return NSFetchRequest<ScreenplaySectionEntity>(entityName: "ScreenplaySectionEntity")
    }
}

// MARK: - Continuity Log Entity

@objc(ContinuityLogEntity)
public class ContinuityLogEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var sceneId: Int32
    @NSManaged public var confidence: Double
    @NSManaged public var issuesJSON: String?
    @NSManaged public var passed: Bool
    @NSManaged public var timestamp: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastSyncedAt: Date?
}

extension ContinuityLogEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContinuityLogEntity> {
        return NSFetchRequest<ContinuityLogEntity>(entityName: "ContinuityLogEntity")
    }
}

// MARK: - Video Clip Entity

@objc(VideoClipEntity)
public class VideoClipEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var projectId: String?
    @NSManaged public var jobId: String?
    @NSManaged public var orderIndex: Int32
    @NSManaged public var status: String?
    @NSManaged public var localURL: String?
    @NSManaged public var remoteURL: String?
    @NSManaged public var duration: Double
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var lastSyncedAt: Date?
}

extension VideoClipEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoClipEntity> {
        return NSFetchRequest<VideoClipEntity>(entityName: "VideoClipEntity")
    }
}

/*
 MARK: - Core Data Model Setup Instructions
 
 Create a new .xcdatamodeld file named "DirectorStudio.xcdatamodeld" with these entities:
 
 1. SceneDraftEntity
    - id: UUID
    - projectId: String
    - orderIndex: Integer 32
    - promptText: String
    - duration: Double
    - sceneType: String (Optional)
    - shotType: String (Optional)
    - createdAt: Date
    - updatedAt: Date
    - needsSync: Boolean
    - lastSyncedAt: Date (Optional)
 
 2. ScreenplayEntity
    - id: UUID
    - title: String
    - content: String
    - version: Integer 32
    - createdAt: Date
    - updatedAt: Date
    - needsSync: Boolean
    - lastSyncedAt: Date (Optional)
    - sections: Relationship (To Many) -> ScreenplaySectionEntity
 
 3. ScreenplaySectionEntity
    - id: UUID
    - heading: String
    - content: String
    - orderIndex: Integer 32
    - screenplay: Relationship (To One) -> ScreenplayEntity (Delete Rule: Cascade)
 
 4. ContinuityLogEntity
    - id: UUID
    - sceneId: Integer 32
    - confidence: Double
    - issuesJSON: String
    - passed: Boolean
    - timestamp: Date
    - needsSync: Boolean
    - lastSyncedAt: Date (Optional)
 
 5. VideoClipEntity
    - id: UUID
    - projectId: String
    - jobId: String (Optional)
    - orderIndex: Integer 32
    - status: String
    - localURL: String (Optional)
    - remoteURL: String (Optional)
    - duration: Double
    - thumbnailData: Binary Data (Optional)
    - createdAt: Date
    - updatedAt: Date
    - needsSync: Boolean
    - lastSyncedAt: Date (Optional)
 
 All entities should have:
 - Codegen: Manual/None (since we define extensions above)
 - Module: DirectorStudio
 */
