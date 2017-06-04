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
    func fetch<P: RecordProjection>(
        _ query: Query<P.Model>
    ) -> Result<P, NoError> {
        fatalError()
    }
}
