import CalcEngine
import SwiftUI
import Testing
@testable import ClassyO80

struct HardwareKeyboardTests {
    @Test(arguments: 0...9)
    func digits(_ digit: Int) {
        #expect(HardwareKeyboard.key(for: "\(digit)", modifiers: []) == .digit(digit))
    }

    @Test func operatorsAndPoint() {
        #expect(HardwareKeyboard.key(for: ".", modifiers: []) == .point)
        #expect(HardwareKeyboard.key(for: "+", modifiers: [.shift]) == .add)
        #expect(HardwareKeyboard.key(for: "-", modifiers: []) == .subtract)
        #expect(HardwareKeyboard.key(for: "*", modifiers: [.shift]) == .multiply)
        #expect(HardwareKeyboard.key(for: "/", modifiers: []) == .divide)
        #expect(HardwareKeyboard.key(for: "%", modifiers: [.shift]) == .percent)
    }

    /// What iPadOS actually sends: Shift-8 arrives as "8" with `.shift`.
    @Test func shiftedDigitRow() {
        #expect(HardwareKeyboard.key(for: "5", modifiers: [.shift]) == .percent)
        #expect(HardwareKeyboard.key(for: "8", modifiers: [.shift]) == .multiply)
        #expect(HardwareKeyboard.key(for: "=", modifiers: [.shift]) == .add)
    }

    @Test func equalsSignAndClear() {
        #expect(HardwareKeyboard.key(for: "=", modifiers: []) == .equals)
        #expect(HardwareKeyboard.key(for: "c", modifiers: []) == .clear)
        #expect(HardwareKeyboard.key(for: "C", modifiers: [.shift]) == .clear)
    }

    @Test func unmappedAndCommandChordsAreIgnored() {
        #expect(HardwareKeyboard.key(for: "a", modifiers: []) == nil)
        #expect(HardwareKeyboard.key(for: "1", modifiers: [.command]) == nil)
        #expect(HardwareKeyboard.key(for: "c", modifiers: [.command]) == nil)
    }

    @Test func returnEscapeAndDeleteAreButtonShortcuts() {
        #expect(HardwareKeyboard.shortcut(for: .equals) == .defaultAction)
        #expect(HardwareKeyboard.shortcut(for: .allClear) == .cancelAction)
        #expect(HardwareKeyboard.shortcut(for: .backspace) == KeyboardShortcut(.delete, modifiers: []))
        #expect(HardwareKeyboard.shortcut(for: .digit(1)) == nil)
        #expect(HardwareKeyboard.shortcut(for: .percent) == nil)
    }
}
