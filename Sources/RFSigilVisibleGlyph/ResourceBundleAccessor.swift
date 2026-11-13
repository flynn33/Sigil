import Foundation

#if !SWIFT_PACKAGE
/// XcodeGen/framework counterpart to SwiftPM's generated `Bundle.module`.
/// Resources ship in this framework's Resources build phase.
private final class ResourceBundleLocator {}

extension Bundle {
    static let module: Bundle = Bundle(for: ResourceBundleLocator.self)
}
#endif
