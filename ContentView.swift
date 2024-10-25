import SwiftUI

struct ContentView: View {
    @State private var textInput: String = ""
    @State private var webhookURL: String = UserDefaults.standard.string(forKey: "webhookURL") ?? ""
    @State private var showSettings: Bool = false
    @State private var showCredits: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var savedWebhooks: [String] = UserDefaults.standard.stringArray(forKey: "savedWebhooks") ?? []
    @State private var selectedWebhooks: Set<String> = []
    @State private var sendCount: String = "1"
    @State private var status: String = "inactive"
    @State private var statusColor: Color = .red
    @State private var isSending: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("NeoSpam")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 10, x: 0, y: 5)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Status: \(status)")
                        .font(.headline)
                        .foregroundColor(statusColor)
                        .padding(.bottom, 10)
                    
                    CustomTextField(placeholder: Text("Enter text here").foregroundColor(.gray), text: $textInput)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .foregroundColor(.black)
                        .disabled(isSending)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(savedWebhooks.enumerated()), id: \.element) { index, webhook in
                                Button(action: {
                                    if !isSending {
                                        withAnimation {
                                            toggleWebhookSelection(webhook)
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text("Webhook \(index + 1)")
                                            .font(.body)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(selectedWebhooks.contains(webhook) ? Color.blue.opacity(0.2) : Color.white)
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(selectedWebhooks.contains(webhook) ? Color.blue.opacity(0.2) : Color.white)
                                    .shadow(radius: selectedWebhooks.contains(webhook) ? 5 : 0)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 150)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    CustomTextField(placeholder: Text("Enter number of times to send").foregroundColor(.gray), text: $sendCount)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .foregroundColor(.black)
                        .keyboardType(.numberPad)
                        .disabled(isSending)
                    
                    Button(action: {
                        handleSendButton()
                    }) {
                        Text("Send")
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(isSending)
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Button(action: {
                        showCredits.toggle()
                    }) {
                        Text("Credits")
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Text("Webhooks")
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding([.leading, .trailing], 20)
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(webhookURL: $webhookURL, savedWebhooks: $savedWebhooks)
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
    
    private func handleSendButton() {
        WebhookManager.shared.checkNetworkConnectivity { isConnected in
            if isConnected {
                if textInput.isEmpty {
                    updateStatus("error: No text entered", color: .red)
                } else if selectedWebhooks.isEmpty {
                    updateStatus("error: No webhook selected", color: .red)
                } else if sendCount.isEmpty {
                    updateStatus("error: No send count entered", color: .red)
                } else {
                    updateStatus("sending...", color: .yellow)
                    sendTextToWebhooks()
                }
            } else {
                updateStatus("error: No network connection", color: .red)
            }
        }
    }
    
    private func sendTextToWebhooks() {
        guard let count = Int(sendCount), count > 0 else {
            feedbackMessage = "Please enter a valid number of times to send."
            return
        }
        
        isSending = true
        
        Task {
            var messagesSent = 0
            for _ in 0..<count {
                for webhook in selectedWebhooks {
                    WebhookManager.shared.sendToWebhook(webhook: webhook, message: textInput, updateStatus: updateStatus) { success in
                        if success {
                            messagesSent += 1
                            updateStatus("sending... (\(messagesSent))", color: .yellow)
                        }
                    }
                    try await Task.sleep(nanoseconds: 420_000_000)
                }
            }
            
            updateStatus("inactive", color: .red)
            isSending = false
        }
    }
    
    private func updateStatus(_ message: String, color: Color) {
        DispatchQueue.main.async {
            status = message
            statusColor = color
        }
    }
    
    private func toggleWebhookSelection(_ webhook: String) {
        if selectedWebhooks.contains(webhook) {
            selectedWebhooks.remove(webhook)
        } else {
            selectedWebhooks.insert(webhook)
        }
    }
}

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var editingChanged: (Bool) -> () = { _ in }
    var commit: () -> () = { }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty { placeholder }
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
