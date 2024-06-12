import Cocoa

class CircleView: NSView {
    var fillColor: NSColor = .green // Default color is green
    
    init(frame frameRect: NSRect, color: NSColor) {
        super.init(frame: frameRect)
        self.fillColor = color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        fillColor.setFill()
        let circlePath = NSBezierPath(ovalIn: dirtyRect)
        circlePath.fill()
    }
}

func drawCircleAt(x: CGFloat, y: CGFloat, diameter: CGFloat, color: NSColor) {
    let circleWindow = NSWindow(contentRect: NSRect(x: x, y: y, width: diameter, height: diameter),
                                styleMask: .borderless,
                                backing: .buffered,
                                defer: false)
    circleWindow.backgroundColor = .clear
    circleWindow.isOpaque = false
    circleWindow.hasShadow = false
    circleWindow.ignoresMouseEvents = true
    circleWindow.level = .floating
    
    let circleView = CircleView(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter), color: color)
    circleWindow.contentView = circleView
    
    circleWindow.makeKeyAndOrderFront(nil)
    circleWindow.orderFrontRegardless() // Makes the window visible at all times
}
