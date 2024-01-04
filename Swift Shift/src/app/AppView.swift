import SwiftUI
import ShortcutRecorder
import Sparkle

struct AppView: View {
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
            HStack(alignment: .center) {
                Text("⌘ Swift Shift")
                    .font(.headline)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    if (version != nil) {
                        Text("v" + version!)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    
                    CheckUpdatesButton()
                }
            }.padding(.horizontal)
                .padding(.top, 6)
            
            Divider()
            
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
        .frame(width: 320)
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
