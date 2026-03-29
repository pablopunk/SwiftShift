import SwiftUI

extension Bundle {
  var buildNumber: String {
    return infoDictionary?["CFBundleVersion"] as! String
  }
}

struct InfoView: View {
  private let version: String?

  init() {
    self.version = Bundle.main.buildNumber
  }

  var body: some View {
    VStack(spacing: 14) {
      // App identity + credits combined
      HStack(spacing: 12) {
        Image(systemName: "macwindow.on.rectangle")
          .font(.system(size: 28, weight: .thin))
          .foregroundStyle(.tint)

        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Swift Shift")
              .font(.system(size: 16, weight: .semibold))
            if let version {
              Text("v\(version)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
            }
          }
          HStack(spacing: 4) {
            Text("Made with 🩵 by")
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
            Link("Pablo Varela", destination: URL(string: "https://pablopunk.com")!)
              .font(.system(size: 11, weight: .medium))
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Divider().opacity(0.5)

      // Actions row
      HStack(spacing: 8) {
        Link(destination: URL(string: "https://github.com/pablopunk/SwiftShift")!) {
          HStack(spacing: 5) {
            Image(systemName: "swift")
              .font(.system(size: 11))
            Text("GitHub")
              .font(.system(size: 11, weight: .medium))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .background(.quaternary.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)

        Button {
          UpdatesManager.shared.checkForUpdates()
        } label: {
          HStack(spacing: 5) {
            Image(systemName: "arrow.counterclockwise")
              .font(.system(size: 11))
            Text("Updates")
              .font(.system(size: 11, weight: .medium))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .background(.tint.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)

        Button {
          NSApplication.shared.terminate(0)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "power")
              .font(.system(size: 11))
            Text("Quit")
              .font(.system(size: 11, weight: .medium))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .background(.quaternary.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .keyboardShortcut("Q", modifiers: .command)
      }
    }
    .padding(14)
  }
}

#Preview {
  InfoView().frame(width: MAIN_WINDOW_WIDTH)
}
