import Foundation
import Schemata

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
