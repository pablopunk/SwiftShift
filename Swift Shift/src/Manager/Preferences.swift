import Foundation

enum PreferenceKey: String {
    case focusOnApp = "focusOnApp"
    case showMenuBarIcon = "showMenuBarIcon"
    case useQuadrants = "useQuadrants"
    case requireMouseClick = "requireMouseClick"
    case fnShortcutWarningDismissed = "fnShortcutWarningDismissed"
    case ignoredApps = "ignoredApps"
    case didMigrateDefaultIgnoredApps = "didMigrateDefaultIgnoredApps"
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
        var apps = Set(SYSTEM_IGNORED_APP_BUNDLE_ID)
        apps.formUnion(getUserIgnoredApps())
        cachedIgnoredApps = apps
        return Array(apps)
    }
    
    static func getUserIgnoredApps() -> [String] {
        migrateDefaultIgnoredAppsIfNeeded()
        if let savedApps = UserDefaults.standard.array(forKey: PreferenceKey.ignoredApps.rawValue) as? [String] {
            return savedApps
        }
        return DEFAULT_IGNORED_APP_BUNDLE_ID
    }
    
    private static func migrateDefaultIgnoredAppsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue) else { return }
        
        var savedApps = UserDefaults.standard.array(forKey: PreferenceKey.ignoredApps.rawValue) as? [String] ?? []
        var merged = Set(savedApps)
        let originalCount = merged.count
        merged.formUnion(DEFAULT_IGNORED_APP_BUNDLE_ID)
        
        // Only save if we actually added new defaults
        if merged.count > originalCount {
            UserDefaults.standard.set(Array(merged), forKey: PreferenceKey.ignoredApps.rawValue)
        }
        
        UserDefaults.standard.set(true, forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
    }
    
    static func setUserIgnoredApps(_ apps: [String]) {
        UserDefaults.standard.set(apps, forKey: PreferenceKey.ignoredApps.rawValue)
        invalidateIgnoredAppsCache()
    }
    
    static func addIgnoredApp(_ bundleId: String) {
        guard !SYSTEM_IGNORED_APP_BUNDLE_ID.contains(bundleId) else { return }
        var currentList = getUserIgnoredApps()
        
        if !currentList.contains(bundleId) {
            currentList.append(bundleId)
            setUserIgnoredApps(currentList)
        }
    }
    
    static func removeIgnoredApp(_ bundleId: String) {
        guard !SYSTEM_IGNORED_APP_BUNDLE_ID.contains(bundleId) else { return }
        var currentList = getUserIgnoredApps()
        currentList.removeAll { $0 == bundleId }
        setUserIgnoredApps(currentList)
    }
    
    static func isAppIgnored(_ bundleId: String) -> Bool {
        return getIgnoredApps().contains(bundleId)
    }
}
