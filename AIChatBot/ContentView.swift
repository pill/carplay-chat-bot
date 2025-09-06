import SwiftUI

struct ContentView: View {
    @StateObject private var aiService = AIService()
    @StateObject private var voiceManager = VoiceManager()
    @State private var messageText = ""
    @State private var showingSettings = false
    @State private var isUserScrolling = false
    @State private var showScrollToBottom = false
    @State private var lastSpokenMessage = ""
    @State private var voiceInput = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(spacing: 8) {
                        Text("AI Chat Bot")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Powered by \(aiService.currentProvider.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Chat messages
                ScrollViewReader { proxy in
                    ZStack {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(aiService.chatHistory) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
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
                                    .id("thinking")
                                }
                                
                                // Invisible spacer to ensure proper bottom padding
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding()
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                if let lastMessage = aiService.chatHistory.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                } else {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: aiService.chatHistory.count) { _ in
                            if !isUserScrolling {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    if let lastMessage = aiService.chatHistory.last {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    } else {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: aiService.isProcessing) { isProcessing in
                            if isProcessing && !isUserScrolling {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("thinking", anchor: .bottom)
                                }
                            } else if !isProcessing && !isUserScrolling {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    if let lastMessage = aiService.chatHistory.last {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    } else {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                if let lastMessage = aiService.chatHistory.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                } else {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { _ in
                                    isUserScrolling = true
                                    showScrollToBottom = true
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        isUserScrolling = false
                                        showScrollToBottom = false
                                    }
                                }
                        )
                        
                        // Scroll to bottom button
                        if showScrollToBottom {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            if let lastMessage = aiService.chatHistory.last {
                                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                            } else {
                                                proxy.scrollTo("bottom", anchor: .bottom)
                                            }
                                        }
                                        showScrollToBottom = false
                                        isUserScrolling = false
                                    }) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(radius: 2)
                                    }
                                    .padding(.trailing)
                                    .padding(.bottom, 10)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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