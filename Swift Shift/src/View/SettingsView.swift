import SwiftUI
import ShortcutRecorder
import Sparkle

struct SettingsView: View {
  @State private var hasPermissions = false
  private var version: String?
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  init(hasPermissions: Bool = false) {
    self._hasPermissions = State(initialValue: hasPermissions)
    self.version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }
  
  private func refreshPermissions() {
    hasPermissions = PermissionsManager.hasAccessibilityPermission()
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
                .padding(.vertical, 6)
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
            Text("⌘+Q").foregroundStyle(.secondary).font(.subheadline)
          }
        })
        .keyboardShortcut("Q", modifiers: .command)
      }
      .padding([.bottom, .horizontal])
      .padding(.top, 5)
    }
    .onAppear {
      refreshPermissions()
    }
    .onReceive(timer) { _ in
      refreshPermissions()
    }
  }
}

#Preview {
  SettingsView(hasPermissions: true).frame(width: MAIN_WINDOW_WIDTH)
}
