import CalcEngine
import Foundation
import Testing

@Suite("Memory")
struct MemoryTests {
    @Test func memoryPlusFinishesPendingCalculation() {
        var calc = Calculator()
        calc.run("2 + 3 M+")
        #expect(calc.display.text == "5.")
        #expect(calc.persistent.memory == 5)
    }

    @Test func memoryPlusAddsDisplayedResult() {
        var calc = Calculator()
        calc.run("4 M+ M+")
        #expect(calc.persistent.memory == 8)
    }

    @Test func digitAfterMemoryPlusStartsNewNumber() {
        var calc = Calculator()
        #expect(calc.run("4 M+ 5") == "5.")
    }

    @Test func recalledMemoryIsAnOperand() {
        var calc = Calculator()
        calc.run("6 M+ AC")
        #expect(calc.run("10 + MRC =") == "16.")
        #expect(calc.run("AC MRC × 2 =") == "12.")
    }

    @Test func digitAfterRecallStartsNewNumber() {
        var calc = Calculator()
        calc.run("6 M+ AC MRC")
        #expect(calc.run("3") == "3.")
    }

    @Test func memoryCanGoNegative() {
        var calc = Calculator()
        calc.run("5 M−")
        #expect(calc.display.indicators.contains(.memory))
        #expect(calc.run("MRC") == "-5.")
    }

    @Test func memoryReturningToZeroHidesIndicator() {
        var calc = Calculator()
        calc.run("5 M+ 5 M−")
        #expect(!calc.display.indicators.contains(.memory))
    }

    @Test func memoryOverflowIsErrorAndKeepsMemory() {
        var calc = Calculator()
        calc.run("99999999 M+ 1 M+")
        #expect(calc.display.indicators.contains(.error))
        calc.run("AC")
        #expect(calc.run("MRC") == "99999999.")
    }

    @Test func memoryKeysAreCurrencyKeysInConversionMode() {
        var calc = Calculator()
        calc.run("M/EX 5 M+")
        #expect(calc.persistent.memory == 0)
        #expect(calc.display.indicators.contains(.c1))
    }

    @Test func memorySurvivesModeToggle() {
        var calc = Calculator()
        calc.run("9 M+ M/EX")
        #expect(calc.display.indicators.contains(.memory))
        calc.run("M/EX AC")
        #expect(calc.run("MRC") == "9.")
    }
}

@Suite("Currency conversion")
struct CurrencyTests {
    @Test func defaultRatesAreOne() {
        var calc = Calculator()
        calc.run("M/EX")
        #expect(calc.run("AC C2") == "1.")
        #expect(calc.run("AC 5 C2 C1") == "5.")
    }

    @Test func setAcceptsRateOfOneOrMoreUpToSixDigits() {
        var calc = Calculator()
        #expect(calc.run("SET C3 1234567 %") == "123456.")
        #expect(calc.persistent.rateC3 == 123456)
    }

    @Test func setAcceptsSixSignificantDigitsBelowOne() {
        var calc = Calculator()
        #expect(calc.run("SET C2 0.01234567 %") == "0.0123456")
        #expect(calc.persistent.rateC2 == Decimal(string: "0.0123456"))
    }

    @Test func setShowsCurrentRateAfterChoosingCurrency() {
        var calc = Calculator()
        calc.run("SET C2 0.9025 %")
        #expect(calc.run("AC SET C2") == "0.9025")
        #expect(calc.display.indicators.isSuperset(of: [.set, .c2, .rate]))
    }

    @Test func setIgnoresC1() {
        var calc = Calculator()
        calc.run("SET C1 5 %")
        #expect(calc.display.indicators.contains(.set))
    }

    @Test func setRejectsZeroRate() {
        var calc = Calculator()
        calc.run("SET C2 0 %")
        #expect(calc.display.indicators.contains(.set))
        #expect(calc.persistent.rateC2 == 1)
    }

    @Test func acAbandonsSet() {
        var calc = Calculator()
        calc.run("SET C2 5 AC")
        #expect(!calc.display.indicators.contains(.set))
        #expect(calc.persistent.rateC2 == 1)
        #expect(calc.display.text == "0.")
    }

    @Test func setWorksInConversionModeToo() {
        var calc = Calculator()
        calc.run("M/EX SET C3 2 %")
        #expect(calc.persistent.rateC3 == 2)
        #expect(calc.run("AC 10 C1 C3") == "20.")
    }

    @Test func pressingSameCurrencyAgainKeepsValue() {
        var calc = ManualExamplesTests.withRates()
        #expect(calc.run("AC 100 C2 C2") == "100.")
        #expect(calc.display.indicators.contains(.c2))
    }

    @Test func conversionResultIsUsableInArithmetic() {
        var calc = ManualExamplesTests.withRates()
        #expect(calc.run("AC 110 C1 C3 + 1 =") == "83.599")
        #expect(!calc.display.indicators.contains(.c3))
        #expect(calc.display.indicators.contains(.exchange))
    }

