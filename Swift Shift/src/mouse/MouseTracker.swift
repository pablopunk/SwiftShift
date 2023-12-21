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

    private init() {}

    func startTracking(for action: MouseAction) {
        currentAction = action
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }

        initialMouseLocation = NSEvent.mouseLocation
        if let currentWindow = WindowManager.getCurrentWindow() {
            trackedWindow = currentWindow
            initialWindowLocation = getWindowPosition(window: currentWindow)
        }
    }

    func stopTracking() {
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
        guard let initialMouseLocation = initialMouseLocation,
              let initialWindowLocation = initialWindowLocation,
              let trackedWindow = trackedWindow else {
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
        
        WindowManager.moveWindow(window: trackedWindow!, to: newOrigin)
    }
    
    private func resizeWindowBasedOnMouseLocation(_ event: NSEvent) {
    }

    func getWindowPosition(window: AXUIElement) -> NSPoint? {
        var positionRef: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        guard result == .success else {
            return nil
        }

        var windowPosition: CGPoint = .zero
        AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &windowPosition)

        return NSPoint(x: windowPosition.x, y: windowPosition.y)
    }
}