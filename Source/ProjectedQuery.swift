internal struct ProjectedQuery<Projection: ModelProjection> {
    let sql: SQL.Query
    let keyPaths: [String: PartialKeyPath<Projection.Model>]

    init(_ query: Query<Projection.Model>) {
        let projection = Projection.projection
        let sql = query.makeSQL()

        keyPaths = Dictionary(uniqueKeysWithValues: projection.keyPaths.map { keyPath in
            (UUID().uuidString, keyPath)
        })

        let aliases = Dictionary(uniqueKeysWithValues: keyPaths.map { ($1, $0) })
        let results = projection.keyPaths.map { keyPath -> SQL.Result in
            let sql = AnyExpression(keyPath).makeSQL()
            return SQL.Result(sql, alias: aliases[keyPath])
        }

        self.sql = SQL.Query(
            results: results,
            predicates: sql.predicates,
            order: sql.order
        )
    }

    func values(for row: Row) -> [PartialKeyPath<Projection.Model>: SQL.Value] {
        return Dictionary(uniqueKeysWithValues: row.dictionary.flatMap { alias, value in
            guard let keyPath = keyPaths[alias] else { return nil }
            return (keyPath, value)
        })
    }
}
