import Foundation
import Schemata

extension SQL {
    /// A SQL value to a SQL statement
    internal enum Value: Hashable {
        /// An integer value
        case integer(Int)

        /// A null value
        case null

        /// A floating point value
        case real(Double)

        /// A string value
        case text(String)

        internal var sql: SQL {
            if self == .null {
                return SQL("NULL")
            } else {
                return SQL("?", parameters: self)
            }
        }

        var integer: Int? {
            switch self {
            case let .integer(integer):
                return integer
            default:
                return nil
            }
        }

        var text: String? {
            switch self {
            case let .text(text):
                return text
            default:
                return nil
            }
        }
    }
}

extension SQL.Value: CustomStringConvertible {
    internal var description: String {
        switch self {
        case let .integer(value):
            return value.description
        case .null:
            return "(null)"
        case let .real(value):
            return value.description
        case let .text(value):
            return "'\(value)'"
        }
    }
}

extension SQL.Value: ExpressibleByStringLiteral {
    internal init(stringLiteral value: String) {
        self = .text(value)
    }

    internal init(unicodeScalarLiteral value: String) {
        self = .text(value)
    }

    internal init(extendedGraphemeClusterLiteral value: String) {
        self = .text(value)
    }
}

extension SQL.Value: ExpressibleByIntegerLiteral {
    internal init(integerLiteral value: Int) {
        self = .integer(value)
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
