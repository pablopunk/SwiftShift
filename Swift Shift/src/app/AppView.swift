import SwiftUI
import ShortcutRecorder
import ServiceManagement
import LaunchAtLogin


struct AppView: View {
    var body: some View {
        VStack {
            Text("Swift Shift").font(.title)
            LaunchAtLogin.Toggle()
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
        }
        .padding(24)
    }
}

#Preview {
    AppView()
}
