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
  @AppStorage(PreferenceKey.showMenuBarIcon.rawValue) private var showMenuBarIcon = true
  @AppStorage(PreferenceKey.focusOnApp.rawValue) private var focusOnApp = true
  @AppStorage(PreferenceKey.useQuadrants.rawValue) private var useQuadrants = false
  @AppStorage(PreferenceKey.snapToWindows.rawValue) private var snapToWindows = true

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
        isOn: $snapToWindows,
        title: "Snap to nearby windows",
        subtitle: "Add resistance near window edges",
        icon: "macwindow.on.rectangle"
      )
    }
  }
}

#Preview {
  PreferencesView().padding().frame(width: 300)
}
