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
        if let currentWindow = WindowManager.getCurrentWindow() {
            if let app = WindowManager.getNSApplication(from: currentWindow) {
                if IGNORE_APP_BUNDLE_ID.contains(app.bundleIdentifier!) {
                    print("ignoring", app.bundleIdentifier!)
                    trackedWindow = nil
                    return
                }
            }
            currentAction = action
            initialMouseLocation = NSEvent.mouseLocation
            trackedWindow = currentWindow
            initialWindowLocation = WindowManager.getPosition(window: currentWindow)
            WindowManager.focus(window: trackedWindow!)
            mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
                self?.handleMouseMoved(event)
            }
            // Start the tracking timer
            trackingTimer?.invalidate() // Invalidate any existing timer
            trackingTimer = Timer.scheduledTimer(withTimeInterval: trackingTimeout, repeats: false) { [weak self] _ in
                self?.stopTracking(for: self!.currentAction)
            }
        } else {
            trackedWindow = nil
        }
    }
    
    func stopTracking(for action: MouseAction) {
        if currentAction != action {
            return
        }
        
        // Invalidate the timer when tracking stops
        trackingTimer?.invalidate()
        trackingTimer = nil
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
        trackedWindow = nil
        initialMouseLocation = nil
        initialWindowLocation = nil
        currentAction = .none
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
}
