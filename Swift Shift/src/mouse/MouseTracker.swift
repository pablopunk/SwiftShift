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
        let currentMouseLocation = NSEvent.mouseLocation
        
        // Calculate the change in mouse location since tracking started
        let deltaX = currentMouseLocation.x - initialMouseLocation!.x
        let deltaY = currentMouseLocation.y - initialMouseLocation!.y
        
        // Get the current window size
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(trackedWindow!, kAXSizeAttribute as CFString, &sizeRef)
        var windowSize: CGSize = .zero
        AXValueGetValue(sizeRef as! AXValue, AXValueType.cgSize, &windowSize)
        
        // Calculate the new size based on mouse movement
        // Adjust these calculations if you want different resize behavior
        let newWidth = max(windowSize.width + deltaX, 0) // Ensure new width is not negative
        let newHeight = max(windowSize.height - deltaY, 0) // Ensure new height is not negative
        var newSize = CGSize(width: newWidth, height: newHeight)
        
        // Create an AXValue representing the new size
        if let newSizeValue = AXValueCreate(AXValueType.cgSize, &newSize) {
            AXUIElementSetAttributeValue(trackedWindow!, kAXSizeAttribute as CFString, newSizeValue)
        }
        
        // Update initial mouse location for the next event
        initialMouseLocation = currentMouseLocation
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
