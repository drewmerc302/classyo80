import CalcEngine
import Foundation
@testable import ClassyO80

/// A scheduler driven by hand: nothing fires until `advance(by:)` moves its clock past a deadline.
@MainActor
final class ManualScheduler: DelayScheduler {
    private struct Entry {
        let id: Int
        let deadline: Duration
        let action: @MainActor @Sendable () -> Void
    }

    private final class Token: ScheduledTask {
        weak var scheduler: ManualScheduler?
        let id: Int

        init(scheduler: ManualScheduler, id: Int) {
            self.scheduler = scheduler
            self.id = id
        }

        func cancel() { scheduler?.cancel(id) }
    }

    private(set) var now: Duration = .zero
    private var entries: [Entry] = []
    private var nextID = 0

    var pendingCount: Int { entries.count }

    func schedule(after delay: Duration, _ action: @escaping @MainActor @Sendable () -> Void) -> any ScheduledTask {
        nextID += 1
        entries.append(Entry(id: nextID, deadline: now + delay, action: action))
        return Token(scheduler: self, id: nextID)
    }

    func advance(by duration: Duration) {
        now += duration
        let due = entries.filter { $0.deadline <= now }.sorted { $0.deadline < $1.deadline }
        entries.removeAll { $0.deadline <= now }
        for entry in due { entry.action() }
    }

    private func cancel(_ id: Int) {
        entries.removeAll { $0.id == id }
    }
}

@MainActor
final class CountingHaptics: KeyHaptics {
    private(set) var count = 0
    func keyPressed() { count += 1 }
}

/// A stand-in engine whose persistent state and power are easy to steer, so model tests do not
/// depend on the real engine's arithmetic. `M+` adds 1 to memory; `OFF` and `AC` switch power.
struct RecordingEngine: CalculatorEngine {
    var persistent: Calculator.Persistent
    private var isOn = true

    init(persistent: Calculator.Persistent) {
        self.persistent = persistent
    }

    var display: Display {
        Display(isOn: isOn, text: isOn ? "0." : "", isNegative: false, indicators: [])
    }

    mutating func press(_ key: Key) {
        switch key {
        case .off: isOn = false
        case .allClear: isOn = true
        case .memoryPlus: persistent.memory += 1
        default: break
        }
    }
}
