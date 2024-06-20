import Cocoa
import Accessibility

enum MouseAction: String {
    case move
    case resize
    case none
}

enum Quadrant {
    case topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight
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
    private var shouldUseQuadrants: Bool = false
    private var quadrant: Quadrant?
    private var windowSize: CGSize?

    private init() {}

    func startTracking(for action: MouseAction, button: MouseButton) {
        prepareTracking(for: action)
        registerMouseEventMonitor(button: button)
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
        shouldUseQuadrants = PreferencesManager.loadBool(for: .useQuadrants)
        trackedWindowIsFocused = false
        currentAction = action
        initialMouseLocation = NSEvent.mouseLocation
        trackedWindow = currentWindow
        initialWindowLocation = WindowManager.getPosition(window: currentWindow)
        windowSize = WindowManager.getSize(window: currentWindow)

        if action == .resize && shouldUseQuadrants, let initialMouseLocation = initialMouseLocation, let initialWindowLocation = initialWindowLocation, let windowSize = windowSize {
            quadrant = determineQuadrant(mouseLocation: initialMouseLocation, windowSize: windowSize, windowLocation: initialWindowLocation)
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

    private func determineQuadrant(mouseLocation: NSPoint, windowSize: CGSize, windowLocation: NSPoint) -> Quadrant {
        if (!shouldUseQuadrants) { return .bottomRight }

        let bounds = WindowManager.getWindowBounds(windowLocation: windowLocation, windowSize: windowSize)

        let centreSize = 0.25 // https://github.com/pablopunk/SwiftShift/pull/54#discussion_r1635854368
        let sideSize = (1 - centreSize) / 2
        let thirdX = (bounds.topRight.x - bounds.topLeft.x) * sideSize
        let thirdY = (bounds.topLeft.y - bounds.bottomLeft.y) * sideSize

        let leftX = bounds.topLeft.x + thirdX
        let rightX = bounds.topRight.x - thirdX
        let topY = bounds.topLeft.y - thirdY
        let bottomY = bounds.bottomLeft.y + thirdY

        switch (mouseLocation.x, mouseLocation.y) {
        case (..<(leftX), topY...):
            return .topLeft
        case (leftX..<rightX, topY...):
            return .top
        case (rightX..., topY...):
            return .topRight
        case (..<(leftX), bottomY..<topY):
            return .left
        case (leftX..<rightX, bottomY..<topY):
            return .center
        case (rightX..., bottomY..<topY):
            return .right
        case (..<(leftX), ..<bottomY):
            return .bottomLeft
        case (leftX..<rightX, ..<bottomY):
            return .bottom
        case (rightX..., ..<bottomY):
            return .bottomRight
        default:
            return .bottomRight // Fallback to bottomRight
        }
    }

    private func registerMouseEventMonitor(button: MouseButton) {
        let eventType: NSEvent.EventTypeMask = switch button {
        case .left: .leftMouseDragged
        case .right: .rightMouseDragged
        case .none: .mouseMoved
        }

        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [eventType]) { [weak self] event in
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

    private func convertToWindowCoordinates(_ mouseLocation: NSPoint, windowOrigin: NSPoint) -> NSPoint {
        return NSPoint(x: mouseLocation.x - windowOrigin.x, y: mouseLocation.y - windowOrigin.y)
    }

    private func resizeWindowBasedOnMouseLocation(_ event: NSEvent) {
        guard let windowSize = windowSize,
              let initialMouseLocation = initialMouseLocation,
              let initialWindowLocation = initialWindowLocation else {
            return
        }

        guard let quadrant = quadrant else { return }

        let currentMouseLocation = NSEvent.mouseLocation
        let windowRelativeCurrentMouseLocation = convertToWindowCoordinates(currentMouseLocation, windowOrigin: initialWindowLocation)

        let deltaX = windowRelativeCurrentMouseLocation.x - (initialMouseLocation.x - initialWindowLocation.x)
        let deltaY = windowRelativeCurrentMouseLocation.y - (initialMouseLocation.y - initialWindowLocation.y)

        var newWidth = windowSize.width
        var newHeight = windowSize.height
        var moving = NSPoint(x: 0, y: 0)

        switch quadrant {
        case .topLeft:
            newWidth -= deltaX
            newHeight += deltaY
            moving.x = 1.0
            moving.y = 1.0
        case .top:
            newHeight += deltaY
            moving.y = 1.0
        case .topRight:
            newWidth += deltaX
            newHeight += deltaY
            moving.y = 1.0
        case .left:
            newWidth -= deltaX
            moving.x = 1.0
        case .center:
            newWidth += 2 * deltaX
            newHeight += 2 * deltaY
            moving.x = 0.5
            moving.y = 0.5
        case .right:
            newWidth += deltaX
        case .bottomLeft:
            newWidth -= deltaX
            newHeight -= deltaY
            moving.x = 1.0
        case .bottom:
            newHeight -= deltaY
        case .bottomRight:
            newWidth += deltaX
            newHeight -= deltaY
        }

        // Ensure the new width and height are not negative
        newWidth = max(newWidth, 1)
        newHeight = max(newHeight, 1)
        let newSize = CGSize(width: newWidth, height: newHeight)
        WindowManager.resizeMove(window: trackedWindow!, from: windowSize, to: newSize, relativeTo: initialWindowLocation, moving: moving)
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
