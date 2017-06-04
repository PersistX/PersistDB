import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: RecordModel> {
    fileprivate let eval: (Model) -> Bool
    
    fileprivate init(evaluate: @escaping (Model) -> Bool) {
        self.eval = evaluate
    }
}

extension Predicate: Hashable {
    public var hashValue: Int {
        return 0
    }
    
    public static func ==(lhs: Predicate, rhs: Predicate) -> Bool {
        return true
    }
}

extension Predicate {
    /// Test whether the predicate evaluates to true for the given model.
    public func evaluate(_ model: Model) -> Bool {
        return eval(model)
    }
}

/// Test whether a property of the model matches a value.
public func ==<Model, Value: RecordValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    let evaluate: (Model) -> Bool = { $0[keyPath: lhs] == rhs }
    return Predicate<Model>(evaluate: evaluate)
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        fatalError()
    }
}
