import Foundation

enum PreferenceKey: String {
    case focusOnApp = "focusOnApp"
    case showMenuBarIcon = "showMenuBarIcon"
    case useQuadrants = "useQuadrants"
    case requireMouseClick = "requireMouseClick"
    case fnShortcutWarningDismissed = "fnShortcutWarningDismissed"
    case ignoredApps = "ignoredApps"
}

class PreferencesManager {
    private static var cachedIgnoredApps: Set<String>?
    
    static func loadBool(for key: PreferenceKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    static func invalidateIgnoredAppsCache() {
        cachedIgnoredApps = nil
    }
    
    static func getIgnoredApps() -> [String] {
        if let cached = cachedIgnoredApps {
            return Array(cached)
        }
        var apps = Set(IGNORE_APP_BUNDLE_ID)
        if let savedApps = UserDefaults.standard.array(forKey: PreferenceKey.ignoredApps.rawValue) as? [String] {
            apps.formUnion(savedApps)
        }
        cachedIgnoredApps = apps
        return Array(apps)
    }
    
    static func getUserIgnoredApps() -> [String] {
        // Return only user-added apps
        if let savedApps = UserDefaults.standard.array(forKey: PreferenceKey.ignoredApps.rawValue) as? [String] {
            return savedApps
        }
        return []
    }
    
    static func setUserIgnoredApps(_ apps: [String]) {
        UserDefaults.standard.set(apps, forKey: PreferenceKey.ignoredApps.rawValue)
        invalidateIgnoredAppsCache()
    }
    
    static func addIgnoredApp(_ bundleId: String) {
        var currentList = getUserIgnoredApps()
        
        // Don't add apps that are already in default list
        if !IGNORE_APP_BUNDLE_ID.contains(bundleId) && !currentList.contains(bundleId) {
            currentList.append(bundleId)
            setUserIgnoredApps(currentList)
        }
    }
    
    static func removeIgnoredApp(_ bundleId: String) {
        // Only remove from user list if it's not in the default list
        if !IGNORE_APP_BUNDLE_ID.contains(bundleId) {
            var currentList = getUserIgnoredApps()
            currentList.removeAll { $0 == bundleId }
            setUserIgnoredApps(currentList)
        }
    }
    
    static func isAppIgnored(_ bundleId: String) -> Bool {
        return getIgnoredApps().contains(bundleId)
    }
}
