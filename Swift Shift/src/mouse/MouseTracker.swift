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
    private var trackedWindowIsFocused: Bool = false
    private var shouldFocusWindow: Bool = false
    private var currentAction: MouseAction = .none
    private var trackingTimer: Timer?
    private let trackingTimeout: TimeInterval = 4 // in seconds
    private var initialMouseQuadrant: WindowQuadrant?

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
        
        shouldFocusWindow = PreferencesManager.loadBool(for: .focusOnApp)
        trackedWindowIsFocused = false
        currentAction = action
        initialMouseLocation = NSEvent.mouseLocation
        trackedWindow = currentWindow
        initialWindowLocation = WindowManager.getPosition(window: currentWindow)
        
        if action == .resize {
            prepareResizeTracking()
        }
    }
    
    private func prepareResizeTracking() {
        let quadrant = determineMouseQuadrant()
        initialMouseQuadrant = quadrant // Store the quadrant information
        print("Mouse is in the \(quadrant) quadrant")
    }
    
    private func determineMouseQuadrant() -> WindowQuadrant {
        // Use CGEvent to get the current mouse location
        guard let event = CGEvent(source: nil) else { return .unknown }
        let mouseLocation = event.unflippedLocation
        
        guard let window = trackedWindow,
              let windowPosition = WindowManager.getPosition(window: window),
              let windowSize = WindowManager.getSize(window: window) else {
            return .unknown
        }
        
        let midX = windowPosition.x + windowSize.width / 2
        let midY = windowPosition.y + windowSize.height / 2
        
        drawCircleAt(x: windowPosition.x, y: windowPosition.y, diameter: 10, color: .purple)
        drawCircleAt(x: midX, y: midY, diameter: 10, color: .blue)
        drawCircleAt(x: mouseLocation.x, y: mouseLocation.y, diameter: 10, color: .green)
        
        if mouseLocation.x < midX && mouseLocation.y > midY {
            return .topLeft
        } else if mouseLocation.x >= midX && mouseLocation.y > midY {
            return .topRight
        } else if mouseLocation.x < midX && mouseLocation.y <= midY {
            return .bottomLeft
        } else {
            return .bottomRight
        }
    }
    
    private func resizeWindowBasedOnMouseLocation(_ event: NSEvent) {
        guard let quadrant = initialMouseQuadrant,
                let window = trackedWindow else {
            return
        }
        
        let currentMouseLocation = NSEvent.mouseLocation
        let deltaX = currentMouseLocation.x - initialMouseLocation!.x
        let deltaY = currentMouseLocation.y - initialMouseLocation!.y
        
        switch quadrant {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            WindowManager.resizeAndMove(window: window, deltaX: deltaX, deltaY: deltaY, fromQuadrant: quadrant)
        case .unknown:
            WindowManager.resize(window: window, deltaX: deltaX, deltaY: deltaY)
        }
        
        // Update initial mouse location for the next event
        initialMouseLocation = currentMouseLocation
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

        if shouldFocusWindow && !trackedWindowIsFocused {
            WindowManager.focus(window: trackedWindow!)
            trackedWindowIsFocused = true
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
