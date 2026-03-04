import ForsettiHostTemplate
import RFSigilForsettiModules
import SwiftUI

struct SigilForsettiHostView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @ObservedObject var controller: ForsettiHostController
    let injectionRegistry: ForsettiViewInjectionRegistry
    let primaryModuleID: String

    @State private var didBootModule = false

    var body: some View {
        ZStack {
            if let injectedRoot = injectionRegistry.resolve(viewID: SigilCoreModule.rootShellViewID) {
                injectedRoot
            } else {
                ContentUnavailableView(
                    "Sigil UI unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Root module view injection is missing for \(SigilCoreModule.rootShellViewID).")
                )
            }

            if !controller.isBooted || controller.isBusy {
                loadingOverlay
            }
        }
        .task {
            guard !didBootModule else { return }
            didBootModule = true

            await controller.bootIfNeeded()
            await controller.openModule(moduleID: primaryModuleID)
        }
        .onChange(of: controller.errorMessage) { _, newValue in
            guard let newValue, !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            coordinator.dependencies.diagnostics.record(
                "Forsetti runtime: \(newValue)",
                level: .error,
                category: "forsetti"
            )
            controller.clearError()
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            ProgressView("Loading Sigil")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
