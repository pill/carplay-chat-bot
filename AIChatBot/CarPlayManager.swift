import Foundation
import CarPlay
import Intents

class CarPlayManager: NSObject {
    static let shared = CarPlayManager()
    
    var interfaceController: CPInterfaceController?
    private var aiService = AIService()
    private var voiceManager = VoiceManager()
    
    private override init() {
        super.init()
    }
    
    func setup() {
        // Register for CarPlay connection notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carPlayDidConnect),
            name: .CPConnectionStatusDidChange,
            object: nil
        )
    }
    
    @objc private func carPlayDidConnect(_ notification: Notification) {
        // Handle CarPlay connection status changes
    }
    
    func setupCarPlayInterface() {
        guard let interfaceController = interfaceController else { return }
        
        // Create the main template
        let template = createMainTemplate()
        interfaceController.setRootTemplate(template, animated: true)
    }
    
    private func createMainTemplate() -> CPTemplate {
        // Create main menu items
        let newChatItem = CPListItem(
            text: "New Chat",
            detailText: "Start a new conversation",
            image: UIImage(systemName: "plus.circle")
        ) { [weak self] _, completion in
            self?.startNewChat(completion: completion)
        }
        
        let recentChatsItem = CPListItem(
            text: "Recent Chats",
            detailText: "View recent conversations",
            image: UIImage(systemName: "clock")
        ) { [weak self] _, completion in
            self?.showRecentChats(completion: completion)
        }
        
        let voiceChatItem = CPListItem(
            text: "Voice Chat",
            detailText: "Start voice conversation",
            image: UIImage(systemName: "mic.circle")
        ) { [weak self] _, completion in
            self?.startVoiceChat(completion: completion)
        }
        
        let settingsItem = CPListItem(
            text: "Settings",
            detailText: "Configure AI service",
            image: UIImage(systemName: "gear")
        ) { [weak self] _, completion in
            self?.showSettings(completion: completion)
        }
        
        let listTemplate = CPListTemplate(
            title: "AI Chat Bot",
            sections: [
                CPListSection(items: [newChatItem, recentChatsItem, voiceChatItem, settingsItem])
            ]
        )
        
        return listTemplate
    }
    
    private func startNewChat(completion: @escaping () -> Void) {
        aiService.startNewChat()
        
        let chatTemplate = createChatTemplate()
        interfaceController?.pushTemplate(chatTemplate, animated: true)
        completion()
    }
    
    private func showRecentChats(completion: @escaping () -> Void) {
        let recentChats = aiService.getRecentChats()
        let items = recentChats.map { chat in
            CPListItem(
                text: chat.title,
                detailText: chat.lastMessage,
                image: UIImage(systemName: "message")
            ) { [weak self] _, completion in
                self?.openChat(chat, completion: completion)
            }
        }
        
        let template = CPListTemplate(
            title: "Recent Chats",
            sections: [CPListSection(items: items)]
        )
        
        interfaceController?.pushTemplate(template, animated: true)
        completion()
    }
    
    private func startVoiceChat(completion: @escaping () -> Void) {
        let voiceTemplate = createVoiceChatTemplate()
        interfaceController?.pushTemplate(voiceTemplate, animated: true)
        completion()
    }
    
    private func showSettings(completion: @escaping () -> Void) {
        let settingsItems = [
            CPListItem(
                text: "AI Service",
                detailText: "Configure AI provider",
                image: UIImage(systemName: "brain")
            ) { _, completion in
                // Handle AI service selection
                completion()
            },
            CPListItem(
                text: "Voice Settings",
                detailText: "Adjust voice preferences",
                image: UIImage(systemName: "speaker.wave.2")
            ) { _, completion in
                // Handle voice settings
                completion()
            }
        ]
        
        let template = CPListTemplate(
            title: "Settings",
            sections: [CPListSection(items: settingsItems)]
        )
        
        interfaceController?.pushTemplate(template, animated: true)
        completion()
    }
    
    private func createChatTemplate() -> CPTemplate {
        let inputField = CPTextButton(
            title: "Tap to speak or type...",
            textStyle: .normal
        ) { [weak self] in
            self?.showChatInput()
        }
        
        let sendButton = CPTextButton(
            title: "Send",
            textStyle: .confirm
        ) { [weak self] in
            self?.sendChatMessage()
        }
        
        let template = CPGridTemplate(
            title: "AI Chat",
            buttons: [
                CPGridButton(
                    titleVariants: ["New Message"],
                    subtitleVariants: ["Start typing or speaking"],
                    image: UIImage(systemName: "plus.circle")
                ) { [weak self] in
                    self?.showChatInput()
                },
                CPGridButton(
                    titleVariants: ["Voice Input"],
                    subtitleVariants: ["Use voice commands"],
                    image: UIImage(systemName: "mic.circle")
                ) { [weak self] in
                    self?.startVoiceInput()
                },
                CPGridButton(
                    titleVariants: ["Repeat Last"],
                    subtitleVariants: ["Hear last response"],
                    image: UIImage(systemName: "arrow.clockwise")
                ) { [weak self] in
                    self?.repeatLastResponse()
                }
            ]
        )
        
        return template
    }
    
    private func createVoiceChatTemplate() -> CPTemplate {
        let template = CPGridTemplate(
            title: "Voice Chat",
            buttons: [
                CPGridButton(
                    titleVariants: ["Start Recording"],
                    subtitleVariants: ["Begin voice input"],
                    image: UIImage(systemName: "mic.circle.fill")
                ) { [weak self] in
                    self?.startVoiceRecording()
                },
                CPGridButton(
                    titleVariants: ["Stop Recording"],
                    subtitleVariants: ["End voice input"],
                    image: UIImage(systemName: "stop.circle.fill")
                ) { [weak self] in
                    self?.stopVoiceRecording()
                }
            ]
        )
        
        return template
    }
    
    private func showChatInput() {
        // Show text input interface
        let alert = CPAlertTemplate(
            titleVariants: ["New Message"],
            actions: [
                CPAlertAction(title: "Cancel", style: .cancel),
                CPAlertAction(title: "Send", style: .default) { [weak self] in
                    self?.sendChatMessage()
                }
            ]
        )
        
        interfaceController?.presentTemplate(alert, animated: true)
    }
    
    private func startVoiceInput() {
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.handleVoiceInput(transcribedText)
            }
        }
    }
    
    private func startVoiceRecording() {
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.handleVoiceInput(transcribedText)
            }
        }
    }
    
    private func stopVoiceRecording() {
        voiceManager.stopRecording()
    }
    
    private func handleVoiceInput(_ text: String) {
        guard !text.isEmpty else { return }
        
        Task {
            await aiService.sendMessage(text)
            
            // Speak the AI response
            if let lastMessage = aiService.chatHistory.last,
               lastMessage.isFromAI {
                voiceManager.speak(lastMessage.content)
            }
        }
    }
    
    private func sendChatMessage() {
        // Handle sending the current message
    }
    
    private func repeatLastResponse() {
        guard let lastMessage = aiService.chatHistory.last,
              lastMessage.isFromAI else { return }
        
        voiceManager.speak(lastMessage.content)
    }
    
    private func openChat(_ chat: ChatSession, completion: @escaping () -> Void) {
        // Open a specific chat session
        completion()
    }
}

// MARK: - Chat Session Model
struct ChatSession {
    let id: UUID
    let title: String
    let lastMessage: String
    let timestamp: Date
} 