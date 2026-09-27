import CalcEngine
import Foundation
import Testing

/// Regressions from the adversarial engine review.
@Suite("Review findings")
struct ReviewFindingsTests {
    // The chip keeps only 8 digits between chained steps (same rule that makes
    // `100 C2 C3` show 83.202212), so every intermediate result is truncated.

    @Test func chainedIntermediateIsTruncated() {
        var calc = Calculator()
        #expect(calc.run("2 ÷ 3 × 3 =") == "1.9999998")
        #expect(calc.run("AC 1 ÷ 3 × 1200 =") == "399.99996")
    }

    @Test func chainedMatchesEqualsThenContinue() {
        var a = Calculator()
        var b = Calculator()
        #expect(a.run("100 ÷ 7 × 7 =") == b.run("100 ÷ 7 = × 7 ="))
        #expect(a.display.text == "99.999998")
    }

    @Test func chainedIntermediateTruncatedForLargeMultiplier() {
        var calc = Calculator()
        #expect(calc.run("7 ÷ 12 × 1000000 =") == "583333.3")
    }

    @Test func constantBuiltFromChainIsTruncated() {
        var calc = Calculator()
        #expect(calc.run("2 ÷ 3 × × 3 =") == "1.9999998")
    }

    @Test func percentBaseFromChainIsTruncated() {
        var calc = Calculator()
        #expect(calc.run("1 ÷ 3 × 300 %") == "0.9999999")
    }

    @Test func underflowInChainGoesToZero() {
        var calc = Calculator()
        #expect(calc.run("0.0001 × 0.0001 × 10000 × 10000 =") == "0.")
        #expect(!calc.display.indicators.contains(.error))
    }

    @Test func repeatedTinyMultiplicationNeverErrors() {
        var calc = Calculator()
        calc.run("0.0000001")
        for _ in 0..<30 { calc.run("× 0.0000001") }
        #expect(calc.run("=") == "0.")
        #expect(!calc.display.indicators.contains(.error))
    }

    // Checking a rate from Memory mode needs M/EX between AC and C2.

    @Test func rateCheckSurvivesModeToggle() {
        var calc = Calculator()
        calc.run("SET C2 0.9025 %")
        #expect(calc.run("AC M/EX C2") == "0.9025")
        #expect(calc.display.indicators.isSuperset(of: [.c2, .rate]))
    }

    // Derived registers are 8-digit values like everything else.

    @Test func marginAmountUsesTruncatedSellPrice() {
        var calc = Calculator()
        #expect(calc.run("100 COST 30 MAR MAR") == "42.85714")
    }

    // Sign and backspace edge cases.

    @Test func negativeZeroEntryHidesMinus() {
        var calc = Calculator()
        calc.run("0 . +/-")
        #expect(!calc.display.isNegative)
        #expect(calc.run("5") == "-0.5")
    }

    @Test func backspacingToEmptyDropsSign() {
        var calc = Calculator()
        #expect(calc.run("5 +/- ▶ 3 =") == "3.")
    }

    @Test func backspaceSkipsTrailingPoint() {
        var calc = Calculator()
        #expect(calc.run("12 . ▶") == "1.")
        #expect(calc.run("5") == "15.")
    }

    // Coverage gaps in the manual examples.

    @Test func constantIndicatorStaysOnSecondLines() {
        for script in ["5 − − 7 = 2 =", "12 × × 2 = 4 =", "9 ÷ ÷ 45 = 72 ="] {
            let calc = Calculator.after(script)
            #expect(calc.display.indicators.contains(.constant), "\(script)")
        }
    }

    @Test func manualRateFootnoteExample() {
        var calc = Calculator()
        #expect(calc.run("SET C2 0.123456 %") == "0.123456")
        #expect(calc.run("AC SET C3 0.1234567 %") == "0.123456")
    }

    @Test func memoryExampleFromConversionMode() {
        var calc = Calculator()
        calc.run("AC M/EX")
        #expect(calc.display.indicators.contains(.exchange))
        calc.run("M/EX MRC MRC")
        #expect(calc.run("8 × 9 M+") == "72.")
        #expect(calc.run("5 × 6 M−") == "30.")
        #expect(calc.run("2 × 3 M+") == "6.")
        #expect(calc.run("MRC") == "48.")
    }
}
