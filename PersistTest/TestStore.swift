import PersistDB
import Schemata

public final class TestStore {
    internal struct ID {
        let type: Any.Type
        let id: Primitive
    }
    
    internal let data: [ID: [AnyValue]]
    
    public init(_ rows: Row...) {
        data = Dictionary(uniqueKeysWithValues: rows.map { (ID(type: $0.type, id: $0.id), $0.values) })
    }
}

extension TestStore.ID: Hashable {
    var hashValue: Int {
        return ObjectIdentifier(type).hashValue ^ id.hashValue
    }
    
    static func ==(lhs: TestStore.ID, rhs: TestStore.ID) -> Bool {
        return lhs.type == rhs.type && lhs.id == rhs.id
    }
}
