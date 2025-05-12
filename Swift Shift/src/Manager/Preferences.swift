import Foundation

enum PreferenceKey: String {
    case focusOnApp = "focusOnApp"
    case showMenuBarIcon = "showMenuBarIcon"
    case useQuadrants = "useQuadrants"
    case requireMouseClick = "requireMouseClick"
    case ignoredApps = "ignoredApps"
}

class PreferencesManager {
    static func loadBool(for key: PreferenceKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    static func getIgnoredApps() -> [String] {
        // Include default apps + user-added apps
        if let savedApps = UserDefaults.standard.array(forKey: PreferenceKey.ignoredApps.rawValue) as? [String] {
            return Array(Set(IGNORE_APP_BUNDLE_ID + savedApps)) // Ensure no duplicates
        }
        return IGNORE_APP_BUNDLE_ID
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
