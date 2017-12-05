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

extension SQL.Value {
    internal func primitive(_ type: AnyValue.Encoded) -> Primitive {
        switch (self, type) {
        case let (.real(timeInterval), .date):
            return .date(Date(timeIntervalSinceReferenceDate: timeInterval))
        case let (.real(double), .double):
            return .double(double)
        case let (.integer(integer), .int):
            return .int(integer)
        case (.null, _):
            return .null
        case let (.text(string), .string):
            return .string(string)
        default:
            return .null
        }
    }
}

