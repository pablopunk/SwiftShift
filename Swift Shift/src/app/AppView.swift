import SwiftUI
import ShortcutRecorder
import ServiceManagement

struct AppView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    
    var body: some View {
        VStack {
            Text("Swift Shift").font(.title)
            Toggle(isOn: $startAtLogin) {
                Text("Start at login")
            }
            .onChange(of: startAtLogin) { value in
                setStartAtLogin(value)
            }
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
        .onAppear {
            // Load the initial state from UserDefaults
            startAtLogin = UserDefaults.standard.bool(forKey: "startAtLogin")
        }
    }
    
    private func setStartAtLogin(_ enabled: Bool) {
        // Create an SMAppService instance with your app's bundle identifier
        let appService = SMAppService()
        
        if enabled {
            // Register the app service to start at login
            do {
                try appService.register()
            } catch {
                print("Failed to register app service: \(error.localizedDescription)")
            }
        } else {
            // Unregister the app service
            appService.unregister { error in
                if let error = error {
                    print("Failed to unregister app service: \(error.localizedDescription)")
                }
            }
        }
        
        // Save the user preference
        UserDefaults.standard.set(enabled, forKey: "startAtLogin")
    }
}

#Preview {
    AppView()
}
