import RFSigilCoreModels
import RFSigilPrivacySecurity
import XCTest

final class PrivacySecurityTests: XCTestCase {
    func testPrivacyPostureIsLocalOnly() {
        let status = SigilPrivacySecurityService().status()

        XCTAssertEqual(status.status, .pass)
        XCTAssertFalse(status.networkDenyStatus.hasNetworkClient)
        XCTAssertFalse(status.networkDenyStatus.hasBackendEndpoint)
        XCTAssertFalse(status.networkDenyStatus.hasAnalyticsSDK)
        XCTAssertTrue(status.diagnosticsLocalOnly)
        XCTAssertEqual(status.secureStorageReadiness, .modeledNotPersistingSensitiveData)
    }
}
