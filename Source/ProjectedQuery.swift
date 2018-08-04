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
    internal init(_ query: Query<Group, Projection.Model>) {
        let projection = Projection.projection

        keyPaths = Dictionary(uniqueKeysWithValues: projection.keyPaths.map { keyPath in
            (UUID(), keyPath)
        })

        let aliases = Dictionary(uniqueKeysWithValues: keyPaths.map { ($1, $0) })
        let results = projection.keyPaths.map { keyPath -> SQL.Result in
            let sql = AnyExpression(keyPath).sql
            return SQL.Result(sql, alias: aliases[keyPath]?.uuidString)
        }

        let order = (query.order.isEmpty ? Projection.Model.defaultOrder : query.order)
            .map { $0.sql }
        let predicates = query.predicates.map { $0.expression.sql }

        if query.groupedBy == .none {
            sql = SQL.Query(
                results: results,
                predicates: predicates,
                order: order
            )
        } else {
            let groupBy = SQL.Result(query.groupedBy.expression.expression.sql, alias: "groupBy")
            sql = SQL.Query(
                results: [groupBy] + results,
                predicates: predicates,
                order: [ query.groupedBy.sql ] + order
            )
        }
    }

    /// Create a result set from the `Row`s returned from the query.
    func resultSet(for rows: [SQL.Row]) -> ResultSet<Group, Projection> {
        let projection = Projection.projection
        let groups = rows
            .compactMap { row -> (Group, Projection)? in
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
    func values(for row: SQL.Row) -> [PartialKeyPath<Projection.Model>: SQL.Value] {
        return Dictionary(uniqueKeysWithValues: row.dictionary.compactMap { alias, value in
            guard let uuid = UUID(uuidString: alias), let keyPath = keyPaths[uuid] else {
                return nil
            }
            return (keyPath, value)
        })
    }
}
