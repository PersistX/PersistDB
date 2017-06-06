import Foundation
import Radicle
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: RecordModel> {
    /// Test whether the predicate evaluates to true for the given model.
    public let evaluate: (Model) -> Bool
    
    public let sqlExpression: Radicle.Expression<Bool>
    
    fileprivate init(
        evaluate: @escaping (Model) -> Bool,
        sqlExpression: Radicle.Expression<Bool>
    ) {
        self.evaluate = evaluate
        self.sqlExpression = sqlExpression
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

/// Test whether a property of the model matches a value.
public func ==<Model>(lhs: KeyPath<Model, String>, rhs: String) -> Predicate<Model> {
    let properties = Model.record.properties(for: lhs)
    let column = properties[0].path
    return Predicate<Model>(
        evaluate: { $0[keyPath: lhs] == rhs },
        sqlExpression: Table(String(describing: Model.self)).column(column) == rhs
    )
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
