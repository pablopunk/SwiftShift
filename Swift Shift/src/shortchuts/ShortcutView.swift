// ShortcutView.swift
import SwiftUI
import ShortcutRecorder

struct ShortcutNSView: NSViewRepresentable {
    @Binding var shortcut: Shortcut?
    
    func makeNSView(context: Context) -> RecorderControl {
        let recorder = RecorderControl()
        recorder.delegate = context.coordinator
        recorder.allowsModifierFlagsOnlyShortcut = true
        
        // custom view layer
        recorder.wantsLayer = true
//        recorder.layer?.cornerRadius = 14
//        recorder.layer?.masksToBounds = true
        
//        recorder.layer?.borderColor = NSColor.gray.cgColor
//        recorder.layer?.borderWidth = 1
        
//        recorder.style = RecorderControlStyle(identifier: nil,
//                                               components: RecorderControlStyle.Components(appearance: .unspecified,
//                                                                                           accessibility: [],
//                                                                                           layoutDirection: .rightToLeft,
//                                                                                           tint: .unspecified))
        
        return recorder
    }
    
    func updateNSView(_ nsView: RecorderControl, context: Context) {
        nsView.objectValue = shortcut
        nsView.translatesAutoresizingMaskIntoConstraints = false
        // Force width/height
        //        NSLayoutConstraint.activate([
        //            nsView.widthAnchor.constraint(equalToConstant: 100),
        //            nsView.heightAnchor.constraint(equalToConstant: 20)
        //        ])
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
    @State private var shortcut: UserShortcut
    
    init(type: ShortcutType) {
        self.shortcut = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .lastTextBaseline, content: {
                switch shortcut.type {
                case .move:
                    Image(systemName: "text.and.command.macwindow")
                case .resize:
                    Image(systemName: "macwindow.and.cursorarrow")
                }
                Text(shortcut.type.rawValue).frame(width: 60, alignment: .leading)
            })
            
            ShortcutNSView(shortcut: $shortcut.shortcut)
                .onChange(of: shortcut.shortcut, perform: {
                    newValue in
                    if (newValue == nil) {
                        ShortcutsManager.shared.delete(for: shortcut.type)
                    } else {
                        ShortcutsManager.shared.save(shortcut)
                    }
                })
            UIButton(action: {
                shortcut.shortcut = nil
            }, label: {
                Text("Clear")
            })
        }
    }
}

#Preview {
    VStack {
        ShortcutView(type: .move)
        ShortcutView(type: .resize)
    }.frame(width: MAIN_WINDOW_WIDTH).padding(32)
}
