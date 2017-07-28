import PersistDB
import Schemata

extension TestStore {
    public struct Row {
        internal let type: Any.Type
        internal let id: Primitive
        internal let values: [AnyValue]
    }
}

extension TestStore.Row: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(type).hashValue ^ id.hashValue
    }
    
    public static func == (lhs: TestStore.Row, rhs: TestStore.Row) -> Bool {
        return lhs.type == rhs.type
            && lhs.id == rhs.id
            && lhs.values == rhs.values
    }
}

infix operator -- : AssignmentPrecedence

public func --<M>(lhs: M.ID, values: [TestStore.Value<M>]) -> TestStore.Row {
    return TestStore.Row(
        type: M.self,
        id: M.ID.anyValue.encode(lhs),
        values: values.map(TestStore.AnyValue.init)
    )
}

public func --<M>(lhs: M.ID, value: TestStore.Value<M>) -> TestStore.Row {
    return TestStore.Row(
        type: M.self,
        id: M.ID.anyValue.encode(lhs),
        values: [TestStore.AnyValue(value)]
    )
}

public func --<M: PersistDB.Model>(lhs: M.ID, type: M.Type) -> TestStore.Row {
    return TestStore.Row(
        type: M.self,
        id: M.ID.anyValue.encode(lhs),
        values: []
    )
}

