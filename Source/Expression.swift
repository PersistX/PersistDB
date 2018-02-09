import Foundation
import ReactiveSwift
import Schemata

/// A type-erased expression.
///
/// This represents the expressions representable in PersistDB. As such, this is a less general, but
/// more semantically meaningful, representation than `SQL.Expression`.
///
/// `AnyExpression`s can also generate new values, e.g. UUIDs, which are expressed as values in SQL.
/// These values are expressed as values within `AnyExpression`, but the act of generating the
/// corresponding `SQL.Expression` causes it to generate any such values.
internal indirect enum AnyExpression {
    internal enum UnaryOperator: String {
        case not
    }

    internal enum BinaryOperator: String {
        case and
        case equal
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
        case notEqual
        case or
    }

    internal enum Function {
        case coalesce
        case max
        case min
    }

    case binary(BinaryOperator, AnyExpression, AnyExpression)
    case function(Function, [AnyExpression])
    case inList(AnyExpression, Set<AnyExpression>)
    case keyPath([AnyProperty])
    case now
    case unary(UnaryOperator, AnyExpression)
    case value(SQL.Value)
}

extension AnyExpression.UnaryOperator: Hashable {
    var hashValue: Int {
        switch self {
        case .not:
            return 0
        }
    }

    static func == (lhs: AnyExpression.UnaryOperator, rhs: AnyExpression.UnaryOperator) -> Bool {
        switch (lhs, rhs) {
        case (.not, .not):
            return true
        }
    }
}

extension AnyExpression.UnaryOperator {
    var sql: SQL.UnaryOperator {
        switch self {
        case .not:
            return .not
        }
    }
}

extension AnyExpression.BinaryOperator: Hashable {
    var hashValue: Int {
        switch self {
        case .and:
            return 0
        case .equal:
            return 1
        case .greaterThan:
            return 2
        case .greaterThanOrEqual:
            return 3
        case .lessThan:
            return 4
        case .lessThanOrEqual:
            return 5
        case .notEqual:
            return 6
        case .or:
            return 7
        }
    }

    static func == (lhs: AnyExpression.BinaryOperator, rhs: AnyExpression.BinaryOperator) -> Bool {
        switch (lhs, rhs) {
        case (.and, .and),
             (.equal, .equal),
             (.greaterThan, .greaterThan),
             (.greaterThanOrEqual, .greaterThanOrEqual),
             (.lessThan, .lessThan),
             (.lessThanOrEqual, .lessThanOrEqual),
             (.notEqual, .notEqual),
             (.or, .or):
            return true
        default:
            return false
        }
    }
}

extension AnyExpression.BinaryOperator {
    var sql: SQL.BinaryOperator {
        switch self {
        case .and:
            return .and
        case .equal:
            return .equal
        case .greaterThan:
            return .greaterThan
        case .greaterThanOrEqual:
            return .greaterThanOrEqual
        case .lessThan:
            return .lessThan
        case .lessThanOrEqual:
            return .lessThanOrEqual
        case .notEqual:
            return .notEqual
        case .or:
            return .or
        }
    }
}

extension AnyExpression.Function: Hashable {
    var hashValue: Int {
        switch self {
        case .coalesce:
            return 1
        case .max:
            return 2
        case .min:
            return 3
        }
    }

    static func == (lhs: AnyExpression.Function, rhs: AnyExpression.Function) -> Bool {
        switch (lhs, rhs) {
        case (.coalesce, .coalesce),
             (.max, .max),
             (.min, .min):
            return true
        default:
            return false
        }
    }
}

extension AnyExpression {
    init<Model: PersistDB.Model>(_ keyPath: PartialKeyPath<Model>) {
        self = .keyPath(Model.anySchema.properties(for: keyPath))
    }

    init<V: ModelValue>(_ value: V) {
        self = .value(V.anyValue.encode(value).sql)
    }

    init<V: ModelValue>(_ value: V?) {
        self = .value(value.map(V.anyValue.encode)?.sql ?? .null)
    }
}

extension AnyExpression.Function {
    fileprivate var sql: SQL.Function {
        switch self {
        case .coalesce:
            return .coalesce
        case .max:
            return .max
        case .min:
            return .min
        }
    }
}

extension AnyExpression: Hashable {
    var hashValue: Int {
        switch self {
        case let .binary(op, lhs, rhs):
            return op.hashValue ^ lhs.hashValue ^ rhs.hashValue
        case let .function(function, expression):
            return function.hashValue ^ expression.map { $0.hashValue }.reduce(0, ^)
        case let .inList(expr, list):
            return expr.hashValue ^ list.map { $0.hashValue }.reduce(0, ^)
        case let .keyPath(properties):
            return properties.map { $0.hashValue }.reduce(0, ^)
        case .now:
            return 0
        case let .value(value):
            return value.hashValue
        case let .unary(op, expr):
            return op.hashValue ^ expr.hashValue
        }
    }

