import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage(PreferenceKey.showMenuBarIcon.rawValue) var showMenuBarIcon = true
    @AppStorage(PreferenceKey.focusOnApp.rawValue) var focusOnApp = true

    var body: some View {
        VStack(alignment: .leading) {
            
            LaunchAtLogin.Toggle()
            
            Toggle(isOn: $showMenuBarIcon) {
                Text("Show menu bar icon")
                Text("Open the app again to re-enable the icon")
            }
            
            Toggle(isOn: $focusOnApp) {
                Text("Focus on window")
                Text("The window you're interacting with will gain focus")
            }
        }
    }
}

#Preview {
    PreferencesView()
}
