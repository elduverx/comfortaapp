import Foundation
import CoreLocation
import Combine

/// Favorites Service using real API
class FavoritesServiceAPI: ObservableObject {
    static let shared = FavoritesServiceAPI()

    @Published var favorites: [APIFavorite] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load favorites on init
        Task {
            await loadFavorites()
        }
    }

    // MARK: - Load Favorites

    func loadFavorites(tipo: String? = nil) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            var queryItems: [URLQueryItem] = []
            if let tipo = tipo {
                queryItems.append(URLQueryItem(name: "tipo", value: tipo))
            }

            let response: FavoritesResponse = try await apiClient.request(
                endpoint: .favorites,
                method: .get,
                queryItems: queryItems.isEmpty ? nil : queryItems,
                requiresAuth: true
            )

            await MainActor.run {
                favorites = response.favorites
                isLoading = false
            }

            print("✅ Favorites loaded: \(response.favorites.count) items")

        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
            print("❌ Load favorites failed: \(error)")
        }
    }

    // MARK: - Create Favorite

    func createFavorite(
        nombre: String,
        direccion: String,
        tipo: String = "OTRO",
        coordinate: CLLocationCoordinate2D? = nil
    ) async throws -> APIFavorite {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let request = CreateFavoriteRequest(
                nombre: nombre,
                direccion: direccion,
                tipo: tipo,
                latitud: coordinate?.latitude,
                longitud: coordinate?.longitude
            )

            let response: FavoriteResponse = try await apiClient.request(
                endpoint: .favorites,
                method: .post,
                body: request,
                requiresAuth: true
            )

            await MainActor.run {
                // Add to list
                favorites.insert(response.favorite, at: 0)
                isLoading = false
            }

            print("✅ Favorite created: \(response.favorite.id)")

            return response.favorite

        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
            throw error
        }
    }

    // MARK: - Update Favorite

    func updateFavorite(
        id: String,
        nombre: String? = nil,
        direccion: String? = nil,
        tipo: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil
    ) async throws -> APIFavorite {
        let request = UpdateFavoriteRequest(
            nombre: nombre,
            direccion: direccion,
            tipo: tipo,
            latitud: coordinate?.latitude,
            longitud: coordinate?.longitude
        )

        let response: FavoriteResponse = try await apiClient.request(
            endpoint: .favoriteDetail(id: id),
            method: .patch,
            body: request,
            requiresAuth: true
        )

        await MainActor.run {
            // Update in list
            if let index = favorites.firstIndex(where: { $0.id == id }) {
                favorites[index] = response.favorite
            }
        }

        print("✅ Favorite updated: \(id)")

        return response.favorite
    }

    // MARK: - Delete Favorite

    func deleteFavorite(id: String) async throws {
        let _: MessageResponse = try await apiClient.request(
            endpoint: .favoriteDetail(id: id),
            method: .delete,
            requiresAuth: true
        )

        await MainActor.run {
            // Remove from list
            favorites.removeAll { $0.id == id }
        }

        print("✅ Favorite deleted: \(id)")
    }

    // MARK: - Get Favorite by ID

    func getFavorite(id: String) async throws -> APIFavorite {
        let response: FavoriteResponse = try await apiClient.request(
            endpoint: .favoriteDetail(id: id),
            method: .get,
            requiresAuth: true
        )

        return response.favorite
    }

    // MARK: - Helpers

    func getFavoritesByType(_ tipo: String) -> [APIFavorite] {
        return favorites.filter { $0.tipo == tipo }
    }

    func searchFavorites(query: String) -> [APIFavorite] {
        let lowercaseQuery = query.lowercased()
        return favorites.filter {
            $0.nombre.lowercased().contains(lowercaseQuery) ||
            $0.direccion.lowercased().contains(lowercaseQuery)
        }
    }
}
