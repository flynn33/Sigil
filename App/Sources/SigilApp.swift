import SwiftUI

@main
struct SigilApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @AppStorage("rf.onboarding.completed") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    RootView()
                        .environmentObject(coordinator)
                        .task { await coordinator.loadProfiles() }
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                }
            }
            .task {
                coordinator.bootstrapDiagnosticsIfNeeded()
            }
        }
    }
}
