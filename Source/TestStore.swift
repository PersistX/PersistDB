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
            values: row.values.mapValues(SQL.Expression.value)
        )
    }
}

extension SQL.Schema {
    fileprivate init<Model: PersistDB.Model>(_ schema: Schema<Model>) {
        let table = SQL.Table(String(describing: Model.self))
        let columns: [SQL.Schema.Column] = schema
            .properties
            .values
            .flatMap { property in
                guard case let .value(type, _) = property.type else { return nil }
                return SQL.Schema.Column(
                    name: property.path,
                    type: type.anyValue.encoded.sql,
                    nullable: true,
                    unique: false,
                    primaryKey: property.path == "id"
                )
            }
        
        self.init(table: table, columns: Set(columns))
    }
}

public final class TestStore {
    fileprivate struct Row {
        let table: SQL.Table
        let values: [String: SQL.Value]
        
        init<Model>(_ id: Model.ID, _ predicates: [Predicate<Model>]) {
            let idValue = Model.ID.anyValue.encode(id).sql
            let pairs = [("id", idValue)] + predicates.map { predicate -> (String, SQL.Value) in
                guard case let .binary(.equal, .column(column), .value(value)) = predicate.sql else {
                    fatalError("TestStore predicates must be `property == value`")
                }
                
                return (column.name, value)
            }
            table = SQL.Table(String(describing: Model.self))
            values = Dictionary(uniqueKeysWithValues: pairs)
        }
    }
    
    let store: Store
    
    private init(schemas: [SQL.Schema], inserts: [SQL.Insert]) {
        store = Store()
        schemas.forEach(store.db.create)
        inserts.forEach(store.db.insert)
    }
    
    public convenience init<A>(
        _ a: [A.ID: [Predicate<A>]]
    ) {
        let aRows = a.map(Row.init)
        self.init(
            schemas: [SQL.Schema(A.schema)],
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

