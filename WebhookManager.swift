import Foundation
import Network
import SwiftUI

class WebhookManager {
    static let shared = WebhookManager()
    
    func sendToWebhook(webhook: String, message: String, updateStatus: @escaping (String, Color) -> Void, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: webhook) else {
            updateStatus("error: invalid URL", .red)
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["content": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                updateStatus("error: \(error.localizedDescription)", .red)
                completion(false)
            } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                updateStatus("error: server \(httpResponse.statusCode)", .red)
                completion(false)
            } else {
                print("Message sent successfully")
                completion(true)
            }
        }.resume()
    }
    
    func checkNetworkConnectivity(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { path in
            completion(path.status == .satisfied)
            monitor.cancel()
        }
        monitor.start(queue: queue)
    }
}
