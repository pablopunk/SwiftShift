import Cocoa
import Accessibility
enum MouseAction: String { case move, resize, none }
enum Quadrant { case topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight }
class MouseTracker {
    static let shared = MouseTracker()
    private var mouseEventMonitor: Any?, initialMouseLocation, initialWindowLocation: NSPoint?
    private var trackedWindow: AXUIElement?, trackedWindowIsFocused = false, shouldFocusWindow = false
    private var currentAction: MouseAction = .none, trackingTimer: Timer?
    private let trackingTimeout: TimeInterval = 4, minimumUpdateInterval: TimeInterval = 1.0 / 120.0
    private var shouldUseQuadrants = false, quadrant: Quadrant?, windowSize: CGSize?, isTracking = false
    private var spaceChangeObserver: Any?, pendingMouseLocation: NSPoint?, lastUpdateTime: TimeInterval = 0
    private var lastAppliedOrigin: NSPoint?, lastAppliedSize: CGSize?
    private init() { registerForSpaceChangeNotifications() }
    deinit { unregisterForSpaceChangeNotifications() }
    private func registerForSpaceChangeNotifications() {
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in self?.handleSpaceChange() }
    }
    private func unregisterForSpaceChangeNotifications() { if let obs = spaceChangeObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) } }
    private func handleSpaceChange() {
        guard currentAction != .none, trackedWindow != nil else { return }
        if isTracking { forceResetTracking() }
    }
    func startTracking(for action: MouseAction, button: MouseButton) {
        if currentAction != .none { stopTracking(for: currentAction) }
        prepareTracking(for: action)
        if trackedWindow != nil { registerMouseEventMonitor(button: button); startTrackingTimer(); isTracking = true }
    }
    func stopTracking(for action: MouseAction) {
        guard currentAction == action else { return }
        flushPendingMouseUpdate(); invalidateTrackingTimer(); removeMouseEventMonitor(); resetTrackingVariables(); isTracking = false
    }
    func forceResetTracking() {
        guard currentAction != .none, let window = trackedWindow else { return }
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowLocation = WindowManager.getPosition(window: window)
        windowSize = WindowManager.getSize(window: window)
        pendingMouseLocation = nil
        lastAppliedOrigin = initialWindowLocation
        lastAppliedSize = windowSize
        if currentAction == .resize, shouldUseQuadrants, let m = initialMouseLocation, let w = initialWindowLocation, let s = windowSize {
            quadrant = determineQuadrant(mouseLocation: m, windowSize: s, windowLocation: w)
        }
    }
    private func prepareTracking(for action: MouseAction) {
        guard let currentWindow = WindowManager.getCurrentWindow(), !shouldIgnore(window: currentWindow) else { trackedWindow = nil; return }
        shouldFocusWindow = PreferencesManager.loadBool(for: .focusOnApp)
        shouldUseQuadrants = PreferencesManager.loadBool(for: .useQuadrants)
        trackedWindowIsFocused = false; currentAction = action; initialMouseLocation = NSEvent.mouseLocation
        trackedWindow = currentWindow; initialWindowLocation = WindowManager.getPosition(window: currentWindow)
        windowSize = WindowManager.getSize(window: currentWindow); pendingMouseLocation = nil; lastUpdateTime = 0
        lastAppliedOrigin = initialWindowLocation; lastAppliedSize = windowSize
        if action == .resize && shouldUseQuadrants, let m = initialMouseLocation, let w = initialWindowLocation, let s = windowSize {
            quadrant = determineQuadrant(mouseLocation: m, windowSize: s, windowLocation: w)
        }
    }
    private func shouldIgnore(window: AXUIElement) -> Bool {
        guard let app = WindowManager.getNSApplication(from: window), let bid = app.bundleIdentifier, PreferencesManager.isAppIgnored(bid) else { return false }
        return true
    }
    private func determineQuadrant(mouseLocation: NSPoint, windowSize: CGSize, windowLocation: NSPoint) -> Quadrant {
        let b = WindowManager.getWindowBounds(windowLocation: windowLocation, windowSize: windowSize)
        let cSize = 0.25, sSize = (1 - cSize) / 2
        let tx = (b.topRight.x - b.topLeft.x) * sSize, ty = (b.topLeft.y - b.bottomLeft.y) * sSize
        let lx = b.topLeft.x + tx, rx = b.topRight.x - tx, tyP = b.topLeft.y - ty, by = b.bottomLeft.y + ty
        switch (mouseLocation.x, mouseLocation.y) {
            case (..<lx, tyP...): return .topLeft
            case (lx..<rx, tyP...): return .top
            case (rx..., tyP...): return .topRight
            case (..<lx, by..<tyP): return .left
            case (lx..<rx, by..<tyP): return .center
            case (rx..., by..<tyP): return .right
            case (..<lx, ..<by): return .bottomLeft
            case (lx..<rx, ..<by): return .bottom
            default: return .bottomRight
        }
    }
    private func registerMouseEventMonitor(button: MouseButton) {
        removeMouseEventMonitor()
        let mask: NSEvent.EventTypeMask = button == .left ? .leftMouseDragged : (button == .right ? .rightMouseDragged : .mouseMoved)
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [mask]) { [weak self] e in self?.handleMouseMoved(e) }
    }
    private func startTrackingTimer() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: trackingTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.stopTracking(for: self.currentAction)
        }
    }
    private func handleMouseMoved(_ event: NSEvent) {
        guard isTracking, let _ = initialMouseLocation, let _ = initialWindowLocation, let _ = trackedWindow else { return }
        if checkForKeyPresses() { pauseTracking(); return }
        if shouldFocusWindow && !trackedWindowIsFocused { WindowManager.focus(window: trackedWindow!); trackedWindowIsFocused = true }
        pendingMouseLocation = NSEvent.mouseLocation
        if event.timestamp - lastUpdateTime >= minimumUpdateInterval { flushPendingMouseUpdate(at: event.timestamp) }
    }
    private func flushPendingMouseUpdate(at timestamp: TimeInterval? = nil) {
        guard let loc = pendingMouseLocation else { return }; pendingMouseLocation = nil
        if currentAction == .move { moveWindowBasedOnMouseLocation(loc) } else if currentAction == .resize { resizeWindowBasedOnMouseLocation(loc) }
        if let t = timestamp { lastUpdateTime = t }
    }
    private func moveWindowBasedOnMouseLocation(_ loc: NSPoint) {
        let dx = loc.x - initialMouseLocation!.x, dy = loc.y - initialMouseLocation!.y
        let newO = NSPoint(x: initialWindowLocation!.x + dx, y: initialWindowLocation!.y - dy)
        if !pointsApproximatelyEqual(newO, lastAppliedOrigin) { lastAppliedOrigin = newO; WindowManager.move(window: trackedWindow!, to: newO) }
    }
    private func resizeWindowBasedOnMouseLocation(_ loc: NSPoint) {
        guard let s = windowSize, let im = initialMouseLocation, let iw = initialWindowLocation else { return }
        var nw = s.width, nh = s.height, no = iw
        if shouldUseQuadrants, let q = quadrant {
            let dx = (loc.x - iw.x) - (im.x - iw.x), dy = (loc.y - iw.y) - (im.y - iw.y)
            switch q {
                case .topLeft: nw -= dx; nh += dy; no.x += dx; no.y -= dy
                case .top: nh += dy; no.y -= dy
                case .topRight: nw += dx; nh += dy; no.y -= dy
                case .left: nw -= dx; no.x += dx
                case .center: nw += 2*dx; no.x -= dx; nh += 2*dy; no.y -= dy
                case .right: nw += dx
                case .bottomLeft: nw -= dx; nh -= dy; no.x += dx
                case .bottom: nh -= dy
                case .bottomRight: nw += dx; nh -= dy
            }
        } else {
            nw = s.width + (loc.x - im.x); nh = s.height - (loc.y - im.y)
        }
        nw = max(nw, 1); nh = max(nh, 1); let ns = CGSize(width: nw, height: nh)
        let moveO = !pointsApproximatelyEqual(no, lastAppliedOrigin)
        if moveO || !sizesApproximatelyEqual(ns, lastAppliedSize) {
            lastAppliedOrigin = no; lastAppliedSize = ns; WindowManager.resize(window: trackedWindow!, to: ns, from: no, shouldMoveOrigin: moveO)
        }
    }
    private func invalidateTrackingTimer() { trackingTimer?.invalidate(); trackingTimer = nil }
    private func removeMouseEventMonitor() { if let m = mouseEventMonitor { NSEvent.removeMonitor(m); mouseEventMonitor = nil } }
    private func resetTrackingVariables() { pendingMouseLocation = nil; lastUpdateTime = 0; lastAppliedOrigin = nil; lastAppliedSize = nil; trackedWindow = nil; initialMouseLocation = nil; initialWindowLocation = nil; currentAction = .none; quadrant = nil; windowSize = nil }
    func pauseTracking() { isTracking = false }
    func resumeTracking() { if currentAction != .none && trackedWindow != nil { isTracking = true } }
    private func checkForKeyPresses() -> Bool {
        guard let ev = NSApp.currentEvent else { return false }
        if ev.type == .keyDown || ev.type == .keyUp { if (36...126).contains(ev.keyCode) { return true } }
        return false
    }
    private func pointsApproximatelyEqual(_ a: NSPoint?, _ b: NSPoint?) -> Bool {
        guard let a = a, let b = b else { return false }; return abs(a.x - b.x) < 0.5 && abs(a.y - b.y) < 0.5
    }
    private func sizesApproximatelyEqual(_ a: CGSize?, _ b: CGSize?) -> Bool {
        guard let a = a, let b = b else { return false }; return abs(a.width - b.width) < 0.5 && abs(a.height - b.height) < 0.5
    }
}
