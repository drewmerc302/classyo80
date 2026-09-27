import CalcEngine
import Foundation
import Testing

/// Every worked example in the MS-80BM User's Guide (HDC463AE0P7, SA1711-A, 2018), in manual order.
/// The guide is Casio's and is not redistributed here; this suite is the record of what it says.
@Suite("Manual examples")
struct ManualExamplesTests {
    // MARK: Basic calculations

    @Test func acShowsZero() {
        var calc = Calculator()
        #expect(calc.run("AC") == "0.")
    }

    @Test func chainedArithmeticIsLeftToRight() {
        var calc = Calculator()
        #expect(calc.run("AC 6 ÷ 3 × 5 + 2.4 − 1 =") == "11.4")
    }

    @Test func signChange() {
        var calc = Calculator()
        #expect(calc.run("AC 2 × 3 +/- =") == "-6.")
    }

    // MARK: Constant calculations

    @Test func constantAddition() {
        var calc = Calculator()
        #expect(calc.run("AC 23 + + 12 =") == "35.")
        #expect(calc.display.indicators.contains(.constant))
        #expect(calc.run("45 =") == "68.")
        #expect(calc.display.indicators.contains(.constant))
    }

    @Test func constantSubtraction() {
        var calc = Calculator()
        #expect(calc.run("AC 5 − − 7 =") == "2.")
        #expect(calc.display.indicators.contains(.constant))
        #expect(calc.run("2 =") == "-3.")
    }

    @Test func constantMultiplication() {
        var calc = Calculator()
        #expect(calc.run("AC 12 × × 2 =") == "24.")
        #expect(calc.display.indicators.contains(.constant))
        #expect(calc.run("4 =") == "48.")
    }

    @Test func constantDivision() {
        var calc = Calculator()
        #expect(calc.run("AC 9 ÷ ÷ 45 =") == "5.")
        #expect(calc.display.indicators.contains(.constant))
        #expect(calc.run("72 =") == "8.")
    }

    // MARK: Percent

    @Test func percentOf() {
        var calc = Calculator()
        #expect(calc.run("AC 200 × 5 %") == "10.")
    }

    @Test func addOn() {
        var calc = Calculator()
        #expect(calc.run("AC 100 × 5 % +") == "105.")
    }

    @Test func discount() {
        var calc = Calculator()
        #expect(calc.run("AC 500 × 20 % −") == "400.")
    }

    @Test func ratio() {
        var calc = Calculator()
        #expect(calc.run("AC 30 ÷ 60 %") == "50.")
    }

    @Test func percentChange() {
        var calc = Calculator()
        #expect(calc.run("AC 12 − 10 %") == "20.")
    }

    @Test func markupThenMarginAmount() {
        var calc = Calculator()
        #expect(calc.run("AC 120 + 25 %") == "160.")
        #expect(calc.run("−") == "40.")
    }

    // MARK: Memory

    @Test func independentMemory() {
        var calc = Calculator()
        calc.run("AC")
        #expect(calc.run("MRC MRC 8 × 9 M+") == "72.")
        #expect(calc.display.indicators.contains(.memory))
        #expect(calc.run("5 × 6 M−") == "30.")
        #expect(calc.display.indicators.contains(.memory))
        #expect(calc.run("2 × 3 M+") == "6.")
        #expect(calc.run("MRC") == "48.")
        #expect(calc.display.indicators.contains(.memory))
    }

    @Test func mrcTwiceClearsMemoryOnly() {
        var calc = Calculator()
        calc.run("AC 7 M+ AC")
        #expect(calc.display.indicators.contains(.memory))
        calc.run("MRC MRC")
        #expect(!calc.display.indicators.contains(.memory))
        #expect(calc.run("MRC") == "0.")
    }

    @Test func acKeepsMemory() {
        var calc = Calculator()
        calc.run("AC 7 M+ AC")
        #expect(calc.run("MRC") == "7.")
    }

    // MARK: Correction

    @Test func clearEntry() {
        var calc = Calculator()
        #expect(calc.run("AC 2 + 3 C 4 =") == "6.")
    }

    @Test func operatorReplacement() {
        var calc = Calculator()
        #expect(calc.run("AC 2 + − 7 =") == "-5.")
    }

