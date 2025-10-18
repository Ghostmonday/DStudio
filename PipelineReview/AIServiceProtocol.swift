import Foundation

// MARK: - Base Service Protocol
protocol AIServiceProtocol {
    func sendRequest(systemPrompt: String, userPrompt: String, temperature: Double, maxTokens: Int?) async throws -> String
}
