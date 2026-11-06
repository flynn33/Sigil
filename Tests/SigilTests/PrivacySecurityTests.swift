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
        XCTAssertFalse(status.userSensitiveDataLogged)
        // Real, implemented encrypted-at-rest persistence (supersedes the
        // modeled-only Phase 1 posture). Local-only invariants preserved.
        XCTAssertEqual(status.secureStorageReadiness, .encryptedAtRestNativeKeychain)
    }
}
