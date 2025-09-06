import Foundation

struct Config {
    static let perplexityBaseURL = "https://api.perplexity.ai"
    
    // MARK: - Secure API Key Management
    
    /// Retrieves the Perplexity API key from secure storage
    static var perplexityAPIKey: String? {
        return KeychainManager.shared.getAPIKey(for: KeychainManager.Provider.perplexity)
    }
    
    /// Sets up the initial API key in secure storage (call once during app setup)
    static func setupPerplexityAPIKey(_ apiKey: String) -> Bool {
        return KeychainManager.shared.storeAPIKey(apiKey, for: KeychainManager.Provider.perplexity)
    }
    
    /// Checks if API key is properly configured
    static var isPerplexityConfigured: Bool {
        return KeychainManager.shared.hasAPIKey(for: KeychainManager.Provider.perplexity)
    }
    
    /// Removes the API key from secure storage
    static func removePerplexityAPIKey() -> Bool {
        return KeychainManager.shared.deleteAPIKey(for: KeychainManager.Provider.perplexity)
    }
}
