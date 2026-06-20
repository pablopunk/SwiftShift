import XCTest
@testable import Swift_Shift_Dev

final class PreferencesManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for the test suite to avoid cross-test contamination
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PreferenceKey.ignoredApps.rawValue)
        defaults.removeObject(forKey: PreferenceKey.focusOnApp.rawValue)
        defaults.removeObject(forKey: PreferenceKey.showMenuBarIcon.rawValue)
        defaults.removeObject(forKey: PreferenceKey.useQuadrants.rawValue)
        defaults.removeObject(forKey: PreferenceKey.requireMouseClick.rawValue)
        // Default to migration-complete to prevent tests from accidentally triggering migration
        defaults.set(true, forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        defaults.synchronize()
        PreferencesManager.invalidateIgnoredAppsCache()
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PreferenceKey.ignoredApps.rawValue)
        defaults.removeObject(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        defaults.removeObject(forKey: PreferenceKey.focusOnApp.rawValue)
        defaults.removeObject(forKey: PreferenceKey.showMenuBarIcon.rawValue)
        defaults.removeObject(forKey: PreferenceKey.useQuadrants.rawValue)
        defaults.removeObject(forKey: PreferenceKey.requireMouseClick.rawValue)
        defaults.synchronize()
        PreferencesManager.invalidateIgnoredAppsCache()
        super.tearDown()
    }

    // MARK: - Bool Preferences

    func testLoadBool_defaultValue() {
        // UserDefaults returns false for unset keys
        XCTAssertFalse(PreferencesManager.loadBool(for: .useQuadrants))
    }

    func testLoadBool_setAndRead() {
        UserDefaults.standard.set(true, forKey: PreferenceKey.focusOnApp.rawValue)
        XCTAssertTrue(PreferencesManager.loadBool(for: .focusOnApp))

        UserDefaults.standard.set(false, forKey: PreferenceKey.focusOnApp.rawValue)
        XCTAssertFalse(PreferencesManager.loadBool(for: .focusOnApp))
    }

    // MARK: - Ignored Apps

    func testGetIgnoredApps_includesSystemApps() {
        let apps = PreferencesManager.getIgnoredApps()
        // System ignored apps are always present
        XCTAssertTrue(apps.contains("com.apple.notificationcenterui"))
    }

    func testGetIgnoredApps_includesDefaultsOnFirstLaunch() {
        // Simulate first launch: clear migration flag and saved apps
        UserDefaults.standard.removeObject(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKey.ignoredApps.rawValue)
        PreferencesManager.invalidateIgnoredAppsCache()
        
        let apps = PreferencesManager.getIgnoredApps()

        // Should contain at least the system apps + defaults
        XCTAssertTrue(apps.contains("com.apple.notificationcenterui"))
        // At least one of the default apps should be present
        let hasDefaultApp = apps.contains { DEFAULT_IGNORED_APP_BUNDLE_ID.contains($0) }
        XCTAssertTrue(hasDefaultApp, "Should include default ignored apps on first launch")
    }

    func testGetUserIgnoredApps_whenEmpty_returnsDefaults() {
        // Simulate first launch: clear migration flag and saved apps
        UserDefaults.standard.removeObject(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKey.ignoredApps.rawValue)
        PreferencesManager.invalidateIgnoredAppsCache()
        
        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertFalse(apps.isEmpty)
        // All returned apps should be from the default list
        for app in apps {
            XCTAssertTrue(DEFAULT_IGNORED_APP_BUNDLE_ID.contains(app),
                          "\(app) should be in DEFAULT_IGNORED_APP_BUNDLE_ID")
        }
    }

    func testSetUserIgnoredApps_overridesList() {
        // Mark migration as done to prevent defaults from being merged
        UserDefaults.standard.set(true, forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        PreferencesManager.invalidateIgnoredAppsCache()
        
        let customApps = ["com.example.app1", "com.example.app2"]
        PreferencesManager.setUserIgnoredApps(customApps)

        let retrieved = PreferencesManager.getUserIgnoredApps()
        XCTAssertEqual(Set(retrieved), Set(customApps))
    }

    func testAddIgnoredApp_addsToExistingList() {
        // Start with a known list
        PreferencesManager.setUserIgnoredApps(["com.example.existing"])
        PreferencesManager.addIgnoredApp("com.example.newapp")

        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertTrue(apps.contains("com.example.existing"))
        XCTAssertTrue(apps.contains("com.example.newapp"))
    }

    func testAddIgnoredApp_doesNotAddDuplicates() {
        PreferencesManager.setUserIgnoredApps(["com.example.app"])
        PreferencesManager.addIgnoredApp("com.example.app")
        PreferencesManager.addIgnoredApp("com.example.app")

        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertEqual(apps.filter { $0 == "com.example.app" }.count, 1)
    }

    func testAddIgnoredApp_preventsSystemAppAddition() {
        // System ignored apps cannot be added to the user list
        PreferencesManager.setUserIgnoredApps(["com.example.app"])
        PreferencesManager.addIgnoredApp("com.apple.notificationcenterui")

        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertFalse(apps.contains("com.apple.notificationcenterui"))
    }

    func testRemoveIgnoredApp_removesFromList() {
        PreferencesManager.setUserIgnoredApps(["com.example.app1", "com.example.app2"])
        PreferencesManager.removeIgnoredApp("com.example.app1")

        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertFalse(apps.contains("com.example.app1"))
        XCTAssertTrue(apps.contains("com.example.app2"))
    }

    func testRemoveIgnoredApp_cannotRemoveSystemApp() {
        // Even if a system app somehow ends up in the user list, removal is blocked
        PreferencesManager.setUserIgnoredApps(["com.apple.notificationcenterui", "com.example.app"])
        PreferencesManager.removeIgnoredApp("com.apple.notificationcenterui")

        let apps = PreferencesManager.getUserIgnoredApps()
        // The system app remains in the user list because the guard prevents removal
        XCTAssertTrue(apps.contains("com.apple.notificationcenterui"))
        XCTAssertTrue(apps.contains("com.example.app"))
    }

    func testIsAppIgnored_checksBothLists() {
        // Reset to first-launch state to include default apps
        UserDefaults.standard.removeObject(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKey.ignoredApps.rawValue)
        PreferencesManager.invalidateIgnoredAppsCache()
        
        // System apps are always ignored
        XCTAssertTrue(PreferencesManager.isAppIgnored("com.apple.notificationcenterui"))

        // Default apps are initially ignored
        XCTAssertTrue(PreferencesManager.isAppIgnored("pl.maketheweb.cleanshotx"))
    }

    func testIsAppIgnored_respectsCustomList() {
        PreferencesManager.setUserIgnoredApps(["com.example.custom"])
        XCTAssertTrue(PreferencesManager.isAppIgnored("com.example.custom"))
        XCTAssertFalse(PreferencesManager.isAppIgnored("com.other.app"))
    }

    // MARK: - Cache Invalidation

    func testCacheInvalidation_reflectsChanges() {
        // Populate cache
        let _ = PreferencesManager.getIgnoredApps()

        // Change user list
        PreferencesManager.setUserIgnoredApps(["com.example.cachedtest"])
        PreferencesManager.invalidateIgnoredAppsCache()

        // Should reflect the new list
        let apps = PreferencesManager.getIgnoredApps()
        XCTAssertTrue(apps.contains("com.example.cachedtest"))
    }

    func testAddIgnoredApp_invalidatesCache() {
        PreferencesManager.setUserIgnoredApps(["com.example.initial"])
        let _ = PreferencesManager.getIgnoredApps() // populate cache

        PreferencesManager.addIgnoredApp("com.example.added")
        let apps = PreferencesManager.getIgnoredApps()
        XCTAssertTrue(apps.contains("com.example.added"))
    }

    // MARK: - Migration

    func testMigration_addsDefaultAppsWhenMissing() {
        // Reset migration flag
        UserDefaults.standard.removeObject(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)
        PreferencesManager.invalidateIgnoredAppsCache()

        // Set a custom list without defaults
        PreferencesManager.setUserIgnoredApps(["com.example.only"])

        // First call to getUserIgnoredApps should trigger migration
        let apps = PreferencesManager.getUserIgnoredApps()
        XCTAssertTrue(apps.contains("com.example.only"))

        // After migration, the migration flag should be set
        XCTAssertTrue(UserDefaults.standard.bool(forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue))
    }

    func testMigration_doesNotRunTwice() {
        // Mark migration as done
        UserDefaults.standard.set(true, forKey: PreferenceKey.didMigrateDefaultIgnoredApps.rawValue)

        let customApps = ["com.example.unique"]
        PreferencesManager.setUserIgnoredApps(customApps)

        let apps = PreferencesManager.getUserIgnoredApps()
        // Should only return the custom apps, not merged with defaults
        XCTAssertEqual(Set(apps), Set(customApps))
    }
}
