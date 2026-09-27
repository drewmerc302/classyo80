import Foundation

/// The calculator's state machine. Feed it keys, read `display`.
///
/// Behavior follows docs/SPEC.md, which is derived from the original's user's guide.
public struct Calculator: Sendable, Equatable {
    /// State that survives power off and app relaunch.
    public struct Persistent: Codable, Equatable, Sendable {
        public var memory: Decimal
        public var rateC2: Decimal
        public var rateC3: Decimal
        public var mode: Mode

        public init(memory: Decimal = 0, rateC2: Decimal = 1, rateC3: Decimal = 1, mode: Mode = .memory) {
            self.memory = memory
            self.rateC2 = rateC2
            self.rateC3 = rateC3
            self.mode = mode
        }

        private enum CodingKeys: String, CodingKey {
            case memory, rateC2, rateC3, mode
        }

        // Decimals are stored as strings: a JSON number round trip can turn 0.9025 into
        // 0.9025000000000001, which would change truncated conversion results.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            func decimal(_ key: CodingKeys, default fallback: Decimal) throws -> Decimal {
                guard let text = try container.decodeIfPresent(String.self, forKey: key) else { return fallback }
                return Decimal(string: text) ?? fallback
            }
            memory = try decimal(.memory, default: 0)
            rateC2 = try decimal(.rateC2, default: 1)
            rateC3 = try decimal(.rateC3, default: 1)
            mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .memory
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("\(memory)", forKey: .memory)
            try container.encode("\(rateC2)", forKey: .rateC2)
            try container.encode("\(rateC3)", forKey: .rateC3)
            try container.encode(mode, forKey: .mode)
        }
    }

    enum Op: Equatable, Sendable {
        case add, subtract, multiply, divide
    }

    /// The K constant: the operator pressed twice and the value it applies.
    struct Constant: Equatable, Sendable {
        var op: Op
        var value: Decimal
    }

    enum Input: Equatable, Sendable {
        case none
        case typing(Entry)
        /// An operand that was not typed: recalled memory, a sign-flipped result, a cleared entry.
        case value(Decimal)
    }

    enum LastAction: Equatable, Sendable {
        case none
        case op(Op)
        case equals
        case mrc
        case allClear
        case register(Register)
        case other
    }

    enum PercentFollowUp: Equatable, Sendable {
        /// `A × B %`: a following + or − gives A ± result.
        case addOn(base: Decimal, amount: Decimal)
        /// `A + B %`: a following − gives result − A.
        case markup(base: Decimal, result: Decimal)
    }

    struct CurrencyTag: Equatable, Sendable {
        var shown: Currency
        var source: Currency
        var amount: Decimal
    }

    enum SetState: Equatable, Sendable {
        case choosing
        case editing(Currency, Entry?)
    }

    enum Register: Equatable, Sendable {
        case cost, sell, margin
    }

    enum RegisterDisplay: Equatable, Sendable {
        case cost, sell, marginPercent, marginAmount
    }

    // MARK: Persistent state

    private var memory: Decimal
    private var rateC2: Decimal
    private var rateC3: Decimal
    private var mode: Mode

    // MARK: Calculation state

    private var isOn = true
    private var isError = false
    private var accumulator: Decimal = 0
    private var pending: Op?
    private var input: Input = .none
    /// The value on the LCD whenever nothing is being typed.
    private var shown: Decimal = 0
    private var constant: Constant?
    private var lastAction: LastAction = .none
    private var percentFollowUp: PercentFollowUp?
    private var currencyTag: CurrencyTag?
    private var rateShown: Currency?
    private var setState: SetState?
    private var registers: [Register: Decimal] = [:]
    /// The two most recently entered registers, oldest first. They define the third.
    private var knownRegisters: [Register] = []
    private var registerShown: RegisterDisplay?

    public init(persistent: Persistent = Persistent()) {
        memory = persistent.memory
        rateC2 = persistent.rateC2
        rateC3 = persistent.rateC3
        mode = persistent.mode
    }

    public var persistent: Persistent {
        get { Persistent(memory: memory, rateC2: rateC2, rateC3: rateC3, mode: mode) }
        set {
            memory = newValue.memory
            rateC2 = newValue.rateC2
            rateC3 = newValue.rateC3
            mode = newValue.mode
        }
    }

    // MARK: Display

    public var display: Display {
        guard isOn else { return Display(isOn: false, text: "", isNegative: false, indicators: []) }

        let text: String
        let negative: Bool
        if case .editing(_, let entry?) = setState {
            text = entry.text
            negative = false
        } else if case .typing(let entry) = input {
            text = entry.text
            negative = entry.showsMinus
        } else {
            text = Numeric.text(shown)
            negative = shown < 0
        }

        var indicators: Set<Indicator> = []
        if negative { indicators.insert(.minus) }
        if memory != 0 { indicators.insert(.memory) }
        if isError { indicators.insert(.error) }
        if constant != nil { indicators.insert(.constant) }
        if mode == .conversion { indicators.insert(.exchange) }

        switch registerShown {
        case .cost: indicators.insert(.cost)
        case .sell: indicators.insert(.sell)
        case .marginPercent: indicators.formUnion([.margin, .percent])
        case .marginAmount: indicators.insert(.margin)
        case nil: break
        }

        var currency = currencyTag?.shown
        if let rateShown {
            currency = rateShown
            indicators.formUnion([.rate, .exchange])
        }
        if let setState {
            indicators.insert(.set)
            if case .editing(let c, _) = setState {
                currency = c
                indicators.formUnion([.rate, .exchange])
            }
        }
        if let currency { indicators.insert(currency.indicator) }

        return Display(isOn: true, text: text, isNegative: negative, indicators: indicators)
    }

    // MARK: Keys

    public mutating func press(_ key: Key) {
        guard isOn else {
            if key == .allClear { powerOn() }
            return
        }
        if key == .off {
            powerOff()
            return
        }
        if key == .allClear {
            allClear()
            return
        }
        if isError { return }
        if setState != nil {
            pressInSetMode(key)
            return
        }

        switch key {
        case .digit(let d): typeDigit(d)
        case .point: typePoint()
        case .add: operatorKey(.add)
        case .subtract: operatorKey(.subtract)
        case .multiply: operatorKey(.multiply)
        case .divide: operatorKey(.divide)
        case .equals: equals()
        case .percent: percent()
        case .plusMinus: plusMinus()
        case .backspace: backspace()
        case .clear: clearEntry()
        case .mrc, .memoryMinus, .memoryPlus:
            if mode == .conversion {
                currencyKey(key.currency!)
            } else {
                memoryKey(key)
            }
        case .modeToggle:
            mode = mode == .memory ? .conversion : .memory
            clearAnnotations()
            // Right after AC, M/EX keeps the calculator "fresh" so AC M/EX C2 still shows the rate.
            if lastAction != .allClear { lastAction = .other }
        case .cost: registerKey(.cost)
        case .sell: registerKey(.sell)
        case .margin: registerKey(.margin)
        case .set:
            clearAnnotations()
            setState = .choosing
            lastAction = .other
        case .allClear, .off: break
        }
    }

    // MARK: Power and clearing

    private mutating func powerOn() {
        isOn = true
        allClear()
    }

    private mutating func powerOff() {
        allClear()
        isOn = false
    }

    private mutating func allClear() {
        isOn = true
        isError = false
        accumulator = 0
        pending = nil
        input = .none
        shown = 0
        constant = nil
        percentFollowUp = nil
        currencyTag = nil
        rateShown = nil
        setState = nil
        registers = [:]
        knownRegisters = []
        registerShown = nil
        lastAction = .allClear
    }

    private mutating func clearEntry() {
        clearAnnotations()
        percentFollowUp = nil
        input = .value(0)
        shown = 0
        lastAction = .other
    }

    /// Drops the labels that describe the displayed value (currency, rate, register).
    private mutating func clearAnnotations() {
        currencyTag = nil
        rateShown = nil
        registerShown = nil
    }

    // MARK: Entry

    private var operand: Decimal? {
        switch input {
        case .none: return nil
        case .typing(let entry): return entry.value
        case .value(let value): return value
        }
    }

    private mutating func typeDigit(_ digit: Int) {
        var entry = startTyping()
        entry.append(digit)
        input = .typing(entry)
    }

    private mutating func typePoint() {
        var entry = startTyping()
        entry.appendPoint()
        input = .typing(entry)
    }

    /// The entry to extend, or a fresh one when the display holds a result.
    private mutating func startTyping() -> Entry {
        clearAnnotations()
        percentFollowUp = nil
        lastAction = .other
        if case .typing(let entry) = input { return entry }
        return Entry()
    }

    private mutating func backspace() {
        guard case .typing(var entry) = input else { return }
        entry.deleteLast()
        input = .typing(entry)
        lastAction = .other
    }

    private mutating func plusMinus() {
        clearAnnotations()
        percentFollowUp = nil
        lastAction = .other
        switch input {
        case .typing(var entry):
            entry.toggleSign()
            input = .typing(entry)
        case .value(let value):
            show(negated(value))
            input = .value(shown)
        case .none:
            show(negated(shown))
            input = .value(shown)
        }
    }

    // MARK: Arithmetic

    private mutating func operatorKey(_ op: Op) {
        if input == .none, let followUp = percentFollowUp {
            percentFollowUp = nil
            switch (followUp, op) {
            case (.addOn(let base, let amount), .add):
                finish(with: base + amount)
                return
            case (.addOn(let base, let amount), .subtract):
                finish(with: base - amount)
                return
            case (.markup(let base, let result), .subtract):
                finish(with: result - base)
                return
            default:
                break
            }
        }
        clearAnnotations()

        if input == .none, case .op(let previous) = lastAction {
            if previous == op {
                constant = Constant(op: op, value: accumulator)
                pending = nil
            } else {
                constant = nil
                pending = op
            }
            lastAction = .op(op)
            return
        }

        if let pending, let operand {
            guard let result = compute(accumulator, pending, operand) else { return }
            show(result)
            if isError { return }
        } else if pending == nil {
            show(operand ?? shown)
        }
        // The chip keeps only the 8 displayed digits between chained steps.
        accumulator = shown
        input = .none
        pending = op
        constant = nil
        lastAction = .op(op)
    }

    private mutating func equals() {
        clearAnnotations()
        percentFollowUp = nil
        if let constant {
            let x = operand ?? shown
            guard let result = applyConstant(constant, to: x) else { return }
            finish(with: result)
        } else if let pending {
            guard let result = compute(accumulator, pending, operand ?? accumulator) else { return }
            finish(with: result)
        } else {
            finish(with: operand ?? shown)
        }
    }

    /// Finishes a pending calculation the way `=` would, if there is one. Used by the keys that
    /// act on "the result so far": M+, M−, the currency keys and the register keys.
    /// Returns false when the calculation raised an error.
    private mutating func finishPendingCalculation() -> Bool {
        guard pending != nil || (constant != nil && operand != nil) else {
            if let operand { show(operand) }
            input = .none
            return !isError
        }
        equals()
        return !isError
    }

    private mutating func percent() {
        clearAnnotations()
        percentFollowUp = nil
        let result: Decimal?
        if let constant {
            let x = operand ?? shown
            switch constant.op {
            case .multiply: result = constant.value * x / 100
            case .divide: result = divide(x * 100, by: constant.value)
            case .add, .subtract: result = applyConstant(constant, to: x)
            }
        } else if let pending {
            let a = accumulator
            let b = operand ?? accumulator
            switch pending {
            case .multiply:
                result = a * b / 100
                if let result, case .value(let amount) = Numeric.fit(result) {
                    percentFollowUp = .addOn(base: a, amount: amount)
                }
            case .divide:
                result = divide(a * 100, by: b)
            case .subtract:
                result = divide((a - b) * 100, by: b)
            case .add:
                result = divide(a * 100, by: 100 - b)
                if let result, case .value(let price) = Numeric.fit(result) {
                    percentFollowUp = .markup(base: a, result: price)
                }
            }
            self.pending = nil
        } else {
            result = operand ?? shown
        }
        guard let result else { return }
        finish(with: result)
    }

    private mutating func compute(_ a: Decimal, _ op: Op, _ b: Decimal) -> Decimal? {
        switch op {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide: return divide(a, by: b)
        }
    }

    private mutating func applyConstant(_ constant: Constant, to x: Decimal) -> Decimal? {
        switch constant.op {
        case .add: return x + constant.value
        case .subtract: return x - constant.value
        case .multiply: return constant.value * x
        case .divide: return divide(x, by: constant.value)
        }
    }

    /// Division that raises `E` on a zero divisor.
    private mutating func divide(_ a: Decimal, by b: Decimal) -> Decimal? {
        guard b != 0 else {
            raiseError(showing: 0)
            return nil
        }
        return a / b
    }

    /// Shows a completed result and ends the calculation.
    private mutating func finish(with value: Decimal) {
        show(value)
        accumulator = shown
        pending = nil
        input = .none
        lastAction = .equals
    }

    /// Puts `value` on the display, truncated, raising `E` if it does not fit.
    private mutating func show(_ value: Decimal) {
        switch Numeric.fit(value) {
        case .value(let fitted):
            shown = fitted
        case .overflow(let scaled):
            raiseError(showing: scaled)
        }
    }

    /// Negation that never produces a negative zero (which Decimal treats as NaN).
    private func negated(_ value: Decimal) -> Decimal {
        value == 0 ? 0 : -value
    }

    private func normalized(_ value: Decimal) -> Decimal {
        if case .value(let fitted) = Numeric.fit(value) { return fitted }
        return value
    }

    private mutating func raiseError(showing value: Decimal) {
        shown = value
        isError = true
        input = .none
        pending = nil
        percentFollowUp = nil
    }

    // MARK: Memory

    private mutating func memoryKey(_ key: Key) {
        if key == .mrc {
            clearAnnotations()
            percentFollowUp = nil
            if lastAction == .mrc {
                memory = 0
                lastAction = .other
                return
            }
            show(memory)
            input = .value(shown)
            lastAction = .mrc
            return
        }

        percentFollowUp = nil
        clearAnnotations()
        guard finishPendingCalculation() else { return }
        let total = key == .memoryPlus ? memory + shown : memory - shown
        switch Numeric.fit(total) {
        case .value(let fitted):
            memory = fitted
            accumulator = shown
            input = .none
            lastAction = .equals
        case .overflow(let scaled):
            raiseError(showing: scaled)
        }
    }

    // MARK: Currency conversion

    private func rate(_ currency: Currency) -> Decimal {
        switch currency {
        case .c1: return 1
        case .c2: return rateC2
        case .c3: return rateC3
        }
    }

    private mutating func currencyKey(_ currency: Currency) {
        percentFollowUp = nil
        registerShown = nil

        if lastAction == .allClear, input == .none {
            show(rate(currency))
            rateShown = currency
            currencyTag = nil
            lastAction = .other
            return
        }
        rateShown = nil

        if input == .none, pending == nil, let tag = currencyTag {
            guard let converted = convert(tag.amount, from: tag.source, to: currency) else { return }
            show(converted)
            if isError { return }
            currencyTag = CurrencyTag(shown: currency, source: tag.source, amount: tag.amount)
        } else {
            guard finishPendingCalculation() else { return }
            currencyTag = CurrencyTag(shown: currency, source: currency, amount: shown)
        }
        accumulator = shown
        input = .none
        lastAction = .other
    }

    /// The manual's conversion formulas. The C2↔C3 cross rate goes through C1 and truncates
    /// there, which is why `100 C2 C3` shows 83.202212 rather than 83.202216.
    private mutating func convert(_ amount: Decimal, from source: Currency, to target: Currency) -> Decimal? {
        if source == target { return amount }
        if source == .c1 { return amount * rate(target) }
        guard let home = divide(amount, by: rate(source)) else { return nil }
        if target == .c1 { return home }
        switch Numeric.fit(home) {
        case .value(let fitted): return fitted * rate(target)
        case .overflow(let scaled):
            raiseError(showing: scaled)
            return nil
        }
    }

    // MARK: Rate setting (hold %)

    private mutating func pressInSetMode(_ key: Key) {
        guard case .editing(let currency, let entry) = setState else {
            if let chosen = key.currency, chosen != .c1 {
                setState = .editing(chosen, nil)
                show(rate(chosen))
            }
            return
        }

        switch key {
        case .digit, .point:
            var editing = entry ?? Entry(limit: .rate)
            if case .digit(let d) = key { editing.append(d) } else { editing.appendPoint() }
            setState = .editing(currency, editing)
        case .backspace:
            guard var editing = entry else { return }
            editing.deleteLast()
            setState = .editing(currency, editing)
        case .clear:
            setState = .editing(currency, Entry(limit: .rate))
        case .memoryMinus, .mrc:
            let chosen = key.currency!
            setState = .editing(chosen, nil)
            show(rate(chosen))
        case .percent:
            let newRate = entry?.value ?? rate(currency)
            guard newRate > 0 else { return }
            switch currency {
            case .c1: return
            case .c2: rateC2 = newRate
            case .c3: rateC3 = newRate
            }
            setState = nil
            show(newRate)
            accumulator = shown
            input = .none
            rateShown = currency
            lastAction = .other
        default:
            break
        }
    }

    // MARK: Cost, sell, margin

    private mutating func registerKey(_ register: Register) {
        percentFollowUp = nil
        currencyTag = nil
        rateShown = nil

        let recalls: Bool
        switch lastAction {
        case .register, .allClear, .none: recalls = operand == nil && pending == nil
        default: recalls = false
        }

        if recalls {
            recall(register)
        } else {
            guard finishPendingCalculation() else { return }
            store(shown, in: register)
        }
        accumulator = shown
        input = .none
        lastAction = .register(register)
    }

    private mutating func store(_ value: Decimal, in register: Register) {
        registers[register] = value
        knownRegisters.removeAll { $0 == register }
        knownRegisters.append(register)
        if knownRegisters.count > 2 { knownRegisters.removeFirst() }
        registerShown = register == .margin ? .marginPercent : RegisterDisplay(register)
    }

    private mutating func recall(_ register: Register) {
        var target = register == .margin ? RegisterDisplay.marginPercent : RegisterDisplay(register)
        if register == .margin, lastAction == .register(.margin), registerShown == .marginPercent {
            target = .marginAmount
        }
        registerShown = target

        let value: Decimal?
        switch target {
        case .cost: value = registerValue(.cost)
        case .sell: value = registerValue(.sell)
        case .marginPercent: value = registerValue(.margin)
        case .marginAmount:
            if let sell = registerValue(.sell), let cost = registerValue(.cost) {
                value = sell - cost
            } else {
                value = nil
            }
        }
        guard !isError else { return }
        show(value ?? 0)
    }

    /// A register's stored value, or the value implied by the two most recent entries.
    /// Nil when it cannot be determined, or on a division by zero (which raises `E`).
    private mutating func registerValue(_ register: Register) -> Decimal? {
        if knownRegisters.contains(register) { return registers[register] }
        guard knownRegisters.count == 2 else { return nil }
        let cost = registers[.cost] ?? 0
        let sell = registers[.sell] ?? 0
        let margin = registers[.margin] ?? 0
        let derived: Decimal?
        switch register {
        case .cost:
            derived = sell * (100 - margin) / 100
        case .sell:
            derived = divide(cost * 100, by: 100 - margin)
        case .margin:
            derived = divide((sell - cost) * 100, by: sell)
        }
        // Derived values are 8-digit values too, so the margin amount matches SELL − COST on the display.
        return derived.map(normalized)
    }
}

extension Calculator.RegisterDisplay {
    init(_ register: Calculator.Register) {
        switch register {
        case .cost: self = .cost
        case .sell: self = .sell
        case .margin: self = .marginPercent
        }
    }
}

extension Key {
    /// The currency a key stands for in Conversion mode (M+ = C1, M− = C2, MRC = C3).
    var currency: Currency? {
        switch self {
        case .memoryPlus: return .c1
        case .memoryMinus: return .c2
        case .mrc: return .c3
        default: return nil
        }
    }
}

extension Currency {
    var indicator: Indicator {
        switch self {
        case .c1: return .c1
        case .c2: return .c2
        case .c3: return .c3
        }
    }
}
