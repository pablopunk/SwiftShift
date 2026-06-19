# Fixes for Issue #167 — System-wide input degradation

## Problem
SwiftShift's mouse-click shortcuts (Command+click for Move, Command+right-click for Resize) use a CGEventTap to intercept mouse events. macOS silently disables event taps on sleep/wake, display changes, session lock, and slow callbacks — but SwiftShift had no recovery mechanism. A dead tap causes system-wide input lag because CGEventTaps are synchronous (WindowServer pauses all input until the callback returns).

## Fixes applied

### 1. CGEventSupervisor: Proper teardown (run loop source leak)
**Files:** `CGEventSupervisor.swift`, `CGEventSupervisor+Setup.swift`

- Added `eventTapRunLoopSource` stored property to track the run loop source
- `teardown()` now removes the source from the run loop and invalidates the CFMachPort, not just disables the tap

### 2. CGEventSupervisor: Handle disabled-tap events
**File:** `CGEventSupervisor+Callback.swift`

- The callback now checks for `.tapDisabledByTimeout` and `.tapDisabledByUserInput`
- When detected, re-enables the tap via `CGEvent.tapEnable(tap:enable: true)`
- Prevents silent tap death from slow callbacks

### 3. ShortcutsManager: System event recovery
**File:** `Swift Shift/src/Manager/ShortcutsManager.swift`

Added observers for three system events that kill taps:
- `NSWorkspace.didWakeNotification` — sleep/wake
- `NSWorkspace.sessionDidBecomeActiveNotification` — screen lock/unlock, fast user switch
- `NSApplication.didChangeScreenParametersNotification` — display connect/disconnect, resolution change

`rebuildAllInputHooks()` now:
1. Stops any active tracking and clears `activeShortcuts` state
2. Tears down the current tap via `CGEventSupervisor.shared.cancelAll()`
3. Rebuilds keyboard monitors via `updateGlobalShortcuts()`
4. Force-rebuilds mouse chord subscriptions via `MouseChordActionManager.shared.forceRebuild()`

### 4. MouseChordActionManager: forceRebuild()
**File:** `Swift Shift/src/Manager/ShortcutsManager.swift`

Added `forceRebuild()` which properly resets the internal `isSubscribed` flag before
re-subscribing. This fixes a state corruption issue where `cancelAll()` could leave
the `isSubscribed` flag true, causing `subscribeIfNeeded()` to return early without
actually re-creating the CGEventSupervisor subscriber.

`ShortcutsManager.rebuildAllInputHooks()` (not `forceRebuild()`) clears
`activeShortcuts` and stops any in-progress tracking before rebuild,
preventing stale modifier-key state from blocking future shortcut activations.

### 5. MouseChordActionManager: Periodic tap health check
**File:** `Swift Shift/src/Manager/ShortcutsManager.swift`

Added a 60-second repeating timer that calls `forceRebuild()` when subscribed.
This catches tap death from Secure Input (password prompts, sudo) and any other
no-notification tap-killing scenarios by fully tearing down and rebuilding the
subscription.

### 6. CGEventSupervisor vendored into project
**Files:** `Swift Shift/packages/CGEventSupervisor/`

The CGEventSupervisor dependency (previously `stephancasas/CGEventSupervisor`)
is now a local package. This allows us to ship the teardown and callback fixes
without waiting for upstream. The package is unchanged except for the fixes
documented in items 1 and 2 above.
The reporter uses Command+click for Move and Command+right-click for Resize. Each shortcut press creates CGEventSupervisor subscriptions which create a CGEventTap. The tap dies silently on system events, and without recovery the tap stays dead — causing the system-wide input delay described in the bug. Restarting the app works because it creates a fresh tap.
