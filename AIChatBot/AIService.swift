import Foundation
import Combine

class AIService: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var currentProvider: AIProvider = .perplexity
    
    private var cancellables = Set<AnyCancellable>()
    private var apiKey: String?
    
    enum AIProvider: String, CaseIterable {
        case perplexity = "Perplexity"
        case claude = "Claude"
        case gpt = "GPT"
        case gemini = "Gemini"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init() {
        loadAPIKey()
        setupDefaultChat()
    }
    
    private func loadAPIKey() {
        // Try to load API key from secure storage
        apiKey = Config.perplexityAPIKey
        
        // If no API key is found in secure storage, initialize it with the default one
        if apiKey == nil && !Config.isPerplexityConfigured {
            let defaultKey = "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"
            if Config.setupPerplexityAPIKey(defaultKey) {
                apiKey = defaultKey
                print("✅ API key successfully stored in Keychain")
            } else {
                print("❌ Failed to store API key in Keychain")
            }
        }
    }
    
    private func setupDefaultChat() {
        let welcomeMessage = ChatMessage(
            content: "Hello! I'm your AI assistant. How can I help you today?",
            isFromAI: true,
            timestamp: Date()
        )
        chatHistory.append(welcomeMessage)
    }
    
    func sendMessage(_ message: String) async {
        let userMessage = ChatMessage(
            content: message,
            isFromAI: false,
            timestamp: Date()
        )
        
        await MainActor.run {
            chatHistory.append(userMessage)
            isProcessing = true
        }
        
        // Call Perplexity API
        let response: String
        do {
            response = try await callPerplexityAPI(message: message)
        } catch {
            response = "I apologize, but I encountered an error: \(error.localizedDescription). Please try again."
        }
        
        let aiMessage = ChatMessage(
            content: response,
            isFromAI: true,
            timestamp: Date()
        )
        
        await MainActor.run {
            chatHistory.append(aiMessage)
            isProcessing = false
        }
    }
    
    private func generateAIResponse(for message: String) async -> String {
        do {
            switch currentProvider {
            case .perplexity:
                return try await callPerplexityAPI(message: message)
            case .claude:
                return try await callClaudeAPI(message: message)
            case .gpt:
                return try await callGPTAPI(message: message)
            case .gemini:
                return try await callGeminiAPI(message: message)
            }
        } catch {
            return "I apologize, but I encountered an error: \(error.localizedDescription). Please try again."
        }
    }
    
    func startNewChat() {
        chatHistory.removeAll()
        setupDefaultChat()
    }
    
    func startAIProcessing() {
        isProcessing = true
    }
    
    func stopAIProcessing() {
        isProcessing = false
    }
    
    func getRecentChats() -> [ChatSession] {
        // In a real app, this would load from persistent storage
        let recentChats = [
            ChatSession(
                title: "General Chat",
                lastMessage: chatHistory.last?.content ?? "No messages yet",
                timestamp: Date()
            ),
            ChatSession(
                title: "Weather Discussion",
                lastMessage: "About weather conditions",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ChatSession(
                title: "Help Session",
                lastMessage: "Getting assistance",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
        
        return recentChats
    }
    
    func setProvider(_ provider: AIProvider) {
        currentProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: "AI_PROVIDER")
    }
    
    func setAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "AI_API_KEY")
    }
    
    // MARK: - Real API Integration Methods
    
    private func callPerplexityAPI(message: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw AIError.invalidAPIKey
        }
        
        let url = URL(string: "\(Config.perplexityBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = PerplexityRequest(
            model: "sonar",
            messages: [
                PerplexityMessage(role: "system", content: "Please provide concise, helpful answers in exactly 2 sentences or less. Be direct and to the point. NEVER include any footnotes, citations, reference numbers, brackets with numbers like [1], [2], or any source references in your response. Only provide the direct answer."),
                PerplexityMessage(role: "user", content: message)
            ],
            max_tokens: 300,
            temperature: 0.7,
            stream: false
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Debug logging
            print("Making Perplexity API request to: \(url)")
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Failed to encode")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.networkError
            }
            
            if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                // Log the response for debugging
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Perplexity API Error (\(httpResponse.statusCode)): \(errorString)")
                
                // Handle specific error codes
                switch httpResponse.statusCode {
                case 500, 502, 503, 504:
                    throw AIError.serverError
                case 429:
                    throw AIError.rateLimitExceeded
                case 401, 403:
                    throw AIError.invalidAPIKey
                default:
                    throw AIError.networkError
                }
            }
            
            let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
            
            let rawContent = perplexityResponse.choices.first?.message.content ?? "I couldn't generate a response. Please try again."
            
            // Clean up any citation numbers that might have slipped through
            return cleanupCitations(rawContent)
            
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError
        }
    }
    
    private func callClaudeAPI(message: String) async throws -> String {
        // Implement Claude API call
        // This would use the actual Claude API with proper authentication
        // When implemented, make sure to apply cleanupCitations() to the response
        throw AIError.notImplemented
    }
    
    private func callGPTAPI(message: String) async throws -> String {
        // Implement GPT API call
        // This would use the actual OpenAI API with proper authentication
        // When implemented, make sure to apply cleanupCitations() to the response
        throw AIError.notImplemented
    }
    
    private func callGeminiAPI(message: String) async throws -> String {
        // Implement Gemini API call
        // This would use the actual Google Gemini API with proper authentication
        // When implemented, make sure to apply cleanupCitations() to the response
        throw AIError.notImplemented
    }
    
    // MARK: - Response Cleanup
    
    private func cleanupCitations(_ text: String) -> String {
        var cleanedText = text
        
        // Remove citation numbers in brackets like [1], [2], [3], etc.
        cleanedText = cleanedText.replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
        
        // Remove citation numbers with parentheses like (1), (2), (3), etc.
        cleanedText = cleanedText.replacingOccurrences(of: "\\(\\d+\\)", with: "", options: .regularExpression)
        
        // Remove superscript numbers that might appear as citations
        cleanedText = cleanedText.replacingOccurrences(of: "\\^\\d+", with: "", options: .regularExpression)
        
        // Remove any trailing citation markers at the end of sentences
        cleanedText = cleanedText.replacingOccurrences(of: "\\s*\\[\\d+\\]\\s*", with: " ", options: .regularExpression)
        
        // Clean up any double spaces that might have been created
        cleanedText = cleanedText.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // Trim whitespace
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
}

// MARK: - Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromAI: Bool
    let timestamp: Date
}

struct ChatSession: Identifiable {
    let id = UUID()
    let title: String
    let lastMessage: String
    let timestamp: Date
}

enum AIError: Error, LocalizedError {
    case notImplemented
    case invalidAPIKey
    case networkError
    case rateLimitExceeded
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError:
            return "Network error. Please check your connection."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "The AI service is temporarily unavailable. Please try again later."
        }
    }
}

// MARK: - Perplexity API Models

struct PerplexityRequest: Codable {
    let model: String
    let messages: [PerplexityMessage]
    let max_tokens: Int
    let temperature: Double
    let stream: Bool
}

struct PerplexityMessage: Codable {
    let role: String
    let content: String
}

struct PerplexityResponse: Codable {
    let choices: [PerplexityChoice]
}

struct PerplexityChoice: Codable {
    let message: PerplexityMessage
} 