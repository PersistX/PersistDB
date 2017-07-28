import PersistDB
import Schemata

extension TestStore {
    internal struct AnyValue {
        internal let keyPath: AnyKeyPath
        internal let value: Primitive
        
        internal init<M>(_ value: Value<M>) {
            self.keyPath = value.keyPath
            self.value = value.value
        }
    }
    
    public struct Value<Model: PersistDB.Model> {
        internal let keyPath: PartialKeyPath<Model>
        internal let value: Primitive
    }
}

extension TestStore.AnyValue: Hashable {
    var hashValue: Int {
        return keyPath.hashValue ^ value.hashValue
    }
    
    static func ==(lhs: TestStore.AnyValue, rhs: TestStore.AnyValue) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.value == rhs.value
    }
}

public func ==<Model: PersistDB.Model, Value: ModelValue>(
    keyPath: KeyPath<Model, Value>,
    value: Value
) -> TestStore.Value<Model> {
    return TestStore.Value(
        keyPath: keyPath,
        value: Value.anyValue.encode(value)
    )
}

