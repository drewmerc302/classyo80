/// Runs work after a delay. Injected so auto power off can be tested without waiting.
@MainActor
protocol DelayScheduler {
    /// Runs `action` after `delay` unless the returned task is cancelled first.
    func schedule(after delay: Duration, _ action: @escaping @MainActor @Sendable () -> Void) -> any ScheduledTask
}

@MainActor
protocol ScheduledTask {
    func cancel()
}

/// The production scheduler: a main-actor task sleeping on the continuous clock, so time spent
/// suspended in the background still counts toward auto power off.
struct SleepingScheduler: DelayScheduler {
    func schedule(after delay: Duration, _ action: @escaping @MainActor @Sendable () -> Void) -> any ScheduledTask {
        Task { @MainActor in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            action()
        }
    }
}

extension Task: ScheduledTask where Success == Void, Failure == Never {}
