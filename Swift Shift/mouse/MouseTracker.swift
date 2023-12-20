import Cocoa
import Accessibility

class MouseTracker {
    static let shared = MouseTracker()
    private var mouseEventMonitor: Any?
    private var initialMouseLocation: NSPoint?
    private var initialWindowLocation: NSPoint?
    private var trackedWindow: AXUIElement?

    private init() {}

    func startTracking() {
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
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard let initialMouseLocation = initialMouseLocation,
              let initialWindowLocation = initialWindowLocation,
              let trackedWindow = trackedWindow else {

            return
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let deltaX = currentMouseLocation.x - initialMouseLocation.x
        let deltaY = currentMouseLocation.y - initialMouseLocation.y
        let newOrigin = NSPoint(x: initialWindowLocation.x + deltaX, y: initialWindowLocation.y - deltaY)
        
        WindowManager.moveWindow(window: trackedWindow, to: newOrigin)
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
