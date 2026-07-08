import RFSigilRuntime
import RFSigilUIModule
import SwiftUI

@main
struct SigilApp: App {
    @StateObject private var viewModel: SigilDashboardViewModel

    init() {
        let assembly = SigilRuntimeAssembly()
        _viewModel = StateObject(
            wrappedValue: SigilDashboardViewModel(status: assembly.dashboardStatus())
        )
    }

    var body: some Scene {
        WindowGroup {
            SigilPhase1DashboardView(viewModel: viewModel)
        }
    }
}