    static func == (lhs: AnyExpression, rhs: AnyExpression) -> Bool {
        switch (lhs, rhs) {
        case let (.binary(lhs), .binary(rhs)):
            return lhs == rhs
        case let (.function(lhsFunc, lhsArgs), .function(rhsFunc, rhsArgs)):
            return lhsFunc == rhsFunc && lhsArgs == rhsArgs
        case let (.inList(lhsExpr, lhsList), .inList(rhsExpr, rhsList)):
            return lhsExpr == rhsExpr && lhsList == rhsList
        case let (.keyPath(lhs), .keyPath(rhs)):
            return lhs == rhs
        case (.now, .now):
            return true
        case let (.unary(lhs), .unary(rhs)):
            return lhs == rhs
        case let (.value(lhs), .value(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension SQL {
    fileprivate static var now: SQL.Expression {
        let seconds = SQL.Expression.function(.strftime, [
            .value(.text("%s")),
            .value(.text("now")),
        ])
        let subseconds = SQL.Expression.function(.substr, [
            .function(.strftime, [
                .value(.text("%f")),
                .value(.text("now")),
            ]),
            .value(.integer(4)),
        ])
        return .cast(
            .binary(
                .concatenate,
                .binary(
                    .subtract,
                    seconds,
                    .value(.integer(Int(Date.timeIntervalBetween1970AndReferenceDate)))
                ),
                .binary(
                    .concatenate,
                    .value(.text(".")),
                    subseconds
                )
            ),
            .real
        )
    }
}

private func sql(for properties: [AnyProperty]) -> SQL.Expression {
    func column(for property: AnyProperty) -> SQL.Column {
        return SQL.Table(String(describing: property.model))[property.path]
    }

    var value: SQL.Expression = .column(column(for: properties.last!))
    for property in properties.reversed().dropFirst() {
        switch property.type {
        case .toMany:
            fatalError("Can't traverse to-many properties")
        case let .toOne(model, _):
            let rhs = SQL.Column(
                table: SQL.Table(String(describing: model)),
                name: "id"
            )
            value = .join(column(for: property), rhs, value)
        case .value:
            fatalError("Invalid scalar property in the middle of a KeyPath")
        }
    }
    return value
}

extension AnyExpression {
    func makeSQL() -> SQL.Expression {
        switch self {
        case let .binary(.equal, .value(.null), rhs):
            return .binary(.is, rhs.makeSQL(), .value(.null))
        case let .binary(.equal, lhs, .value(.null)):
            return .binary(.is, lhs.makeSQL(), .value(.null))
        case let .binary(.notEqual, .value(.null), rhs):
            return .binary(.isNot, rhs.makeSQL(), .value(.null))
        case let .binary(.notEqual, lhs, .value(.null)):
            return .binary(.isNot, lhs.makeSQL(), .value(.null))
        case let .binary(op, lhs, rhs):
            return .binary(op.sql, lhs.makeSQL(), rhs.makeSQL())
        case let .function(function, args):
            return .function(function.sql, args.map { $0.makeSQL() })
        case let .inList(expr, list):
            return .inList(expr.makeSQL(), Set(list.map { $0.makeSQL() }))
        case let .keyPath(properties):
            return sql(for: properties)
        case .now:
            return SQL.now
        case let .unary(op, expr):
            return .unary(op.sql, expr.makeSQL())
        case let .value(value):
            return .value(value)
        }
    }
}

/// An expression that can be used in `Predicate`s, `Ordering`s, etc.
public struct Expression<Model: PersistDB.Model, Value> {
    internal let expression: AnyExpression

    internal init(_ expression: AnyExpression) {
        self.expression = expression
    }
}

extension Expression: Hashable {
    public var hashValue: Int {
        return expression.hashValue
    }

    public static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.expression == rhs.expression
    }
}

extension Expression where Value == Date {
    /// An expression that evaluates to the current datetime.
    public static var now: Expression {
        return Expression(.now)
    }
}

extension Expression where Value: ModelValue {
    public init(_ value: Value) {
        expression = .value(Value.anyValue.encode(value).sql)
    }
}

extension Expression where Value: OptionalProtocol, Value.Wrapped: ModelValue {
    public init(_ value: Value?) {
        expression = .value(value.map(Value.Wrapped.anyValue.encode)?.sql ?? .null)
    }
}

// MARK: - Operators

internal func == (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.equal, lhs, rhs)
}

internal func != (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.notEqual, lhs, rhs)
}

internal func && (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.and, lhs, rhs)
}

internal func || (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.or, lhs, rhs)
}

internal prefix func ! (expression: AnyExpression) -> AnyExpression {
    return .unary(.not, expression)
}

internal func < (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.lessThan, lhs, rhs)
}

internal func > (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.greaterThan, lhs, rhs)
}

internal func <= (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.lessThanOrEqual, lhs, rhs)
}

internal func >= (lhs: AnyExpression, rhs: AnyExpression) -> AnyExpression {
    return .binary(.greaterThanOrEqual, lhs, rhs)
}

// MARK: - Aggregates

internal func max(_ expressions: [AnyExpression]) -> AnyExpression {
    return .function(.max, expressions)
}

internal func max(_ expressions: AnyExpression...) -> AnyExpression {
    return max(expressions)
}

internal func min(_ expressions: [AnyExpression]) -> AnyExpression {
    return .function(.min, expressions)
}

internal func min(_ expressions: AnyExpression...) -> AnyExpression {
    return min(expressions)
}

// MARK: - Collections

extension Collection where Iterator.Element: ModelValue {
    /// An expression that tests whether the list contains the value of an
    /// expression.
    internal func contains(_ expression: AnyExpression) -> AnyExpression {
        return .inList(expression, Set(map(AnyExpression.init)))
    }
}

// MARK: - Functions

/// Evaluates to the first non-NULL argument, or NULL if all argumnets are NULL.
public func coalesce<Model: PersistDB.Model, Value>(
    _ a: KeyPath<Model, Value?>,
    _ b: KeyPath<Model, Value?>,
    _ rest: KeyPath<Model, Value?>...
) -> Expression<Model, Value?> {
    let args = ([a, b] + rest)
        .map(Model.anySchema.properties(for:))
        .map(AnyExpression.keyPath)
    return Expression(.function(.coalesce, args))
}