    @Test func backspace() {
        var calc = Calculator()
        #expect(calc.run("AC 5 + 77 ▶ =") == "12.")
    }

    // MARK: Currency conversion (C2 = 0.9025, C3 = 0.7509)

    static func withRates() -> Calculator {
        var calc = Calculator()
        calc.run("AC SET C2 0.9025 %")
        calc.run("AC SET C3 0.7509 %")
        calc.run("AC M/EX")
        return calc
    }

    @Test func modeToggleShowsExch() {
        var calc = Calculator()
        calc.run("AC")
        #expect(!calc.display.indicators.contains(.exchange))
        calc.run("M/EX")
        #expect(calc.display.indicators.contains(.exchange))
        #expect(calc.display.text == "0.")
        calc.run("M/EX")
        #expect(!calc.display.indicators.contains(.exchange))
    }

    @Test func settingRateShowsRate() {
        var calc = Calculator()
        calc.run("AC SET")
        #expect(calc.display.indicators.contains(.set))
        #expect(calc.run("C2 0.9025 %") == "0.9025")
        #expect(calc.display.indicators.isSuperset(of: [.c2, .exchange, .rate]))
        #expect(!calc.display.indicators.contains(.set))
        #expect(calc.persistent.rateC2 == Decimal(string: "0.9025"))
    }

    @Test func checkingRate() {
        var calc = Self.withRates()
        #expect(calc.run("AC C2") == "0.9025")
        #expect(calc.display.indicators.isSuperset(of: [.c2, .rate]))
        #expect(calc.run("AC C3") == "0.7509")
        #expect(calc.display.indicators.isSuperset(of: [.c3, .rate]))
    }

    @Test func euroToDollar() {
        var calc = Self.withRates()
        #expect(calc.run("AC 100 C2 C1") == "110.80332")
        #expect(calc.display.indicators.isSuperset(of: [.c1, .exchange]))
        #expect(calc.run("C2") == "100.")
        #expect(calc.display.indicators.isSuperset(of: [.c2, .exchange]))
    }

    @Test func dollarToPound() {
        var calc = Self.withRates()
        #expect(calc.run("AC 110 C1 C3") == "82.599")
        #expect(calc.display.indicators.isSuperset(of: [.c3, .exchange]))
        #expect(calc.run("C1") == "110.")
        #expect(calc.display.indicators.isSuperset(of: [.c1, .exchange]))
    }

    @Test func euroToPoundTruncatesCrossRate() {
        var calc = Self.withRates()
        #expect(calc.run("AC 100 C2 C3") == "83.202212")
        #expect(calc.display.indicators.isSuperset(of: [.c3, .exchange]))
        #expect(calc.run("C2") == "100.")
        #expect(calc.display.indicators.isSuperset(of: [.c2, .exchange]))
    }

    // MARK: Cost, sell, margin

    @Test func marginFromCostAndSell() {
        var calc = Calculator()
        #expect(calc.run("AC 800 COST 2000 SELL MAR") == "60.")
        #expect(calc.display.indicators.isSuperset(of: [.margin, .percent]))
    }

    @Test func marginAmountAndSellFromCostAndMargin() {
        var calc = Calculator()
        #expect(calc.run("AC 120 COST 40 MAR MAR") == "80.")
        #expect(calc.display.indicators.contains(.margin))
        #expect(!calc.display.indicators.contains(.percent))
        #expect(calc.run("SELL") == "200.")
        #expect(calc.display.indicators.contains(.sell))
    }

    @Test func marginAmountAndCostFromSellAndMargin() {
        var calc = Calculator()
        #expect(calc.run("AC 150 SELL 30 MAR MAR") == "45.")
        #expect(calc.display.indicators.contains(.margin))
        #expect(calc.run("COST") == "105.")
        #expect(calc.display.indicators.contains(.cost))
    }

    // MARK: Error

    @Test func overflowShowsErrorAndOnlyACClears() {
        var calc = Calculator()
        calc.run("AC 99999999 + 1 =")
        #expect(calc.display.indicators.contains(.error))
        calc.run("5 + 3 = C")
        #expect(calc.display.indicators.contains(.error))
        #expect(calc.run("AC") == "0.")
        #expect(!calc.display.indicators.contains(.error))
    }
}
