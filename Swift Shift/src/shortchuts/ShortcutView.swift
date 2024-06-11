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
    @State private var isExpanded: Bool
    @State private var requireMouseClick: Bool
    
    init(type: ShortcutType) {
        let loadedShortcut = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type, mouseButton: .none)
        self.shortcut = loadedShortcut
        self.requireMouseClick = loadedShortcut.mouseButton != MouseButton.none
        self.isExpanded = loadedShortcut.mouseButton != MouseButton.none
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(shortcut.type.rawValue)
                    .font(.headline)
                    .frame(width: 60, alignment: .leading)
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
                Button(action: {
                    withAnimation(.easeIn(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }.buttonStyle(.borderless)
            }
            if isExpanded {
                HStack {
                    Toggle(isOn: $requireMouseClick, label: {
                        Text("Require mouse click")
                    }).onChange(of: requireMouseClick) {
                        newValue in
                        if (newValue == false) {
                            shortcut.mouseButton = MouseButton.none
                        } else {
                            shortcut.mouseButton = MouseButton.left
                        }
                        ShortcutsManager.shared.save(shortcut)
                    }
                    
                    if requireMouseClick {
                        
                        Spacer()
                        
                        Image(systemName: "magicmouse.fill")
                        
                        Picker("", selection: $shortcut.mouseButton) {
                            ForEach(Array(MouseButton.allCases), id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }.onChange(of: shortcut.mouseButton) {
                            newValue in
                            if (newValue == .none) {
                                requireMouseClick = false
                            }
                            ShortcutsManager.shared.save(shortcut)
                        }
                        .frame(width: 100).padding(.leading, -10)
                    }
                }
                .animation(.easeInOut, value: isExpanded)
            }
            
        }
    }
}

#Preview {
    ShortcutView(type: .move)
        .padding()
        .frame(width: MAIN_WINDOW_WIDTH)
}
