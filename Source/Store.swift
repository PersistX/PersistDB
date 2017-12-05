import Foundation
import ReactiveSwift
import Result
import Schemata

public final class Store {
    internal let db: Database
    
    private init(_ db: Database) {
        self.db = db
    }
    
    public convenience init() {
        self.init(Database())
    }
    
    public convenience init(at url: URL) {
        self.init(Database())
    }
}

extension Store {
    func fetch<Projection: ModelProjection>(
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
        let values = db
            .query(SQL.Query(results: results, predicates: sql.predicates, order: sql.order))
            .map { values in
                var result: [PartialKeyPath<Projection.Model>: Any] = [:]
                for (alias, value) in values.dictionary {
                    let keyPath = keyPaths[alias]!
                    let property = Projection.Model.schema.properties(for: keyPath).last!
                    guard case let .value(type, _) = property.type else {
                        fatalError()
                    }
                    let primitive = value.primitive(type.anyValue.encoded)
                    result[keyPath] = type.anyValue.decode(primitive).value!
                }
                return result
            }
            .map(Projection.projection.makeValue)
        return SignalProducer<Projection, NoError>(values)
    }
}
