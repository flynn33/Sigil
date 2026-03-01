import ForsettiHostTemplate
import RFSigilForsettiModules
import SwiftUI

struct SigilForsettiHostView: View {
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
        .alert(
            "Forsetti Error",
            isPresented: Binding(
                get: { controller.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        controller.clearError()
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    controller.clearError()
                }
            },
            message: {
                Text(controller.errorMessage ?? "Unknown error")
            }
        )
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
