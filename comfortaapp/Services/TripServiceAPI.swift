import Foundation
import CoreLocation
import Combine

/// Trip Service using real API
class TripServiceAPI: ObservableObject {
    static let shared = TripServiceAPI()

    @Published var activeTrip: APITrip?
    @Published var tripHistory: [APITrip] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    private var persistenceCancellable: AnyCancellable?
    private let tripHistoryStorageKey = "trip_history_api_v1"
    private let activeTripStorageKey = "active_trip_api_v1"

    private init() {
        loadCachedTrips()
        setupTripPersistence()
        // Load initial trip history
        Task {
            await loadTripHistory()
        }
    }

    private func setupTripPersistence() {
        persistenceCancellable = Publishers.CombineLatest($tripHistory, $activeTrip)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] trips, active in
                self?.persistTripCache(trips: trips, activeTrip: active)
            }
    }

    private func persistTripCache(trips: [APITrip], activeTrip: APITrip?) {
        if let encodedTrips = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encodedTrips, forKey: tripHistoryStorageKey)
        }

        if let activeTrip = activeTrip,
           let encodedActive = try? JSONEncoder().encode(activeTrip) {
            UserDefaults.standard.set(encodedActive, forKey: activeTripStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeTripStorageKey)
        }
    }

    private func loadCachedTrips() {
        if let data = UserDefaults.standard.data(forKey: tripHistoryStorageKey),
           let cachedTrips = try? JSONDecoder().decode([APITrip].self, from: data) {
            tripHistory = cachedTrips
        }

        if let data = UserDefaults.standard.data(forKey: activeTripStorageKey),
           let cachedActive = try? JSONDecoder().decode(APITrip.self, from: data) {
            activeTrip = cachedActive
        } else if let cachedActive = tripHistory.first(where: { !$0.pagado && $0.estado == "PENDIENTE" }) {
            activeTrip = cachedActive
        }
    }

    // MARK: - Create Trip

    func createTrip(
        pickupLocation: String?,
        destination: String,
        pickupCoordinate: CLLocationCoordinate2D? = nil,
        destinationCoordinate: CLLocationCoordinate2D? = nil,
        startDate: Date,
        endDate: Date? = nil,
        timeSlot: String? = nil,
        notes: String? = nil,
        distanceKm: Double? = nil,
        basePrice: Double? = nil,
        totalPrice: Double? = nil
    ) async throws -> APITrip {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let request = CreateTripRequest(
                lugarRecogida: pickupLocation,
                destino: destination,
                fechaInicio: startDate.toISO8601String(),
                fechaFin: endDate?.toISO8601String(),
                franjaHoraria: timeSlot,
                notas: notes,
                distanciaKm: distanceKm,
                precioBase: basePrice,
                precioTotal: totalPrice,
                pickupLat: pickupCoordinate?.latitude,
                pickupLng: pickupCoordinate?.longitude,
                destinationLat: destinationCoordinate?.latitude,
                destinationLng: destinationCoordinate?.longitude
            )

            let response: TripResponse = try await apiClient.request(
                endpoint: .trips,
                method: .post,
                body: request,
                requiresAuth: true
            )

            await MainActor.run {
                // Add to trip history
                tripHistory.insert(response.trip, at: 0)

                // If not paid yet, set as active trip
                if !response.trip.pagado {
                    activeTrip = response.trip
                }

                isLoading = false
            }

            // Track analytics
            AnalyticsService.shared.track(.tripCreated, metadata: [
                "trip_id": response.trip.id,
                "destination": destination
            ])

            print("✅ Trip created: \(response.trip.id)")

            return response.trip

        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
            throw error
        }
    }

    // MARK: - Get Trip History

    func loadTripHistory(
        status: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        includeUnpaid: Bool = false
    ) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]

            if let status = status {
                queryItems.append(URLQueryItem(name: "status", value: status))
            }

            if includeUnpaid {
                queryItems.append(URLQueryItem(name: "includeUnpaid", value: "true"))
            }

            let response: TripsListResponse = try await apiClient.request(
                endpoint: .trips,
                method: .get,
                queryItems: queryItems,
                requiresAuth: true
            )

            await MainActor.run {
                if offset == 0 {
                    // First page, replace all
                    tripHistory = response.trips
                } else {
                    // Append to existing
                    tripHistory.append(contentsOf: response.trips)
                }

                // Update active trip if exists
                if let activeTrip = response.trips.first(where: { !$0.pagado && $0.estado == "PENDIENTE" }) {
                    self.activeTrip = activeTrip
                }

                isLoading = false
            }

            print("✅ Trips loaded: \(response.trips.count) trips")

        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
            print("❌ Load trips failed: \(error)")
        }
    }

    // MARK: - Get Trip Details

    func getTripDetails(id: String) async throws -> APITrip {
        let response: TripResponse = try await apiClient.request(
            endpoint: .tripDetail(id: id),
            method: .get,
            requiresAuth: true
        )

        // Update in cache if exists
        await MainActor.run {
            if let index = tripHistory.firstIndex(where: { $0.id == id }) {
                tripHistory[index] = response.trip
            }

            if activeTrip?.id == id {
                activeTrip = response.trip
            }
        }

        return response.trip
    }

    // MARK: - Get Trip Status

    func getTripStatus(tripId: String) async throws -> APITrip {
        try await getTripDetails(id: tripId)
    }

    // MARK: - Update Trip

    func updateTrip(
        id: String,
        notes: String? = nil,
        telefono: String? = nil
    ) async throws -> APITrip {
        let request = UpdateTripRequest(
            notas: notes,
            telefono: telefono
        )

        let response: TripResponse = try await apiClient.request(
            endpoint: .tripDetail(id: id),
            method: .patch,
            body: request,
            requiresAuth: true
        )

        await MainActor.run {
            // Update in cache
            if let index = tripHistory.firstIndex(where: { $0.id == id }) {
                tripHistory[index] = response.trip
            }

            if activeTrip?.id == id {
                activeTrip = response.trip
            }
        }

        print("✅ Trip updated: \(id)")

        return response.trip
    }

    // MARK: - Cancel Trip

    func cancelTrip(id: String, reason: String? = nil) async throws {
        let request = CancelTripRequest(reason: reason)

        let _: MessageResponse = try await apiClient.request(
            endpoint: .tripDetail(id: id),
            method: .delete,
            body: request,
            requiresAuth: true
        )

        await MainActor.run {
            // Update status in cache
            if let index = tripHistory.firstIndex(where: { $0.id == id }) {
                var updatedTrip = tripHistory[index]
                // Create a new instance with updated estado
                // Note: We need to update the estado field, but APITrip is immutable
                // We'll fetch the trip again to get updated data
            }

            if activeTrip?.id == id {
                activeTrip = nil
            }
        }

        // Reload trip to get updated status
        _ = try await getTripDetails(id: id)

        // Track analytics
        AnalyticsService.shared.track(.tripCancelled, metadata: [
            "trip_id": id,
            "reason": reason ?? "no_reason"
        ])

        print("✅ Trip cancelled: \(id)")
    }

    // MARK: - Clear Active Trip

    func clearActiveTrip() {
        activeTrip = nil
    }

    // MARK: - Helpers

    func getTripById(_ id: String) -> APITrip? {
        return tripHistory.first { $0.id == id }
    }

    func getPaidTrips() -> [APITrip] {
        return tripHistory.filter { $0.pagado }
    }

    func getPendingTrips() -> [APITrip] {
        return tripHistory.filter { !$0.pagado && $0.estado == "PENDIENTE" }
    }
}
