import SwiftUI

struct PermissionRequestView: View {
    @State var key = UUID() // To force view refresh

    var body: some View {
        VStack {
            Text("Accessibility Permission Required")
            Text("This app requires accessibility permissions to function properly.")
            Button("Open System Preferences") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Refresh") {
                self.key = UUID() // Change key to force ContentView to re-render
            }
        }
    }
}
