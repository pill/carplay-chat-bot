import Foundation
import Combine

class AIService: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var currentProvider: AIProvider = .claude
    
    private var cancellables = Set<AnyCancellable>()
    private var apiKey: String?
    
    enum AIProvider: String, CaseIterable {
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
        // In a real app, this would load from Keychain or secure storage
        // For demo purposes, we'll use a placeholder
        apiKey = UserDefaults.standard.string(forKey: "AI_API_KEY")
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
    
    private func callPerplexityAPI(message: String) async throws -> String {
        let url = URL(string: "\(Config.perplexityBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.perplexityAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = PerplexityRequest(
            model: "sonar",
            messages: [
                PerplexityMessage(role: "user", content: message)
            ],
            max_tokens: 1000,
            temperature: 0.7,
            stream: false
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            print("Making Perplexity API request to: \(url)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.networkError
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Perplexity API Error (\(httpResponse.statusCode)): \(errorString)")
                
                switch httpResponse.statusCode {
                case 500, 502, 503, 504:
                    throw AIError.serverError
                case 429:
                    throw AIError.rateLimitExceeded
                default:
                    throw AIError.networkError
                }
            }
            
            let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
            
            return perplexityResponse.choices.first?.message.content ?? "I couldn't generate a response. Please try again."
            
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError
        }
    }
    
    private func generateAIResponse(for message: String) async -> String {
        // Fallback method - kept for backward compatibility
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return "I'm having trouble connecting to the AI service. Please try again."
    }
    
    func startNewChat() {
        chatHistory.removeAll()
        setupDefaultChat()
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
    
    // MARK: - Real API Integration Methods (to be implemented)
    
    private func callClaudeAPI(message: String) async throws -> String {
        // Implement Claude API call
        // This would use the actual Claude API with proper authentication
        throw AIError.notImplemented
    }
    
    private func callGPTAPI(message: String) async throws -> String {
        // Implement GPT API call
        // This would use the actual OpenAI API with proper authentication
        throw AIError.notImplemented
    }
    
    private func callGeminiAPI(message: String) async throws -> String {
        // Implement Gemini API call
        // This would use the actual Google Gemini API with proper authentication
        throw AIError.notImplemented
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