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

private struct Tagged<Value> {
    let uuid: UUID
    let value: Value

    init(_ value: Value) {
        uuid = UUID()
        self.value = value
    }

    private init(uuid: UUID, value: Value) {
        self.uuid = uuid
        self.value = value
    }

    func map<NewValue>(_ transform: (Value) -> NewValue) -> Tagged<NewValue> {
        return Tagged<NewValue>(uuid: uuid, value: transform(value))
    }
}

public enum ReadOnly {}
public enum ReadWrite {}

/// A store of model objects, either in memory or on disk, that can be modified, queried, and
/// observed.
public final class Store<Mode> {
    /// Create a new scheduler to use for database access.
    fileprivate static func makeScheduler() -> QueueScheduler {
        return QueueScheduler(qos: .userInitiated, name: "org.persistx.PersistDB")
    }

    /// The underlying SQL database.
    private let db: SQL.Database

    /// The scheduler used when accessing the database.
    private let scheduler: QueueScheduler

    /// A pipe of the actions and effects that are mutating the store.
    ///
    /// Used to determine when observed queries must be refetched.
    private let actions: Signal<Tagged<SQL.Action>?, NoError>.Observer
    private let effects: Signal<Tagged<SQL.Effect>?, NoError>

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
        _ db: SQL.Database,
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
            } else if Mode.self == ReadOnly.self {
                throw OpenError.incompatibleSchema
            } else {
                db.create(sql)
            }
        }

        let pipe = Signal<Tagged<SQL.Action>?, NoError>.pipe()
        actions = pipe.input
        effects = pipe.output
            .observe(on: scheduler)
            .map { action in
                return action?.map(db.perform)
            }
            .observe(on: UIScheduler())
    }

    fileprivate static func _open(
        at url: URL,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        let scheduler = Store.makeScheduler()
        return SignalProducer(value: url)
            .observe(on: scheduler)
            .attemptMap { url in
                do {
                    let db = try SQL.Database(at: url)
                    let store = try Store(db, for: schemas, scheduler: scheduler)
                    return .success(store)
                } catch let error as OpenError {
                    return .failure(error)
                } catch {
                    return .failure(.unknown(AnyError(error)))
                }
            }
            .observe(on: UIScheduler())
    }

    fileprivate static func _open(
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
                self._open(at: url, for: schemas)
            }
    }

    fileprivate static func _open(
        libraryNamed fileName: String,
        inApplicationGroup applicationGroup: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        let url = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: applicationGroup)!
            .appendingPathComponent(fileName)
        return _open(at: url, for: schemas)
            .on(value: { store in
                let nc = CFNotificationCenterGetDarwinNotifyCenter()
                let name = CFNotificationName("\(applicationGroup)-\(fileName)" as CFString)
                store
                    .effects
                    .filter { $0 != nil }
                    .observe { _ in
                        CFNotificationCenterPostNotification(nc, name, nil, nil, true)
                    }

                let observer = UnsafeRawPointer(Unmanaged.passUnretained(store.actions).toOpaque())
                CFNotificationCenterAddObserver(
                    nc,
                    observer,
                    { _, observer, _, _, _ in // swiftlint:disable:this opening_brace
                        if let observer = observer {
                            let actions = Unmanaged<Signal<Tagged<SQL.Action>?, NoError>.Observer>
                                .fromOpaque(observer)
                                .takeUnretainedValue()
                            actions.send(value: nil)
                        }
                    },
                    name.rawValue,
                    nil,
                    .deliverImmediately
                )
            })
    }
}

extension Store where Mode == ReadOnly {
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
    public static func open(
        at url: URL,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return _open(at: url, for: schemas)
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
    public static func open(
        at url: URL,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return _open(at: url, for: types.map { $0.anySchema })
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
    public static func open(
        libraryNamed fileName: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return _open(libraryNamed: fileName, for: schemas)
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
    public static func open(
        libraryNamed fileName: String,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return _open(libraryNamed: fileName, for: types.map { $0.anySchema })
    }

    /// Open an on-disk store inside the application group directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - applicationGroup: The identifier for the shared application group.
    ///   - schemas: The schemas for the models in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public static func open(
        libraryNamed fileName: String,
        inApplicationGroup applicationGroup: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return _open(
            libraryNamed: fileName,
            inApplicationGroup: applicationGroup,
            for: schemas
        )
    }

    /// Open an on-disk store inside the application group directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - applicationGroup: The identifier for the shared application group.
    ///   - types: The model types in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public static func open(
        libraryNamed fileName: String,
        inApplicationGroup applicationGroup: String,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return _open(
            libraryNamed: fileName,
            inApplicationGroup: applicationGroup,
            for: types.map { $0.anySchema }
        )
    }
}

extension Store where Mode == ReadWrite {
    /// Create an in-memory store for the given schemas.
    public convenience init(for schemas: [AnySchema]) {
        try! self.init(SQL.Database(), for: schemas) // swiftlint:disable:this force_try
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
        return _open(at: url, for: schemas)
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
        return _open(at: url, for: types.map { $0.anySchema })
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
        return _open(libraryNamed: fileName, for: schemas)
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
        return _open(libraryNamed: fileName, for: types.map { $0.anySchema })
    }

