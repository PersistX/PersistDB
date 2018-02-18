import Foundation
import ReactiveSwift
import Schemata

/// A particular day (i.e. a `Date` without a time)
public struct Day {
    public let daysSinceReferenceDate: Int

    public init(daysSinceReferenceDate: Int) {
        self.daysSinceReferenceDate = daysSinceReferenceDate
    }

    public init(_ date: Date = Date(), timeZone: TimeZone = .current) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let reference = calendar.date(from: DateComponents(
            year: 2001,
            month: 1,
            day: 1
        ))!
        let components = calendar.dateComponents([.day], from: reference, to: date)
        daysSinceReferenceDate = components.day!
    }
}

extension Day {
    /// The start timestamp of `self` in the given timezone.
    internal func start(in timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let reference = calendar.date(from: DateComponents(
            year: 2001,
            month: 1,
            day: 1
        ))!
        return calendar.date(byAdding: .day, value: daysSinceReferenceDate, to: reference)!
    }

    /// The start timestamp of `self` in the current timezone.
    public var start: Date {
        return start()
    }
}

extension Day: Hashable {
    public var hashValue: Int {
        return daysSinceReferenceDate.hashValue
    }

    public static func == (lhs: Day, rhs: Day) -> Bool {
        return lhs.daysSinceReferenceDate == rhs.daysSinceReferenceDate
    }
}

extension Day: Comparable {
    public static func < (lhs: Day, rhs: Day) -> Bool {
        return lhs.daysSinceReferenceDate < rhs.daysSinceReferenceDate
    }
}

extension Day {
    /// A property with the current day that changes when the day changes.
    public static let current = ReactiveSwift.Property<Day>(
        initial: Day(),
        then: NotificationCenter
            .default
            .reactive
            .notifications(forName: .NSCalendarDayChanged)
            .map { _ in Day() }
    )
}

extension Day: ModelValue {
    public static let value = Int.value.bimap(
        decode: Day.init(daysSinceReferenceDate:),
        encode: { $0.daysSinceReferenceDate }
    )
}

extension Day {
    public static func + (lhs: Day, rhs: Int) -> Day {
        return Day(daysSinceReferenceDate: lhs.daysSinceReferenceDate + rhs)
    }
}
