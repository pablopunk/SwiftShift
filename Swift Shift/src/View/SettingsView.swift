import SwiftUI
import ShortcutRecorder
import Sparkle

struct SectionHeader: View {
  let title: String
  let icon: String

  var body: some View {
    Label(title, systemImage: icon)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
  }
}

struct SettingsView: View {
  @State private var hasPermissions = false
  @AppStorage(PreferenceKey.requireMouseClick.rawValue) var requireMouseClick = false
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  init(hasPermissions: Bool = false) {
    self._hasPermissions = State(initialValue: hasPermissions)
  }

  private func refreshPermissions() {
    hasPermissions = PermissionsManager.hasAccessibilityPermission()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      // Preferences section
      VStack(alignment: .leading, spacing: 6) {
        SectionHeader(title: "Preferences", icon: "slider.horizontal.3")
        PreferencesView()
      }

      Divider().opacity(0.5)

      // Shortcuts section
      VStack(alignment: .leading, spacing: 6) {
        SectionHeader(title: "Shortcuts", icon: "keyboard")

        if hasPermissions {
          VStack(spacing: requireMouseClick ? 16 : 4) {
            ForEach(Array(ShortcutType.allCases), id: \.self) { type in
              ShortcutView(type: type)
            }
          }
        } else {
          PermissionRequestView()
        }
      }

      Divider().opacity(0.5)

      // Quit
      HStack {
        Button {
          NSApplication.shared.terminate(0)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "power")
            Text("Quit")
            Text("⌘Q")
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
          .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .keyboardShortcut("Q", modifiers: .command)
      }
    }
    .padding(14)
    .onAppear { refreshPermissions() }
    .onReceive(timer) { _ in refreshPermissions() }
  }
}

#Preview {
  SettingsView(hasPermissions: true).frame(width: MAIN_WINDOW_WIDTH)
}
