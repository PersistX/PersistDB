import Foundation
import ReactiveSwift
import Schemata

private struct ID<A: PersistDB.Model>: ModelProjection, Hashable {
    typealias Model = A

    let id: Model.ID

    static var projection: Projection<Model, ID<Model>> {
        return Projection<Model, ID<Model>>(ID.init, Model.idKeyPath)
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
        let values = valueSet.update(with: [ Model.idKeyPath == Expression(idValue) ])
        self.init(unvalidated: values)
    }
}

extension Result {
    fileprivate var value: Success? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
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
    let store: Store<ReadWrite>

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
        _ query: Query<None, Model>
    ) -> [Model.ID] {
        return store
            .fetch(query)
            .map { $0.map { (id: ID<Model>) in id.id } }
            .awaitFirst()!
            .value!
    }

    /// Synchronously fetch the results of the query.
    public func fetch<Projection: ModelProjection>(
        _ query: Query<None, Projection.Model>
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

    /// Delete a model entity.
    public func delete<Model>(
        _ delete: Delete<Model>
    ) {
        _ = store
            .delete(delete)
            .await()
    }

    /// Update properties for a model entity.
    public func update<Model>(
        _ update: Update<Model>
    ) {
        _ = store
            .update(update)
            .await()
    }
}
