import Foundation
import SwiftUI
import Combine

// MARK: - App State Manager

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentProject: ProjectModel?
    @Published var projects: [ProjectModel] = []
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var processingStatus: String = ""
    @Published var credits: Int = 5
    @Published var selectedTab: Int = 0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    init() {
        loadPersistedData()
    }
    
    // MARK: - Project Management
    
    func createProject(title: String, story: String) {
        let project = ProjectModel(
            title: title,
            story: story
        )
        
        currentProject = project
        projects.append(project)
        saveProjects()
    }
    
    func updateProject(_ project: ProjectModel) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            return
        }
        
        projects[index] = project
        
        if currentProject?.id == project.id {
            currentProject = project
        }
        
        saveProjects()
    }
    
    func deleteProject(_ project: ProjectModel) {
        projects.removeAll { $0.id == project.id }
        
        if currentProject?.id == project.id {
            currentProject = nil
        }
        
        saveProjects()
    }
    
    func selectProject(_ project: ProjectModel) {
        currentProject = project
    }
    
    // MARK: - Segment Management
    
    func updateSegments(_ segments: [PromptSegment]) {
        guard var project = currentProject else { return }
        
        project.segments = segments
        project.updatedAt = Date()
        
        updateProject(project)
    }
    
    func updateSegment(_ segment: PromptSegment) {
        guard var project = currentProject else { return }
        
        if let index = project.segments.firstIndex(where: { $0.id == segment.id }) {
            project.segments[index] = segment
            project.updatedAt = Date()
            updateProject(project)
        }
    }
    
    // MARK: - Analysis Management
    
    func updateAnalysis(_ analysis: StoryAnalysis) {
        guard var project = currentProject else { return }
        
        project.analysis = analysis
        project.updatedAt = Date()
        
        updateProject(project)
    }
    
    // MARK: - Processing State
    
    func startProcessing(status: String = "Processing...") {
        isProcessing = true
        processingProgress = 0.0
        processingStatus = status
    }
    
    func updateProgress(_ progress: Double, status: String? = nil) {
        processingProgress = progress
        if let status = status {
            processingStatus = status
        }
    }
    
    func finishProcessing() {
        isProcessing = false
        processingProgress = 1.0
        processingStatus = "Complete"
    }
    
    func failProcessing(error: String) {
        isProcessing = false
        processingProgress = 0.0
        processingStatus = "Failed: \(error)"
    }
    
    // MARK: - Credits Management
    
    func deductCredits(_ amount: Int) -> Bool {
        guard credits >= amount else {
            return false
        }
        
        credits -= amount
        saveCredits()
        return true
    }
    
    func addCredits(_ amount: Int) {
        credits += amount
        saveCredits()
    }
    
    func hasEnoughCredits(for amount: Int) -> Bool {
        return credits >= amount
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() {
        // Load projects
        if let data = userDefaults.data(forKey: "DirectorStudio.projects"),
           let decoded = try? JSONDecoder().decode([ProjectModel].self, from: data) {
            projects = decoded
        }
        
        // Load credits
        let savedCredits = userDefaults.integer(forKey: "DirectorStudio.credits")
        if savedCredits > 0 {
            credits = savedCredits
        }
        
        // Load current project ID
        if let projectIdString = userDefaults.string(forKey: "DirectorStudio.currentProjectId"),
           let projectId = UUID(uuidString: projectIdString),
           let project = projects.first(where: { $0.id == projectId }) {
            currentProject = project
        }
    }
    
    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: "DirectorStudio.projects")
        }
        
        // Save current project ID
        if let currentProject = currentProject {
            userDefaults.set(currentProject.id.uuidString, forKey: "DirectorStudio.currentProjectId")
        } else {
            userDefaults.removeObject(forKey: "DirectorStudio.currentProjectId")
        }
    }
    
    private func saveCredits() {
        userDefaults.set(credits, forKey: "DirectorStudio.credits")
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        currentProject = nil
        projects = []
        credits = 5
        
        userDefaults.removeObject(forKey: "DirectorStudio.projects")
        userDefaults.removeObject(forKey: "DirectorStudio.currentProjectId")
        userDefaults.set(5, forKey: "DirectorStudio.credits")
    }
}
