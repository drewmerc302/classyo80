import CalcEngine
import SwiftUI

/// Maps hardware keyboard input (iPad) onto calculator keys.
enum HardwareKeyboard {
    /// Printable keys, from `KeyPress.characters`. iPadOS reports the unshifted character with
    /// `.shift` in `modifiers` (Shift-8 arrives as "8"), so the US shifted digit row is mapped
    /// explicitly; the shifted characters themselves are accepted too.
    static func key(for characters: String, modifiers: EventModifiers) -> Key? {
        guard modifiers.isDisjoint(with: [.command, .control, .option]) else { return nil }
        let shifted = modifiers.contains(.shift)

        switch characters {
        case "5" where shifted, "%": return .percent
        case "8" where shifted, "*", "×": return .multiply
        case "=" where shifted, "+": return .add
        case "-", "−": return .subtract
        case "/", "÷": return .divide
        case ".", ",": return .point
        case "=": return .equals
        case "c", "C": return .clear
        default:
            guard characters.count == 1, let digit = Int(characters) else { return nil }
            return .digit(digit)
        }
    }

    /// Return, Escape and Delete are taken by the system before `onKeyPress` sees them, so the
    /// matching buttons carry them as keyboard shortcuts.
    static func shortcut(for key: Key) -> KeyboardShortcut? {
        switch key {
        case .equals: .defaultAction
        case .allClear: .cancelAction
        case .backspace: KeyboardShortcut(.delete, modifiers: [])
        default: nil
        }
    }
}
