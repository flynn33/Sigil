import Testing
@testable import RFGeocoding

@Test
func manualOverrideReturnsRequestedCoordinates() {
    let resolver = AppleMapsBirthplaceResolver()
    let point = resolver.manualOverride(lat: 10.5, lon: -22.4)
    #expect(point.latitude == 10.5)
    #expect(point.longitude == -22.4)
}
