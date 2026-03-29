import SwiftUI
import LaunchAtLogin

struct PreferenceToggle: View {
  @Binding var isOn: Bool
  let title: String
  let subtitle: String
  let icon: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 13))
        .foregroundStyle(.tint)
        .frame(width: 18)
      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: 12, weight: .medium))
        Text(subtitle)
          .font(.system(size: 10))
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
      Spacer()
      Toggle("", isOn: $isOn)
        .toggleStyle(.switch)
        .controlSize(.mini)
        .labelsHidden()
    }
    .frame(minHeight: 32)
  }
}

struct PreferencesView: View {
  @AppStorage(PreferenceKey.showMenuBarIcon.rawValue) var showMenuBarIcon = true
  @AppStorage(PreferenceKey.focusOnApp.rawValue) var focusOnApp = true
  @AppStorage(PreferenceKey.useQuadrants.rawValue) var useQuadrants = false
  @AppStorage(PreferenceKey.requireMouseClick.rawValue) var requireMouseClick = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "play.circle")
          .font(.system(size: 13))
          .foregroundStyle(.tint)
          .frame(width: 18)
        Text("Launch at login")
          .font(.system(size: 12, weight: .medium))
        Spacer()
        LaunchAtLogin.Toggle { EmptyView() }
          .toggleStyle(.switch)
          .controlSize(.mini)
          .labelsHidden()
      }
      .frame(minHeight: 32)

      PreferenceToggle(
        isOn: $showMenuBarIcon,
        title: "Show menu bar icon",
        subtitle: "Reopen app to re-enable",
        icon: "menubar.rectangle"
      )

      PreferenceToggle(
        isOn: $focusOnApp,
        title: "Focus on window",
        subtitle: "Target window gains focus",
        icon: "macwindow"
      )

      PreferenceToggle(
        isOn: $useQuadrants,
        title: "Use quadrants",
        subtitle: "Resize from nearest edge/corner",
        icon: "rectangle.split.2x2"
      )

      PreferenceToggle(
        isOn: $requireMouseClick,
        title: "Require mouse click",
        subtitle: "Use mouse buttons in shortcuts",
        icon: "computermouse"
      )
      .onChange(of: requireMouseClick) { newValue in
        if newValue == false {
          ShortcutsManager.shared.removeClickActionsForAll()
        }
      }
    }
  }
}

#Preview {
  PreferencesView().padding().frame(width: 300)
}
