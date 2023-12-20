import SwiftUI
import ShortcutRecorder

struct ShortcutView: NSViewRepresentable {
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
        var parent: ShortcutView

        init(_ parent: ShortcutView) {
            self.parent = parent
        }

        func shortcutRecorderDidEndRecording(_ recorder: RecorderControl) {
            parent.shortcut = recorder.objectValue as? Shortcut
        }
    }
}
