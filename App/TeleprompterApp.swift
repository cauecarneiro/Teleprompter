import SwiftData
import SwiftUI

@main
struct TeleprompterApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .tint(.white)
        }
        .modelContainer(for: [Script.self, Take.self])
    }
}
