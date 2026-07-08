import Cocoa
import Accessibility

/// Applies AX position/size writes on a dedicated serial queue.
/// `AXUIElementSetAttributeValue` is synchronous IPC into the target app (typically
/// 5-30ms per call, up to the 6s AX global timeout if the app hangs). Issuing it on
/// the main thread caps gesture updates at the target app's responsiveness and can
/// stall event handling entirely. The writer keeps only the newest requested
/// geometry (latest-wins) and applies it as fast as the target app accepts values,
/// so the main thread never blocks on the target app mid-gesture.
final class AXWindowWriter {
    static let shared = AXWindowWriter()
    private let queue = DispatchQueue(label: "com.swiftshift.axwindowwriter", qos: .userInteractive)
    private let lock = NSLock()
    private var pending: Pending?
    private var drainScheduled = false
    // Accessed only on `queue` (or via `queue.sync` from the main thread).
    private var window: AXUIElement?
    private var lastAppliedOrigin: NSPoint?
    private var lastAppliedSize: CGSize?

    private struct Pending {
        var origin: NSPoint?
        var size: CGSize?
    }

    /// Cap AX messaging so a hung target app costs at most this per write instead
    /// of the 6s global default. Generous enough that slow-but-alive apps (heavy
    /// Electron windows) don't get their writes cancelled mid-flight.
    private static let messagingTimeout: Float = 0.25

    private init() {}

    func beginGesture(window: AXUIElement, origin: NSPoint?, size: CGSize?) {
        clearPending()
        queue.sync {
            AXUIElementSetMessagingTimeout(window, Self.messagingTimeout)
            self.window = window
            lastAppliedOrigin = origin
            lastAppliedSize = size
        }
    }

    /// Drops any queued request and waits for an in-flight apply to finish, so the
    /// caller can then read window geometry that reflects every applied write.
    func synchronize() {
        clearPending()
        queue.sync {}
    }

    /// Re-baseline after an external change (e.g. space switch) and drop stale requests.
    func reset(origin: NSPoint?, size: CGSize?) {
        clearPending()
        queue.sync {
            lastAppliedOrigin = origin
            lastAppliedSize = size
        }
    }

    /// Applies the last requested geometry (if any) and detaches from the window.
    /// Synchronous so callers can order it before re-enabling
    /// AXEnhancedUserInterface on the target app. Worst case this blocks the
    /// caller for a few messaging timeouts behind a hung target app — bounded,
    /// and far below the 6s-per-write stalls the main thread saw before.
    func endGesture() {
        let final = takePending()
        queue.sync {
            if let final { apply(final) }
            if let window { AXUIElementSetMessagingTimeout(window, 0) } // 0 restores the global default
            window = nil
            lastAppliedOrigin = nil
            lastAppliedSize = nil
        }
    }

    func requestMove(to origin: NSPoint) {
        submit(Pending(origin: origin, size: nil))
    }

    func requestResize(origin: NSPoint, size: CGSize) {
        submit(Pending(origin: origin, size: size))
    }

    private func submit(_ request: Pending) {
        lock.lock()
        pending = request
        let shouldSchedule = !drainScheduled
        if shouldSchedule { drainScheduled = true }
        lock.unlock()
        if shouldSchedule { queue.async { self.drain() } }
    }

    private func takePending() -> Pending? {
        lock.lock(); defer { lock.unlock() }
        let taken = pending
        pending = nil
        return taken
    }

    private func clearPending() {
        lock.lock()
        pending = nil
        lock.unlock()
    }

    private func drain() {
        while true {
            lock.lock()
            guard let request = pending else {
                drainScheduled = false
                lock.unlock()
                return
            }
            pending = nil
            lock.unlock()
            apply(request)
        }
    }

    private func apply(_ request: Pending) {
        guard let window = window else { return }
        if let size = request.size {
            let origin = request.origin ?? lastAppliedOrigin ?? .zero
            let shouldMoveOrigin = !pointsApproximatelyEqual(request.origin, lastAppliedOrigin)
            guard shouldMoveOrigin || !sizesApproximatelyEqual(size, lastAppliedSize) else { return }
            if WindowManager.resize(window: window, to: size, from: origin, shouldMoveOrigin: shouldMoveOrigin) {
                if let requestedOrigin = request.origin { lastAppliedOrigin = requestedOrigin }
                lastAppliedSize = size
            }
        } else if let origin = request.origin {
            guard !pointsApproximatelyEqual(origin, lastAppliedOrigin) else { return }
            if WindowManager.move(window: window, to: origin) == .success {
                lastAppliedOrigin = origin
            }
        }
    }

    private func pointsApproximatelyEqual(_ a: NSPoint?, _ b: NSPoint?) -> Bool {
        guard let a = a, let b = b else { return false }
        return abs(a.x - b.x) < 0.5 && abs(a.y - b.y) < 0.5
    }

    private func sizesApproximatelyEqual(_ a: CGSize?, _ b: CGSize?) -> Bool {
        guard let a = a, let b = b else { return false }
        return abs(a.width - b.width) < 0.5 && abs(a.height - b.height) < 0.5
    }
}
