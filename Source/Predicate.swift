import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: RecordModel> {

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
        return false
    }
}

extension Predicate {
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    public static prefix func !(predicate: Predicate) -> Predicate {
        fatalError()
    }
}
