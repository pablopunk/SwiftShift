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
  private var recordedModifierKeyCodes = Set<UInt16>()

  override var acceptsFirstResponder: Bool { true }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    configure()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  override func performClick(_ sender: Any?) {
    beginRecording()
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

    updateRecordedModifierKeys(with: event)

    if recordedModifierKeyCodes.isEmpty {
      if !recordedModifierFlags.isEmpty {
        finishRecording(with: KeyboardShortcut(keyCode: nil, modifierFlags: recordedModifierFlags))
      }
      return
    }

    let modifierFlags = event.modifierFlags.swiftShiftShortcutFlags
    recordedModifierFlags.formUnion(modifierFlags)
    title = KeyboardShortcut(keyCode: nil, modifierFlags: recordedModifierFlags).displayString
  }

  private func updateRecordedModifierKeys(with event: NSEvent) {
    if event.modifierFlags.swiftShiftShortcutFlags.contains(modifierFlag(for: event.keyCode)) {
      recordedModifierKeyCodes.insert(event.keyCode)
    } else {
      recordedModifierKeyCodes.remove(event.keyCode)
    }
  }

  private func modifierFlag(for keyCode: UInt16) -> NSEvent.ModifierFlags {
    switch keyCode {
    case 54, 55: return .command
    case 56, 60: return .shift
    case 58, 61: return .option
    case 59, 62: return .control
    case 63: return .function
    default: return []
    }
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
    recordedModifierKeyCodes = []
    title = "Press shortcut"
    state = .on
    window?.makeFirstResponder(self)
    needsDisplay = true
  }

  private func cancelRecording() {
    isRecordingShortcut = false
    recordedModifierFlags = []
    recordedModifierKeyCodes = []
    state = .off
    updateTitle()
  }

  private func finishRecording(with newShortcut: KeyboardShortcut?) {
    isRecordingShortcut = false
    recordedModifierFlags = []
    recordedModifierKeyCodes = []
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

private struct TriggerToggleButton: View {
  let title: String
  let icon: String
  let isOn: Bool
  let canTurnOff: Bool
  let isFlashingError: Bool
  let onToggle: (Bool) -> Void

  var body: some View {
    Button {
      if isOn && !canTurnOff { return }
      onToggle(!isOn)
    } label: {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 10))
        Text(title)
          .font(.system(size: 10, weight: isOn ? .semibold : .regular))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(triggerBackgroundColor)
      )
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .foregroundStyle(isFlashingError ? .red : (isOn ? .teal : .secondary))
    .animation(.easeInOut(duration: 0.18), value: isFlashingError)
    .help(isOn && !canTurnOff ? "At least one trigger is required" : "")
  }

  private var triggerBackgroundColor: Color {
    if isFlashingError {
      return .red.opacity(0.28)
    }

    return isOn ? Color.teal.opacity(0.2) : Color.primary.opacity(0.05)
  }
}

private enum TriggerKind {
  case keyboard
  case mouse
}

struct ShortcutView: View {
  @State private var shortcut: UserShortcut
  @State private var keyboardTriggerErrorPulse = false
  @State private var mouseTriggerErrorPulse = false
  @State private var errorToastVisible = false
  @State private var errorToastMessage = ""
  let onShortcutChanged: () -> Void

