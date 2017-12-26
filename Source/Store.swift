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
