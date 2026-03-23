import XCTest
@testable import Comforta

final class FeatureFlagServiceTests: XCTestCase {
    func testOverrideTogglesFlag() {
        let service = FeatureFlagService.shared
        service.setOverride(.offlineMode, enabled: true)
        XCTAssertTrue(service.isEnabled(.offlineMode))

        service.setOverride(.offlineMode, enabled: false)
        XCTAssertFalse(service.isEnabled(.offlineMode))

        service.clearOverrides()
    }
}
