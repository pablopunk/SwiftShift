import Cocoa
import Accessibility

class WindowManager {
    // Function to move a specified window to a new location
    static func moveWindow(window: AXUIElement, to point: NSPoint) {
        var mutablePoint = point
        var pointValue = AXValueCreate(AXValueType.cgPoint, &mutablePoint)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pointValue)
    }
    
    // Function to get the current active window
    static func getCurrentWindow() -> AXUIElement? {
        // Create a system-wide accessibility object
        let systemWideElement = AXUIElementCreateSystemWide()

        // Create a variable to hold the focused application
        var focusedApp: AnyObject?

        // Get the focused application
        let error: AXError = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)

        if error == .success {
            // Create a variable to hold the focused window
            var focusedWindow: AnyObject?

            // Get the focused window
            AXUIElementCopyAttributeValue(focusedApp as! AXUIElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

            if let focusedWindow = focusedWindow {
                return focusedWindow as! AXUIElement
            }
        }
        return nil
    }
}
