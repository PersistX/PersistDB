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
            values: row.values.mapValues { .init(.value($0)) }
        )
    }
}

extension SQL.Schema {
    fileprivate init(_ rows: [TestStore.Row]) {
        let table = rows[0].table
        let columns: [SQL.Schema.Column] = rows
            .flatMap { $0.values.keys }
            .map { name in
                return SQL.Schema.Column(
                    name: name,
                    // SQLite doesn't require values to match the column type, so this doesn't matter
                    type: .text,
                    nullable: true,
                    unique: false,
                    primaryKey: name == "id"
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
            schemas: [SQL.Schema(aRows)],
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

