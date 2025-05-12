import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct IgnoredAppsTabView: View {
    @State private var ignoredApps: [String] = []
    @State private var defaultIgnoredApps: [String] = []
    @State private var appNames: [String: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Ignored Applications").font(.title2).bold()
                Text("Applications in this list will be ignored when using Swift Shift shortcuts.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            }.padding(.horizontal)
            
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    HStack {
                        Button(action: {
                            selectApp()
                        }) {
                            Label("Add", systemImage: "plus.circle")
                        }
                    }.padding(.bottom, 2)
                    
                    if ignoredApps.isEmpty {
                        Text("No applications added")
                            .italic()
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        List {
                            ForEach(ignoredApps, id: \.self) { bundleId in
                                HStack {
                                    Text(appNames[bundleId] ?? bundleId)
                                    Spacer()
                                    Button(action: {
                                        removeApp(bundleId)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }.padding(.vertical, 5)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Note: Some system applications are already ignored by default.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            loadApps()
        }
    }
    
    private func loadApps() {
        defaultIgnoredApps = IGNORE_APP_BUNDLE_ID
        ignoredApps = PreferencesManager.getUserIgnoredApps()
        
        // Resolve bundle IDs to app names
        for bundleId in (defaultIgnoredApps + ignoredApps) {
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
        
        // Activate the app first to ensure its windows are in front
        NSApp.activate(ignoringOtherApps: true)
        
        // Use runModal for sheet-style presentation that will come to the front
        let response = openPanel.runModal()
        
        if response == .OK, let selectedURL = openPanel.url {
            if let bundle = Bundle(url: selectedURL), 
               let bundleIdentifier = bundle.bundleIdentifier {
                let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundleIdentifier
                
                // Don't add if it's already in the default list
                if !defaultIgnoredApps.contains(bundleIdentifier) {
                    // Add to ignored apps list
                    PreferencesManager.addIgnoredApp(bundleIdentifier)
                    appNames[bundleIdentifier] = appName
                    ignoredApps = PreferencesManager.getUserIgnoredApps()
                }
            }
        }
    }
    
    private func removeApp(_ bundleId: String) {
        PreferencesManager.removeIgnoredApp(bundleId)
        ignoredApps = PreferencesManager.getUserIgnoredApps()
    }
}

#Preview {
    IgnoredAppsTabView()
} 
