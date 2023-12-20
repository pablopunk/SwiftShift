import SwiftUI
import ShortcutRecorder

@main
struct SwiftShiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

