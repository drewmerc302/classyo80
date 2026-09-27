import Foundation

/// Eight-digit arithmetic rules of the calculator.
enum Numeric {
    static let digits = 8
    /// First magnitude that no longer fits: 10^8.
    static let limit: Decimal = 100_000_000

    enum Fitted: Equatable {
        case value(Decimal)
        /// Integer part needs more than 8 digits. Carries the value shifted 8 places, for the `E` display.
        case overflow(Decimal)
    }

    /// Truncates `value` to what the 8-digit display can hold.
    static func fit(_ value: Decimal) -> Fitted {
        if value.isNaN { return .overflow(0) }
        let magnitude = abs(value)
        if magnitude >= limit {
            var scaled = magnitude / limit
            if scaled >= limit { scaled = limit - 1 }
            return .overflow(signed(truncate(scaled), negative: value < 0))
        }
        return .value(signed(truncate(magnitude), negative: value < 0))
    }

    /// Unsigned display text: "0.", "35.", "11.4", "0.0000001".
    static func text(_ value: Decimal) -> String {
        var text = "\(abs(value))"
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            return text
        }
        return text + "."
    }

    static func integerDigitCount(_ magnitude: Decimal) -> Int {
        guard magnitude >= 1 else { return 1 }
        var count = 1
        var power: Decimal = 10
        while magnitude >= power {
            count += 1
            power *= 10
        }
        return count
    }

    /// Truncates a non-negative magnitude to 8 significant display digits.
    private static func truncate(_ magnitude: Decimal) -> Decimal {
        let scale = digits - integerDigitCount(magnitude)
        var input = magnitude
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .down)
        return result
    }

    private static func signed(_ magnitude: Decimal, negative: Bool) -> Decimal {
        negative && magnitude != 0 ? -magnitude : magnitude
    }
}
