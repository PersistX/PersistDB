import Foundation
import ReactiveSwift
import Result

extension SignalProducer {
    /// Await the termination of the signal producer.
    ///
    /// - returns: A `Bool` indicated whether the producer completed.
    internal func await(timeout: TimeInterval = 0.1) -> Bool {
        var done = false
        var completed = false

        let started = Date()
        start { event in
            switch event {
            case .value:
                break
            case .completed:
                completed = true
                done = true
            case .interrupted, .failed:
                done = true
            }
        }

        while !done && abs(started.timeIntervalSinceNow) < timeout {
            RunLoop.main.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.01))
        }

        return completed
    }

    /// Await the first value from the signal producer.
    internal func awaitFirst() -> Result<Value, Error>? {
        var result: Result<Value, Error>?

        _ = take(first: 1)
            .map(Result.success)
            .flatMapError { error -> SignalProducer<Result<Value, Error>, NoError> in
                let result = Result<Value, Error>.failure(error)
                return SignalProducer<Result<Value, Error>, NoError>(value: result)
            }
            .on(value: { result = $0 })
            .await()

        return result
    }

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
