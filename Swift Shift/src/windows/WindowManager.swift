import Cocoa
import Accessibility

class WindowManager {
    // Function to move a specified window to a new location
    static func moveWindow(window: AXUIElement, to point: NSPoint) {
        var mutablePoint = point
        var pointValue = AXValueCreate(AXValueType.cgPoint, &mutablePoint)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pointValue)
    }
    
    // Function to get the window under the cursor (even if it's not focused)
    static func getCurrentWindow() -> AXUIElement? {
        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation
        
        // Create a system-wide accessibility object
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Convert the mouse location to a CGPoint for the hit test
        let point = CGPoint(x: mouseLocation.x, y: NSScreen.main!.frame.height - mouseLocation.y)
        
        // Perform a hit test to find the element under the mouse
        var element: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(systemWideElement, Float(point.x), Float(point.y), &element)
        
        if error == .success, let element = element {
            // Check if the found element is a window, or find the window that contains it
            return getWindowFromElement(element as! AXUIElement)
        }
        return nil
    }
    
    // Helper function to find the window containing a given accessibility element
    private static func getWindowFromElement(_ element: AXUIElement) -> AXUIElement? {
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        if role as? String == kAXWindowRole {
            return element
        } else {
            var parent: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent)
            if let parent = parent {
                return getWindowFromElement(parent as! AXUIElement)
            }
        }
        return nil
    }
}
