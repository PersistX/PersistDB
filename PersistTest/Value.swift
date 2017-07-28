import PersistDB
import Schemata

extension TestStore {
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

