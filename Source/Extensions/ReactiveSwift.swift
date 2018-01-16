import ReactiveSwift

extension SignalProducer {
    internal func collect<Key: Equatable>(
        groupingBy: @escaping (Value) -> Key
    ) -> SignalProducer<(Key, [Value]), Error> {
        return map { (groupingBy($0), $0) }
            .collect { values, value in
                guard let key = values.first?.0 else { return false }
                return key != value.0
            }
            .filterMap { tuples in
                guard let key = tuples.first?.0 else { return nil }
                return (key, tuples.map { $0.1 })
            }
    }
}
