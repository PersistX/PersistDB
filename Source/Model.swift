import Foundation
import Schemata

extension AnyValue.Encoded {
    internal var sql: SQL.DataType {
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
        let dataType: SQL.DataType?
        let nullable: Bool
        switch type {
        case .toMany:
            dataType = nil
            nullable = false

        case let .toOne(_, null):
            dataType = .integer
            nullable = null

        case let .value(type, null):
            dataType = type.anyValue.encoded.sql
            nullable = null
        }

        return dataType.map { dataType in
            SQL.Schema.Column(
                name: path,
                type: dataType,
                nullable: nullable,
                primaryKey: path == "id"
            )
        }
    }
}

extension AnyModelValue {
    internal static func decode(_ value: SQL.Value) -> Any? {
        let primitive = value.primitive(anyValue.encoded)
        return anyValue.decode(primitive).value
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
            .keyPath as! KeyPath<Self, ID> // swiftlint:disable:this force_cast
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

extension Projection {
    internal func makeValue(_ values: [PartialKeyPath<Model>: SQL.Value]) -> Value? {
        let schema = Model.schema
        var result: [PartialKeyPath<Model>: Any] = [:]
        for (keyPath, value) in values {
            let property = schema.properties(for: keyPath).last!
            guard case let .value(type, isOptional) = property.type else {
                fatalError("keypath should end with a scalar value")
            }
            let decoded = type.decode(value)
            result[keyPath] = isOptional ? .some(decoded as Any) : decoded!
        }
        return makeValue(result)
    }
}
