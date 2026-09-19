import SwiftUI
import SwiftData

@main
struct LensApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environment(settings)
        }
        .modelContainer(for: Record.self)
    }
}
