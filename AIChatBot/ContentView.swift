import SwiftUI

struct ContentView: View {
    @StateObject private var aiService = AIService()
    @StateObject private var voiceManager = VoiceManager()
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("AI Chat Bot")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewChat = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 2)
                
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(aiService.chatHistory, id: \.id) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Input area
                VStack(spacing: 12) {
                    HStack {
                        TextField("Type your message...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isRecording)
                        
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(isRecording ? .red : .blue)
                        }
                    }
                    
                    HStack {
                        Button("Send") {
                            sendMessage()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(messageText.isEmpty || isRecording)
                        
                        Spacer()
                        
                        Button("Repeat Last") {
                            repeatLastAnswer()
                        }
                        .buttonStyle(.bordered)
                        .disabled(aiService.chatHistory.isEmpty)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
        }
        .alert("New Chat", isPresented: $showingNewChat) {
            Button("Start New Chat") {
                aiService.startNewChat()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Start a new conversation? This will clear the current chat history.")
        }
        .onAppear {
            voiceManager.requestPermissions()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        
        Task {
            await aiService.sendMessage(userMessage)
        }
    }
    
    private func startRecording() {
        isRecording = true
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.messageText = transcribedText
                self?.isRecording = false
            }
        }
    }
    
    private func stopRecording() {
        voiceManager.stopRecording()
        isRecording = false
    }
    
    private func repeatLastAnswer() {
        guard let lastMessage = aiService.chatHistory.last,
              lastMessage.isFromAI else { return }
        
        voiceManager.speak(lastMessage.content)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromAI {
                Spacer()
            }
            
            VStack(alignment: message.isFromAI ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(message.isFromAI ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromAI ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromAI {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
} 