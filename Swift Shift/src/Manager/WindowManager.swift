import Cocoa
import Accessibility

struct WindowBounds {
    let topLeft: NSPoint
    let topRight: NSPoint
    let bottomLeft: NSPoint
    let bottomRight: NSPoint
}

class WindowManager {
    // Function to move a specified window to a new location
    static func move(window: AXUIElement, to point: NSPoint) {
        var mutablePoint = point
        let pointValue = AXValueCreate(AXValueType.cgPoint, &mutablePoint)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pointValue)
    }

    // Function to resize a specified window to a new size, moving the window if necessary
    static func resizeMove(window: AXUIElement, from oldSize: CGSize, to newSize: CGSize, relativeTo oldOrigin: NSPoint, moving: NSPoint) {
        var mutableSize = newSize
        let sizeValue = AXValueCreate(AXValueType.cgSize, &mutableSize)!
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        guard let resultSize = getSize(window: window) else { return }
        let diffX = oldSize.width - resultSize.width
        let diffY = oldSize.height - resultSize.height
        var newOrigin = oldOrigin
        newOrigin.x += diffX * moving.x
        newOrigin.y += diffY * moving.y
        move(window: window, to: newOrigin)
    }

    // Function to get the window size
    static func getSize(window: AXUIElement) -> NSSize? {
        var sizeRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        guard result == .success, let sizeValue = sizeRef else {
            return nil
        }
        var windowSize: CGSize = .zero
        AXValueGetValue(sizeValue as! AXValue, AXValueType.cgSize, &windowSize)
        return NSSize(width: windowSize.width, height: windowSize.height)
    }
    
    // Function to get the window under the cursor (even if it's not focused)
    static func getCurrentWindow() -> AXUIElement? {
        // Use CGEvent to get the current mouse location
        guard let event = CGEvent(source: nil) else { return nil }
        let mouseLocation = event.location

        // Create a system-wide accessibility object
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Perform a hit test to find the element under the mouse
        var element: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(systemWideElement, Float(mouseLocation.x), Float(mouseLocation.y), &element)
        
        if error == .success, let element = element, let window = getWindow(from: element) {
            var pid: pid_t = 0
            AXUIElementGetPid(window, &pid)
            // Don't return the window of this app
            if pid != NSRunningApplication.current.processIdentifier {
                return window
            }
        } else {
            // Fallback using CGWindowListCopyWindowInfo
            return getTopWindowAtCursorUsingCGWindowList(mouseLocation: mouseLocation)
        }
        
        return nil
    }
    
    // Fallback function using CGWindowListCopyWindowInfo
    private static func getTopWindowAtCursorUsingCGWindowList(mouseLocation: NSPoint) -> AXUIElement? {
        let windowListInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as NSArray? as? [[String: AnyObject]]
        
        guard let windowList = windowListInfo else { return nil }
        
        // Sort the windows based on their layer. Lower layer numbers are closer to the front
        let sortedWindows = windowList.sorted {
            ($0[kCGWindowLayer as String] as? Int ?? 0) < ($1[kCGWindowLayer as String] as? Int ?? 0)
        }
        
        for entry in sortedWindows {
            if let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat],
               let windowBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                
                if windowBounds.contains(mouseLocation),
                   let pid = entry[kCGWindowOwnerPID as String] as? pid_t {
                    let appAXUIElement = AXUIElementCreateApplication(pid)
                    var value: AnyObject?
                    
                    if let app = getNSApplication(from: appAXUIElement) {
                        if (IGNORE_APP_BUNDLE_ID.contains(app.bundleIdentifier!)) {
                            print("ignoring", app.bundleIdentifier! as String)
                            continue
                        }
                    }
                    
                    if AXUIElementCopyAttributeValue(appAXUIElement, kAXWindowsAttribute as CFString, &value) == .success,
                       let windowList = value as? [AXUIElement],
                       let window = windowList.first {
                        return window
                    }
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
        
        if let app = getNSApplication(from: window) {
            app.activate()
        }
    }
    
    static func getNSApplication(from element: AXUIElement) -> NSRunningApplication? {
        // Get the PID of the application that owns the window
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        
        // Activate the application with the obtained PID
        if let app = NSRunningApplication(processIdentifier: pid) {
            return app
        } else {
            print("Error: Unable to find running application for PID \(pid)")
            return nil
        }
    }
    
    static func convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: NSPoint) -> NSPoint {
        return NSPoint(x: point.x, y: CGDisplayBounds(CGMainDisplayID()).height - point.y)
    }
    
    
    static func getPosition(window: AXUIElement) -> NSPoint? {
        var positionRef: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        guard result == .success else { return nil }
        
        var windowPosition: CGPoint = .zero
        AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &windowPosition)
        
        return NSPoint(x: windowPosition.x, y: windowPosition.y)
    }
    
    static func getWindowBounds(windowLocation: NSPoint, windowSize: CGSize) -> WindowBounds {
        let windowLocationWithFixedCoordinates = WindowManager.convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: windowLocation)
        let topLeft = NSPoint(x: windowLocationWithFixedCoordinates.x, y: windowLocationWithFixedCoordinates.y)
        let topRight = NSPoint(x: windowLocationWithFixedCoordinates.x + windowSize.width, y: windowLocationWithFixedCoordinates.y)
        let bottomLeft = NSPoint(x: windowLocationWithFixedCoordinates.x, y: windowLocationWithFixedCoordinates.y - windowSize.height)
        let bottomRight = NSPoint(x: windowLocationWithFixedCoordinates.x + windowSize.width, y: windowLocationWithFixedCoordinates.y - windowSize.height)
        
        // drawCircleAt(x: topLeft.x, y: topLeft.y, diameter: 10, color: .blue)
        // drawCircleAt(x: topRight.x, y: topRight.y, diameter: 10, color: .blue)
        // drawCircleAt(x: bottomLeft.x, y: bottomLeft.y, diameter: 10, color: .blue)
        // drawCircleAt(x: bottomRight.x, y: bottomRight.y, diameter: 10, color: .blue)

        return WindowBounds(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
    }
}

