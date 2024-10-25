import SwiftUI

struct SettingsView: View {
    @Binding var webhookURL: String
    @Binding var savedWebhooks: [String]
    @State private var message: (text: String, color: Color) = ("", .clear)
    
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
                .onSubmit { validateAndSaveWebhook() }
                .onDisappear { validateAndSaveWebhook() }
            
            if !message.text.isEmpty {
                Text(message.text)
                    .foregroundColor(message.color)
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
                webhookURL = ""
                message = ("Webhook added successfully!", .green)
                hideMessageAfterDelay()
            } else {
                message = ("Webhook is already in the list.", .orange)
                hideMessageAfterDelay()
            }
        } else {
            message = ("Invalid Discord Webhook URL. Please enter a valid URL.", .red)
            hideMessageAfterDelay()
        }
    }
    
    private func isValidWebhookURL(_ url: String) -> Bool {
        let regex = "^https://discord.com/api/webhooks/\\d+/[A-Za-z0-9_-]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: url)
    }
    
    private func removeWebhook(at offsets: IndexSet) {
        savedWebhooks.remove(atOffsets: offsets)
        UserDefaults.standard.set(savedWebhooks, forKey: "savedWebhooks")
        message = ("Webhook removed successfully!", .green)
        hideMessageAfterDelay()
    }
    
    private func hideMessageAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            message = ("", .clear)
        }
    }
}
