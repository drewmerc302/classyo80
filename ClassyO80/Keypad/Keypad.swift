import CalcEngine
import CoreGraphics

/// One key on the front panel: what it sends, where it sits, and how it looks.
struct KeySpec: Identifiable, Sendable {
    enum Style: Sendable {
        /// The short top-row keys (OFF, ▶, COST, SELL, MAR).
        case small
        /// Mid-grey function and operator keys.
        case function
        /// Near-black number keys.
        case digit
        /// Orange C and AC.
        case clear
    }

    enum Legend: Sendable {
        /// Text printed on the key; `size` is the font size in millimetres.
        case text(String, size: CGFloat)
        /// Gold text on the small COST, SELL and MAR keys.
        case gold(String)
        /// The ▶ triangle.
        case play
        /// The stacked +/− legend.
        case plusMinus
        /// The decimal point.
        case dot
    }

    let identifier: String
    let key: Key
    var holdKey: Key? = nil
    let legend: Legend
    /// Small text printed on the key cap above the legend (SET on %, MODE on M/EX).
    var caption: String? = nil
    let spokenLabel: String
    let style: Style
    let row: Int
    let column: Int
    var rowSpan = 1

    var id: String { identifier }
}

/// The key layout: 5 columns by 6 rows, with + spanning the bottom two rows.
enum Keypad {
    static let keys: [KeySpec] = [
        KeySpec(identifier: "key.OFF", key: .off, legend: .text("OFF", size: 2.7),
                spokenLabel: "off", style: .small, row: 0, column: 0),
        KeySpec(identifier: "key.backspace", key: .backspace, legend: .play,
                spokenLabel: "delete last digit", style: .small, row: 0, column: 1),
        KeySpec(identifier: "key.COST", key: .cost, legend: .gold("COST"),
                spokenLabel: "cost", style: .small, row: 0, column: 2),
        KeySpec(identifier: "key.SELL", key: .sell, legend: .gold("SELL"),
                spokenLabel: "sell", style: .small, row: 0, column: 3),
        KeySpec(identifier: "key.MAR", key: .margin, legend: .gold("MAR"),
                spokenLabel: "margin", style: .small, row: 0, column: 4),

        KeySpec(identifier: "key.MRC", key: .mrc, legend: .text("MRC", size: 4.5),
                spokenLabel: "memory recall clear", style: .function, row: 1, column: 0),
        KeySpec(identifier: "key.Mminus", key: .memoryMinus, legend: .text("M−", size: 4.5),
                spokenLabel: "memory minus", style: .function, row: 1, column: 1),
        KeySpec(identifier: "key.Mplus", key: .memoryPlus, legend: .text("M+", size: 4.5),
                spokenLabel: "memory plus", style: .function, row: 1, column: 2),
        KeySpec(identifier: "key.percent", key: .percent, holdKey: .set, legend: .text("%", size: 4.6),
                caption: "SET", spokenLabel: "percent", style: .function, row: 1, column: 3),
        KeySpec(identifier: "key.divide", key: .divide, legend: .text("÷", size: 6.4),
                spokenLabel: "divide", style: .function, row: 1, column: 4),

        KeySpec(identifier: "key.MEX", key: .modeToggle, legend: .text("M/EX", size: 3.9),
                caption: "MODE", spokenLabel: "mode, memory or exchange", style: .function, row: 2, column: 0),
        digit(7, row: 2, column: 1),
        digit(8, row: 2, column: 2),
        digit(9, row: 2, column: 3),
        KeySpec(identifier: "key.multiply", key: .multiply, legend: .text("×", size: 6.4),
                spokenLabel: "multiply", style: .function, row: 2, column: 4),

        KeySpec(identifier: "key.plusMinus", key: .plusMinus, legend: .plusMinus,
                spokenLabel: "plus minus", style: .function, row: 3, column: 0),
        digit(4, row: 3, column: 1),
        digit(5, row: 3, column: 2),
        digit(6, row: 3, column: 3),
        KeySpec(identifier: "key.minus", key: .subtract, legend: .text("−", size: 6.4),
                spokenLabel: "minus", style: .function, row: 3, column: 4),

        KeySpec(identifier: "key.C", key: .clear, legend: .text("C", size: 5.4),
                spokenLabel: "clear entry", style: .clear, row: 4, column: 0),
        digit(1, row: 4, column: 1),
        digit(2, row: 4, column: 2),
        digit(3, row: 4, column: 3),
        KeySpec(identifier: "key.plus", key: .add, legend: .text("+", size: 7.4),
                spokenLabel: "plus", style: .function, row: 4, column: 4, rowSpan: 2),

        KeySpec(identifier: "key.AC", key: .allClear, legend: .text("AC", size: 5.0),
                spokenLabel: "all clear, on", style: .clear, row: 5, column: 0),
        digit(0, row: 5, column: 1),
        KeySpec(identifier: "key.point", key: .point, legend: .dot,
                spokenLabel: "decimal point", style: .digit, row: 5, column: 2),
        KeySpec(identifier: "key.equals", key: .equals, legend: .text("=", size: 6.4),
                spokenLabel: "equals", style: .function, row: 5, column: 3),
    ]

    private static func digit(_ value: Int, row: Int, column: Int) -> KeySpec {
        KeySpec(identifier: "key.\(value)", key: .digit(value), legend: .text("\(value)", size: 5.8),
                spokenLabel: "\(value)", style: .digit, row: row, column: column)
    }
}
