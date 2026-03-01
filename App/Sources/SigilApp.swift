import ForsettiHostTemplate
import SwiftUI

@main
struct SigilApp: App {
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var hostController: ForsettiHostController
    private let injectionRegistry: ForsettiViewInjectionRegistry

    @AppStorage("rf.onboarding.completed") private var onboardingCompleted = false

    @MainActor
    init() {
        let appCoordinator = AppCoordinator()
        let artifacts = SigilForsettiBootstrap.makeHostArtifacts(coordinator: appCoordinator)

        _coordinator = StateObject(wrappedValue: appCoordinator)
        _hostController = StateObject(wrappedValue: artifacts.controller)
        injectionRegistry = artifacts.injectionRegistry
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    SigilForsettiHostView(
                        controller: hostController,
                        injectionRegistry: injectionRegistry
                    )
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                }
            }
            .task {
                coordinator.bootstrapDiagnosticsIfNeeded()
                await coordinator.loadProfiles()
            }
        }
    }
}
