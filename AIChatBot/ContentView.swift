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
                    
                    // Voice permission status
                    if !voiceManager.hasPermission {
                        Button("Enable Voice") {
                            voiceManager.requestPermissions()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    
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
                                
                                // Voice input indicator
                                if voiceManager.isRecording {
                                    HStack {
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                        Text("Listening... \(voiceInput)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("listening")
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
                                        // Auto-speak AI responses
                                        if lastMessage.isFromAI && lastMessage.content != lastSpokenMessage {
                                            voiceManager.speak(lastMessage.content)
                                            lastSpokenMessage = lastMessage.content
                                        }
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
                        .onChange(of: voiceManager.isRecording) { isRecording in
                            if isRecording {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("listening", anchor: .bottom)
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

                // Voice control panel
                if voiceManager.hasPermission {
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            // Voice record button
                            Button(action: {
                                if voiceManager.isRecording {
                                    voiceManager.stopRecording()
                                } else {
                                    startVoiceInput()
                                }
                            }) {
                                Image(systemName: voiceManager.isRecording ? "mic.fill" : "mic")
                                    .font(.title2)
                                    .foregroundColor(voiceManager.isRecording ? .red : .blue)
                            }
                            .disabled(aiService.isProcessing)

                            // Stop speaking button
                            Button(action: {
                                voiceManager.stopSpeaking()
                            }) {
                                Image(systemName: "speaker.slash")
                                    .font(.title2)
                                    .foregroundColor(voiceManager.isSpeaking ? .red : .gray)
                            }
                            .disabled(!voiceManager.isSpeaking)

                            // New chat button
                            Button(action: {
                                aiService.startNewChat()
                                voiceManager.stopSpeaking()
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(voiceStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }

                // Input area
                VStack(spacing: 12) {
                    TextField("Type your message or use voice...", text: $messageText)
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
        .onAppear {
            voiceManager.requestPermissions()
            // Start always-on voice command listening
            startAlwaysOnVoiceCommands()
        }
    }
    
    private var voiceStatusText: String {
        if voiceManager.isRecording {
            return "🎤 Listening..."
        } else if voiceManager.isSpeaking {
            return "🔊 Speaking..."
        } else if aiService.isProcessing {
            return "💭 Thinking..."
        } else if voiceManager.isListeningForCommands {
            return "👂 Listening for commands..."
        } else {
            return "Tap 🎤 to speak"
        }
    }
    
    private func startAlwaysOnVoiceCommands() {
        print("🎤 Starting always-on voice commands...")
        voiceManager.startListeningForCommands { command in
            print("🎤 Always-on voice command received: '\(command)'")
            processVoiceInput(command)
            
            // Only restart command listening if we're not starting regular recording
            if !command.lowercased().contains("start ai") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.restartAlwaysOnVoiceCommands()
                }
            }
        }
    }
    
    private func restartAlwaysOnVoiceCommands() {
        print("🎤 Restarting always-on voice commands...")
        // Use a fresh start instead of restart to avoid any state issues
        startAlwaysOnVoiceCommands()
        print("🎤 Command listening restart initiated")
    }

    private func startVoiceInput() {
        print("🎤 startVoiceInput() called")
        voiceInput = ""
        
        // Stop command listening when starting regular recording
        voiceManager.stopListeningForCommands()
        
        voiceManager.startRecording { transcription in
            DispatchQueue.main.async {
                print("🎤 Voice transcription: '\(transcription)'")
                voiceInput = transcription
            }
        }
        
        // Auto-stop recording after 5 seconds of silence
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("🎤 Auto-stop check: isRecording=\(voiceManager.isRecording), voiceInput='\(voiceInput)'")
            if voiceManager.isRecording && !voiceInput.isEmpty {
                print("🎤 Auto-stopping recording and processing input")
                voiceManager.stopRecording()
                processVoiceInput(voiceInput)
                
                // Restart command listening after processing voice input
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🎤 Restarting command listening after voice input processing")
                    self.restartAlwaysOnVoiceCommands()
                }
            } else if voiceManager.isRecording {
                // If recording but no input, just stop and restart command listening
                print("🎤 Auto-stopping recording with no input")
                voiceManager.stopRecording()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🎤 Restarting command listening after no input")
                    self.restartAlwaysOnVoiceCommands()
                }
            }
        }
    }

    private func processVoiceInput(_ input: String) {
        print("🎤 Processing voice input: '\(input)'")
        // Check for voice commands first
        if let command = voiceManager.processVoiceCommand(input) {
            print("🎤 Recognized voice command: \(command)")
            handleVoiceCommand(command)
        } else if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Treat as regular message
            print("🎤 Treating as regular message")
            messageText = input
            sendMessage()
        }
    }

    private func handleVoiceCommand(_ command: VoiceCommand) {
        print("🎤 Voice command received: \(command)")
        switch command {
        case .stop:
            voiceManager.stopSpeaking()
        case .continue:
            voiceManager.continueSpeaking()
        case .`repeat`:
            if let lastMessage = aiService.chatHistory.last, lastMessage.isFromAI {
                voiceManager.speak(lastMessage.content)
            }
        case .newChat:
            aiService.startNewChat()
            voiceManager.stopSpeaking()
        case .startAI:
            print("🎤 Starting voice input...")
            startVoiceInput()
        case .stopAI:
            aiService.stopAIProcessing()
            voiceManager.speak("AI processing stopped")
        case .help:
            let helpMessage = "I can respond to voice commands like 'stop', 'repeat', 'new chat', 'start AI' to begin voice recording, 'stop AI' to stop processing, or you can ask me questions directly."
            voiceManager.speak(helpMessage)
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