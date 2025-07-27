import SwiftUI
import AppKit

struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragHandleView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DragHandleView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Make it semi-transparent so user knows it's a drag area
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
    
    override func resetCursorRects() {
        self.addCursorRect(self.bounds, cursor: .openHand)
    }
}