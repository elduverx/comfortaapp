import Foundation
import Combine
import CoreLocation

struct PendingTripRequest: Identifiable, Codable {
    let id: String
    let pickupLocation: String?
    let destination: String
    let pickupLat: Double?
    let pickupLng: Double?
    let destinationLat: Double?
    let destinationLng: Double?
    let startDate: Date
    let endDate: Date?
    let timeSlot: String?
    let notes: String?
    let distanceKm: Double?
    let basePrice: Double?
    let totalPrice: Double?
    let createdAt: Date

    init(
        pickupLocation: String?,
        destination: String,
        pickupCoordinate: CLLocationCoordinate2D?,
        destinationCoordinate: CLLocationCoordinate2D?,
        startDate: Date,
        endDate: Date?,
        timeSlot: String?,
        notes: String?,
        distanceKm: Double?,
        basePrice: Double?,
        totalPrice: Double?
    ) {
        self.id = UUID().uuidString
        self.pickupLocation = pickupLocation
        self.destination = destination
        self.pickupLat = pickupCoordinate?.latitude
        self.pickupLng = pickupCoordinate?.longitude
        self.destinationLat = destinationCoordinate?.latitude
        self.destinationLng = destinationCoordinate?.longitude
        self.startDate = startDate
        self.endDate = endDate
        self.timeSlot = timeSlot
        self.notes = notes
        self.distanceKm = distanceKm
        self.basePrice = basePrice
        self.totalPrice = totalPrice
        self.createdAt = Date()
    }
}

final class OfflineService: ObservableObject {
    static let shared = OfflineService()

    @Published private(set) var pendingTrips: [PendingTripRequest] = []

    private let storageKey = "offline_pending_trips_v1"
    private let connectivityMonitor = ConnectivityMonitor()
    private var cancellables = Set<AnyCancellable>()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        loadPendingTrips()
        observeConnectivity()
    }

    func cacheTripRequest(
        pickupLocation: String?,
        destination: String,
        pickupCoordinate: CLLocationCoordinate2D?,
        destinationCoordinate: CLLocationCoordinate2D?,
        startDate: Date,
        endDate: Date? = nil,
        timeSlot: String? = nil,
        notes: String? = nil,
        distanceKm: Double? = nil,
        basePrice: Double? = nil,
        totalPrice: Double? = nil
    ) {
        let request = PendingTripRequest(
            pickupLocation: pickupLocation,
            destination: destination,
            pickupCoordinate: pickupCoordinate,
            destinationCoordinate: destinationCoordinate,
            startDate: startDate,
            endDate: endDate,
            timeSlot: timeSlot,
            notes: notes,
            distanceKm: distanceKm,
            basePrice: basePrice,
            totalPrice: totalPrice
        )

        pendingTrips.append(request)
        persistPendingTrips()
    }

    func syncWhenOnline() {
        guard !connectivityMonitor.isOffline else { return }
        guard !pendingTrips.isEmpty else { return }
        guard KeychainManager.shared.getAccessToken() != nil else { return }

        Task {
            for request in pendingTrips {
                do {
                    let pickupCoordinate = coordinate(lat: request.pickupLat, lng: request.pickupLng)
                    let destinationCoordinate = coordinate(lat: request.destinationLat, lng: request.destinationLng)

                    _ = try await TripServiceAPI.shared.createTrip(
                        pickupLocation: request.pickupLocation,
                        destination: request.destination,
                        pickupCoordinate: pickupCoordinate,
                        destinationCoordinate: destinationCoordinate,
                        startDate: request.startDate,
                        endDate: request.endDate,
                        timeSlot: request.timeSlot,
                        notes: request.notes,
                        distanceKm: request.distanceKm,
                        basePrice: request.basePrice,
                        totalPrice: request.totalPrice
                    )

                    await MainActor.run {
                        removePendingTrip(id: request.id)
                    }
                } catch {
                    MonitoringService.shared.record(error: error, context: "offline_sync")
                }
            }
        }
    }

    func removePendingTrip(id: String) {
        pendingTrips.removeAll { $0.id == id }
        persistPendingTrips()
    }

    private func coordinate(lat: Double?, lng: Double?) -> CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private func observeConnectivity() {
        connectivityMonitor.$isOffline
            .removeDuplicates()
            .sink { [weak self] isOffline in
                if !isOffline {
                    self?.syncWhenOnline()
                }
            }
            .store(in: &cancellables)
    }

    private func loadPendingTrips() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? decoder.decode([PendingTripRequest].self, from: data) else {
            return
        }
        pendingTrips = saved
    }

    private func persistPendingTrips() {
        guard let data = try? encoder.encode(pendingTrips) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
