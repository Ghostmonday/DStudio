import Foundation
import os.log

// MARK: - Secure Secrets Manager
class SecretsManager {
    
    // MARK: - Logging
    private static let logger = Logger(subsystem: "net.neuraldraft.DirectorStudio", category: "SecretsManager")
    
    // MARK: - Build Configuration Keys
    private static let deepSeekKeyName = "DEEPSEEK_API_KEY"
    
    // MARK: - API Key Retrieval
    static var deepSeekAPIKey: String {
        // Method 1: Try build settings first (from .xcconfig)
        logger.info("🔍 Checking for API key in Info.plist...")
        if let buildKey = Bundle.main.object(forInfoDictionaryKey: deepSeekKeyName) as? String,
           !buildKey.isEmpty && buildKey != "YOUR_DEEPSEEK_API_KEY_HERE" {
            logger.info("✅ Found API key in Info.plist: \(String(buildKey.prefix(10)))...")
            return buildKey
        }
        logger.error("❌ No API key found in Info.plist")
        
        // Method 1.5: Try build settings directly
        if let buildSettingsKey = Bundle.main.object(forInfoDictionaryKey: "DEEPSEEK_API_KEY") as? String,
           !buildSettingsKey.isEmpty && buildSettingsKey != "YOUR_DEEPSEEK_API_KEY_HERE" {
            logger.info("✅ Found API key in build settings: \(String(buildSettingsKey.prefix(10)))...")
            return buildSettingsKey
        }
        logger.error("❌ No API key found in build settings")
        
        // Method 2: Fallback to environment variable (for development)
        if let envKey = ProcessInfo.processInfo.environment[deepSeekKeyName],
           !envKey.isEmpty {
            return envKey
        }
        
        // Method 3: Development fallback (should be replaced in production)
        #if DEBUG
        if let devKey = Bundle.main.object(forInfoDictionaryKey: "DeepSeekAPIKey") as? String,
           !devKey.isEmpty {
            print("⚠️ Using development API key from Info.plist")
            return devKey
        }
        #endif
        
        // No key found
        print("❌ DeepSeek API key not configured")
        print("📝 Configuration required:")
        print("   1. Create Secrets.xcconfig with DEEPSEEK_API_KEY")
        print("   2. Add Secrets.xcconfig to Build Settings")
        print("   3. Ensure Secrets.xcconfig is in .gitignore")
        return ""
    }
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        logger.info("🔍 Starting API key validation...")
        let apiKey = deepSeekAPIKey
        let hasKey = !apiKey.isEmpty
        if hasKey {
            logger.info("✅ DeepSeek API key configured securely: \(String(apiKey.prefix(10)))...")
        } else {
            logger.error("❌ DeepSeek API key not configured")
        }
        return hasKey
    }
    
    // MARK: - Security Check
    static func performSecurityCheck() {
        #if DEBUG
        // Development security warnings
        if deepSeekAPIKey.contains("YOUR_DEEPSEEK_API_KEY_HERE") {
            print("⚠️ SECURITY WARNING: Using placeholder API key")
        }
        
        if deepSeekAPIKey.contains("sk-") && deepSeekAPIKey.count < 20 {
            print("⚠️ SECURITY WARNING: API key appears to be invalid")
        }
        #endif
    }
}
