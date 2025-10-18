import Foundation
import os.log

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
    // BugScan: token tracker noop touch for analysis
    
    private let logger = Logger(subsystem: "net.neuraldraft.DirectorStudio", category: "DeepSeekService")
    
    func sendRequest(systemPrompt: String, userPrompt: String, temperature: Double = 0.7, maxTokens: Int? = 2000) async throws -> String {
        
        logger.info("🚀 Starting DeepSeek API request")
        logger.info("📝 System prompt: \(systemPrompt.prefix(50))...")
        logger.info("👤 User prompt: \(userPrompt.prefix(50))...")
        
        let apiKey = DeepSeekConfig.apiKey
        logger.info("🔑 API key length: \(apiKey.count)")
        logger.info("🔑 API key prefix: \(String(apiKey.prefix(10)))...")
        
        guard !apiKey.isEmpty else {
            logger.error("❌ API key is empty")
            throw AIModuleError.invalidAPIKey
        }
        
        guard let url = URL(string: DeepSeekConfig.baseURL) else {
            logger.error("❌ Invalid URL: \(DeepSeekConfig.baseURL)")
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
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        logger.info("🌐 Sending request to DeepSeek API...")
        logger.info("🔗 URL: \(url)")
        logger.info("🔑 Authorization header: Bearer \(String(apiKey.prefix(10)))...")
        logger.info("📦 Request body size: \(urlRequest.httpBody?.count ?? 0) bytes")
        
        if let bodyData = urlRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.info("📋 Request body: \(bodyString)")
        }
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Invalid response type")
            throw AIModuleError.networkError("Invalid response type")
        }
        
        logger.info("📡 HTTP Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("❌ API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw AIModuleError.networkError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let decoder = JSONDecoder()
        let deepSeekResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        
        guard let content = deepSeekResponse.choices.first?.message.content, !content.isEmpty else {
            logger.error("❌ Empty response from API")
            throw AIModuleError.emptyResponse
        }
        
        logger.info("✅ Successfully received response: \(content.prefix(100))...")
        return content
    }
}
