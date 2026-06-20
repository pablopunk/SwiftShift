import XCTest
@testable import Swift_Shift_Dev

final class KeyboardShortcutTests: XCTestCase {

    // MARK: - Initialization

    func testInitWithKeyCodeAndModifiers() {
        let shortcut = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command, .shift],
            characters: "\r",
            charactersIgnoringModifiers: "r"
        )
        XCTAssertEqual(shortcut.keyCode, 36)
        XCTAssertEqual(shortcut.modifierFlags, [.command, .shift])
        XCTAssertEqual(shortcut.characters, "\r")
        XCTAssertEqual(shortcut.charactersIgnoringModifiers, "r")
    }

    func testInitWithNilKeyCode_createsModifierOnlyShortcut() {
        let shortcut = KeyboardShortcut(
            keyCode: nil,
            modifierFlags: [.command, .option]
        )
        XCTAssertNil(shortcut.keyCode)
        XCTAssertTrue(shortcut.isModifierOnly)
        XCTAssertEqual(shortcut.modifierFlags, [.command, .option])
    }

    func testInitFromShortcutRecorderShortcut() {
        // ShortcutRecorder Shortcut can't easily be constructed in tests
        // but we can test the KeyboardShortcut initializer logic indirectly
        let shortcut = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command],
            characters: "\r",
            charactersIgnoringModifiers: "r"
        )
        XCTAssertEqual(shortcut.keyCode, 36)
        XCTAssertEqual(shortcut.modifierFlags, [.command])
    }

    // MARK: - Modifier Flags

    func testModifierFlagsAreFilteredToSwiftShiftMask() {
        // The swiftShiftShortcutMask includes only [.command, .option, .shift, .control, .function]
        // CapsLock and numericPad should be stripped
        let shortcut = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command, .capsLock, .numericPad]
        )
        // Only .command should remain after filtering through swiftShiftShortcutFlags
        XCTAssertEqual(shortcut.modifierFlags, [.command])
        XCTAssertFalse(shortcut.modifierFlags.contains(.capsLock))
        XCTAssertFalse(shortcut.modifierFlags.contains(.numericPad))
    }

    func testModifierFlagsPreservesFunctionKey() {
        let shortcut = KeyboardShortcut(
            keyCode: 63,
            modifierFlags: [.function, .command]
        )
        XCTAssertTrue(shortcut.usesFunctionModifier)
        XCTAssertEqual(shortcut.modifierFlags, [.command, .function])
    }

    func testModifierFlagsRawValuePersistence() {
        let shortcut = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command, .option],
            characters: "\r",
            charactersIgnoringModifiers: "r"
        )
        // Encode and decode to verify modifier flags survive roundtrip
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let data = try? encoder.encode(shortcut),
              let decoded = try? decoder.decode(KeyboardShortcut.self, from: data) else {
            XCTFail("Failed to encode/decode KeyboardShortcut")
            return
        }

        XCTAssertEqual(decoded.keyCode, 36)
        XCTAssertEqual(decoded.modifierFlags, [.command, .option])
        XCTAssertEqual(decoded.characters, "\r")
        XCTAssertEqual(decoded.charactersIgnoringModifiers, "r")
    }

    // MARK: - isModifierOnly

    func testIsModifierOnly_whenKeyCodeIsNil() {
        let shortcut = KeyboardShortcut(keyCode: nil, modifierFlags: [.command])
        XCTAssertTrue(shortcut.isModifierOnly)
    }

    func testIsModifierOnly_whenKeyCodeIsSet() {
        let shortcut = KeyboardShortcut(keyCode: 36, modifierFlags: [.command])
        XCTAssertFalse(shortcut.isModifierOnly)
    }

    // MARK: - usesFunctionModifier

    func testUsesFunctionModifier_whenFnKeyPresent() {
        let shortcut = KeyboardShortcut(keyCode: 122, modifierFlags: [.function])
        XCTAssertTrue(shortcut.usesFunctionModifier)
    }

    func testUsesFunctionModifier_whenFnKeyAbsent() {
        let shortcut = KeyboardShortcut(keyCode: 122, modifierFlags: [.command])
        XCTAssertFalse(shortcut.usesFunctionModifier)
    }

    // MARK: - displayString

    func testDisplayString_forStandardShortcut() {
        let shortcut = KeyboardShortcut(
            keyCode: 0, // "a" key
            modifierFlags: [.command],
            characters: "a",
            charactersIgnoringModifiers: "a"
        )
        XCTAssertEqual(shortcut.displayString, "⌘A")
    }

    func testDisplayString_forModifierOnlyShortcut() {
        let shortcut = KeyboardShortcut(keyCode: nil, modifierFlags: [.command, .option])
        XCTAssertEqual(shortcut.displayString, "⌥⌘")
    }

    func testDisplayString_forFunctionKeyShortcut() {
        let shortcut = KeyboardShortcut(keyCode: 122, modifierFlags: [.function])
        XCTAssertEqual(shortcut.displayString, "fnF1")
    }

    func testDisplayString_whenEmpty_returnsRecordShortcut() {
        let shortcut = KeyboardShortcut(keyCode: nil, modifierFlags: [])
        XCTAssertEqual(shortcut.displayString, "Record Shortcut")
    }

    func testDisplayString_forSpaceCharacter() {
        let shortcut = KeyboardShortcut(
            keyCode: 49,
            modifierFlags: [.command],
            characters: " ",
            charactersIgnoringModifiers: " "
        )
        XCTAssertEqual(shortcut.displayString, "⌘Space")
    }

    func testDisplayString_forAllModifierCombinations() {
        let shortcut = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command, .option, .shift, .control, .function],
            characters: "\r",
            charactersIgnoringModifiers: "r"
        )
        XCTAssertTrue(shortcut.displayString.contains("fn"))
        XCTAssertTrue(shortcut.displayString.contains("⌃"))
        XCTAssertTrue(shortcut.displayString.contains("⌥"))
        XCTAssertTrue(shortcut.displayString.contains("⇧"))
        XCTAssertTrue(shortcut.displayString.contains("⌘"))
    }

    // MARK: - canUseWithoutModifiers

    func testCanUseWithoutModifiers_forFunctionKeys() {
        // F1-F20 should be usable without modifiers
        let functionKeyCodes: [UInt16] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
                                           103, 111, 105, 107, 113, 106, 64, 79, 80, 90]
        for keyCode in functionKeyCodes {
            XCTAssertTrue(KeyboardShortcut.canUseWithoutModifiers(keyCode: keyCode),
                          "Key code \(keyCode) should be usable without modifiers")
        }
    }

    func testCanUseWithoutModifiers_forRegularKeys() {
        // Regular alpha keys should NOT be usable without modifiers
        XCTAssertFalse(KeyboardShortcut.canUseWithoutModifiers(keyCode: 0))   // 'a'
        XCTAssertFalse(KeyboardShortcut.canUseWithoutModifiers(keyCode: 36))  // Return
        XCTAssertFalse(KeyboardShortcut.canUseWithoutModifiers(keyCode: 49))  // Space
        XCTAssertFalse(KeyboardShortcut.canUseWithoutModifiers(keyCode: 53))  // Escape
    }

    // MARK: - Codable

    func testCodableRoundtrip_preservesAllFields() {
        let original = KeyboardShortcut(
            keyCode: 36,
            modifierFlags: [.command, .shift],
            characters: "\r",
            charactersIgnoringModifiers: "r"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let data = try? encoder.encode(original),
              let decoded = try? decoder.decode(KeyboardShortcut.self, from: data) else {
            XCTFail("Codable roundtrip failed")
            return
        }

        XCTAssertEqual(decoded.keyCode, original.keyCode)
        XCTAssertEqual(decoded.modifierFlags, original.modifierFlags)
        XCTAssertEqual(decoded.characters, original.characters)
        XCTAssertEqual(decoded.charactersIgnoringModifiers, original.charactersIgnoringModifiers)
    }

    func testCodableRoundtrip_modifierOnlyShortcut() {
        let original = KeyboardShortcut(keyCode: nil, modifierFlags: [.command, .option])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let data = try? encoder.encode(original),
              let decoded = try? decoder.decode(KeyboardShortcut.self, from: data) else {
            XCTFail("Codable roundtrip failed")
            return
        }

        XCTAssertNil(decoded.keyCode)
        XCTAssertEqual(decoded.modifierFlags, [.command, .option])
        XCTAssertTrue(decoded.isModifierOnly)
    }

    func testDecodeFromJSON() {
        let json = """
        {
            "keyCode": 36,
            "modifierFlagsRawValue": 1179648,
            "characters": "\\r",
            "charactersIgnoringModifiers": "r"
        }
        """
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8),
              let shortcut = try? decoder.decode(KeyboardShortcut.self, from: data) else {
            XCTFail("JSON decoding failed")
            return
        }

        XCTAssertEqual(shortcut.keyCode, 36)
        XCTAssertEqual(shortcut.characters, "\r")
        XCTAssertEqual(shortcut.charactersIgnoringModifiers, "r")
        // 1179648 = NSEvent.ModifierFlags([.command, .shift]).rawValue (1048576 + 131072)
        XCTAssertEqual(shortcut.modifierFlags, [.command, .shift])
    }

    // MARK: - Equatable

    func testEquatable_sameShortcutsAreEqual() {
        let a = KeyboardShortcut(keyCode: 36, modifierFlags: [.command], characters: "\r", charactersIgnoringModifiers: "r")
        let b = KeyboardShortcut(keyCode: 36, modifierFlags: [.command], characters: "\r", charactersIgnoringModifiers: "r")
        XCTAssertEqual(a, b)
    }

    func testEquatable_differentModifierFlagsAreNotEqual() {
        let a = KeyboardShortcut(keyCode: 36, modifierFlags: [.command])
        let b = KeyboardShortcut(keyCode: 36, modifierFlags: [.option])
        XCTAssertNotEqual(a, b)
    }

    func testEquatable_differentKeyCodesAreNotEqual() {
        let a = KeyboardShortcut(keyCode: 36, modifierFlags: [.command])
        let b = KeyboardShortcut(keyCode: 0, modifierFlags: [.command])
        XCTAssertNotEqual(a, b)
    }

    // MARK: - NSEvent.ModifierFlags extension

    func testSwiftShiftShortcutMask_excludesCapsLock() {
        XCTAssertFalse(NSEvent.ModifierFlags.swiftShiftShortcutMask.contains(.capsLock))
    }

    func testSwiftShiftShortcutMask_includesCoreModifiers() {
        let mask = NSEvent.ModifierFlags.swiftShiftShortcutMask
        XCTAssertTrue(mask.contains(.command))
        XCTAssertTrue(mask.contains(.option))
        XCTAssertTrue(mask.contains(.shift))
        XCTAssertTrue(mask.contains(.control))
        XCTAssertTrue(mask.contains(.function))
    }
}
