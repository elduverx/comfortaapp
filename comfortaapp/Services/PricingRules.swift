import Foundation

enum PricingRules {
    static let shortDistanceThresholdKm: Double = 50.0
    static let longDistanceThresholdKm: Double = 100.0
    static let shortDistanceRatePerKm: Double = 1.50
    static let midDistanceRatePerKm: Double = 1.20
    static let longDistanceRatePerKm: Double = 1.10

    static let minimumFare: Double = 7.50
    static let minimumFareThresholdKm: Double = 10.0
    static let minimumFareForLongTrips: Double = 15.00
    static let airportSurcharge: Double = 8.00

    static func pricePerKm(for distanceKm: Double) -> Double {
        if distanceKm > longDistanceThresholdKm {
            return longDistanceRatePerKm
        } else if distanceKm >= shortDistanceThresholdKm {
            return midDistanceRatePerKm
        } else {
            return shortDistanceRatePerKm
        }
    }

    static func applyMinimums(
        to basePrice: Double,
        distanceKm: Double,
        minimumFare: Double = PricingRules.minimumFare,
        minimumFareForLongTrips: Double = PricingRules.minimumFareForLongTrips,
        minimumFareThresholdKm: Double = PricingRules.minimumFareThresholdKm
    ) -> Double {
        if distanceKm >= minimumFareThresholdKm {
            return max(basePrice, minimumFareForLongTrips)
        }
        return max(basePrice, minimumFare)
    }

    static func hasAirportPortOrStation(origin: String?, destination: String?) -> Bool {
        if let origin = origin, containsTransportHub(origin) {
            return true
        }
        if let destination = destination, containsTransportHub(destination) {
            return true
        }
        return false
    }

    static func containsTransportHub(_ address: String) -> Bool {
        let normalized = normalize(address)
        for keyword in transportKeywords {
            if normalized.contains(keyword) {
                return true
            }
        }
        return false
    }

    private static let transportKeywords = [
        "aeropuerto",
        "airport",
        "puerto",
        "port",
        "estacion",
        "station",
        "estacio",
        "renfe",
        "ave",
        "cercanias",
        "metro"
    ]

    private static func normalize(_ input: String) -> String {
        input.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }
}
