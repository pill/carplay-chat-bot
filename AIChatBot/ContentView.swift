import SwiftUI

struct ContentView: View {
    @StateObject private var aiService = AIService()
    @State private var messageText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("AI Chat Bot")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Powered by \(aiService.currentProvider.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))

                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(aiService.chatHistory) { message in
                            MessageBubble(message: message)
                        }
                        
                        if aiService.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }

                // Input area
                VStack(spacing: 12) {
                    TextField("Type your message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send Message") {
                        sendMessage()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(messageText.isEmpty || aiService.isProcessing)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await aiService.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromAI {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 