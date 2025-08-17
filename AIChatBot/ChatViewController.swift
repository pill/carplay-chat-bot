import UIKit
import CarPlay

class ChatViewController: UIViewController {
    
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    
    private var aiService = AIService()
    private var voiceManager = VoiceManager()
    private var messages: [ChatMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
        setupInputView()
        
        // Load initial messages
        messages = aiService.chatHistory
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "AI Chat"
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(textField)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(voiceButton)
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Text field
            textField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            textField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            
            // Voice button
            voiceButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            voiceButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 44),
            voiceButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Send button
            sendButton.leadingAnchor.constraint(equalTo: voiceButton.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
    }
    
    private func setupInputView() {
        // Input container styling
        inputContainerView.backgroundColor = .systemBackground
        inputContainerView.layer.shadowColor = UIColor.black.cgColor
        inputContainerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        inputContainerView.layer.shadowOpacity = 0.1
        inputContainerView.layer.shadowRadius = 4
        
        // Text field styling
        textField.placeholder = "Type your message..."
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.delegate = self
        
        // Send button styling
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 22
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        // Voice button styling
        voiceButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        voiceButton.tintColor = .systemBlue
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
    }
    
    @objc private func sendButtonTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        
        sendMessage(text)
        textField.text = ""
    }
    
    @objc private func voiceButtonTapped() {
        if voiceManager.isRecording {
            stopVoiceRecording()
        } else {
            startVoiceRecording()
        }
    }
    
    private func sendMessage(_ text: String) {
        let userMessage = ChatMessage(
            content: text,
            isFromAI: false,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        tableView.reloadData()
        scrollToBottom()
        
        // Send to AI service
        Task {
            await aiService.sendMessage(text)
            
            await MainActor.run {
                self.messages = self.aiService.chatHistory
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    private func startVoiceRecording() {
        voiceButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        voiceButton.tintColor = .systemRed
        
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.textField.text = transcribedText
                self?.stopVoiceRecording()
            }
        }
    }
    
    private func stopVoiceRecording() {
        voiceButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        voiceButton.tintColor = .systemBlue
        voiceManager.stopRecording()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - MessageCell

class MessageCell: UITableViewCell {
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let bubbleView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Bubble view
        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // Message label
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Time label
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        if message.isFromAI {
            // AI message - left aligned
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = false
        } else {
            // User message - right aligned
            bubbleView.backgroundColor = .systemGray5
            messageLabel.textColor = .label
            
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = false
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        }
    }
} 