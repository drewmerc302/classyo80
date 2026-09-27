import CalcEngine

/// The engine surface `CalculatorModel` drives. `Calculator` is the real one; tests substitute
/// a recording engine so persistence and power timing can be checked on their own.
protocol CalculatorEngine: Sendable {
    init(persistent: Calculator.Persistent)
    var display: Display { get }
    var persistent: Calculator.Persistent { get }
    mutating func press(_ key: Key)
}

extension Calculator: CalculatorEngine {}
