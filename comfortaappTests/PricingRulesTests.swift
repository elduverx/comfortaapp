import XCTest
@testable import Comforta

final class PricingRulesTests: XCTestCase {
    func testPricePerKmShortDistance() {
        let rate = PricingRules.pricePerKm(for: 10)
        XCTAssertEqual(rate, PricingRules.shortDistanceRatePerKm)
    }

    func testPricePerKmMidDistance() {
        let rate = PricingRules.pricePerKm(for: 60)
        XCTAssertEqual(rate, PricingRules.midDistanceRatePerKm)
    }

    func testApplyMinimumsLongTrip() {
        let basePrice = 12.0
        let adjusted = PricingRules.applyMinimums(to: basePrice, distanceKm: 15)
        XCTAssertEqual(adjusted, PricingRules.minimumFareForLongTrips)
    }

    func testContainsTransportHubMatches() {
        XCTAssertTrue(PricingRules.hasAirportPortOrStation(origin: "Aeropuerto Madrid", destination: nil))
        XCTAssertTrue(PricingRules.hasAirportPortOrStation(origin: nil, destination: "Estacion Central"))
    }
}
