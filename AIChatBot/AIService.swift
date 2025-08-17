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
        
        // Simulate AI response (replace with actual API call)
        let response = await generateAIResponse(for: message)
        
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
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock responses based on input
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("hello") || lowercasedMessage.contains("hi") {
            return "Hello! It's great to meet you. How can I assist you today?"
        } else if lowercasedMessage.contains("weather") {
            return "I'd be happy to help with weather information, but I don't have access to real-time weather data. You might want to check a weather app or website for current conditions."
        } else if lowercasedMessage.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))."
        } else if lowercasedMessage.contains("help") {
            return "I can help you with various tasks like answering questions, providing information, or just having a conversation. What would you like to know?"
        } else if lowercasedMessage.contains("joke") {
            return "Why don't scientists trust atoms? Because they make up everything! 😄"
        } else {
            return "That's an interesting question! I'm here to help. Could you provide more details about what you'd like to know?"
        }
    }
    
    func startNewChat() {
        chatHistory.removeAll()
        setupDefaultChat()
    }
    
    func getRecentChats() -> [ChatSession] {
        // In a real app, this would load from persistent storage
        let recentChats = [
            ChatSession(
                id: UUID(),
                title: "General Chat",
                lastMessage: chatHistory.last?.content ?? "No messages yet",
                timestamp: Date()
            ),
            ChatSession(
                id: UUID(),
                title: "Weather Discussion",
                lastMessage: "About weather conditions",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ChatSession(
                id: UUID(),
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

enum AIError: Error, LocalizedError {
    case notImplemented
    case invalidAPIKey
    case networkError
    case rateLimitExceeded
    
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
        }
    }
} 