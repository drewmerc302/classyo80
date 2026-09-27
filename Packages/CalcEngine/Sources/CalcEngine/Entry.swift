import Foundation

/// A number being typed.
struct Entry: Equatable, Sendable {
    enum Limit: Equatable, Sendable {
        /// Up to 8 digits; the integer `0` of a fraction counts as one.
        case standard
        /// Exchange rates: up to 6 digits when >= 1; below 1, up to 8 digits
        /// with at most 6 significant ones.
        case rate
    }

    var limit: Limit = .standard
    /// Digits and at most one point, unsigned: "", "0.", "12", "2.50".
    private(set) var digits = ""
    private(set) var isNegative = false

    init(limit: Limit = .standard) {
        self.limit = limit
    }

    var value: Decimal {
        guard let magnitude = Decimal(string: digits.isEmpty ? "0" : digits) else { return 0 }
        return isNegative && magnitude != 0 ? -magnitude : magnitude
    }

    /// What the LCD shows while typing: "0.", "12.", "2.50".
    var text: String {
        if digits.isEmpty { return "0." }
        return digits.contains(".") ? digits : digits + "."
    }

    /// Hides the minus sign until there is something to negate.
    var showsMinus: Bool { isNegative && value != 0 }

    private var digitCount: Int { digits.filter(\.isNumber).count }

    mutating func append(_ digit: Int) {
        if digits == "0" || digits.isEmpty {
            digits = String(digit)
            return
        }
        let candidate = digits + String(digit)
        guard fits(candidate) else { return }
        digits = candidate
    }

    mutating func appendPoint() {
        if digits.contains(".") { return }
        if digits.isEmpty {
            digits = "0."
            return
        }
        guard digitCount < maxDigits(for: digits) else { return }
        digits += "."
    }

    /// Deletes the last digit. A trailing point is invisible on the LCD ("12." looks like "12"),
    /// so it goes together with the digit before it.
    mutating func deleteLast() {
        if digits.hasSuffix(".") { digits.removeLast() }
        if !digits.isEmpty { digits.removeLast() }
        if digits.isEmpty { isNegative = false }
    }

    mutating func toggleSign() {
        isNegative.toggle()
    }

    private func maxDigits(for digits: String) -> Int {
        switch limit {
        case .standard: return Numeric.digits
        case .rate: return digits.hasPrefix("0") ? Numeric.digits : 6
        }
    }

    private func fits(_ candidate: String) -> Bool {
        let count = candidate.filter(\.isNumber).count
        guard count <= maxDigits(for: candidate) else { return false }
        if limit == .rate, candidate.hasPrefix("0") {
            return Entry.significantDigitCount(candidate) <= 6
        }
        return true
    }

    private static func significantDigitCount(_ digits: String) -> Int {
        digits.filter(\.isNumber).drop { $0 == "0" }.count
    }
}
