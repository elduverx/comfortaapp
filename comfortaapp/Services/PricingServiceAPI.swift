import Foundation
import CoreLocation
import Combine

/// Pricing Service using real API with local fallback
class PricingServiceAPI: ObservableObject {
    static let shared = PricingServiceAPI()

    @Published var isCalculating = false
    @Published var error: String?

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    // Cache for pricing results (5 min cache)
    private var pricingCache: [String: CachedPricing] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    private init() {}

    // MARK: - Calculate Pricing

    func calculatePricing(
        origin: String?,
        destination: String
    ) async throws -> PricingResponse {
        // Check cache first
        let cacheKey = "\(origin ?? "nil")_\(destination)"
        if let cached = pricingCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            print("📦 Using cached pricing for \(cacheKey)")
            return cached.pricing
        }

        await MainActor.run {
            isCalculating = true
            error = nil
        }

        do {
            let request = CalculatePricingRequest(
                origin: origin,
                destination: destination
            )

            let apiResponse: PricingAPIResponse = try await apiClient.request(
                endpoint: .calculatePricing,
                method: .post,
                body: request,
                requiresAuth: false // Pricing doesn't require auth
            )

            // Convert API response to app PricingResponse
            let pricingResponse = PricingResponse(
                distance: apiResponse.distance,
                estimatedTime: formatDurationFromDistance(apiResponse.distance),
                basePrice: apiResponse.basePrice,
                totalPrice: apiResponse.totalPrice,
                priceBreakdown: PriceBreakdown(
                    baseRate: apiResponse.basePrice,
                    distanceRate: apiResponse.basePrice,
                    timeRate: 0,
                    additionalFees: apiResponse.airportSurcharge
                )
            )

            // Cache the result
            pricingCache[cacheKey] = CachedPricing(
                pricing: pricingResponse,
                timestamp: Date()
            )

            await MainActor.run {
                isCalculating = false
            }

            print("✅ Pricing calculated: €\(apiResponse.totalPrice) for \(apiResponse.distance)km")

            return pricingResponse

        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isCalculating = false
            }

            // Fallback to local calculation
            print("⚠️ API pricing failed, using local fallback")
            return try await calculatePricingLocally(
                origin: origin,
                destination: destination
            )
        }
    }

    // MARK: - Local Fallback Calculation

    private func calculatePricingLocally(
        origin: String?,
        destination: String
    ) async throws -> PricingResponse {
        let routeInfo: RouteService.RouteInfo?
        if let origin = origin {
            routeInfo = try? await RouteService().calculateRoute(from: origin, to: destination)
        } else {
            routeInfo = nil
        }

        let estimatedDistance = routeInfo?.distance ?? 25.0

        let pricePerKm = PricingRules.pricePerKm(for: estimatedDistance)
        var basePrice = estimatedDistance * pricePerKm
        basePrice = PricingRules.applyMinimums(to: basePrice, distanceKm: estimatedDistance)
        basePrice = round(basePrice * 100) / 100

        let airportSurcharge: Double = PricingRules.hasAirportPortOrStation(
            origin: origin,
            destination: destination
        ) ? PricingRules.airportSurcharge : 0.0

        let totalPrice = round((basePrice + airportSurcharge) * 100) / 100

        return PricingResponse(
            distance: estimatedDistance,
            estimatedTime: routeInfo.map { formatDurationFromDuration($0.duration) } ?? formatDurationFromDistance(estimatedDistance),
            basePrice: basePrice,
            totalPrice: totalPrice,
            priceBreakdown: PriceBreakdown(
                baseRate: basePrice,
                distanceRate: basePrice,
                timeRate: 0,
                additionalFees: airportSurcharge
            )
        )
    }

    // MARK: - Helpers

    private func formatDurationFromDistance(_ distance: Double) -> String {
        // Rough estimate: 60 km/h average
        let durationMinutes = (distance / 60.0) * 60.0
        let hours = Int(durationMinutes / 60)
        let minutes = Int(durationMinutes.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    private func formatDurationFromDuration(_ duration: TimeInterval) -> String {
        let durationMinutes = duration / 60.0
        let hours = Int(durationMinutes / 60)
        let minutes = Int(durationMinutes.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    // MARK: - Clear Cache

    func clearCache() {
        pricingCache.removeAll()
    }
}

// MARK: - Cached Pricing

private struct CachedPricing {
    let pricing: PricingResponse
    let timestamp: Date
}

// MARK: - Local PricingResponse (removed duplicates, using definitions from PricingService.swift)
