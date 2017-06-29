import Foundation
import Schemata

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
            let encoded = type.anyValue.encoded
            if encoded == String.self {
                dataType = .text
            } else if encoded == Int.self {
                dataType = .integer
            } else {
                fatalError("Unknown encoded property type \(encoded)")
            }
            nullable = null
        }
        
        return dataType.map { SQL.Schema.Column(name: path, type: $0, nullable: nullable) }
    }
}

extension Model {
    internal static var sql: SQL.Schema {
        return SQL.Schema(
            table: SQL.Table(String(describing: Self.self)),
            columns: Set(anySchema.properties.values.flatMap { $0.sql })
        )
    }
}
