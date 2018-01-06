import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: PersistDB.Model> {
    internal let expression: AnyExpression
    
    fileprivate init(_ expression: AnyExpression) {
        self.expression = expression
    }
}

extension Predicate: Hashable {
    public var hashValue: Int {
        return expression.hashValue
    }
    
    public static func == (lhs: Predicate, rhs: Predicate) -> Bool {
        return lhs.expression == rhs.expression
    }
}

/// Test that a property of the model matches a value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) == AnyExpression(rhs))
}

/// Test that a property of the model matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) == AnyExpression(rhs))
}

/// Test that an expression matches a value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression == AnyExpression(rhs))
}

/// Test that an expression matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression == AnyExpression(rhs))
}

/// Test that a property of the model doesn't match a value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) != AnyExpression(rhs))
}

/// Test that a property of the model doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) != AnyExpression(rhs))
}

/// Test that an expression doesn't matc a value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression != AnyExpression(rhs))
}

/// Test that an expression doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression != AnyExpression(rhs))
}

/// Test that a property of the model is less than a value.
public func < <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) < AnyExpression(rhs))
}

/// Test that a property of the model is less than an optional value.
public func < <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) < AnyExpression(rhs))
}

/// Test that an expression is less than a value.
public func < <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression < AnyExpression(rhs))
}

/// Test that an expression is less than an optional value.
public func < <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression < AnyExpression(rhs))
}

/// Test that a property of the model is greater than a value.
public func > <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) > AnyExpression(rhs))
}

/// Test that a property of the model is greater than an optional value.
public func > <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) > AnyExpression(rhs))
}

/// Test that an expression is greater than a value.
public func > <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression > AnyExpression(rhs))
}

/// Test that an expression is greater than an optional value.
public func > <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression > AnyExpression(rhs))
}

/// Test that a property of the model is less than or equal to a value.
public func <= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) <= AnyExpression(rhs))
}

/// Test that a property of the model is less than or equal to an optional value.
public func <= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) <= AnyExpression(rhs))
}

/// Test that an expression is less than or equal to a value.
public func <= <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression <= AnyExpression(rhs))
}

/// Test that an expression is less than or equal to an optional value.
public func <= <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression <= AnyExpression(rhs))
}

/// Test that a property of the model is greater than or equal to a value.
public func >= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) >= AnyExpression(rhs))
}

/// Test that a property of the model is greater than or equal to an optional value.
public func >= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) >= AnyExpression(rhs))
}

/// Test that an expression is greater than or equal to a value.
public func >= <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.expression >= AnyExpression(rhs))
}

/// Test that an expression is greater than or equal to an optional value.
public func >= <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.expression >= AnyExpression(rhs))
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.expression && rhs.expression)
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.expression || rhs.expression)
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        return Predicate(!predicate.expression)
    }
}
