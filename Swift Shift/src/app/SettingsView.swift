import SwiftUI
import ShortcutRecorder
import Sparkle

struct SettingsView: View {
    @State var hasPermissions = false
    private var version: String? = nil
    
    init(hasPermissions: Bool = false) {
        self.hasPermissions = hasPermissions
        self.version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    private func refreshPermissions() {
        hasPermissions =  PermissionsManager.hasAccessibilityPermission()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text("Preferences").font(.title2).bold()
                
                PreferencesView()
            }.padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Shortcuts").font(.title2).bold()
                
                if hasPermissions {
                    VStack {
                        ForEach(Array(ShortcutType.allCases), id: \.self) { type in
                            ShortcutView(type: type)
                        }
                    }
                } else {
                    PermissionRequestView().padding(.vertical, 5)
                }
            }.padding(.horizontal)
            
            Divider()
            
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(0)
                }, label: {
                    HStack {
                        Text("Quit")
                        Text("⌘+Q").foregroundStyle(.gray).font(.subheadline)
                    }
                })
                .keyboardShortcut("Q", modifiers: .command)
                
                if !hasPermissions {
                    Button("Refresh permissions") {
                        refreshPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding([.bottom, .horizontal])
            .padding(.top, 5)
        }
        .onAppear {
            refreshPermissions()
        }
    }
}

#Preview {
    SettingsView(hasPermissions: true).frame(width: MAIN_WINDOW_WIDTH)
}
