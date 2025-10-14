import Foundation

// MARK: - Configuration
struct DeepSeekConfig {
    static let baseURL = "https://api.deepseek.com/v1/chat/completions"
    static let model = "deepseek-chat"
    static var apiKey: String {
        // TODO: Replace with secure keychain storage in production
        return UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
    }
}
