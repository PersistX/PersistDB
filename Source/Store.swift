import Foundation
import ReactiveSwift
import Result
import Schemata

public enum OpenError: Error {
    case incompatibleSchema
    case unknown(AnyError)
}

public final class Store {
    fileprivate let db: Database
    fileprivate let actions = Signal<SQL.Action, NoError>.pipe()
    
    private init(_ db: Database, for schemas: [AnySchema]) throws {
        self.db = db
        
        let existing = Dictionary(uniqueKeysWithValues: db
            .schema()
            .map { ($0.table, $0) }
        )
        for schema in schemas {
            let sql = schema.sql
            if let existing = existing[sql.table] {
                if existing != sql {
                    throw OpenError.incompatibleSchema
                }
            } else {
                db.create(sql)
            }
        }
        
        actions.output.observeValues(db.perform)
    }
    
    public convenience init(for schemas: [AnySchema]) {
        try! self.init(Database(), for: schemas)
    }
    
    public convenience init(for types: [Schemata.AnyModel.Type]) {
        self.init(for: types.map { $0.anySchema })
    }
    
    public static func open(
        at url: URL,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return SignalProducer<Store, OpenError> { observer, _ in
            do {
                let db = try Database(at: url)
                let store = try Store(db, for: schemas)
                observer.send(value: store)
                observer.sendCompleted()
            } catch let error as OpenError {
                observer.send(error: error)
            } catch let error {
                observer.send(error: OpenError.unknown(AnyError(error)))
            }
        }
    }
    
    public static func open(
        at url: URL,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return open(at: url, for: types.map { $0.anySchema })
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
    private func fetch<Projection>(
        _ projected: ProjectedQuery<Projection>
    ) -> SignalProducer<Projection, NoError> {
        return SignalProducer { [db = self.db] observer, _ in
            let values = db
                .query(projected.sql)
                .map(projected.values(for:))
                .flatMap(Projection.projection.makeValue)
            values.forEach(observer.send(value:))
            observer.sendCompleted()
        }
    }
    
    public func fetch<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<Projection, NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return fetch(projected)
    }
    
    public func observe<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<[Projection], NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return fetch(projected)
            .collect()
            .concat(.never)
            .take(until: actions.output
                .filter(projected.sql.affected(by:))
                .map { _ in () }
            )
            .repeat(.max)
            .skipRepeats { $0 == $1 }
    }
}
