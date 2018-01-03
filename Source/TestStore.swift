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
        let idValue = SQL.Expression.value(Model.ID.anyValue.encode(id).sql)
        let id = Assignment(keyPath: Model.idKeyPath, sql: idValue)
        var values = valueSet
        values.assignments.insert(id, at: 0)
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
    
    private init(for types: [Schemata.AnyModel.Type]) {
        store = Store(for: types.map { $0.testSchema })
    }
    
    public convenience init<A>(
        _ a: [A.ID: ValueSet<A>]
    ) {
        self.init(for: [A.self])
        let aRows = a.map(Insert.init)
        aRows.forEach(store.insert)
    }
    
    /// Synchronously fetch the results of the query.
    public func fetch<Model>(
        _ query: Query<Model>
    ) -> [Model.ID] {
        return store
            .fetch(query)
            .map { (id: ID<Model>) in id.id }
            .collect()
            .first()!
            .value!
    }
}

