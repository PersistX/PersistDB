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
        _ query: Query<Model>
    ) -> Result<Value, NoError> {
        fatalError()
    }
}
