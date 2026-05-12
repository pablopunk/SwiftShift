import SwiftUI
import AppKit

private final class FnShortcutRecorderControl: NSButton {
  var onShortcutChange: ((KeyboardShortcut?) -> Void)?
  var shortcut: KeyboardShortcut? {
    didSet {
      if !isRecordingShortcut {
        updateTitle()
      }
    }
  }

  private var isRecordingShortcut = false
  private var recordedModifierFlags: NSEvent.ModifierFlags = []

  override var acceptsFirstResponder: Bool { true }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    configure()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  override func mouseDown(with event: NSEvent) {
    beginRecording()
  }

  override func keyDown(with event: NSEvent) {
    guard isRecordingShortcut else {
      super.keyDown(with: event)
      return
    }

    let modifierFlags = event.modifierFlags.swiftShiftShortcutFlags

    if modifierFlags.isEmpty && event.keyCode == 53 {
      cancelRecording()
      return
    }

    if modifierFlags.isEmpty && (event.keyCode == 51 || event.keyCode == 117) {
      finishRecording(with: nil)
      return
    }

    if modifierFlags.isEmpty && !KeyboardShortcut.canUseWithoutModifiers(keyCode: event.keyCode) {
      NSSound.beep()
      return
    }

    finishRecording(with: KeyboardShortcut(
      keyCode: event.keyCode,
      modifierFlags: modifierFlags,
      characters: event.characters,
      charactersIgnoringModifiers: event.charactersIgnoringModifiers
    ))
  }

  override func flagsChanged(with event: NSEvent) {
    guard isRecordingShortcut else {
      super.flagsChanged(with: event)
      return
    }

    let modifierFlags = event.modifierFlags.swiftShiftShortcutFlags
    if modifierFlags.isEmpty {
      if !recordedModifierFlags.isEmpty {
        finishRecording(with: KeyboardShortcut(keyCode: nil, modifierFlags: recordedModifierFlags))
      }
      return
    }

    recordedModifierFlags.formUnion(modifierFlags)
    title = KeyboardShortcut(keyCode: nil, modifierFlags: recordedModifierFlags).displayString
  }

  override func resignFirstResponder() -> Bool {
    if isRecordingShortcut {
      cancelRecording()
    }
    return super.resignFirstResponder()
  }

  private func configure() {
    setButtonType(.momentaryPushIn)
    bezelStyle = .rounded
    controlSize = .small
    font = .systemFont(ofSize: NSFont.smallSystemFontSize)
    focusRingType = .default
    lineBreakMode = .byTruncatingTail
    alignment = .center
    updateTitle()
  }

  private func beginRecording() {
    isRecordingShortcut = true
    recordedModifierFlags = []
    title = "Press shortcut"
    state = .on
    window?.makeFirstResponder(self)
    needsDisplay = true
  }

  private func cancelRecording() {
    isRecordingShortcut = false
    recordedModifierFlags = []
    state = .off
    updateTitle()
  }

  private func finishRecording(with newShortcut: KeyboardShortcut?) {
    isRecordingShortcut = false
    recordedModifierFlags = []
    state = .off
    shortcut = newShortcut
    onShortcutChange?(newShortcut)
    window?.makeFirstResponder(nil)
  }

  private func updateTitle() {
    title = shortcut?.displayString ?? "Record Shortcut"
  }
}

private struct ShortcutRecorderView: NSViewRepresentable {
  @Binding var shortcut: KeyboardShortcut?

  func makeNSView(context: Context) -> FnShortcutRecorderControl {
    let recorder = FnShortcutRecorderControl()
    recorder.onShortcutChange = { newShortcut in
      context.coordinator.parent.shortcut = newShortcut
    }
    return recorder
  }

  func updateNSView(_ nsView: FnShortcutRecorderControl, context: Context) {
    nsView.shortcut = shortcut
    nsView.translatesAutoresizingMaskIntoConstraints = false
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator {
    var parent: ShortcutRecorderView

    init(_ parent: ShortcutRecorderView) {
      self.parent = parent
    }
  }
}

struct ShortcutFnWarningView: View {
  let onDismiss: () -> Void
  private let keyboardSettingsURL = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.yellow)
        .padding(.top, 1)

      Button {
        NSWorkspace.shared.open(keyboardSettingsURL)
      } label: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Disable the fn key Emoji & Symbols shortcut in System Settings → Keyboard for more reliable shortcuts.")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

          Text("Open Keyboard Settings")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Open Keyboard settings")

      Spacer(minLength: 0)

      Button(action: onDismiss) {
        Image(systemName: "xmark")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.tertiary)
          .frame(width: 16, height: 16)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Dismiss")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

struct ShortcutView: View {
  @State private var shortcut: UserShortcut
  @AppStorage(PreferenceKey.requireMouseClick.rawValue) private var requireMouseClick = false
  let onShortcutChanged: () -> Void

  init(type: ShortcutType, onShortcutChanged: @escaping () -> Void = {}) {
    let loaded = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type, mouseButton: .none)
    self.shortcut = loaded
    self.onShortcutChanged = onShortcutChanged
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        Image(systemName: actionIcon())
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.tint)
          .frame(width: 22)

        Text(shortcut.type.rawValue)
          .font(.system(size: 13, weight: .semibold))
          .frame(width: 50, alignment: .leading)

        ShortcutRecorderView(shortcut: $shortcut.keyboardShortcut)
          .onChange(of: shortcut.keyboardShortcut) { newValue in
            shortcut.shortcut = newValue?.shortcutRecorderShortcut
            if newValue == nil {
              ShortcutsManager.shared.delete(for: shortcut.type)
            } else {
              ShortcutsManager.shared.save(shortcut)
            }
            onShortcutChanged()
          }
          .frame(maxWidth: .infinity, alignment: .leading)

        Button {
          shortcut.shortcut = nil
          shortcut.keyboardShortcut = nil
          onShortcutChanged()
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
                onShortcutChanged()
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
