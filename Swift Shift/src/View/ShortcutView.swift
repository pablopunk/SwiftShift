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
  @AppStorage(PreferenceKey.requireMouseClick.rawValue) var requireMouseClick = false

  init(type: ShortcutType) {
    let loaded = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type, mouseButton: .none)
    self.shortcut = loaded
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: actionIcon())
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.tint)
          .frame(width: 22)

        Text(shortcut.type.rawValue)
          .font(.system(size: 13, weight: .semibold))
          .frame(width: 50, alignment: .leading)

        ShortcutNSView(shortcut: $shortcut.shortcut)
          .onChange(of: shortcut.shortcut) { newValue in
            if newValue == nil {
              ShortcutsManager.shared.delete(for: shortcut.type)
            } else {
              ShortcutsManager.shared.save(shortcut)
            }
          }

        Button {
          shortcut.shortcut = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
      }

      if requireMouseClick {
        HStack(spacing: 6) {
          Image(systemName: "computermouse")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .frame(width: 22)

          HStack(spacing: 4) {
            ForEach(Array(MouseButton.allCases), id: \.self) { mouseButton in
              let selected = mouseButton == shortcut.mouseButton
              Button {
                shortcut.mouseButton = mouseButton
                ShortcutsManager.shared.save(shortcut)
              } label: {
                HStack(spacing: 3) {
                  if mouseButton != .none {
                    Image(systemName: clickIcon(mouseButton))
                      .font(.system(size: 9))
                  }
                  Text(mouseButton.rawValue)
                    .font(.system(size: 10, weight: selected ? .semibold : .regular))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                  Capsule()
                    .fill(selected ? Color.teal.opacity(0.2) : Color.primary.opacity(0.05))
                )
                .clipShape(Capsule())
              }
              .buttonStyle(.plain)
              .foregroundStyle(selected ? .teal : .secondary)
            }
          }
        }
        .onAppear {
          loadShortcutFromStorage()
        }
      }
    }
  }

  private func loadShortcutFromStorage() {
    let loaded = ShortcutsManager.shared.load(for: shortcut.type) ?? UserShortcut(type: shortcut.type, mouseButton: .none)
    self.shortcut = loaded
  }

  private func actionIcon() -> String {
    switch shortcut.type {
    case .move: return "arrow.up.and.down.and.arrow.left.and.right"
    case .resize: return "arrow.up.left.and.arrow.down.right"
    }
  }

  private func clickIcon(_ clickType: MouseButton) -> String {
    switch clickType {
    case .left: return "capsule.lefthalf.filled"
    case .right: return "capsule.righthalf.filled"
    case .none: return ""
    }
  }
}

#Preview {
  VStack {
    ShortcutView(type: .move)
    ShortcutView(type: .resize)
  }.frame(width: MAIN_WINDOW_WIDTH).padding()
}
