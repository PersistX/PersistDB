import Foundation
import ReactiveSwift
import Result
import Schemata

/// An error that occurred while opening an on-disk `Store`.
public enum OpenError: Error {
    /// The schema of the on-disk database is incompatible with the schema of the store.
    case incompatibleSchema
    /// An unknown error occurred. An unfortunate reality.
    case unknown(AnyError)
}

/// A store of model objects, either in memory or on disk, that can be modified, queried, and
/// observed.
public final class Store {
    /// Create a new scheduler to use for database access.
    fileprivate static func makeScheduler() -> QueueScheduler {
        return QueueScheduler(qos: .userInitiated, name: "org.persistx.PersistDB")
    }

    /// The underlying SQL database.
    fileprivate let db: Database

    /// The scheduler used when accessing the database.
    fileprivate let scheduler: QueueScheduler

    /// A pipe of the actions and effects that are mutating the store.
    ///
    /// Used to determine when observed queries must be refetched.
    fileprivate let actions: Signal<(UUID, SQL.Action), NoError>.Observer
    fileprivate let effects: Signal<(UUID, SQL.Effect), NoError>

    /// The designated initializer.
    ///
    /// - parameters:
    ///   - db: An opened SQL database that backs the store.
    ///   - schemas: The schemas of the models in the store.
    ///   - scheduler: The scheduler to use when accessing the database.
    ///
    /// - throws: An `OpenError` if the store cannot be created from the given database.
    ///
    /// As part of initialization, the store will verify the schema of and create tables in the
    /// database.
    private init(
        _ db: Database,
        for schemas: [AnySchema],
        scheduler: QueueScheduler = Store.makeScheduler()
    ) throws {
        self.db = db
        self.scheduler = scheduler

        let existing = Dictionary(
            uniqueKeysWithValues: db
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

        let pipe = Signal<(UUID, SQL.Action), NoError>.pipe()
        actions = pipe.input
        effects = pipe.output
            .observe(on: scheduler)
            .map { uuid, action in
                return (uuid, db.perform(action))
            }
            .observe(on: UIScheduler())
    }

    /// Create an in-memory store for the given schemas.
    public convenience init(for schemas: [AnySchema]) {
        try! self.init(Database(), for: schemas) // swiftlint:disable:this force_try
    }

    /// Create an in-memory store for the given model types.
    public convenience init(for types: [Schemata.AnyModel.Type]) {
        self.init(for: types.map { $0.anySchema })
    }

    /// Open an on-disk store.
    ///
    /// - parameters:
    ///   - url: The file URL of the store to open.
    ///   - schemas: The schemas for the models in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        at url: URL,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        let scheduler = Store.makeScheduler()
        return SignalProducer(value: url)
            .observe(on: scheduler)
            .attemptMap { url in
                do {
                    let db = try Database(at: url)
                    let store = try Store(db, for: schemas, scheduler: scheduler)
                    return .success(store)
                } catch let error as OpenError {
                    return .failure(error)
                } catch let error {
                    return .failure(.unknown(AnyError(error)))
                }
            }
            .observe(on: UIScheduler())
    }

    /// Open an on-disk store.
    ///
    /// - parameters:
    ///   - url: The file URL of the store to open.
    ///   - types: The model types in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        at url: URL,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return open(at: url, for: types.map { $0.anySchema })
    }

    /// Open an on-disk store inside the Application Support directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - schemas: The schemas for the models in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        libraryNamed fileName: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return SignalProducer(value: fileName)
            .attemptMap { fileName in
                try FileManager
                    .default
                    .url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                    .appendingPathComponent(fileName)
            }
            .mapError(OpenError.unknown)
            .flatMap(.latest) { url in
                self.open(at: url, for: schemas)
            }
    }

    /// Open an on-disk store inside the Application Support directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - types: The model types in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        libraryNamed fileName: String,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return open(libraryNamed: fileName, for: types.map { $0.anySchema })
    }
}

extension Store {
    /// Perform an action.
    ///
    /// - parameter:
    ///   - action: The SQL action to perform.
    /// - returns: A signal producer that sends the effect of the action and then completes.
    private func perform(_ action: SQL.Action) -> SignalProducer<SQL.Effect, NoError> {
        let uuid = UUID()
        defer { actions.send(value: (uuid, action)) }

        let effect = SignalProducer<(UUID, SQL.Effect), NoError>(effects)
            .filter { $0.0 == uuid }
            .map { $0.1 }
            .take(first: 1)
            .replayLazily(upTo: 1)
        effect.start()
        return effect
    }

    /// Insert a model entity into the store.
    ///
    /// - important: This is done asynchronously.
    ///
    /// - parameters:
    ///   - insert: The entity to insert
    /// - returns: A signal producer that sends the ID after the model has been inserted.
    @discardableResult
    public func insert<Model>(_ insert: Insert<Model>) -> SignalProducer<Model.ID, NoError> {
        return perform(.insert(insert.makeSQL()))
            .map { effect -> Model.ID in
                guard case let .inserted(_, id) = effect else { fatalError("Mistaken effect") }
                let anyValue = Model.ID.anyValue
                let primitive = id.primitive(anyValue.encoded)
                let decoded = anyValue.decode(primitive).value!
                return decoded as! Model.ID // swiftlint:disable:this force_cast
            }
    }

