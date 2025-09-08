import Foundation

struct Config {
    static let perplexityBaseURL = "https://api.perplexity.ai"
    
    // MARK: - User Preferences
    
    /// Gets the preferred number of sentences for AI responses
    static var responseSentenceCount: Int {
        let count = UserDefaults.standard.integer(forKey: "response_sentence_count")
        return count > 0 ? count : 2 // Default to 2 sentences
    }
    
    /// Sets the preferred number of sentences for AI responses
    static func setResponseSentenceCount(_ count: Int) {
        print("📝 Setting response sentence count to: \(count)")
        UserDefaults.standard.set(count, forKey: "response_sentence_count")
        UserDefaults.standard.synchronize() // Force immediate save
        
        // Post notification for immediate updates
        NotificationCenter.default.post(
            name: NSNotification.Name("SentenceCountChanged"), 
            object: nil, 
            userInfo: ["count": count]
        )
    }
    
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
