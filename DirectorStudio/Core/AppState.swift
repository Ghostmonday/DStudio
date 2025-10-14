import Foundation
import SwiftUI

// MARK: - App State with Persistence
class AppState: ObservableObject {
    @Published var currentProject: Project?
    @Published var projects: [Project] = []
    
    private let projectsKey = "savedProjects"
    
    init() {
        loadProjects()
        
        // Load demo project on first launch for "Wow" moment
        if projects.isEmpty {
            projects.append(Project.demoProject)
            currentProject = projects.first
            saveProjects()
        }
    }
    
    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: projectsKey)
        }
    }
    
    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if currentProject?.id == project.id {
            currentProject = projects.first
        }
        saveProjects()
    }
}
