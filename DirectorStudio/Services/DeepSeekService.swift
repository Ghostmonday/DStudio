import Foundation

// MARK: - Common Models
struct DeepSeekRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct DeepSeekResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

// MARK: - DeepSeek Service Implementation
class DeepSeekService: AIServiceProtocol {
    
    func sendRequest(systemPrompt: String, userPrompt: String, temperature: Double = 0.7, maxTokens: Int? = 2000) async throws -> String {
        
        guard !DeepSeekConfig.apiKey.isEmpty else {
            throw AIModuleError.invalidAPIKey
        }
        
        guard let url = URL(string: DeepSeekConfig.baseURL) else {
            throw AIModuleError.networkError("Invalid URL")
        }
        
        let messages = [
            DeepSeekRequest.Message(role: "system", content: systemPrompt),
            DeepSeekRequest.Message(role: "user", content: userPrompt)
        ]
        
        let request = DeepSeekRequest(
            model: DeepSeekConfig.model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(DeepSeekConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIModuleError.networkError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIModuleError.networkError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let decoder = JSONDecoder()
        let deepSeekResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        
        guard let content = deepSeekResponse.choices.first?.message.content, !content.isEmpty else {
            throw AIModuleError.emptyResponse
        }
        
        return content
    }
}
