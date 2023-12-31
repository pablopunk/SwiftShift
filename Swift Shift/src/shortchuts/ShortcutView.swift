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
        nsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nsView.widthAnchor.constraint(equalToConstant: 100),
            nsView.heightAnchor.constraint(equalToConstant: 20)
        ])
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
            parent.shortcut = recorder.objectValue
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
                .onChange(of: shortcut.shortcut, perform: {
                    newValue in
                    if (newValue == nil) {
                        ShortcutsManager.shared.delete(for: shortcut.type)
                    } else {
                        ShortcutsManager.shared.save(shortcut)
                    }
                })
            Button("Clear") {
                shortcut.shortcut = nil
            }
        }
    }
}

#Preview {
    ShortcutView(type: .move)
}
