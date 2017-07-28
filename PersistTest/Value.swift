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

public func ==<Model: PersistDB.Model, Value: ModelValue>(
    keyPath: KeyPath<Model, Value>,
    value: Value
) -> TestStore.Value<Model> {
    return TestStore.Value(
        keyPath: keyPath,
        value: Value.anyValue.encode(value)
    )
}

