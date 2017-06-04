import Foundation
import Result
import Schemata

public final class Store {
    init() {
    }
    
    init(at url: URL) {
    }
}

extension Store {
    func fetch<Model: RecordObject, Value>(
        _ projection: Projection<Model, Value>
    ) -> Result<Value, NoError> {
        fatalError()
    }
}
