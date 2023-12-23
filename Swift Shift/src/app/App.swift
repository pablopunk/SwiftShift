import SwiftUI
import AppKit

@main
struct SwiftShiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        MenuBarExtra {
            AppView()
        } label: {
            Image("MenuBarIcon").renderingMode(.template).resizable()
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 400, height: 400)
    }
}