    /// Delete a model entity from the store.
    ///
    /// - important: This is done asynchronously.
    @discardableResult
    public func delete<Model>(_ delete: Delete<Model>) -> SignalProducer<Never, NoError> {
        return perform(.delete(delete.makeSQL())).then(.empty)
    }

    /// Update properties for a model entity in the store.
    ///
    /// - important: This is done asynchronously.
    @discardableResult
    public func update<Model>(_ update: Update<Model>) -> SignalProducer<Never, NoError> {
        return perform(.update(update.makeSQL())).then(.empty)
    }
}

extension Store {
    /// Fetch a projected query from the store.
    ///
    /// This method backs the public `fetch` and `observe` methods.
    ///
    /// - parameters:
    ///   - projected: The projected query to be fetched from the store.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    private func fetch<Projection>(
        _ projected: ProjectedQuery<Projection>
    ) -> SignalProducer<ResultSet<None, Projection>, NoError> {
        return SignalProducer(value: db)
            .observe(on: scheduler)
            .map { db in
                let values = db
                    .query(projected.sql)
                    .map(projected.values(for:))
                    .flatMap(Projection.projection.makeValue)
                return ResultSet(values)
            }
            .observe(on: UIScheduler())
    }

    /// Observe a projected query from the store.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// projections will be re-fetched and re-sent.
    ///
    /// - parameters:
    ///   - query: The projected query to be observed.
    ///
    /// - returns: A `SignalProducer` that will send sets of projections for entities that match the
    ////           query, sending a new set whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    private func observe<Projection>(
        _ projected: ProjectedQuery<Projection>
    ) -> SignalProducer<ResultSet<None, Projection>, NoError> {
        return fetch(projected)
            .concat(.never)
            .take(
                until: effects
                    .map { $0.1 }
                    .filter(projected.sql.invalidated(by:))
                    .map { _ in () }
            )
            .repeat(.max)
    }

    /// Fetch a projection from the store by the model entity's id.
    ///
    /// - parameters:
    ///   - id: The ID of the entity to be projected.
    ///
    /// - returns: A `SignalProducer` that will fetch the projection for the entity that matches the
    ///            query or send `nil` if no entity exists with that ID.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func fetch<Projection: ModelProjection>(
        _ id: Projection.Model.ID
    ) -> SignalProducer<Projection?, NoError> {
        let query = Projection.Model.all
            .filter(Projection.Model.idKeyPath == id)
        return fetch(query)
            .map { resultSet in resultSet.values.first }
    }

    /// Observe a projection from the store by the model entity's id.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// projections will be re-fetched and re-sent.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will send sets of projections for entities that match the
    ////           query, sending a new set whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func observe<Projection: ModelProjection>(
        _ id: Projection.Model.ID
    ) -> SignalProducer<Projection?, NoError> {
        let query = Projection.Model.all
            .filter(Projection.Model.idKeyPath == id)
        return observe(query)
            .map { resultSet in resultSet.values.first }
    }

    /// Fetch projections from the store with a query.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func fetch<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<ResultSet<None, Projection>, NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return fetch(projected)
    }

    /// Fetch projections from the store with a query and group them by some value.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///   - keyPath: The property that should be used to group consecutive projections.
    ///   - ascending: Whether the query should be sorted by the `keyPath` ascending or descending.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// - important: This will sort the query by the grouped property.
    public func fetch<Projection: ModelProjection, Value: ModelValue>(
        _ query: Query<Projection.Model>,
        groupedBy keyPath: KeyPath<Projection.Model, Value>,
        ascending: Bool = true
    ) -> SignalProducer<ResultSet<Value, Projection>, NoError> {
        let groupedBy = AnyExpression(keyPath).makeSQL()
        let projected = ProjectedQuery<Projection>(query)
        let sql = projected.sql
            .select(SQL.Result(groupedBy, alias: "groupBy"))
            .sorted(by: SQL.Ordering(groupedBy, ascending ? .ascending : .descending))
        return SignalProducer(value: db)
            .observe(on: scheduler)
            .map { db in
                db.query(sql)
            }
            .observe(on: UIScheduler())
            .flatten()
            .filterMap { row -> (Value, Projection)? in
                let groupBy = Value.decode(row.dictionary["groupBy"]!)!
                    as! Value // swiftlint:disable:this force_cast
                let values = projected.values(for: row)
                return Projection
                    .projection
                    .makeValue(values)
                    .map { (groupBy, $0) }
            }
            .collect { $0.0 }
            .map { arg in
                let (key, values) = arg
                return Group(key: key, values: values.map { $0.1 })
            }
            .collect()
            .map(ResultSet.init)
    }

    /// Observe projections from the store with a query.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// projections will be re-fetched and re-sent.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will send sets of projections for entities that match the
    ////           query, sending a new set whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func observe<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<ResultSet<None, Projection>, NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return observe(projected)
    }
}
