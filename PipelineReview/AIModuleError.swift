import Foundation

// MARK: - AI Module Error Types
enum AIModuleError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case parsingError(String)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API key is missing or invalid"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .parsingError(let msg):
            return "Failed to parse response: \(msg)"
        case .emptyResponse:
            return "Received empty response from API"
        }
    }
}
