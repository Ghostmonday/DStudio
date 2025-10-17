import Foundation

// MARK: - Configuration
struct DeepSeekConfig {
    static let baseURL = "https://api.deepseek.com/chat/completions"
    static let model = "deepseek-chat"
    
    // MARK: - Secure API Key Management
    static var apiKey: String {
        return SecretsManager.deepSeekAPIKey
    }
    
    static func hasValidAPIKey() -> Bool {
        return !apiKey.isEmpty
    }
    
    // MARK: - Configuration Validation
    static func validateConfiguration() -> Bool {
        let isValid = SecretsManager.validateConfiguration()
        SecretsManager.performSecurityCheck()
        return isValid
    }
}
