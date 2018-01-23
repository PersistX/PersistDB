import Foundation
import ReactiveSwift
import Result
import Schemata

private struct ID<A: PersistDB.Model>: ModelProjection {
    typealias Model = A

    let id: Model.ID

    static var projection: Projection<Model, ID<Model>> {
        return Projection<Model, ID<Model>>(ID.init, Model.idKeyPath)
    }

    var hashValue: Int {
        return id.hashValue
    }

    static func == (lhs: ID, rhs: ID) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Schemata.AnyModel {
    /// An adjusted schema for testing where all fields are nullable.
    fileprivate static var testSchema: AnySchema {
        var schema = anySchema
        schema.properties = schema.properties.mapValues { p in
            var result = p
            switch result.type {
            case let .toOne(type, false):
                result.type = .toOne(type, nullable: true)
            case let .value(type, false):
                result.type = .value(type, nullable: true)
            default:
                break
            }
            return result
        }
        return schema
    }
}

extension Insert {
    fileprivate init(_ id: Model.ID, _ valueSet: ValueSet<Model>) {
        let idValue = AnyExpression.value(Model.ID.anyValue.encode(id).sql)
        var values = valueSet
        values.values[Model.idKeyPath] = idValue
        self.init(unvalidated: values)
    }
}

/// A `Store`-like object that's useful for unit tests.
///
/// The primary convenience of `TestStore` is that it provides a shortcut for inserting fixtures.
/// Instead of inserting rows manually, data can be passed to the `init`. All fields are treated as
/// optionals and any unspecified keys will have `nil` values.
///
///     let store = TestStore(
///         [ id1: [ \Author.name == "…" ]]
///     )
///
/// A complete example can be found in PersistDB's own tests.
///
/// - important: This class should **only** be used for testing.
public final class TestStore {
    let store: Store

    /// Create a test store for the given types without inserting any fixtures.
    public init(for types: [Schemata.AnyModel.Type]) {
        store = Store(for: types.map { $0.testSchema })
    }

    public convenience init<A>(
        _ a: [A.ID: ValueSet<A>]
    ) {
        self.init(for: [A.self])
        _ = SignalProducer(a)
            .map(Insert.init)
            .flatMap(.merge, store.insert)
            .await()
    }

    /// Synchronously fetch the results of the query.
    public func fetch<Model>(
        _ query: Query<Model>
    ) -> [Model.ID] {
        return store
            .fetch(query)
            .map { $0.map { (id: ID<Model>) in id.id } }
            .awaitFirst()!
            .value!
    }

    /// Synchronously fetch the results of the query.
    public func fetch<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> [Projection] {
        return store
            .fetch(query)
            .map { $0.map { $0 } }
            .awaitFirst()!
            .value!
    }

    /// Insert a model entity and return a projection from it.
    public func insert<Projection: ModelProjection>(
        _ insert: Insert<Projection.Model>
    ) -> Projection {
        return store
            .insert(insert)
            .awaitFirst()!
            .map { id -> Projection in
                let query = Projection.Model.all
                    .filter(Projection.Model.idKeyPath == id)
                return self.fetch(query)[0]
            }
            .value!
    }
}
