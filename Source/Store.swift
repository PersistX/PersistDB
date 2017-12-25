import Foundation
import ReactiveSwift
import Result
import Schemata

public final class Store {
    fileprivate let db: Database
    fileprivate let actions = Signal<SQL.Action, NoError>.pipe()
    
    private init(_ db: Database, for schemas: [AnySchema]) {
        self.db = db
        
        for schema in schemas {
            db.create(schema.sql)
        }
        
        actions.output.observeValues(db.perform)
    }
    
    public convenience init(for schemas: [AnySchema]) {
        self.init(Database(), for: schemas)
    }
    
    public convenience init(for types: [Schemata.AnyModel.Type]) {
        self.init(Database(), for: types.map { $0.anySchema })
    }
}

extension Store {
    public func insert<Model>(_ insert: Insert<Model>) {
        actions.input.send(value: .insert(insert.sql))
    }
    
    public func delete<Model>(_ delete: Delete<Model>) {
        actions.input.send(value: .delete(delete.sql))
    }
    
    public func update<Model>(_ update: Update<Model>) {
        actions.input.send(value: .update(update.sql))
    }
}

extension Store {
    public func fetch<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<Projection, NoError> {
        let projection = Projection.projection
        let keyPaths = Dictionary(uniqueKeysWithValues: projection.keyPaths.map { keyPath in
            (UUID().uuidString, keyPath)
        })
        let aliases = Dictionary(uniqueKeysWithValues: keyPaths.map { ($1, $0) })
        let results = projection.keyPaths.map { keyPath in
            return SQL.Result(keyPath.sql, alias: aliases[keyPath])
        }
        let sql = query.sql
        return SignalProducer { [db = self.db] observer, _ in
            let values = db
                .query(SQL.Query(results: results, predicates: sql.predicates, order: sql.order))
                .map { row -> [PartialKeyPath<Projection.Model>: SQL.Value] in
                    return Dictionary(uniqueKeysWithValues: row.dictionary.map { alias, value in
                        let keyPath = keyPaths[alias]! as PartialKeyPath<Projection.Model>
                        return (keyPath, value)
                    })
                }
                .flatMap(Projection.projection.makeValue)
            values.forEach(observer.send(value:))
            observer.sendCompleted()
        }
    }
    
    public func observe<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<[Projection], NoError> {
        let invalidated = actions.output
            .map { _ in () }
        return fetch(query)
            .collect()
            .concat(.never)
            .take(until: invalidated)
            .repeat(.max)
            .skipRepeats { $0 == $1 }
    }
}
