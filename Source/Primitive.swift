import Schemata

extension Primitive {
    internal var sql: SQL.Value {
        switch self {
        case let .date(date):
            return .real(date.timeIntervalSinceReferenceDate)
        case let .double(double):
            return .real(double)
        case let .int(int):
            return .integer(int)
        case .null:
            return .null
        case let .string(string):
            return .text(string)
        }
    }
}
