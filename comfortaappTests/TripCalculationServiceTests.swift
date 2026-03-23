import XCTest
@testable import Comforta

final class TripCalculationServiceTests: XCTestCase {
    func testCalculateFareAppliesMinimumFare() {
        let service = TripCalculationService()
        let fare = service.calculateFare(for: 2000)
        XCTAssertEqual(fare, PricingRules.minimumFare)
    }

    func testCalculateFareAddsAirportSurcharge() {
        let service = TripCalculationService()
        let fare = service.calculateFare(for: 20000, includesAirport: true)
        XCTAssertTrue(fare >= PricingRules.minimumFareForLongTrips + PricingRules.airportSurcharge)
    }

    func testFormatDistance() {
        let service = TripCalculationService()
        XCTAssertEqual(service.formatDistance(500), "500 m")
        XCTAssertEqual(service.formatDistance(1500), "1.5 km")
    }
}
