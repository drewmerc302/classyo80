import CalcEngine
import Foundation
import Testing

/// Deterministic random key mashing. Every display along the way must be something the
/// 8-digit LCD could actually show.
@Suite("Fuzz")
struct FuzzTests {
    struct SplitMix: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// Digits appear twice so numbers get long enough to hit the limits.
    static let pool: [Key] = (0...9).map { Key.digit($0) } + (0...9).map { Key.digit($0) } + [
        .point, .add, .subtract, .multiply, .divide, .equals, .percent, .plusMinus, .backspace,
        .clear, .allClear, .off, .mrc, .memoryMinus, .memoryPlus, .modeToggle, .cost, .sell, .margin, .set,
    ]

    static func violation(_ display: Display) -> String? {
        guard display.isOn else { return nil }
        let text = display.text
        if text.contains(where: { !$0.isNumber && $0 != "." }) { return "unexpected character" }
        if text.filter({ $0 == "." }).count != 1 { return "point count" }
        if text.filter(\.isNumber).count > 8 { return "more than 8 digits" }
        if display.isNegative, Decimal(string: text) == 0 { return "negative zero" }
        return nil
    }

    @Test func randomKeySequencesKeepDisplayValid() {
        var rng = SplitMix(state: 42)
        for _ in 0..<5_000 {
            var calc = Calculator()
            var history: [Key] = []
            for _ in 0..<40 {
                let key = Self.pool.randomElement(using: &rng)!
                calc.press(key)
                history.append(key)
                if let problem = Self.violation(calc.display) {
                    Issue.record("\(problem) after \(history): \(calc.display.signedText)")
                    return
                }
                #expect(!calc.persistent.memory.isNaN)
            }
        }
    }
}
