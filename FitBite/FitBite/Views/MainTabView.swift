import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) var authVM

    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "fork.knife")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.blue)
    }
}
