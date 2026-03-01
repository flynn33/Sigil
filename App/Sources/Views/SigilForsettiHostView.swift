import ForsettiHostTemplate
import SwiftUI

struct SigilForsettiHostView: View {
    let controller: ForsettiHostController
    let injectionRegistry: ForsettiViewInjectionRegistry

    var body: some View {
        ForsettiHostRootView(
            controller: controller,
            injectionRegistry: injectionRegistry
        )
    }
}
