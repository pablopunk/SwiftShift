import SwiftUI
import ShortcutRecorder
import Sparkle

enum Tab: String, CaseIterable {
  case settings = "Settings"
  case ignoredApps = "Ignored Apps"
  case info = "About"

  var icon: String {
    switch self {
    case .settings: return "gear"
    case .ignoredApps: return "macwindow.on.rectangle"
    case .info: return "info.circle"
    }
  }
}

struct AppView: View {
  @State private var selectedTab: Tab = .settings

  var body: some View {
    VStack(spacing: 0) {
      // Navigation tab bar — glass layer
      HStack(spacing: 0) {
        ForEach(Tab.allCases, id: \.self) { tab in
          Button {
            withAnimation(.snappy(duration: 0.25)) {
              selectedTab = tab
            }
          } label: {
            HStack(spacing: 5) {
              Image(systemName: tab.icon)
                .font(.system(size: 12, weight: .medium))
              if selectedTab == tab {
                Text(tab.rawValue)
                  .font(.system(size: 11, weight: .semibold))
                  .lineLimit(1)
                  .fixedSize()
              }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
              Group {
                if selectedTab == tab {
                  Capsule()
                    .fill(.tint.opacity(0.15))
                }
              }
            )
            .clipShape(Capsule())
          }
          .buttonStyle(.plain)
          .foregroundStyle(selectedTab == tab ? .primary : .secondary)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)

      // Content
      Group {
        switch selectedTab {
        case .settings:
          SettingsView()
        case .ignoredApps:
          IgnoredAppsTabView()
        case .info:
          InfoView()
        }
      }
      .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    .frame(width: MAIN_WINDOW_WIDTH)
  }
}

#Preview {
  AppView()
}
