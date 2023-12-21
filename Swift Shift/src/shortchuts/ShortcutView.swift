// ShortcutView.swift
import SwiftUI
import ShortcutRecorder

struct ShortcutNSView: NSViewRepresentable {
    @Binding var shortcut: Shortcut?
    
    func makeNSView(context: Context) -> RecorderControl {
        let recorder = RecorderControl()
        recorder.delegate = context.coordinator
        recorder.allowsModifierFlagsOnlyShortcut = true
        return recorder
    }
    
    func updateNSView(_ nsView: RecorderControl, context: Context) {
        nsView.objectValue = shortcut
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RecorderControlDelegate {
        var parent: ShortcutNSView
        
        init(_ parent: ShortcutNSView) {
            self.parent = parent
        }
        
        func shortcutRecorderDidEndRecording(_ recorder: RecorderControl) {
            parent.shortcut = recorder.objectValue as? Shortcut
        }
    }
}

struct ShortcutView: View {
    @State private var recorder = RecorderControl()
    @State private var shortcut: UserShortcut
    
    init(type: ShortcutType) {
        self.shortcut = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type)
        recorder.allowsModifierFlagsOnlyShortcut = true
    }
    
    var body: some View {
        HStack {
            Text(shortcut.type.rawValue).frame(width: 60, alignment: .leading)
            ShortcutNSView(shortcut: $shortcut.shortcut)
                .frame(width: 150, alignment: .leading).onChange(of: shortcut.shortcut) { oldValue, newValue in
                    ShortcutsManager.shared.save(shortcut)
                }
            Button("Clear") {
                shortcut.shortcut = nil
                ShortcutsManager.shared.delete(for: shortcut.type)
            }
        }
    }
}

#Preview {
    ShortcutView(type: .move)
}