    /// Open an on-disk store inside the application group directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - applicationGroup: The identifier for the shared application group.
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
        inApplicationGroup applicationGroup: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return _open(
            libraryNamed: fileName,
            inApplicationGroup: applicationGroup,
            for: schemas
        )
    }

    /// Open an on-disk store inside the application group directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - applicationGroup: The identifier for the shared application group.
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
        inApplicationGroup applicationGroup: String,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return _open(
            libraryNamed: fileName,
            inApplicationGroup: applicationGroup,
            for: types.map { $0.anySchema }
        )
    }
}

extension Store where Mode == ReadWrite {
    /// Perform an action.
    ///
    /// - parameter:
    ///   - action: The SQL action to perform.
    /// - returns: A signal producer that sends the effect of the action and then completes.
    private func perform(_ action: SQL.Action) -> SignalProducer<SQL.Effect, NoError> {
        let tagged = Tagged(action)
        defer { actions.send(value: tagged) }

        let effect = SignalProducer<Tagged<SQL.Effect>?, NoError>(effects)
            .filterMap { $0 }
            .filter { $0.uuid == tagged.uuid }
            .map { $0.value }
            .take(first: 1)
            .replayLazily(upTo: 1)
        effect.start()
        return effect
    }

    /// Perform an action in the store.
    ///
    /// - important: This is done asynchronously.
    @discardableResult
    public func perform(_ action: Action) -> SignalProducer<Never, NoError> {
        return perform(action.makeSQL()).then(.empty)
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
                switch anyValue.decode(primitive) {
                case let .success(decoded):
                    return decoded as! Model.ID // swiftlint:disable:this force_cast
                case .failure:
                    fatalError("Decoding ID should never fail")
                }
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
    /// Fetch a SQL query from the store.
    ///
    /// This method backs the public `fetch` and `observe` methods.
    ///
    /// - parameters:
    ///   - query: The SQL query to be fetched from the store.
    ///   - transform: A black to transform the SQL rows into a value.
    ///
    /// - returns: A `SignalProducer` that will fetch values for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    private func fetch<Value>(
        _ query: SQL.Query,
        _ transform: @escaping ([SQL.Row]) -> Value
    ) -> SignalProducer<Value, NoError> {
        return SignalProducer(value: query)
            .observe(on: scheduler)
            .map(db.query)
            .map(transform)
            .observe(on: UIScheduler())
    }

    /// Observe a SQL query from the store.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// value will re-fetched and re-sent.
    ///
    /// - parameters:
    ///   - query: The SQL query to be observed.
    ///   - transform: A black to transform the SQL rows into a value.
    /// - returns: A `SignalProducer` that will send values for entities that match the
    ////           query, sending a new value whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    private func observe<Value>(
        _ query: SQL.Query,
        _ transform: @escaping ([SQL.Row]) -> Value
    ) -> SignalProducer<Value, NoError> {
        return fetch(query, transform)
            .concat(.never)
            .take(
                until: effects
                    .filter { $0?.map(query.invalidated(by:)).value ?? true }
                    .map { _ in () }
            )
            .repeat(.max)
    }

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
    private func fetch<Group, Projection>(
        _ projected: ProjectedQuery<Group, Projection>
    ) -> SignalProducer<ResultSet<Group, Projection>, NoError> {
        return fetch(projected.sql, projected.resultSet(for:))
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
    private func observe<Group, Projection>(
        _ projected: ProjectedQuery<Group, Projection>
    ) -> SignalProducer<ResultSet<Group, Projection>, NoError> {
        return observe(projected.sql, projected.resultSet(for:))
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
            .map { resultSet in resultSet.first }
    }

    /// Fetch projections from the store with a query.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func fetch<Key, Projection: ModelProjection>(
        _ query: Query<Key, Projection.Model>
    ) -> SignalProducer<ResultSet<Key, Projection>, NoError> {
        let projected = ProjectedQuery<Key, Projection>(query)
        return fetch(projected)
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
    public func observe<Key, Projection: ModelProjection>(
        _ query: Query<Key, Projection.Model>
    ) -> SignalProducer<ResultSet<Key, Projection>, NoError> {
        let projected = ProjectedQuery<Key, Projection>(query)
        return observe(projected)
    }

    /// Fetch an aggregate value from the store.
    ///
    /// - parameters:
    ///   - aggregate: The aggregate value to fetch.
    ///
    /// - returns: A `SignalProducer` that will fetch the aggregate.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func fetch<Model, Value>(
        _ aggregate: Aggregate<Model, Value>
    ) -> SignalProducer<Value, NoError> {
        return fetch(aggregate.sql, aggregate.result(for:))
    }

    /// Observe an aggregate value from the store.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// value will be re-fetched and re-sent.
    ///
    /// - parameters:
    ///   - aggregate: The aggregate value to fetch.
    ///
    /// - returns: A `SignalProducer` that will send the aggregate value, sending a new value
    ///            whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func observe<Model, Value>(
        _ aggregate: Aggregate<Model, Value>
    ) -> SignalProducer<Value, NoError> {
        return observe(aggregate.sql, aggregate.result(for:))
    }
}
