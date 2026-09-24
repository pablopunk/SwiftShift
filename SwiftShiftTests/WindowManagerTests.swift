import XCTest
import Cocoa
@testable import Swift_Shift_Dev

final class WindowManagerTests: XCTestCase {

    // MARK: - Coordinate Conversion

    func testConvertYCoordinate_flipsYAxis() {
        // In AppKit, y=0 is at bottom; in CoreGraphics, y=0 is at top
        // convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems flips relative to main display height
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        let point = NSPoint(x: 100, y: 200)

        let converted = WindowManager.convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: point)

        XCTAssertEqual(converted.x, 100)
        XCTAssertEqual(converted.y, mainDisplayHeight - 200)
    }

    func testConvertYCoordinate_doubleConversionIsIdentity() {
        let original = NSPoint(x: 500, y: 300)
        let convertedOnce = WindowManager.convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: original)
        let convertedTwice = WindowManager.convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: convertedOnce)

        XCTAssertEqual(convertedTwice.x, original.x, accuracy: 0.01)
        XCTAssertEqual(convertedTwice.y, original.y, accuracy: 0.01)
    }

    func testConvertYCoordinate_atOrigin() {
        let converted = WindowManager.convertYCoordinateBecauseTheAreTwoFuckingCoordinateSystems(point: NSPoint(x: 0, y: 0))
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height

        XCTAssertEqual(converted.x, 0)
        XCTAssertEqual(converted.y, mainDisplayHeight)
    }

    // MARK: - Window Bounds

    func testGetWindowBounds_producesCorrectCorners() {
        let location = NSPoint(x: 100, y: 200)
        let size = CGSize(width: 300, height: 400)
        let displayHeight = CGDisplayBounds(CGMainDisplayID()).height

        let bounds = WindowManager.getWindowBounds(windowLocation: location, windowSize: size)

        // The function converts the Y coordinate: y' = displayHeight - y
        let expectedY = displayHeight - location.y

        // topLeft: the point itself after conversion
        XCTAssertEqual(bounds.topLeft.x, location.x, accuracy: 0.01)
        XCTAssertEqual(bounds.topLeft.y, expectedY, accuracy: 0.01)

        // topRight: x + width
        XCTAssertEqual(bounds.topRight.x, location.x + size.width, accuracy: 0.01)
        XCTAssertEqual(bounds.topRight.y, expectedY, accuracy: 0.01)

        // bottomLeft: x, y - height
        XCTAssertEqual(bounds.bottomLeft.x, location.x, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomLeft.y, expectedY - size.height, accuracy: 0.01)

        // bottomRight: x + width, y - height
        XCTAssertEqual(bounds.bottomRight.x, location.x + size.width, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomRight.y, expectedY - size.height, accuracy: 0.01)
    }

    func testGetWindowBounds_withZeroSize() {
        let location = NSPoint(x: 0, y: 0)
        let size = CGSize(width: 0, height: 0)

        let bounds = WindowManager.getWindowBounds(windowLocation: location, windowSize: size)
        let displayHeight = CGDisplayBounds(CGMainDisplayID()).height

        // All corners should be at the same point (top-left after conversion)
        XCTAssertEqual(bounds.topLeft.x, 0, accuracy: 0.01)
        XCTAssertEqual(bounds.topLeft.y, displayHeight, accuracy: 0.01)
        XCTAssertEqual(bounds.topRight.x, 0, accuracy: 0.01)
        XCTAssertEqual(bounds.topRight.y, displayHeight, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomLeft.x, 0, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomLeft.y, displayHeight, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomRight.x, 0, accuracy: 0.01)
        XCTAssertEqual(bounds.bottomRight.y, displayHeight, accuracy: 0.01)
    }

    // MARK: - Window Bounds Structure

    func testWindowBounds_isFullyDefined() {
        let bounds = WindowBounds(
            topLeft: NSPoint(x: 0, y: 100),
            topRight: NSPoint(x: 100, y: 100),
            bottomLeft: NSPoint(x: 0, y: 0),
            bottomRight: NSPoint(x: 100, y: 0)
        )

        XCTAssertEqual(bounds.topLeft.x, 0)
        XCTAssertEqual(bounds.topLeft.y, 100)
        XCTAssertEqual(bounds.topRight.x, 100)
        XCTAssertEqual(bounds.bottomRight.y, 0)
    }
}

final class ScrollResizeTests: XCTestCase {
    func testScrollResizesAroundWindowCenter() {
        let original = CGRect(x: 100, y: 200, width: 300, height: 400)
        let larger = ScrollResizeGeometry.resized(origin: original.origin, size: original.size, scrollDelta: 2)
        let smaller = ScrollResizeGeometry.resized(origin: original.origin, size: original.size, scrollDelta: -2)

        XCTAssertEqual(larger.size.width, 320)
        XCTAssertEqual(larger.size.height, 420)
        XCTAssertEqual(smaller.size.width, 280)
        XCTAssertEqual(smaller.size.height, 380)
        XCTAssertEqual(larger.midX, original.midX)
        XCTAssertEqual(larger.midY, original.midY)
        XCTAssertEqual(smaller.midX, original.midX)
        XCTAssertEqual(smaller.midY, original.midY)
    }

    func testScrollDoesNotShrinkBelowSafeSizeOrGrowSmallWindow() {
        let normal = ScrollResizeGeometry.resized(origin: .zero, size: CGSize(width: 300, height: 250), scrollDelta: -100)
        XCTAssertEqual(normal.size.width, 100)
        XCTAssertEqual(normal.size.height, 100)

        let small = ScrollResizeGeometry.resized(origin: .zero, size: CGSize(width: 70, height: 80), scrollDelta: -100)
        XCTAssertEqual(small.size.width, 70)
        XCTAssertEqual(small.size.height, 80)
    }

    func testOnlyControlAndVerticalScrollTriggerResize() {
        let control: CGEventFlags = .maskControl
        XCTAssertTrue(ScrollResizeInput.shouldResize(enabled: true, flags: control, vertical: 1, horizontal: 0, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: false, flags: control, vertical: 1, horizontal: 0, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: true, flags: [], vertical: 1, horizontal: 0, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: true, flags: [.maskControl, .maskShift], vertical: 1, horizontal: 0, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: true, flags: control, vertical: 0, horizontal: 1, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: true, flags: control, vertical: 1, horizontal: 2, hasActiveShortcut: false))
        XCTAssertFalse(ScrollResizeInput.shouldResize(enabled: true, flags: control, vertical: 1, horizontal: 0, hasActiveShortcut: true))
    }
}