    @Test func currencyKeyFinishesPendingCalculation() {
        var calc = ManualExamplesTests.withRates()
        #expect(calc.run("AC 100 + 10 C1 C2") == "99.275")
    }

    @Test func newNumberStartsNewConversion() {
        var calc = ManualExamplesTests.withRates()
        calc.run("AC 100 C2 C1")
        #expect(calc.run("200 C1 C2") == "180.5")
    }

    @Test func resultTaggedAfterEquals() {
        var calc = ManualExamplesTests.withRates()
        #expect(calc.run("AC 60 + 50 = C1 C3") == "82.599")
    }

    @Test func conversionOverflowIsError() {
        var calc = Calculator()
        calc.run("SET C2 100000 % M/EX AC 99999999 C1 C2")
        #expect(calc.display.indicators.contains(.error))
    }
}

@Suite("Cost, sell, margin")
struct CostSellMarginTests {
    @Test func storingShowsValueWithIndicator() {
        var calc = Calculator()
        #expect(calc.run("800 COST") == "800.")
        #expect(calc.display.indicators.contains(.cost))
        #expect(calc.run("2000 SELL") == "2000.")
        #expect(calc.display.indicators.contains(.sell))
        #expect(!calc.display.indicators.contains(.cost))
    }

    @Test func storingMarginShowsPercent() {
        var calc = Calculator()
        #expect(calc.run("40 MAR") == "40.")
        #expect(calc.display.indicators.isSuperset(of: [.margin, .percent]))
    }

    @Test func marginTogglesBetweenPercentAndAmount() {
        var calc = Calculator()
        calc.run("800 COST 2000 SELL MAR")
        #expect(calc.run("MAR") == "1200.")
        #expect(!calc.display.indicators.contains(.percent))
        #expect(calc.run("MAR") == "60.")
        #expect(calc.display.indicators.contains(.percent))
    }

    @Test func recallStoredRegister() {
        var calc = Calculator()
        calc.run("800 COST 2000 SELL")
        #expect(calc.run("COST") == "800.")
        #expect(calc.run("SELL") == "2000.")
    }

    @Test func latestTwoEntriesDefineTheThird() {
        var calc = Calculator()
        calc.run("100 COST 200 SELL 25 MAR")
        // Known: SELL 200 and MAR 25%, so COST is recomputed from them.
        #expect(calc.run("COST") == "150.")
    }

    @Test func unknownRegisterShowsZero() {
        var calc = Calculator()
        calc.run("800 COST")
        #expect(calc.run("SELL") == "0.")
    }

    @Test func registerValueUsableInArithmetic() {
        var calc = Calculator()
        #expect(calc.run("120 COST 40 MAR SELL − 20 =") == "180.")
    }

    @Test func pendingCalculationFinishesBeforeStore() {
        var calc = Calculator()
        calc.run("100 + 20 COST")
        #expect(calc.display.text == "120.")
        calc.run("50 MAR SELL")
        #expect(calc.display.text == "240.")
    }

    @Test func hundredPercentMarginIsError() {
        var calc = Calculator()
        calc.run("120 COST 100 MAR SELL")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func zeroSellIsError() {
        var calc = Calculator()
        calc.run("120 COST 0 SELL MAR")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func acClearsRegisters() {
        var calc = Calculator()
        calc.run("800 COST 2000 SELL AC")
        #expect(calc.run("MAR") == "0.")
    }

    @Test func fractionalMarginTruncates() {
        var calc = Calculator()
        #expect(calc.run("100 COST 30 MAR SELL") == "142.85714")
    }
}

@Suite("Power and persistence")
struct PowerTests {
    @Test func offBlanksDisplay() {
        var calc = Calculator()
        calc.run("5 OFF")
        #expect(!calc.display.isOn)
        #expect(calc.display.text.isEmpty)
        #expect(calc.display.indicators.isEmpty)
    }

    @Test func keysIgnoredWhileOff() {
        var calc = Calculator()
        calc.run("OFF 5 + 3 M+ M/EX")
        #expect(!calc.display.isOn)
        #expect(calc.persistent.memory == 0)
        #expect(calc.persistent.mode == .memory)
    }

    @Test func acTurnsOnCleared() {
        var calc = Calculator()
        calc.run("7 M+ 5 + 3 OFF")
        #expect(calc.run("ON") == "0.")
        #expect(calc.display.isOn)
        #expect(calc.display.indicators.contains(.memory))
    }

    @Test func persistentRoundTrip() throws {
        var calc = Calculator()
        calc.run("SET C2 0.9025 % AC 42 M+ M/EX")
        let data = try JSONEncoder().encode(calc.persistent)
        let restored = try JSONDecoder().decode(Calculator.Persistent.self, from: data)
        var fresh = Calculator(persistent: restored)
        #expect(fresh.display.indicators.isSuperset(of: [.memory, .exchange]))
        #expect(fresh.run("AC C2") == "0.9025")
        fresh.run("M/EX")
        #expect(fresh.run("MRC") == "42.")
    }
}
