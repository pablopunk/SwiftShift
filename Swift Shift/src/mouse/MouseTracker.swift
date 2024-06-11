import Cocoa
import Accessibility

enum MouseAction {
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
        let bounds = WindowManager.getWindowBounds(windowLocation: windowLocation, windowSize: windowSize)

        let thirdX = (bounds.topRight.x - bounds.topLeft.x) / 3
        let thirdY = (bounds.topLeft.y - bounds.bottomLeft.y) / 3

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

    private func convertToWindowCoordinates(_ mouseLocation: NSPoint, windowOrigin: NSPoint) -> NSPoint {
        return NSPoint(x: mouseLocation.x - windowOrigin.x, y: mouseLocation.y - windowOrigin.y)
    }

    private func resizeWindowBasedOnMouseLocation(_ event: NSEvent) {
        guard let windowSize = windowSize,
              let initialMouseLocation = initialMouseLocation,
              let initialWindowLocation = initialWindowLocation else {
            return
        }

        var newWidth: CGFloat, newHeight: CGFloat, newOrigin: NSPoint

        if (shouldUseQuadrants) {
            guard let quadrant = quadrant else { return }

            let currentMouseLocation = NSEvent.mouseLocation
            let windowRelativeCurrentMouseLocation = convertToWindowCoordinates(currentMouseLocation, windowOrigin: initialWindowLocation)

            let deltaX = windowRelativeCurrentMouseLocation.x - (initialMouseLocation.x - initialWindowLocation.x)
            let deltaY = windowRelativeCurrentMouseLocation.y - (initialMouseLocation.y - initialWindowLocation.y)

            newWidth = windowSize.width
            newHeight = windowSize.height
            newOrigin = initialWindowLocation

            switch quadrant {
            case .topLeft:
                newWidth -= deltaX
                newHeight += deltaY
                newOrigin.x += deltaX
                newOrigin.y -= deltaY
            case .top:
                newHeight += deltaY
                newOrigin.y -= deltaY
            case .topRight:
                newWidth += deltaX
                newHeight += deltaY
                newOrigin.y -= deltaY
            case .left:
                newWidth -= deltaX
                newOrigin.x += deltaX
            case .center:
                if abs(deltaX) > abs(deltaY) {
                    newWidth += 2 * deltaX
                    newOrigin.x -= deltaX
                } else {
                    newHeight += 2 * deltaY
                    newOrigin.y -= deltaY
                }
            case .right:
                newWidth += deltaX
            case .bottomLeft:
                newWidth -= deltaX
                newHeight -= deltaY
                newOrigin.x += deltaX
            case .bottom:
                newHeight -= deltaY
            case .bottomRight:
                newWidth += deltaX
                newHeight -= deltaY
            }
        } else {
            let currentMouseLocation = NSEvent.mouseLocation
            let deltaX = currentMouseLocation.x - initialMouseLocation.x
            let deltaY = currentMouseLocation.y - initialMouseLocation.y
            newWidth = windowSize.width + deltaX
            newHeight = windowSize.height - deltaY
            newOrigin = initialWindowLocation
        }

        // Ensure the new width and height are not negative
        newWidth = max(newWidth, 1)
        newHeight = max(newHeight, 1)
        let newSize = CGSize(width: newWidth, height: newHeight)
        WindowManager.resize(window: trackedWindow!, to: newSize, from: newOrigin)
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
