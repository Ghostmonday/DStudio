import Foundation
import SwiftUI

// MARK: - Sora Service
@MainActor
class SoraService: ObservableObject {
    @Published var previewURL: URL?
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    
    private let apiKey: String
    private let baseURL = URL(string: "https://pollo.ai/api/platform")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Video Generation
    func generate(prompt: String, length: Int = 4) async throws -> String? {
        isGenerating = true
        generationProgress = "Starting generation..."
        
        defer {
            isGenerating = false
            generationProgress = ""
        }
        
        var req = URLRequest(url: baseURL.appendingPathComponent("generation/sora/sora-2-pro"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let body: [String: Any] = [
            "input": [
                "prompt": prompt,
                "length": length,
                "aspectRatio": "16:9"
            ]
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        generationProgress = "Sending request to Sora..."
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIModuleError.networkError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIModuleError.networkError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let resp = try JSONDecoder().decode(SoraResponse.self, from: data)
        generationProgress = "Generation started, polling for completion..."
        
        return resp.data.taskId
    }
    
    func checkStatus(taskId: String) async throws -> [String: Any] {
        var req = URLRequest(url: baseURL.appendingPathComponent("task/\(taskId)"))
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIModuleError.networkError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIModuleError.networkError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        return (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
    
    // MARK: - Polling with Progress Updates
    func pollForCompletion(taskId: String) async throws -> URL? {
        var attempts = 0
        let maxAttempts = 30 // 5 minutes max (10s intervals)
        
        while attempts < maxAttempts {
            attempts += 1
            generationProgress = "Checking status... (\(attempts)/\(maxAttempts))"
            
            let status = try await checkStatus(taskId: taskId)
            
            if let statusString = status["status"] as? String {
                switch statusString.lowercased() {
                case "completed", "success":
                    if let urlStr = (status["video_url"] as? String) ??
                                   (status["data"] as? [String: Any])?["video_url"] as? String,
                       let url = URL(string: urlStr) {
                        generationProgress = "Generation complete!"
                        return url
                    }
                case "failed", "error":
                    let errorMsg = status["error"] as? String ?? "Unknown error"
                    throw AIModuleError.networkError("Generation failed: \(errorMsg)")
                case "processing", "pending", "queued":
                    generationProgress = "Processing... (\(statusString))"
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    continue
                default:
                    generationProgress = "Status: \(statusString)"
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    continue
                }
            }
            
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        }
        
        throw AIModuleError.networkError("Generation timeout after \(maxAttempts) attempts")
    }
}

// MARK: - Sora Response Models
struct SoraResponse: Codable {
    let data: DataObj
    
    struct DataObj: Codable {
        let taskId: String
    }
}
