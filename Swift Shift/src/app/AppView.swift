import SwiftUI
import ShortcutRecorder
import LaunchAtLogin

struct AppView: View {
    @State var hasPermissions = false
    @AppStorage("showMenuBarIcon") var showMenuBarIcon = true
    private var version: String? = nil
    
    init(hasPermissions: Bool = false, showMenuBarIcon: Bool = true, version: String? = nil) {
        self.hasPermissions = hasPermissions
        self.showMenuBarIcon = showMenuBarIcon
        self.version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    private func refreshPermissions() {
        hasPermissions =  PermissionsManager.hasAccessibilityPermission()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("⌘ Swift Shift")
                    .font(.headline)
                
                Spacer()
                
                if (version != nil) {
                    Text("version " + version!)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }.padding(.horizontal)
                .padding(.top, 6)
            
            Divider()
            
            VStack(alignment: .leading) {
                
                LaunchAtLogin.Toggle()
                
                Toggle(isOn: $showMenuBarIcon) {
                    Text("Show menu bar icon")
                }
            }.padding(.horizontal)
            
            Divider()
            
            if hasPermissions {
                VStack {
                    ForEach(Array(ShortcutType.allCases), id: \.self) { type in
                        ShortcutView(type: type)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 3)
            } else {
                PermissionRequestView()
                    .padding(.horizontal)
            }
            
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
                }
            }
            .padding([.bottom, .horizontal])
            .padding(.top, 5)
        }
        .frame(width: 260)
        .onAppear {
            refreshPermissions()
        }
    }
}

// Preview
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