  init(type: ShortcutType, onShortcutChanged: @escaping () -> Void = {}) {
    let loaded = ShortcutsManager.shared.load(for: type) ?? UserShortcut(type: type, mouseButton: .none)
    self.shortcut = loaded
    self.onShortcutChanged = onShortcutChanged
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: actionIcon())
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.tint)
          .frame(width: 22)

        Text(shortcut.type.rawValue)
          .font(.system(size: 15, weight: .semibold))
      }

      VStack(spacing: 6) {
        keyboardRow
        mouseRow
      }

      if errorToastVisible {
        errorToast
          .transition(.opacity.combined(with: .scale(scale: 0.98)))
      }
    }
    .padding(10)
    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
    )
    .onAppear {
      loadShortcutFromStorage()
    }
    .onReceive(NotificationCenter.default.publisher(for: .shortcutsDidChange)) { _ in
      loadShortcutFromStorage()
    }
  }

  private var keyboardRow: some View {
    HStack(spacing: 8) {
      TriggerToggleButton(
        title: "Keyboard",
        icon: "keyboard",
        isOn: shortcut.keyboardEnabled,
        canTurnOff: shortcut.mouseEnabled,
        isFlashingError: keyboardTriggerErrorPulse,
        onToggle: setKeyboardEnabled
      )
      .frame(width: 116)

      HStack(spacing: 4) {
        ShortcutRecorderView(shortcut: $shortcut.keyboardShortcut)
          .onChange(of: shortcut.keyboardShortcut) { newValue in
            shortcut.shortcut = newValue?.shortcutRecorderShortcut
            saveShortcut()
          }
          .disabled(!shortcut.keyboardEnabled)

        Button {
          shortcut.shortcut = nil
          shortcut.keyboardShortcut = nil
          saveShortcut()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .disabled(!shortcut.keyboardEnabled)
      }
      .frame(maxWidth: .infinity)
      .opacity(shortcut.keyboardEnabled ? 1 : 0.25)
      .animation(.easeInOut(duration: 0.18), value: shortcut.keyboardEnabled)
    }
    .animation(.easeInOut(duration: 0.18), value: shortcut.keyboardEnabled)
  }

  private var mouseRow: some View {
    HStack(spacing: 8) {
      TriggerToggleButton(
        title: "Mouse",
        icon: "computermouse",
        isOn: shortcut.mouseEnabled,
        canTurnOff: shortcut.keyboardEnabled,
        isFlashingError: mouseTriggerErrorPulse,
        onToggle: setMouseEnabled
      )
      .frame(width: 116)

      mouseButtonPicker
        .frame(maxWidth: .infinity)
        .disabled(!shortcut.mouseEnabled)
        .opacity(shortcut.mouseEnabled ? 1 : 0.25)
        .animation(.easeInOut(duration: 0.18), value: shortcut.mouseEnabled)
    }
    .animation(.easeInOut(duration: 0.18), value: shortcut.mouseEnabled)
  }

  private var errorToast: some View {
    HStack(spacing: 6) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 10, weight: .semibold))
      Text(errorToastMessage)
        .font(.system(size: 10, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .foregroundStyle(.red)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 8)
    .padding(.vertical, 5)
    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var mouseButtonPicker: some View {
    HStack(spacing: 4) {
      ForEach([MouseButton.left, .right, .both], id: \.self) { mouseButton in
        let isAvailable = shortcut.keyboardEnabled || mouseButton == .both
        let selected = mouseButton == shortcut.mouseButton || (!shortcut.keyboardEnabled && mouseButton == .both)
        Button {
          guard isAvailable else { return }
          shortcut.mouseButton = mouseButton
          saveShortcut()
        } label: {
          HStack(spacing: 3) {
            Image(systemName: clickIcon(mouseButton))
              .font(.system(size: 9))
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
        .opacity(isAvailable ? 1 : 0.35)
        .animation(.easeInOut(duration: 0.18), value: isAvailable)
        .disabled(!isAvailable)
      }
    }
  }

  private func setKeyboardEnabled(_ enabled: Bool) {
    guard enabled || shortcut.mouseEnabled else { return }

    if !enabled && shortcut.mouseEnabled && hasOtherMouseOnlyAction() {
      showTriggerConflict(on: .keyboard)
      return
    }

    shortcut.keyboardEnabled = enabled
    if !enabled {
      shortcut.mouseEnabled = true
      shortcut.mouseButton = .both
    } else if shortcut.mouseEnabled && shortcut.mouseButton == .none {
      shortcut.mouseButton = .left
    }

    saveShortcut()
  }

  private func setMouseEnabled(_ enabled: Bool) {
    guard enabled || shortcut.keyboardEnabled else { return }

    if enabled && !shortcut.keyboardEnabled && hasOtherMouseOnlyAction() {
      showTriggerConflict(on: .mouse)
      return
    }

    shortcut.mouseEnabled = enabled
    if enabled {
      if shortcut.keyboardEnabled {
        if shortcut.mouseButton == .none {
          shortcut.mouseButton = .left
        }
      } else {
        shortcut.mouseButton = .both
      }
    } else {
      shortcut.mouseButton = .none
    }

    saveShortcut()
  }

  private func showTriggerConflict(on trigger: TriggerKind) {
    errorToastMessage = "You cannot use the same trigger for both actions"

    withAnimation(.easeIn(duration: 0.08)) {
      errorToastVisible = true
      switch trigger {
      case .keyboard:
        keyboardTriggerErrorPulse = true
      case .mouse:
        mouseTriggerErrorPulse = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
      withAnimation(.easeOut(duration: 0.45)) {
        keyboardTriggerErrorPulse = false
        mouseTriggerErrorPulse = false
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
      withAnimation(.easeOut(duration: 0.2)) {
        errorToastVisible = false
      }
    }
  }

  private func hasOtherMouseOnlyAction() -> Bool {
    ShortcutType.allCases.contains { type in
      guard type != shortcut.type, let other = ShortcutsManager.shared.load(for: type) else { return false }
      return !other.keyboardEnabled && other.mouseEnabled
    }
  }

  private func saveShortcut() {
    ShortcutsManager.shared.save(shortcut)
    onShortcutChanged()
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
    case .both: return "capsule.fill"
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
