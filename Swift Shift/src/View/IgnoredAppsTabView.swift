import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct IgnoredAppsTabView: View {
  @State private var ignoredApps: [String] = []
  @State private var appNames: [String: String] = [:]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      VStack(alignment: .leading, spacing: 4) {
        SectionHeader(title: "Ignored Apps", icon: "eye.slash")
        Text("These apps won't respond to Swift Shift shortcuts.")
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)
      }

      // Add button
      Button {
        selectApp()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "plus.circle.fill")
          Text("Add Application")
        }
        .font(.system(size: 12, weight: .medium))
      }
      .buttonStyle(.plain)
      .foregroundStyle(.tint)

      // List
      if ignoredApps.isEmpty {
        HStack {
          Spacer()
          VStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 20))
              .foregroundStyle(.tertiary)
            Text("No apps ignored")
              .font(.system(size: 12))
              .foregroundStyle(.tertiary)
          }
          Spacer()
        }
        .padding(.vertical, 20)
      } else {
        VStack(spacing: 2) {
          ForEach(ignoredApps, id: \.self) { bundleId in
            HStack {
              Text(appNames[bundleId] ?? bundleId)
                .font(.system(size: 12))
                .lineLimit(1)
              Spacer()
              Button {
                removeApp(bundleId)
              } label: {
                Image(systemName: "minus.circle.fill")
                  .font(.system(size: 13))
                  .foregroundStyle(.red.opacity(0.7))
              }
              .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }
        }
      }

      Text("System apps like Notification Center are always ignored.")
        .font(.system(size: 10))
        .foregroundStyle(.quaternary)
    }
    .padding(14)
    .onAppear { loadApps() }
  }

  private func loadApps() {
    ignoredApps = PreferencesManager.getUserIgnoredApps()
    for bundleId in ignoredApps {
      if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
         let appBundle = Bundle(url: appURL),
         let appName = appBundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
        appNames[bundleId] = appName
      }
    }
  }

  private func selectApp() {
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = true
    openPanel.canChooseDirectories = false
    openPanel.allowsMultipleSelection = false
    openPanel.allowedContentTypes = [UTType.application]
    openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

    NSApp.activate(ignoringOtherApps: true)

    let response = openPanel.runModal()
    if response == .OK, let selectedURL = openPanel.url {
      if let bundle = Bundle(url: selectedURL),
         let bundleIdentifier = bundle.bundleIdentifier {
        let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundleIdentifier
        PreferencesManager.addIgnoredApp(bundleIdentifier)
        appNames[bundleIdentifier] = appName
        ignoredApps = PreferencesManager.getUserIgnoredApps()
      }
    }
  }

  private func removeApp(_ bundleId: String) {
    PreferencesManager.removeIgnoredApp(bundleId)
    ignoredApps = PreferencesManager.getUserIgnoredApps()
  }
}

#Preview {
  IgnoredAppsTabView().frame(width: MAIN_WINDOW_WIDTH)
}
