import Foundation
import Combine

struct TripTrackingUpdate: Codable {
    let tripId: String
    let driverLat: Double
    let driverLng: Double
    let updatedAt: Date
}

final class TripTrackingWebSocketService: ObservableObject {
    static let shared = TripTrackingWebSocketService()

    @Published private(set) var isConnected = false
    @Published private(set) var latestUpdate: TripTrackingUpdate?
    @Published private(set) var lastError: String?

    private var task: URLSessionWebSocketTask?
    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func connect(tripId: String) {
        disconnect()

        guard let url = URL(string: "\(AppEnvironment.current.webSocketBaseURL)/tracking/\(tripId)") else {
            lastError = "Invalid WebSocket URL"
            return
        }

        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        lastError = nil

        listen()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                self.handle(message: message)
                self.listen()
            case .failure(let error):
                self.isConnected = false
                self.lastError = error.localizedDescription
                MonitoringService.shared.record(error: error, context: "websocket_receive")
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let update = try? decoder.decode(TripTrackingUpdate.self, from: data) {
                latestUpdate = update
            }
        case .data(let data):
            if let update = try? decoder.decode(TripTrackingUpdate.self, from: data) {
                latestUpdate = update
            }
        @unknown default:
            break
        }
    }
}
