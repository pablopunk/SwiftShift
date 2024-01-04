import Cocoa
import Accessibility

enum MouseAction {
    case move
    case resize
    case none
}

class MouseTracker {
    static let shared = MouseTracker()
    private var mouseEventMonitor: Any?
    private var initialMouseLocation: NSPoint?
    private var initialWindowLocation: NSPoint?
    private var trackedWindow: AXUIElement?
    private var currentAction: MouseAction = .none
    private var trackingTimer: Timer?
    private let trackingTimeout: TimeInterval = 8 // in seconds
    
    private init() {}
    
    func startTracking(for action: MouseAction) {
        prepareTracking(for: action)
        registerMouseEventMonitor()
        startTrackingTimer()
    }
    
    func stopTracking(for action: MouseAction) {
        guard currentAction == action else { return }
        invalidateTrackingTimer()
        removeMouseEventMonitor()
        resetTrackingVariables()
    }
    
    private func prepareTracking(for action: MouseAction) {
        guard let currentWindow = WindowManager.getCurrentWindow(),
                !shouldIgnore(window: currentWindow) else {
            trackedWindow = nil
            return
        }
        
        currentAction = action
        initialMouseLocation = NSEvent.mouseLocation
        trackedWindow = currentWindow
        initialWindowLocation = WindowManager.getPosition(window: currentWindow)
        if PreferencesManager.loadBool(for: .focusOnApp) == true {
            WindowManager.focus(window: trackedWindow!)
        }
    }
    
    private func shouldIgnore(window: AXUIElement) -> Bool {
        guard let app = WindowManager.getNSApplication(from: window),
              let bundleIdentifier = app.bundleIdentifier,
              IGNORE_APP_BUNDLE_ID.contains(bundleIdentifier) else {
            return false
        }
        print("Ignoring", bundleIdentifier)
        return true
    }
    
    private func registerMouseEventMonitor() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
    }
    
    private func startTrackingTimer() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: trackingTimeout, repeats: false) { [weak self] _ in
            self?.stopTracking(for: self!.currentAction)
        }
    }
    
    private func handleMouseMoved(_ event: NSEvent) {
        guard let _ = initialMouseLocation,
              let _ = initialWindowLocation,
              let _ = trackedWindow else {
            return
        }
        
        switch currentAction {
        case .move:
            moveWindowBasedOnMouseLocation(event)
        case .resize:
            resizeWindowBasedOnMouseLocation(event)
        case .none:
            break
        }
    }
    
    private func moveWindowBasedOnMouseLocation(_ event: NSEvent) {
        let currentMouseLocation = NSEvent.mouseLocation
        let deltaX = currentMouseLocation.x - initialMouseLocation!.x
        let deltaY = currentMouseLocation.y - initialMouseLocation!.y
        let newOrigin = NSPoint(x: initialWindowLocation!.x + deltaX, y: initialWindowLocation!.y - deltaY)
        
        WindowManager.move(window: trackedWindow!, to: newOrigin)
    }
    
    private func resizeWindowBasedOnMouseLocation(_ event: NSEvent) {
        let currentMouseLocation = NSEvent.mouseLocation
        
        // Calculate the change in mouse location since tracking started
        let deltaX = currentMouseLocation.x - initialMouseLocation!.x
        let deltaY = currentMouseLocation.y - initialMouseLocation!.y
        
        WindowManager.resize(window: trackedWindow!, deltaX: deltaX, deltaY: deltaY)
        
        // Update initial mouse location for the next event
        initialMouseLocation = currentMouseLocation
    }
    
    private func invalidateTrackingTimer() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    private func removeMouseEventMonitor() {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }
    
    private func resetTrackingVariables() {
        trackedWindow = nil
        initialMouseLocation = nil
        initialWindowLocation = nil
        currentAction = .none
    }
}
