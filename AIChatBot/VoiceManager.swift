import Foundation
import Speech
import AVFoundation

class VoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var hasPermission = false
    @Published var isListeningForCommands = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Always-on voice command listening
    private var commandCompletion: ((String) -> Void)?
    private var isCommandListeningMode = false
    private var isAlwaysOnListening = false
    private var speechCompletion: (() -> Void)?
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // Helper method to safely remove audio tap
    private func safelyRemoveAudioTap() {
        if audioEngine.inputNode.numberOfInputs > 0 {
            do {
                audioEngine.inputNode.removeTap(onBus: 0)
                print("🎤 Audio tap removed successfully")
            } catch {
                print("🎤 Error removing audio tap: \(error)")
            }
        }
    }
    
    // Helper method to safely install audio tap
    private func safelyInstallAudioTap(format: AVAudioFormat, bufferSize: AVAudioFrameCount, block: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) -> Bool {
        // First remove any existing tap
        safelyRemoveAudioTap()
        
        do {
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format, block: block)
            print("🎤 Audio tap installed successfully")
            return true
        } catch {
            print("🎤 Error installing audio tap: \(error)")
            return false
        }
    }
    
    override init() {
        super.init()
        synthesizer.delegate = self
        checkPermissions()
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.hasPermission = status == .authorized
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasPermission = self?.hasPermission ?? false && granted
                }
            }
        }
    }
    
    private func checkPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        
        hasPermission = speechStatus == .authorized && audioStatus == .granted
    }
    
    func startRecording(completion: @escaping (String) -> Void) {
        print("🎤 VoiceManager.startRecording() called")
        guard hasPermission else {
            print("🎤 Speech recognition permission not granted")
            return
        }
        
        print("🎤 Starting voice recording...")
        // Stop any existing recording and command listening
        stopRecording()
        stopListeningForCommands()
        
        // Wait a bit for the speech recognition service to reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startRecordingInternal(completion: completion)
        }
    }
    
    private func startRecordingInternal(completion: @escaping (String) -> Void) {
        print("🎤 Starting internal voice recording...")
        isCommandListeningMode = false
        isAlwaysOnListening = false
        
        // Configure audio session for iOS Simulator compatibility
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("🎤 Audio session configured successfully")
        } catch {
            print("🎤 Failed to set up audio session: \(error)")
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("🎤 Unable to create recognition request")
            return
        }
        
        print("🎤 Recognition request created successfully")
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                var isFinal = false
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    print("🎤 Speech recognition result: '\(transcribedText)' (isFinal: \(result.isFinal))")
                    
                    // Check if we're in command listening mode
                    if self?.isCommandListeningMode == true {
                        // Check if it's a voice command
                        if let command = self?.processVoiceCommand(transcribedText) {
                            print("🎤 Voice command detected: \(command)")
                            self?.commandCompletion?(transcribedText)
                            self?.stopRecording()
                            return
                        }
                        
                        // If it's final and not a command, ignore it
                        if result.isFinal {
                            print("🎤 Final result but not a voice command, continuing to listen...")
                        }
                    } else {
                        // Regular recording mode
                        completion(transcribedText)
                        isFinal = result.isFinal
                    }
                }
                
                if let error = error {
                    print("🎤 Speech recognition error: \(error)")
                    // Handle specific error codes
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case 1101: // Speech recognition service unavailable
                            print("🎤 Speech recognition service unavailable, continuing...")
                            // Don't stop recording, just log the error
                        case 1110: // No speech detected
                            print("🎤 No speech detected, continuing...")
                            // Don't stop recording, just continue
                        case 1111: // Speech recognition not available
                            print("🎤 Speech recognition not available, stopping")
                            self?.stopRecording()
                        default:
                            print("🎤 Other speech recognition error: \(nsError.localizedDescription)")
                        }
                    }
                }
                
                if error != nil || isFinal {
                    if self?.isCommandListeningMode == false {
                        print("🎤 Stopping recording due to error or final result")
                        self?.stopRecording()
                    }
                }
            }
        }
        
        // Configure audio input with safer format handling
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎤 Audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
        
        // Validate format before using
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("🎤 Invalid audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            return
        }
        
        // Safely install audio tap
        guard safelyInstallAudioTap(format: recordingFormat, bufferSize: 1024, block: { buffer, _ in
            recognitionRequest.append(buffer)
        }) else {
            print("🎤 Failed to install audio tap, stopping recording")
            stopRecording()
            return
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            print("🎤 Audio engine started successfully, isRecording = \(isRecording)")
        } catch {
            print("🎤 Failed to start audio engine: \(error)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        print("🎤 VoiceManager.stopRecording() called")
        guard isRecording else { 
            print("🎤 Not currently recording, nothing to stop")
            return 
        }
        
        print("🎤 Stopping voice recording...")
        audioEngine.stop()
        
        // Safely remove audio tap
        safelyRemoveAudioTap()
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        print("🎤 Voice recording stopped successfully")
        
        // Reset audio session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        guard !text.isEmpty else { 
            completion?()
            return 
        }
        
        print("🎤 Starting speech synthesis...")
        
        // Store completion handler
        speechCompletion = completion
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Stop command listening while speaking to avoid audio conflicts
        if isListeningForCommands {
            print("🎤 Stopping command listening for speech synthesis")
            stopListeningForCommands()
        }
        
        // Configure audio session for speech synthesis
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session for speech: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        // Speak
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        
        // Restart command listening after speech finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🎤 Restarting command listening after speech finished")
            // Note: We'll need to restart from ContentView since we don't have access to the completion handler here
        }
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func continueSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // MARK: - Always-on Voice Command Listening
    
    func startListeningForCommands(completion: @escaping (String) -> Void) {
        print("🎤 Starting always-on voice command listening...")
        guard hasPermission else {
            print("🎤 Speech recognition permission not granted for command listening")
            return
        }
        
        commandCompletion = completion
        stopListeningForCommands() // Stop any existing command listening
        
        // Wait a bit for the speech recognition service to reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startListeningForCommandsInternal(completion: completion)
        }
    }
    
    private func startListeningForCommandsInternal(completion: @escaping (String) -> Void) {
        print("🎤 Starting internal command listening...")
        isCommandListeningMode = true
        isAlwaysOnListening = true
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("🎤 Command listening audio session configured")
        } catch {
            print("🎤 Failed to set up command listening audio session: \(error)")
            return
        }
        
        // Create recognition request for commands
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("🎤 Unable to create command recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    print("🎤 Command listening result: '\(transcribedText)' (isFinal: \(result.isFinal))")
                    
                    // Check if it's a voice command
                    if let command = self?.processVoiceCommand(transcribedText) {
                        print("🎤 Voice command detected: \(command)")
                        completion(transcribedText)
                        self?.stopListeningForCommands()
                        return
                    }
                    
                    // If it's final and not a command, ignore it
                    if result.isFinal {
                        print("🎤 Final result but not a voice command, continuing to listen...")
                    }
                }
                
                if let error = error {
                    print("🎤 Command listening error: \(error)")
                    // Handle specific error codes gracefully
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case 1101: // Speech recognition service unavailable
                            print("🎤 Speech recognition service unavailable, continuing to listen...")
                            // Don't stop listening, just continue
                        case 1110: // No speech detected
                            print("🎤 No speech detected, continuing to listen...")
                            // Don't stop listening, just continue
                        case 1111: // Speech recognition not available
                            print("🎤 Speech recognition not available, stopping command listening")
                            self?.stopListeningForCommands()
                        default:
                            print("🎤 Other speech recognition error: \(nsError.localizedDescription)")
                            // Don't stop listening on other errors
                        }
                    }
                }
            }
        }
        
        // Configure audio input for command listening
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎤 Command listening audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("🎤 Invalid audio format for command listening")
            return
        }
        
        // Safely install audio tap for command listening
        guard safelyInstallAudioTap(format: recordingFormat, bufferSize: 1024, block: { buffer, _ in
            recognitionRequest.append(buffer)
        }) else {
            print("🎤 Failed to install command listening audio tap, stopping")
            stopListeningForCommands()
            return
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListeningForCommands = true
            print("🎤 Command listening audio engine started, isListeningForCommands = \(isListeningForCommands)")
        } catch {
            print("🎤 Failed to start command listening audio engine: \(error)")
            stopListeningForCommands()
        }
    }
    
    func stopListeningForCommands() {
        print("🎤 Stopping always-on voice command listening...")
        guard isListeningForCommands else { return }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        audioEngine.stop()
        
        // Safely remove audio tap
        safelyRemoveAudioTap()
        
        isListeningForCommands = false
        isCommandListeningMode = false
        isAlwaysOnListening = false
        // Don't clear commandCompletion here - we need it for restart
        print("🎤 Command listening stopped")
    }
    
    func stopListeningForCommandsCompletely() {
        print("🎤 Completely stopping always-on voice command listening...")
        stopListeningForCommands()
        commandCompletion = nil
        print("🎤 Command listening completely stopped")
    }
    
    func restartCommandListening() {
        print("🎤 Restarting command listening...")
        guard let completion = commandCompletion else {
            print("🎤 No command completion handler available, cannot restart")
            return
        }
        
        print("🎤 Command completion handler found, stopping current listening...")
        stopListeningForCommands()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🎤 Restarting command listening with existing completion handler")
            // Double-check that we still have the completion handler
            if self.commandCompletion != nil {
                self.startListeningForCommands(completion: completion)
            } else {
                print("🎤 Command completion handler lost during restart, cannot restart")
            }
        }
    }
    
    // MARK: - Voice Commands
    
    func processVoiceCommand(_ command: String) -> VoiceCommand? {
        let lowercasedCommand = command.lowercased()
        print("🎤 VoiceManager processing command: '\(lowercasedCommand)'")
        
        if lowercasedCommand.contains("stop") || lowercasedCommand.contains("pause") {
            print("🎤 Recognized as .stop command")
            return .stop
        } else if lowercasedCommand.contains("continue") || lowercasedCommand.contains("resume") {
            print("🎤 Recognized as .continue command")
            return .continue
        } else if lowercasedCommand.contains("repeat") {
            print("🎤 Recognized as .repeat command")
            return .`repeat`
        } else if lowercasedCommand.contains("new chat") || lowercasedCommand.contains("start over") {
            print("🎤 Recognized as .newChat command")
            return .newChat
        } else if lowercasedCommand.contains("help") {
            print("🎤 Recognized as .help command")
            return .help
        } else if lowercasedCommand.contains("start ai") || lowercasedCommand.contains("start processing") || lowercasedCommand.contains("begin ai") {
            print("🎤 Recognized as .startAI command")
            return .startAI
        } else if lowercasedCommand.contains("stop ai") || lowercasedCommand.contains("stop processing") || lowercasedCommand.contains("cancel ai") {
            print("🎤 Recognized as .stopAI command")
            return .stopAI
        }
        
        print("🎤 No voice command recognized")
        return nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("🎤 Speech synthesis finished")
            self.isSpeaking = false
            self.speechCompletion?()
            self.speechCompletion = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("🎤 Speech synthesis cancelled")
            self.isSpeaking = false
            self.speechCompletion?()
            self.speechCompletion = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("🎤 Speech synthesis paused")
            self.isSpeaking = false
            self.speechCompletion?()
            self.speechCompletion = nil
        }
    }
}

// MARK: - Voice Commands

enum VoiceCommand {
    case stop
    case `continue`
    case `repeat`
    case newChat
    case help
    case startAI
    case stopAI
    
    var description: String {
        switch self {
        case .stop:
            return "Stop speaking"
        case .continue:
            return "Continue speaking"
        case .`repeat`:
            return "Repeat last response"
        case .newChat:
            return "Start new chat"
        case .help:
            return "Show help"
        case .startAI:
            return "Start voice recording"
        case .stopAI:
            return "Stop AI processing"
        }
    }
} 