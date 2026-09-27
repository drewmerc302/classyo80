import CalcEngine
import Testing
@testable import ClassyO80

struct KeyHoldTrackerTests {
    @Test func plainKeyNeverStartsAHoldTimer() {
        var tracker = KeyHoldTracker(tapKey: .digit(7))
        #expect(tracker.pressBegan() == false)
        #expect(tracker.holdElapsed() == nil)
        tracker.pressEnded()
        #expect(tracker.activated() == .digit(7))
    }

    @Test func quickTapOnPercentSendsPercent() {
        var tracker = KeyHoldTracker(tapKey: .percent, holdKey: .set)
        #expect(tracker.pressBegan() == true)
        tracker.pressEnded()
        #expect(tracker.activated() == .percent)
    }

    @Test func activationBeforeReleaseStillSendsPercent() {
        var tracker = KeyHoldTracker(tapKey: .percent, holdKey: .set)
        _ = tracker.pressBegan()
        #expect(tracker.activated() == .percent)
        tracker.pressEnded()
    }

    @Test func holdingPercentSendsSetOnceAndSwallowsTheRelease() {
        var tracker = KeyHoldTracker(tapKey: .percent, holdKey: .set)
        _ = tracker.pressBegan()
        #expect(tracker.holdElapsed() == .set)
        #expect(tracker.holdElapsed() == nil)
        tracker.pressEnded()
        #expect(tracker.activated() == nil)
    }

    @Test func holdTimerFiringAfterReleaseIsIgnored() {
        var tracker = KeyHoldTracker(tapKey: .percent, holdKey: .set)
        _ = tracker.pressBegan()
        tracker.pressEnded()
        #expect(tracker.holdElapsed() == nil)
    }

    @Test func nextTapAfterAHoldReleasedOutsideIsAPlainTap() {
        var tracker = KeyHoldTracker(tapKey: .percent, holdKey: .set)
        _ = tracker.pressBegan()
        #expect(tracker.holdElapsed() == .set)
        tracker.pressEnded()
        // Released outside the key: no activation.
        _ = tracker.pressBegan()
        tracker.pressEnded()
        #expect(tracker.activated() == .percent)
    }

    @Test func holdDurationIsAboutEightTenthsOfASecond() {
        #expect(KeyHoldTracker.holdDuration == .milliseconds(800))
    }
}
