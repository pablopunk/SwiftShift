import SwiftUI
import AppKit

@main
struct SwiftShiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        MenuBarExtra("⌘") {
            AppView()
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 400, height: 400)
    }
}
