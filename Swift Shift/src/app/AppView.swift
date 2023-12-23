import SwiftUI
import ShortcutRecorder
import ServiceManagement
import LaunchAtLogin

struct AppView: View {
    @Binding var showMenuBarIcon: Bool
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("⌘ Swift Shift").font(.title)
                    .padding(.vertical)
                LaunchAtLogin.Toggle()
                
                Toggle(isOn: $showMenuBarIcon) {
                    Text("Show menu bar icon")
                }
            }.padding(.horizontal)
            
            if PermissionsManager.hasAccessibilityPermission() {
                VStack {
                    ForEach(Array(ShortcutType.allCases), id: \.self) { type in
                        ShortcutView(type: type)
                    }
                }
                .padding()
            } else {
                PermissionRequestView()
            }
            
            Button("Quit ⌘+Q") { NSApplication.shared.terminate(0) }
                .keyboardShortcut("Q", modifiers: .command).padding([.bottom, .horizontal])
        }
    }
}

// Preview
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(showMenuBarIcon: .constant(true)) // Updated for preview
    }
}
