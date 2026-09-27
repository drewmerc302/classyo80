import CalcEngine
import Foundation
import Testing
@testable import ClassyO80

@MainActor
final class CalculatorModelTests {
    private let suiteName = "ClassyO80Tests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let scheduler = ManualScheduler()
    private let haptics = CountingHaptics()

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func makeModel(engine: any CalculatorEngine.Type = RecordingEngine.self) -> CalculatorModel {
        CalculatorModel(engine: engine, defaults: defaults, scheduler: scheduler, haptics: haptics)
    }

    // MARK: Persistence

    @Test func freshInstallStartsFromDefaults() {
        #expect(makeModel().persistent == Calculator.Persistent())
    }

    @Test func persistentStateSurvivesARelaunch() {
        let first = makeModel()
        first.press(.memoryPlus)
        first.press(.memoryPlus)
        #expect(first.persistent.memory == 2)

        let second = makeModel()
        #expect(second.persistent.memory == 2)
    }

    @Test func unreadableStoredStateFallsBackToDefaults() {
        defaults.set(Data("not json".utf8), forKey: CalculatorModel.storageKey)
        #expect(makeModel().persistent == Calculator.Persistent())
    }

    @Test func realEngineRestoresMemoryRatesAndMode() throws {
        let stored = Calculator.Persistent(
            memory: 48, rateC2: Decimal(string: "0.9025")!, rateC3: Decimal(string: "0.7509")!, mode: .conversion
        )
        defaults.set(try JSONEncoder().encode(stored), forKey: CalculatorModel.storageKey)

        #expect(makeModel(engine: Calculator.self).persistent == stored)
    }

    @Test func realEngineMemoryRoundTrip() {
        let first = makeModel(engine: Calculator.self)
        for key: Key in [.mrc, .mrc, .digit(8), .multiply, .digit(9), .memoryPlus] {
            first.press(key)
        }

        let second = makeModel(engine: Calculator.self)
        second.press(.mrc)
        #expect(second.display.text == "72.")
    }

    // MARK: Auto power off

    @Test func powersOffAfterSixMinutesWithoutAKeyPress() {
        let model = makeModel()
        scheduler.advance(by: .seconds(359))
        #expect(model.display.isOn)

        scheduler.advance(by: .seconds(1))
        #expect(!model.display.isOn)
    }

    @Test func keyPressRestartsTheSixMinuteTimer() {
        let model = makeModel()
        scheduler.advance(by: .seconds(300))
        model.press(.digit(1))

        scheduler.advance(by: .seconds(300))
        #expect(model.display.isOn, "only 5 minutes since the last press")

        scheduler.advance(by: .seconds(60))
        #expect(!model.display.isOn)
    }

    @Test func pressingOffStopsTheTimer() {
        let model = makeModel()
        model.press(.off)
        #expect(scheduler.pendingCount == 0)

        model.press(.allClear)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func autoPowerOffIsPersistedWithoutAHapticTap() {
        let model = makeModel()
        model.press(.memoryPlus)
        scheduler.advance(by: CalculatorModel.autoPowerOffDelay)
        #expect(!model.display.isOn)
        #expect(haptics.count == 1)
        #expect(makeModel().persistent.memory == 1)
    }

    // MARK: Haptics

    @Test func everyKeyPressTaps() {
        let model = makeModel()
        model.press(.digit(1))
        model.press(.add)
        model.press(.digit(2))
        #expect(haptics.count == 3)
    }
}
