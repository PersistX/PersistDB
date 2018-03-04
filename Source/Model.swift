import Foundation
import Schemata

public protocol Model: Schemata.Model {
    associatedtype ID: ModelValue

    var id: ID { get }

    static var defaultOrder: [Ordering<Self>] { get }
}

extension Model {
    /// A `Query` matching all values.
    public static var all: Query<None, Self> {
        return .init()
    }
}

extension Model {
    internal static var idKeyPath: KeyPath<Self, ID> {
        return schema
            .properties
            .values
            .first { $0.path == "id" }!
            .keyPath as! KeyPath<Self, ID> // swiftlint:disable:this force_cast
    }
}

public protocol ModelProjection: Schemata.ModelProjection where Model: PersistDB.Model {
    var id: Model.ID { get }
}
