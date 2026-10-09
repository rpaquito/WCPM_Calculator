import Testing
import Foundation
@testable import WCPMCalculator

struct WCPMTests {
    @Test func computesWordsCorrectPerMinute() {
        // 100 words, 5 wrong, 90s -> 95 / 1.5
        #expect(abs(WCPM.compute(wordCount: 100, wrongWords: 5, duration: 90) - 63.3333) < 0.001)
    }

    @Test func zeroDurationGivesZero() {
        #expect(WCPM.compute(wordCount: 100, wrongWords: 0, duration: 0) == 0)
    }

    @Test func wrongWordsNeverMakeNegative() {
        #expect(WCPM.compute(wordCount: 10, wrongWords: 20, duration: 60) == 0)
    }

    @Test func validation() {
        #expect(WCPM.isValid(wordCount: 50, wrongWords: 50, duration: 1))
        #expect(!WCPM.isValid(wordCount: 50, wrongWords: 51, duration: 1))
        #expect(!WCPM.isValid(wordCount: 50, wrongWords: -1, duration: 1))
        #expect(!WCPM.isValid(wordCount: 0, wrongWords: 0, duration: 1))
        #expect(!WCPM.isValid(wordCount: 50, wrongWords: 0, duration: 0))
    }

    @Test func resultStoresComputedWCPM() {
        let r = TestResult(duration: 60, wordCount: 80, wrongWords: 10)
        #expect(r.wcpm == 70)
    }
}
