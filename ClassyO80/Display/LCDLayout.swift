import CalcEngine

/// One of the eight seven-segment positions on the LCD.
struct LCDCell: Equatable, Sendable {
    /// "0" through "9", or nil for an unlit cell.
    var digit: Character?
    /// The decimal point to the lower right of the digit.
    var hasPoint = false
    /// The three-digit separator tick to the upper right of the digit (1'234'567.8).
    var hasSeparator = false

    static let blank = LCDCell(digit: nil)
}

enum LCDLayout {
    static let digitCount = 8

    /// Maps the engine's display text ("1234567.8", "0.", "2.50") onto the eight cells,
    /// right-aligned. Separators go only in the integer part.
    static func cells(for text: String) -> [LCDCell] {
        let integerDigitCount = text.prefix { $0 != "." }.filter(\.isASCIIDigit).count
        var cells: [LCDCell] = []
        var integerDigitsPlaced = 0
        var inFraction = false

        for character in text {
            if character == "." {
                if cells.isEmpty { cells.append(.blank) }
                cells[cells.count - 1].hasPoint = true
                inFraction = true
            } else if character.isASCIIDigit {
                var cell = LCDCell(digit: character)
                if !inFraction {
                    integerDigitsPlaced += 1
                    let remaining = integerDigitCount - integerDigitsPlaced
                    cell.hasSeparator = remaining > 0 && remaining % 3 == 0
                }
                cells.append(cell)
            }
        }

        cells = Array(cells.prefix(digitCount))
        return Array(repeating: .blank, count: digitCount - cells.count) + cells
    }

    /// The signed value as a person would type it: "-6", "11.4", "2.50". Empty when off.
    /// Used for Copy and for the LCD's accessibility value.
    static func plainValue(of display: Display) -> String {
        guard display.isOn, !display.text.isEmpty else { return "" }
        var text = display.text
        if text.hasSuffix(".") { text.removeLast() }
        return display.isNegative ? "-" + text : text
    }
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
