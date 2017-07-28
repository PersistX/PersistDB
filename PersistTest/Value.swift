import PersistDB
import Schemata

extension TestDB {
    public struct Value {
        internal let keyPath: AnyKeyPath
        internal let value: Primitive
        
        internal init<Model: PersistDB.Model, Value: ModelValue>(
            keyPath: KeyPath<Model, Value>,
            value: Value
        ) {
            self.keyPath = keyPath
            self.value = Value.anyValue.encode(value)
        }
    }
}

public func ==<Model: PersistDB.Model, Value: ModelValue>(
    keyPath: KeyPath<Model, Value>,
    value: Value
) -> TestDB.Value {
    return TestDB.Value(keyPath: keyPath, value: value)
}

