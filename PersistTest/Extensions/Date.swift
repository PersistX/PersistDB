import Foundation

extension TimeZone {
    static let utc = TimeZone(abbreviation: "UTC")!
}

extension Date {
    public static func today(h: Int = 12, m: Int = 0, s: Int = 0) -> Date {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: .utc,
            year: 2014,
            month: 6,
            day: 2,
            hour: h,
            minute: m,
            second: s
        )
        return components.date!
    }
    
    public static func yesterday(h: Int = 12, m: Int = 0, s: Int = 0) -> Date {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: .utc,
            year: 2014,
            month: 6,
            day: 1,
            hour: h,
            minute: m,
            second: s
        )
        return components.date!
    }
    
    public static func tomorrow(h: Int = 12, m: Int = 0, s: Int = 0) -> Date {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: .utc,
            year: 2014,
            month: 6,
            day: 3,
            hour: h,
            minute: m,
            second: s
        )
        return components.date!
    }
}
