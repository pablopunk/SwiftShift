import SwiftUI
import ShortcutRecorder

struct AppView: View {
    @State private var shortcut: Shortcut? {
        didSet {
            ShortcutsManager.shared.shortcut = shortcut
        }
    }
    
    var body: some View {
        VStack {
            Text("Swift Shift").font(.title)
            if PermissionsManager.hasAccessibilityPermission() {
                HStack {
                    Text("Move a window")
                    ShortcutView(shortcut: $shortcut)
                        .frame(width: 150, alignment: .leading)
                        .onChange(of: shortcut) { _oldValue, newValue in
                            self.shortcut = newValue
                        }
                    Button("Clear") {
                        ShortcutsManager.shared.clearShortcut()
                        self.shortcut = nil
                    }
                }
                .padding()
            } else {
                PermissionRequestView()
            }
        }
        .frame(width: 450, height: 150)
        .onAppear {
            // Ensure the shortcut is set when the view appears
            self.shortcut = ShortcutsManager.shared.shortcut
        }
    }
}

#Preview {
    AppView()
}
