import Foundation

public enum ReviewScheduler {
    public static let intervals = [1, 3, 7, 14, 30]

    public static func nextStep(current: Int, correct: Bool) -> Int {
        guard correct else { return 0 }
        return min(max(0, current) + 1, intervals.count - 1)
    }

    public static func nextDue(step: Int, from date: Date = Date(), calendar: Calendar = .current) -> Date {
        let index = min(max(0, step), intervals.count - 1)
        return calendar.date(byAdding: .day, value: intervals[index], to: date) ?? date
    }

    public static func isDue(_ date: Date?, now: Date = Date()) -> Bool {
        guard let date else { return false }
        return date <= now
    }
}
