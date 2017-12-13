import Foundation
import Schemata

extension AnyValue.Encoded {
    internal var sql: SQL.Schema.DataType {
        switch self {
        case .date, .double:
            return .real
        case .int:
            return .integer
        case .string:
            return .text
        }
    }
}

extension AnyProperty {
    internal var sql: SQL.Schema.Column? {
        let dataType: SQL.Schema.DataType?
        let nullable: Bool
        switch type {
        case .toMany:
            dataType = nil
            nullable = false
            
        case .toOne:
            dataType = .integer
            nullable = false
            
        case let .value(type, null):
            dataType = type.anyValue.encoded.sql
            nullable = null
        }
        
        return dataType.map { dataType in
            return SQL.Schema.Column(
                name: path,
                type: dataType,
                nullable: nullable,
                primaryKey: path == "id"
            )
        }
    }
}

public protocol Model: Schemata.Model {
    associatedtype ID: ModelValue
    
    var id: ID { get }
    
    static var defaultOrder: [Ordering<Self>] { get }
}

extension Model {
    /// A `Query` matching all values.
    public static var all: Query<Self> {
        return .init()
    }
}

extension Model {
    internal static var idKeyPath: KeyPath<Self, ID> {
        return schema
            .properties
            .values
            .first { $0.path == "id" }!
            .keyPath as! KeyPath<Self, ID>
    }
}

extension AnySchema {
    internal var sql: SQL.Schema {
        return SQL.Schema(
            table: SQL.Table(name),
            columns: Set(properties.values.flatMap { $0.sql })
        )
    }
}
