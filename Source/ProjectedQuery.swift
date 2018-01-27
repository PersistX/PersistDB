import Foundation
import Schemata

internal struct ProjectedQuery<Group: ModelValue, Projection: PersistDB.ModelProjection> {
    let sql: SQL.Query
    let keyPaths: [UUID: PartialKeyPath<Projection.Model>]

    fileprivate init(_ sql: SQL.Query) {
        let projection = Projection.projection

        keyPaths = Dictionary(uniqueKeysWithValues: projection.keyPaths.map { keyPath in
            (UUID(), keyPath)
        })

        let aliases = Dictionary(uniqueKeysWithValues: keyPaths.map { ($1, $0) })
        let results = projection.keyPaths.map { keyPath -> SQL.Result in
            let sql = AnyExpression(keyPath).makeSQL()
            return SQL.Result(sql, alias: aliases[keyPath]?.uuidString)
        }

        self.sql = SQL.Query(
            results: sql.results + results,
            predicates: sql.predicates,
            order: sql.order
        )
    }

    func resultSet(for rows: [Row]) -> ResultSet<Group, Projection> {
        let projection = Projection.projection
        let groups = rows
            .flatMap { row -> (Group, Projection)? in
                return projection
                    .makeValue(values(for: row))
                    .map { value in
                        let groupBy: Group
                        if Group.self == None.self {
                            groupBy = None.none as! Group // swiftlint:disable:this force_cast
                        } else {
                            groupBy = Group.decode(row.dictionary["groupBy"]!)!
                                as! Group // swiftlint:disable:this force_cast
                        }
                        return (groupBy, value)
                    }
            }
            .group { return $0 }
        return ResultSet(groups)
    }

    func values(for row: Row) -> [PartialKeyPath<Projection.Model>: SQL.Value] {
        return Dictionary(uniqueKeysWithValues: row.dictionary.flatMap { alias, value in
            guard let uuid = UUID(uuidString: alias), let keyPath = keyPaths[uuid] else {
                return nil
            }
            return (keyPath, value)
        })
    }
}

extension ProjectedQuery where Group == None {
    init(_ query: Query<Projection.Model>) {
        self.init(query.makeSQL())
    }
}

extension ProjectedQuery {
    init(_ query: Query<Projection.Model>, groupedBy: SQL.Ordering) {
        let sql = query.makeSQL()
            .select(SQL.Result(groupedBy.expression, alias: "groupBy"))
            .sorted(by: groupedBy)
        self.init(sql)
    }
}
