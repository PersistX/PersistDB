import Foundation

extension SQL {
    /// The type of data in a column.
    internal enum DataType: String {
        case text = "TEXT"
        case numeric = "NUMERIC"
        case integer = "INTEGER"
        case real = "REAL"
        case blob = "BLOB"
    }
}

extension SQL.DataType {
    internal var sql: SQL {
        return SQL(rawValue)
    }
}

extension String {
    static let PlaceholderRegex = try! NSRegularExpression(
        pattern: "(\\?) | '[^']*' | --[^\\n]* | /\\* (?:(?!\\*/).)* \\*/",
        options: [ .allowCommentsAndWhitespace, .dotMatchesLineSeparators ]
    )
    
    internal var placeholders: IndexSet {
        let range = NSRange(location: 0, length: count)
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

extension SQL {
    internal enum Parameter {
        case value(Value)
    }
}

extension SQL.Parameter: Hashable {
    var hashValue: Int {
        switch self {
        case let .value(value):
            return value.hashValue
        }
    }
    
    static func == (lhs: SQL.Parameter, rhs: SQL.Parameter) -> Bool {
        switch (lhs, rhs) {
        case let (.value(lhs), .value(rhs)):
            return lhs == rhs
        }
    }
}

extension SQL.Parameter: CustomStringConvertible {
    var description: String {
        switch self {
        case let .value(value):
            return value.description
        }
    }
}

/// A SQL statement with placeholders for sanitized values.
public struct SQL {
    /// The SQL statement.
    public private(set) var sql: String
    
    /// The parameters to the SQL statement.
    internal private(set) var parameters: [SQL.Parameter]
    
    internal init(_ sql: String, parameters: [SQL.Parameter]) {
        precondition(sql.placeholders.count == parameters.count)
        self.sql = sql
        self.parameters = parameters
    }
    
    internal init(_ sql: String, parameters: [SQL.Value]) {
        self.init(sql, parameters: parameters.map(Parameter.value))
    }
    
    internal init(_ sql: String, parameters: SQL.Value...) {
        self.init(sql, parameters: parameters)
    }
    
    public init() {
        self.init("")
    }
    
    /// A textual representation of self, suitable for debugging.
    public var debugDescription: String {
        var result = sql
        var offset = 0
        for (index, parameter) in zip(sql.placeholders, parameters) {
            let replacement = parameter.description
            let adjusted = result.index(result.startIndex, offsetBy: index + offset)
            result.replaceSubrange(adjusted...adjusted, with: replacement)
            
            offset += replacement.count - 1
        }
        return String(result)
    }
    
    /// Append the given statement to the statement.
    internal mutating func append(_ sql: String, parameters: [SQL.Parameter]) {
        self.sql += sql
        self.parameters += parameters
    }
    
    /// Append the given statement to the statement.
    internal mutating func append(_ sql: String, parameters: [SQL.Value]) {
        append(sql, parameters: parameters.map(Parameter.value))
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
    internal func appending(_ sql: String, parameters: [SQL.Parameter]) -> SQL {
        return SQL(self.sql + sql, parameters: self.parameters + parameters)
    }
    
    /// Create a new SQL statement by appending a SQL statement
    internal func appending(_ sql: String, parameters: [SQL.Value]) -> SQL {
        return appending(sql, parameters: parameters.map(Parameter.value))
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
