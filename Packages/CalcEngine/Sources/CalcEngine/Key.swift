/// One physical key on the calculator, or one gesture on it (holding `%` is `.set`).
public enum Key: Hashable, Sendable {
    case digit(Int)
    case point
    case add, subtract, multiply, divide
    case equals
    case percent
    case plusMinus
    /// The ▶ key: deletes the last digit typed.
    case backspace
    /// C: clears the current entry.
    case clear
    /// AC (also ON).
    case allClear
    case off
    /// MRC in Memory mode, C3 in Conversion mode.
    case mrc
    /// M− in Memory mode, C2 in Conversion mode.
    case memoryMinus
    /// M+ in Memory mode, C1 in Conversion mode.
    case memoryPlus
    /// M/EX: toggles Memory mode and Conversion mode.
    case modeToggle
    case cost, sell, margin
    /// Holding `%` until SET appears.
    case set
}

public enum Mode: String, Codable, Sendable {
    case memory
    case conversion
}

public enum Currency: Int, Codable, Sendable, CaseIterable {
    case c1 = 1, c2, c3
}

/// LCD annunciators, in the order they are laid out on the display.
public enum Indicator: String, CaseIterable, Sendable {
    case minus = "−"
    case memory = "M"
    case error = "E"
    case constant = "K"
    case cost = "COST"
    case sell = "SELL"
    case margin = "MAR"
    case percent = "%"
    case exchange = "EXCH"
    case rate = "RATE"
    case c1 = "C1"
    case c2 = "C2"
    case c3 = "C3"
    case set = "SET"
}

/// What the LCD shows.
public struct Display: Equatable, Sendable {
    public var isOn: Bool
    /// Unsigned digits with the decimal point, no separators: "0.", "35.", "11.4", "2.50".
    /// Empty when the calculator is off.
    public var text: String
    public var isNegative: Bool
    public var indicators: Set<Indicator>

    public init(isOn: Bool, text: String, isNegative: Bool, indicators: Set<Indicator>) {
        self.isOn = isOn
        self.text = text
        self.isNegative = isNegative
        self.indicators = indicators
    }

    /// `text` with a leading "-" when negative, e.g. "-6.". Handy for tests and accessibility.
    public var signedText: String { isNegative ? "-" + text : text }
}
