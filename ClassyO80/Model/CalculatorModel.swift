import CalcEngine
import Foundation
import Observation

/// The app's single calculator: forwards key presses to the engine, keeps memory, rates and mode
/// across launches, and powers off after six idle minutes like the real unit.
@Observable
@MainActor
final class CalculatorModel {
    static let autoPowerOffDelay: Duration = .seconds(6 * 60)
    static let storageKey = "calculator.persistent"

    private var engine: any CalculatorEngine

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: any DelayScheduler
    @ObservationIgnored private let haptics: any KeyHaptics
    @ObservationIgnored private var autoPowerOff: (any ScheduledTask)?
    @ObservationIgnored private var savedPersistent: Calculator.Persistent?

    init(
        engine: any CalculatorEngine.Type = Calculator.self,
        defaults: UserDefaults = .standard,
        scheduler: any DelayScheduler = SleepingScheduler(),
        haptics: any KeyHaptics = ImpactHaptics()
    ) {
        let stored = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode(Calculator.Persistent.self, from: $0) }
        self.engine = engine.init(persistent: stored ?? Calculator.Persistent())
        self.defaults = defaults
        self.scheduler = scheduler
        self.haptics = haptics
        self.savedPersistent = stored
        restartAutoPowerOff()
    }

    var display: Display { engine.display }
    var persistent: Calculator.Persistent { engine.persistent }

    func press(_ key: Key) {
        haptics.keyPressed()
        engine.press(key)
        save()
        restartAutoPowerOff()
    }

    private func restartAutoPowerOff() {
        autoPowerOff?.cancel()
        autoPowerOff = nil
        guard engine.display.isOn else { return }
        autoPowerOff = scheduler.schedule(after: Self.autoPowerOffDelay) { [weak self] in
            self?.powerOff()
        }
    }

    private func powerOff() {
        autoPowerOff = nil
        engine.press(.off)
        save()
    }

    private func save() {
        let current = engine.persistent
        guard current != savedPersistent, let data = try? JSONEncoder().encode(current) else { return }
        defaults.set(data, forKey: Self.storageKey)
        savedPersistent = current
    }
}
