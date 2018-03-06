import Foundation
import Schemata

/// A logical condition used for filtering.
public typealias Predicate<Model> = Expression<Model, Bool>

/// Test that a property of the model matches a value.
public func == <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) == AnyExpression(rhs))
}

/// Test that a property of the model matches an optional value.
public func == <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) == AnyExpression(rhs))
}

/// Test that an expression matches a value.
public func == <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression == AnyExpression(rhs))
}

/// Test that an expression matches an optional value.
public func == <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression == AnyExpression(rhs))
}

/// Test that a property of the model doesn't match a value.
public func != <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) != AnyExpression(rhs))
}

/// Test that a property of the model doesn't match an optional value.
public func != <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) != AnyExpression(rhs))
}

/// Test that an expression doesn't matc a value.
public func != <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression != AnyExpression(rhs))
}

/// Test that an expression doesn't match an optional value.
public func != <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression != AnyExpression(rhs))
}

/// Test that a property of the model is less than a value.
public func < <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) < AnyExpression(rhs))
}

/// Test that a property of the model is less than an optional value.
public func < <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) < AnyExpression(rhs))
}

/// Test that an expression is less than a value.
public func < <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression < AnyExpression(rhs))
}

/// Test that an expression is less than an optional value.
public func < <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression < AnyExpression(rhs))
}

/// Test that a property of the model is greater than a value.
public func > <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) > AnyExpression(rhs))
}

/// Test that a property of the model is greater than an optional value.
public func > <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) > AnyExpression(rhs))
}

/// Test that an expression is greater than a value.
public func > <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression > AnyExpression(rhs))
}

/// Test that an expression is greater than an optional value.
public func > <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression > AnyExpression(rhs))
}

/// Test that a property of the model is less than or equal to a value.
public func <= <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) <= AnyExpression(rhs))
}

/// Test that a property of the model is less than or equal to an optional value.
public func <= <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) <= AnyExpression(rhs))
}

/// Test that an expression is less than or equal to a value.
public func <= <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression <= AnyExpression(rhs))
}

/// Test that an expression is less than or equal to an optional value.
public func <= <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression <= AnyExpression(rhs))
}

/// Test that a property of the model is greater than or equal to a value.
public func >= <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) >= AnyExpression(rhs))
}

/// Test that a property of the model is greater than or equal to an optional value.
public func >= <Model: PersistDB.Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(AnyExpression(lhs) >= AnyExpression(rhs))
}

/// Test that an expression is greater than or equal to a value.
public func >= <Model, Value: ModelValue>(
    lhs: Expression<Model, Value>,
    rhs: Value
) -> Predicate<Model> {
    return Predicate(lhs.expression >= AnyExpression(rhs))
}

/// Test that an expression is greater than or equal to an optional value.
public func >= <Model, Value: ModelValue>(
    lhs: Expression<Model, Value?>,
    rhs: Value?
) -> Predicate<Model> {
    return Predicate(lhs.expression >= AnyExpression(rhs))
}

/// Creates a predicate that's true when both predicates are true.
public func && <M>(lhs: Predicate<M>, rhs: Predicate<M>) -> Predicate<M> {
    return Predicate(lhs.expression && rhs.expression)
}

/// Creates a predicate that's true when either predicates is true.
public func || <M>(lhs: Predicate<M>, rhs: Predicate<M>) -> Predicate<M> {
    return Predicate(lhs.expression || rhs.expression)
}

/// Creates a predicate that's true when the given predicate is false.
public prefix func ! <M>(predicate: Predicate<M>) -> Predicate<M> {
    return Predicate(!predicate.expression)
}

extension Collection where Iterator.Element: ModelValue {
    /// A predicate that tests whether the list contains the value of the given expression.
    public func contains<Model>(
        _ expression: Expression<Model, Iterator.Element>
    ) -> Predicate<Model> {
        return Predicate(.inList(expression.expression, Set(map(AnyExpression.init))))
    }

    /// A predicate that tests whether the list contains the value of the given keypath.
    public func contains<Model: PersistDB.Model>(
        _ keyPath: KeyPath<Model, Iterator.Element>
    ) -> Predicate<Model> {
        return Predicate(.inList(AnyExpression(keyPath), Set(map(AnyExpression.init))))
    }
}
