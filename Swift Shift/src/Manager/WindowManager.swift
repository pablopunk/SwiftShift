import Cocoa
import Accessibility
struct WindowBounds {
    let topLeft: NSPoint
    let topRight: NSPoint
    let bottomLeft: NSPoint
    let bottomRight: NSPoint
}
class WindowManager {
    static func move(window: AXUIElement, to point: NSPoint) {
        var p = point; let v = AXValueCreate(.cgPoint, &p)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, v)
    }
    static func resize(window: AXUIElement, to s: CGSize, from o: NSPoint, shouldMoveOrigin: Bool = true) {
        if shouldMoveOrigin { move(window: window, to: o) }
        var sz = s; let v = AXValueCreate(.cgSize, &sz)!
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, v)
    }
    static func getSize(window: AXUIElement) -> NSSize? {
        var r: CFTypeRef?; guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &r) == .success else { return nil }
        var s: CGSize = .zero; AXValueGetValue(r as! AXValue, .cgSize, &s); return NSSize(width: s.width, height: s.height)
    }
    static func getVisibleWindowRects(excluding excludedWindow: AXUIElement? = nil) -> [CGRect] {
        let excludedRect: CGRect? = {
            guard let window = excludedWindow, let position = getPosition(window: window), let size = getSize(window: window) else { return nil }
            return CGRect(origin: position, size: size)
        }()
        let windowInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] ?? []
        return windowInfo.compactMap { info in
            guard (info[kCGWindowLayer as String] as? Int ?? 0) == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid != NSRunningApplication.current.processIdentifier,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary),
                  rect.width > 1, rect.height > 1 else { return nil }
            guard let bundleId = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier, !PreferencesManager.isAppIgnored(bundleId) else { return nil }
            if let excludedRect = excludedRect, rect.equalTo(excludedRect) { return nil }
            return rect
        }
    }
    static func getCurrentWindow() -> AXUIElement? {
        guard let ev = CGEvent(source: nil) else { return nil }
        let sys = AXUIElementCreateSystemWide(); var el: AXUIElement?
        if AXUIElementCopyElementAtPosition(sys, Float(ev.location.x), Float(ev.location.y), &el) == .success, let el = el, let w = getWindow(from: el) {
            var pid: pid_t = 0; AXUIElementGetPid(w, &pid)
            if pid != NSRunningApplication.current.processIdentifier { return w }
        }
        return getTopWindowAtCursorUsingCGWindowList(mouseLocation: ev.location)
    }
    private static func getTopWindowAtCursorUsingCGWindowList(mouseLocation: NSPoint) -> AXUIElement? {
        let list = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] ?? []
        for e in list.sorted(by: { ($0[kCGWindowLayer as String] as? Int ?? 0) < ($1[kCGWindowLayer as String] as? Int ?? 0) }) {
            if let bDict = e[kCGWindowBounds as String] as? [String: CGFloat], let b = CGRect(dictionaryRepresentation: bDict as CFDictionary), b.contains(mouseLocation), let pid = e[kCGWindowOwnerPID as String] as? pid_t {
                let app = AXUIElementCreateApplication(pid); var val: AnyObject?
                if let nsApp = getNSApplication(from: app), let bid = nsApp.bundleIdentifier, PreferencesManager.isAppIgnored(bid) { continue }
                if AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &val) == .success, let wList = val as? [AXUIElement] {
                    for w in wList {
                        if let pos = getPosition(window: w), let size = getSize(window: w) {
                            let winRect = CGRect(origin: pos, size: size)
                            if winRect.contains(mouseLocation) { return w }
                        }
                    }
                    return wList.first
                }
            }
        }
        return nil
    }
    private static func getWindow(from element: AXUIElement) -> AXUIElement? {
        var r: AnyObject?; AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &r)
        if r as? String == kAXWindowRole { return element }
        var p: AnyObject?; AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &p)
        if let parent = p { return getWindow(from: parent as! AXUIElement) }
        return nil
    }
    static func focus(window: AXUIElement) { AXUIElementPerformAction(window, kAXRaiseAction as CFString); getNSApplication(from: window)?.activate() }
    static func getNSApplication(from element: AXUIElement) -> NSRunningApplication? {
        var pid: pid_t = 0; AXUIElementGetPid(element, &pid); return NSRunningApplication(processIdentifier: pid)
    }
    static func convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: NSPoint) -> NSPoint {
        return NSPoint(x: point.x, y: CGDisplayBounds(CGMainDisplayID()).height - point.y)
    }
    static func getPosition(window: AXUIElement) -> NSPoint? {
        var r: CFTypeRef?; guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &r) == .success else { return nil }
        var p: CGPoint = .zero; AXValueGetValue(r as! AXValue, .cgPoint, &p); return NSPoint(x: p.x, y: p.y)
    }
    static func getWindowBounds(windowLocation: NSPoint, windowSize: CGSize) -> WindowBounds {
        let fixed = convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: windowLocation)
        return WindowBounds(topLeft: fixed, topRight: NSPoint(x: fixed.x + windowSize.width, y: fixed.y), bottomLeft: NSPoint(x: fixed.x, y: fixed.y - windowSize.height), bottomRight: NSPoint(x: fixed.x + windowSize.width, y: fixed.y - windowSize.height))
    }
}

