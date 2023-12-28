import Cocoa
import Accessibility

class WindowManager {
    // Function to move a specified window to a new location
    static func move(window: AXUIElement, to point: NSPoint) {
        var mutablePoint = point
        var pointValue = AXValueCreate(AXValueType.cgPoint, &mutablePoint)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pointValue)
    }
    
    // Function to resize a specified window to a new size
    static func resize(window: AXUIElement, deltaX: CGFloat, deltaY: CGFloat) {
        // Get the current window size
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var windowSize: CGSize = .zero
        AXValueGetValue(sizeRef as! AXValue, AXValueType.cgSize, &windowSize)
        
        // Calculate the new size based on mouse movement
        // Adjust these calculations if you want different resize behavior
        let newWidth = max(windowSize.width + deltaX, 0) // Ensure new width is not negative
        let newHeight = max(windowSize.height - deltaY, 0) // Ensure new height is not negative
        var newSize = CGSize(width: newWidth, height: newHeight)
        
        // Create an AXValue representing the new size
        if let newSizeValue = AXValueCreate(AXValueType.cgSize, &newSize) {
            AXUIElementSetAttributeValue(window , kAXSizeAttribute as CFString, newSizeValue)
        }
    }
    
    // Function to get the window under the cursor (even if it's not focused)
    // It won't return the window if it's from this app
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
        
        if error == .success, let element = element, let window = getWindow(from: element) {
            var pid: pid_t = 0
            AXUIElementGetPid(window, &pid)
            if pid != NSRunningApplication.current.processIdentifier {
                return window
            }
        } else if error == .notImplemented {
            // Fallback using CGWindowListCopyWindowInfo
            return getTopWindowAtCursorUsingCGWindowList(mouseLocation: mouseLocation)
        }
        
        return nil
    }
    
    // Fallback function using CGWindowListCopyWindowInfo
    private static func getTopWindowAtCursorUsingCGWindowList(mouseLocation: NSPoint) -> AXUIElement? {
        let windowListInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as NSArray? as? [[String: AnyObject]]
        
        guard let windowList = windowListInfo else { return nil }
        
        for entry in windowList {
            if let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat],
               let windowBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
               windowBounds.contains(mouseLocation),
               let pid = entry[kCGWindowOwnerPID as String] as? pid_t {
                
                let appRef = AXUIElementCreateApplication(pid)
                var value: AnyObject?
                
                if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success,
                   let windowList = value as? [AXUIElement],
                   let window = windowList.first {
                    return window
                }
            }
        }
        
        return nil
    }
    
    // Helper function to find the window containing a given accessibility element
    private static func getWindow(from element: AXUIElement) -> AXUIElement? {
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        if role as? String == kAXWindowRole {
            return element
        } else {
            var parent: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent)
            if let parent = parent {
                return getWindow(from: parent as! AXUIElement)
            }
        }
        return nil
    }
    
    static func focus(window: AXUIElement) {
        // Bring the window to the foreground
        let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        if result != .success {
            print("Error: Unable to focus window")
        }
        
        // Get the PID of the application that owns the window
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)
        
        // Activate the application with the obtained PID
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate(options: [.activateIgnoringOtherApps])
        } else {
            print("Error: Unable to find running application for PID \(pid)")
        }
    }
    
    static func getPosition(window: AXUIElement) -> NSPoint? {
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
