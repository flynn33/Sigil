import CoreLocation
import Foundation
import MapKit
import RFCoreModels

public protocol BirthplaceResolver: Sendable {
    func search(query: String) async throws -> [PlaceCandidate]
    func resolve(candidate: PlaceCandidate) async throws -> GeoPoint
    func manualOverride(lat: Double, lon: Double) -> GeoPoint
}

public enum LocationPermissionStatus: Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways

    public var canUseLocation: Bool {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways:
            true
        case .notDetermined, .restricted, .denied:
            false
        }
    }
}

public enum CurrentLocationLookupError: LocalizedError, Sendable {
    case locationServicesDisabled
    case permissionDenied(LocationPermissionStatus)
    case noCoordinatesFound
    case locationRequestFailed(String)

    public var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            "Location Services are disabled on this device."
        case .permissionDenied:
            "Location permission is required to use your current location for birthplace lookup."
        case .noCoordinatesFound:
            "Unable to determine your current location."
        case .locationRequestFailed(let message):
            "Location request failed: \(message)"
        }
    }
}

public final class AppleMapsBirthplaceResolver: BirthplaceResolver, Sendable {
    public init() {}

    public func search(query: String) async throws -> [PlaceCandidate] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let response = try await MKLocalSearch(request: request).start()

        return response.mapItems.map {
            PlaceCandidate(
                title: $0.name ?? "Unnamed Place",
                subtitle: $0.placemark.title ?? "",
                location: GeoPoint(
                    latitude: $0.placemark.coordinate.latitude,
                    longitude: $0.placemark.coordinate.longitude
                )
            )
        }
    }

    public func resolve(candidate: PlaceCandidate) async throws -> GeoPoint {
        candidate.location
    }

    public func manualOverride(lat: Double, lon: Double) -> GeoPoint {
        GeoPoint(latitude: lat, longitude: lon)
    }

    public func locationAuthorizationStatus() -> LocationPermissionStatus {
        Self.locationPermissionStatus(from: CLLocationManager().authorizationStatus)
    }

    @MainActor
    public func requestLocationPermissionIfNeeded() async -> LocationPermissionStatus {
        guard CLLocationManager.locationServicesEnabled() else {
            return .restricted
        }

        let status = locationAuthorizationStatus()
        guard status == .notDetermined else {
            return status
        }

        let session = LocationLookupSession()
        return await session.requestAuthorization()
    }

    @MainActor
    public func currentLocationCandidate() async throws -> PlaceCandidate {
        guard CLLocationManager.locationServicesEnabled() else {
            throw CurrentLocationLookupError.locationServicesDisabled
        }

        let session = LocationLookupSession()
        let permission = await session.ensureAuthorized()
        guard permission.canUseLocation else {
            throw CurrentLocationLookupError.permissionDenied(permission)
        }

        let coordinate = try await session.requestCurrentCoordinate()
        let title = try await Self.reverseGeocodedPlaceName(for: coordinate)

        return PlaceCandidate(
            title: title,
            subtitle: String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude),
            location: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
    }

    fileprivate static func locationPermissionStatus(from status: CLAuthorizationStatus) -> LocationPermissionStatus {
        switch status {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .authorizedWhenInUse:
            .authorizedWhenInUse
        case .authorizedAlways:
            .authorizedAlways
        @unknown default:
            .denied
        }
    }

    private static func reverseGeocodedPlaceName(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try await CLGeocoder().reverseGeocodeLocation(location).first

        let placeParts = [
            placemark?.locality,
            placemark?.administrativeArea,
            placemark?.country
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !placeParts.isEmpty else {
            return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
        }

        return placeParts.joined(separator: ", ")
    }
}

@MainActor
private final class LocationLookupSession: NSObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return manager
    }()

    private var permissionContinuation: CheckedContinuation<LocationPermissionStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAuthorization() async -> LocationPermissionStatus {
        let status = AppleMapsBirthplaceResolver.locationPermissionStatus(from: manager.authorizationStatus)
        guard status == .notDetermined else {
            return status
        }

        return await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func ensureAuthorized() async -> LocationPermissionStatus {
        let status = AppleMapsBirthplaceResolver.locationPermissionStatus(from: manager.authorizationStatus)
        guard status == .notDetermined else {
            return status
        }
        return await requestAuthorization()
    }

    func requestCurrentCoordinate() async throws -> CLLocationCoordinate2D {
        let status = await ensureAuthorized()
        guard status.canUseLocation else {
            throw CurrentLocationLookupError.permissionDenied(status)
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.handleAuthorizationChange()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            self.handleLocationUpdate(coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.handleLocationFailure(message: message)
        }
    }

    private func handleAuthorizationChange() {
        guard let continuation = permissionContinuation else {
            return
        }

        let status = AppleMapsBirthplaceResolver.locationPermissionStatus(from: manager.authorizationStatus)
        guard status != .notDetermined else {
            return
        }

        permissionContinuation = nil
        continuation.resume(returning: status)
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D?) {
        guard let continuation = locationContinuation else {
            return
        }

        guard let coordinate else {
            locationContinuation = nil
            continuation.resume(throwing: CurrentLocationLookupError.noCoordinatesFound)
            return
        }

        locationContinuation = nil
        continuation.resume(returning: coordinate)
    }

    private func handleLocationFailure(message: String) {
        guard let continuation = locationContinuation else {
            return
        }

        locationContinuation = nil
        continuation.resume(throwing: CurrentLocationLookupError.locationRequestFailed(message))
    }
}
