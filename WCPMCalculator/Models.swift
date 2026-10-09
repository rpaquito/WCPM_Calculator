import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ReadingTest.profile)
    var tests: [ReadingTest] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class ReadingTest {
    var name: String
    var details: String
    var wordCount: Int
    var profile: Profile?
    @Relationship(deleteRule: .cascade, inverse: \TestResult.test)
    var results: [TestResult] = []

    init(name: String, details: String = "", wordCount: Int, profile: Profile? = nil) {
        self.name = name
        self.details = details
        self.wordCount = wordCount
        self.profile = profile
    }
}

@Model
final class TestResult {
    var date: Date
    var duration: TimeInterval
    var wordCount: Int
    var wrongWords: Int
    var wcpm: Double
    var test: ReadingTest?

    init(date: Date = .now, duration: TimeInterval, wordCount: Int, wrongWords: Int, test: ReadingTest? = nil) {
        self.date = date
        self.duration = duration
        self.wordCount = wordCount
        self.wrongWords = wrongWords
        self.wcpm = WCPM.compute(wordCount: wordCount, wrongWords: wrongWords, duration: duration)
        self.test = test
    }
}

enum WCPM {
    /// Words correct per minute. Returns 0 when duration is not positive.
    static func compute(wordCount: Int, wrongWords: Int, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return Double(max(0, wordCount - wrongWords)) / (duration / 60)
    }

    static func isValid(wordCount: Int, wrongWords: Int, duration: TimeInterval) -> Bool {
        duration > 0 && wordCount >= 1 && (0...wordCount).contains(wrongWords)
    }
}

extension TimeInterval {
    /// `mm:ss`, e.g. 83.4 -> "01:23".
    var clock: String {
        let s = Int(self)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
