import Foundation
import ReactiveSwift
import Result
import Schemata

private struct ID<A: PersistDB.Model>: ModelProjection {
    typealias Model = A
    
    let id: Model.ID
    
    static var projection: Projection<Model, ID<Model>> {
        let id = Model.schema.properties.values.first { $0.path == "id" }!.keyPath as! KeyPath<Model, Model.ID>
        return Projection<Model, ID<Model>>(ID.init, id)
    }
}

extension SQL.Insert {
    fileprivate init(_ row: TestStore.Row) {
        self.init(
            table: row.table,
            values: row.values
        )
    }
}

extension Schemata.AnyModel {
    /// An adjusted schema for testing where all fields are nullable.
    fileprivate static var testSchema: AnySchema {
        var schema = anySchema
        schema.properties = schema.properties.mapValues { p in
            guard case let .value(type, false) = p.type else {
                return p
            }
            var result = p
            result.type = .value(type, nullable: true)
            return result
        }
        return schema
    }
}

public final class TestStore {
    fileprivate struct Row {
        let table: SQL.Table
        let values: [String: SQL.Expression]
        
        init<Model>(_ id: Model.ID, _ valueSet: ValueSet<Model>) {
            let schema = Model.schema
            let idValue = SQL.Expression.value(Model.ID.anyValue.encode(id).sql)
            let pairs = [("id", idValue)] + valueSet.assignments.map { assignment -> (String, SQL.Expression) in
                let column = schema.properties(for: assignment.keyPath).last!.path
                return (column, assignment.sql)
            }
            table = SQL.Table(String(describing: Model.self))
            values = Dictionary(uniqueKeysWithValues: pairs)
        }
    }
    
    let store: Store
    
    private init(
        types: [Schemata.AnyModel.Type],
        inserts: [SQL.Insert]
    ) {
        store = Store(for: types.map { $0.testSchema })
        inserts.forEach(store.db.insert)
    }
    
    public convenience init<A>(
        _ a: [A.ID: ValueSet<A>]
    ) {
        let aRows = a.map(Row.init)
        self.init(
            types: [A.self],
            inserts: aRows.map(SQL.Insert.init)
        )
    }
    
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

