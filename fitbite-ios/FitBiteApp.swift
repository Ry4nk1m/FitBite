import SwiftUI

@main
struct FitBiteApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authVM.isLoggedIn {
                MainTabView()
                    .environment(authVM)
            } else {
                AuthView()
                    .environment(authVM)
            }
        }
    }
}
