import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage(PreferenceKey.showMenuBarIcon.rawValue) var showMenuBarIcon = true
    @AppStorage(PreferenceKey.focusOnApp.rawValue) var focusOnApp = true
    @AppStorage(PreferenceKey.useQuadrants.rawValue) var useQuadrants = false
    @AppStorage(PreferenceKey.requireMouseClick.rawValue) var requireMouseClick = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            LaunchAtLogin.Toggle()
            
            Toggle(isOn: $showMenuBarIcon) {
                Text("Show menu bar icon")
                Text("Open the app again to re-enable the icon")
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Toggle(isOn: $focusOnApp) {
                Text("Focus on window")
                Text("The window you're interacting with will gain focus")
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Toggle(isOn: $useQuadrants) {
                Text("Use quadrants")
                Text("The resize action will happen from the edge/corner that's closer to your mouse")
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Toggle(isOn: $requireMouseClick) {
                Text("Require mouse click")
                Text("Allows you to use the mouse buttons in your shortcuts")
                    .fixedSize(horizontal: false, vertical: true)
            }.onChange(of: requireMouseClick, perform: { newValue in
                if newValue == false {
                    ShortcutsManager.shared.removeClickActionsForAll()
                }
            })
        }
    }
}

#Preview {
    PreferencesView()
}
