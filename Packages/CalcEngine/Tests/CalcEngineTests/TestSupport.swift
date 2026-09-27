import CalcEngine
import Foundation

/// Parses a space-separated key script such as "6 ÷ 3 × 5 + 2.4 − 1 =" into keys.
/// Numbers expand to digit and point keys. Currency keys (C1/C2/C3) map to the physical
/// M+/M−/MRC keys, exactly as on the real unit.
func keys(_ script: String) -> [Key] {
    script.split(separator: " ").flatMap { token -> [Key] in
        switch token {
        case "+": return [.add]
        case "-", "−": return [.subtract]
        case "*", "×", "x": return [.multiply]
        case "/", "÷": return [.divide]
        case "=": return [.equals]
        case "%": return [.percent]
        case "SET": return [.set]
        case "+/-", "±": return [.plusMinus]
        case "▶", "BS": return [.backspace]
        case "C": return [.clear]
        case "AC", "ON": return [.allClear]
        case "OFF": return [.off]
        case "MRC", "C3": return [.mrc]
        case "M-", "M−", "C2": return [.memoryMinus]
        case "M+", "C1": return [.memoryPlus]
        case "M/EX", "MEX": return [.modeToggle]
        case "COST": return [.cost]
        case "SELL": return [.sell]
        case "MAR": return [.margin]
        default:
            return token.map { ch -> Key in
                if ch == "." { return .point }
                guard let d = ch.wholeNumberValue else { fatalError("Unknown token \(token)") }
                return .digit(d)
            }
        }
    }
}

extension Calculator {
    /// Presses every key in the script and returns the signed display text, e.g. "-6.".
    @discardableResult
    mutating func run(_ script: String) -> String {
        for key in keys(script) { press(key) }
        return display.signedText
    }

    static func after(_ script: String) -> Calculator {
        var calc = Calculator()
        calc.run(script)
        return calc
    }
}
