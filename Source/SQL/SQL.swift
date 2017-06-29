import Foundation

extension SQL {
    /// A SQL value to a SQL statement
    public enum Value {
        /// A null parameter
        case null
        
        /// An integer parameter
        case integer(Int)
        
        /// A string parameter
        case string(String)
        
        internal var sql: SQL {
            return SQL("?", parameters: self)
        }
    }
}

extension SQL.Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null:
            return "(null)"
        case let .integer(value):
            return value.description
        case let .string(value):
            return "'\(value)'"
        }
    }
}

extension SQL.Value: Hashable {
    public var hashValue: Int {
        switch self {
        case .null:
            return 0
        case let .integer(value):
            return value.hashValue
        case let .string(value):
            return value.hashValue
        }
    }

    public static func ==(lhs: SQL.Value, rhs: SQL.Value) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            return true
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.string(left), .string(right)):
            return left == right
        default:
            return false
        }
    }
}

extension SQL.Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension SQL.Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension SQL.Value: InsertValueConvertible {
    internal var insertValue: SQL.Insert.Value {
        return SQL.Insert.Value(.value(self))
    }
}

extension String {
    static let PlaceholderRegex = try! NSRegularExpression(
        pattern: "(\\?) | '[^']*' | --[^\\n]* | /\\* (?:(?!\\*/).)* \\*/",
        options: [ .allowCommentsAndWhitespace, .dotMatchesLineSeparators ]
    )
    
    internal var placeholders: IndexSet {
        let range = NSRange(location: 0, length: self.characters.count)
        let matches = String.PlaceholderRegex.matches(in: self, range: range)
        var result = IndexSet()
        for match in matches {
            let location = match.range(at: 1).location
            if location != NSNotFound {
                result.insert(location)
            }
        }
        return result
    }
}

/// A SQL statement with placeholders for sanitized values.
public struct SQL {
    /// The SQL statement.
    public private(set) var sql: String
    
    /// The parameters to the SQL statement.
    public private(set) var parameters: [SQL.Value]
    
    public init(_ sql: String, parameters: [SQL.Value]) {
        precondition(sql.placeholders.count == parameters.count)
        self.sql = sql
        self.parameters = parameters
    }
    
    public init(_ sql: String, parameters: SQL.Value...) {
        self.init(sql, parameters: parameters)
    }
    
    public init() {
        self.init("")
    }
    
    /// A textual representation of self, suitable for debugging.
    public var debugDescription: String {
        var result = sql.characters
        var offset = 0
        for (index, parameter) in zip(sql.placeholders, parameters) {
            let replacement = parameter.description.characters
            let adjusted = result.index(result.startIndex, offsetBy: index + offset)
            result.replaceSubrange(adjusted...adjusted, with: replacement)
            
            offset += replacement.count - 1
        }
        return String(result)
    }
    
    /// Append the given statement to the statement.
    internal mutating func append(_ sql: String, parameters: [SQL.Value]) {
        self.sql += sql
        self.parameters += parameters
    }
    
    /// Append the given statement to the statement.
    internal mutating func append(_ sql: String, parameters: SQL.Value...) {
        append(sql, parameters: parameters)
    }
    
    /// Append the given statement to the statement.
    internal mutating func append(_ sql: SQL) {
        append(sql.sql, parameters: sql.parameters)
    }
    
    /// Create a new SQL statement by appending a SQL statement
    internal func appending(_ sql: String, parameters: [SQL.Value]) -> SQL {
        return SQL(self.sql + sql, parameters: self.parameters + parameters)
    }
    
    /// Create a new SQL statement by appending a SQL statement
    internal func appending(_ sql: String, parameters: SQL.Value...) -> SQL {
        return appending(sql, parameters: parameters)
    }
    
    /// Create a new SQL statement by appending a SQL statement
    internal func appending(_ sql: SQL) -> SQL {
        return appending(sql.sql, parameters: sql.parameters)
    }
    
    /// Returns a version of the statement that's surrounded by paretheses.
    internal var parenthesized: SQL {
        return "(" + self + ")"
    }
}

/// Create a new SQL statement by appending a SQL statement
internal func +(lhs: SQL, rhs: SQL) -> SQL {
    return lhs.appending(rhs)
}

/// Create a new SQL statement by appending a SQL statement
internal func +(lhs: SQL, rhs: String) -> SQL {
    return lhs.appending(rhs)
}

/// Create a new SQL statement by appending a SQL statement
internal func +(lhs: String, rhs: SQL) -> SQL {
    return SQL(lhs).appending(rhs)
}

internal func +=(lhs: inout SQL, rhs: SQL) {
    lhs.append(rhs)
}

internal func +=(lhs: inout SQL, rhs: String) {
    lhs.append(rhs)
}

extension SQL: Hashable {
    public var hashValue: Int {
        return parameters.reduce(sql.hashValue) { $0 ^ $1.hashValue }
    }

    public static func ==(lhs: SQL, rhs: SQL) -> Bool {
        return lhs.sql == rhs.sql && lhs.parameters == rhs.parameters
    }
}

extension Sequence where Iterator.Element == SQL {
    internal func joined(separator: String) -> SQL {
        var result: SQL? = nil
        for sql in self {
            if let accumulated = result {
                result = accumulated + separator + sql
            } else {
                result = sql
            }
        }
        return result ?? SQL()
    }
}
