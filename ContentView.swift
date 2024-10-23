import SwiftUI

struct ContentView: View {
    @State private var textInput: String = ""
    @State private var webhookURL: String = UserDefaults.standard.string(forKey: "webhookURL") ?? ""
    @State private var showSettings: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var savedWebhooks: [String] = UserDefaults.standard.stringArray(forKey: "savedWebhooks") ?? []
    @State private var selectedWebhooks: Set<String> = []
    @State private var isSubmitted: Bool = false
    @State private var sendCount: String = "1"
    @State private var status: String = "inactive" // New state variable for status
    @State private var statusColor: Color = .red // New state variable for status color

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Neo")
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

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(savedWebhooks.enumerated()), id: \.element) { index, webhook in
                                Button(action: {
                                    if selectedWebhooks.contains(webhook) {
                                        selectedWebhooks.remove(webhook)
                                    } else {
                                        selectedWebhooks.insert(webhook)
                                    }
                                }) {
                                    HStack {
                                        Text("Link \(index + 1)")
                                            .font(.body)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(selectedWebhooks.contains(webhook) ? Color.blue.opacity(0.2) : Color.clear)
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity)
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

                    Button(action: {
                        sendTextToWebhooks()
                        isSubmitted = true
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
                }
                .padding()

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Text("Webhooks")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(webhookURL: $webhookURL, savedWebhooks: $savedWebhooks)
        }
    }

    private func sendTextToWebhooks() {
        guard let count = Int(sendCount), count > 0 else {
            feedbackMessage = "Please enter a valid number of times to send."
            return
        }

        status = "sending..."
        statusColor = .yellow

        for _ in 0..<count {
            for webhook in selectedWebhooks {
                sendToWebhook(webhook: webhook, message: textInput)
            }
        }
    }

    private func sendToWebhook(webhook: String, message: String) {
        guard let url = URL(string: webhook) else {
            print("Invalid webhook URL")
            status = "error: invalid URL"
            statusColor = .red
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["content": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                status = "error: \(error.localizedDescription)"
                statusColor = .red
            } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Server error: \(httpResponse.statusCode)")
                status = "error: server \(httpResponse.statusCode)"
                statusColor = .red
            } else {
                print("Message sent successfully")
                status = "sent"
                statusColor = .green
            }
        }.resume()
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

struct SettingsView: View {
    @Binding var webhookURL: String
    @Binding var savedWebhooks: [String]
    @State private var errorMessage: String = ""

    var body: some View {
        VStack {
            Text("Webhooks")
                .font(.headline)
                .padding(.bottom, 10)

            TextField("Enter Discord Webhook URL", text: $webhookURL)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .shadow(radius: 5)
                .onSubmit {
                    validateAndSaveWebhook()
                }
                .onDisappear {
                    validateAndSaveWebhook()
                }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }

            List {
                ForEach(savedWebhooks, id: \.self) { webhook in
                    Text(webhook)
                }
                .onDelete(perform: removeWebhook)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private func validateAndSaveWebhook() {
        if isValidWebhookURL(webhookURL) {
            if !savedWebhooks.contains(webhookURL) {
                savedWebhooks.append(webhookURL)
                UserDefaults.standard.set(savedWebhooks, forKey: "savedWebhooks")
                webhookURL = "" // Clear the input box
                errorMessage = ""
            }
        } else {
            errorMessage = "Invalid Discord Webhook URL. Please enter a valid URL."
        }
    }

    private func isValidWebhookURL(_ url: String) -> Bool {
        let regex = "^https://discord.com/api/webhooks/\\d+/[A-Za-z0-9_-]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: url)
    }

    private func removeWebhook(at offsets: IndexSet) {
        savedWebhooks.remove(atOffsets: offsets)
        UserDefaults.standard.set(savedWebhooks, forKey: "savedWebhooks")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
