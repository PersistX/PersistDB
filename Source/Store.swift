import Foundation
import ReactiveSwift
import Result
import Schemata

public final class Store {
    init() {
    }
    
    init(at url: URL) {
    }
}

extension Store {
    func fetch<Model, Value>(
        _ query: Query<Model>
    ) -> SignalProducer<Projection<Model, Value>, NoError> {
        fatalError()
    }
}
