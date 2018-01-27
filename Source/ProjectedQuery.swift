import Foundation
import Schemata

/// A `Query` that will select the columns required for `Projection` and also handle grouping.
internal struct ProjectedQuery<Group: ModelValue, Projection: PersistDB.ModelProjection> {
    /// The projected SQL query, adjusted from what's passed into `init`.
    let sql: SQL.Query
    
    /// A mapping of UUIDs to key paths.
    ///
    /// UUIDs serve as names for the key paths since the paths aren't convertible to strings.
    let keyPaths: [UUID: PartialKeyPath<Projection.Model>]

    /// Create a new projected query from a SQL query.
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

    /// Create a result set from the `Row`s returned from the query.
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

    /// Extract the values for each key path in the projection.
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
