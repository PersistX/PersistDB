import Foundation
import Result
import Schemata

public protocol RecordValue {
    static var record: Value<Self, Record> { get }
}

public protocol RecordObject: KeyPathCompliant {
    static var record: Schema<Self, Record> { get }
}

public struct Record: Format {
    public enum Error: Swift.Error {
    }
    
    public typealias Path = String
    
    public enum Field: FormatValue {
        public typealias Error = Record.Error
        
        case string(String)
    }
    
    public var fields: [String: Field]
    
    
    public init(_ fields: [String: Field]) {
        self.fields = fields
    }
    
    public init() {
        self.init([:])
    }
    
    public subscript(_ field: String) -> Field? {
        get {
            return fields[field]
        }
        set {
            fields[field] = newValue
        }
    }
    
    public func decode<T>(_ path: Path, _ decode: Schemata.Value<T, Record>.Decoder) -> Result<T, DecodeError<Record>> {
        guard let value = self[path].flatMap({ decode($0).value }) else {
            fatalError()
        }
        return .success(value)
    }
}

extension Record.Error: Hashable {
    public var hashValue: Int {
        return 0
    }
    
    public static func == (lhs: Record.Error, rhs: Record.Error) -> Bool {
        return false
    }
}

extension Record.Field: Hashable {
    public var hashValue: Int {
        switch self {
        case let .string(value):
            return value.hashValue
        }
    }
    
    public static func == (lhs: Record.Field, rhs: Record.Field) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhs), .string(rhs)):
            return lhs == rhs
        }
    }
}

extension Record: Hashable {
    public var hashValue: Int {
        return fields.map { $0.hashValue ^ $1.hashValue }.reduce(0, ^)
    }
    
    public static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.fields == rhs.fields
    }
}

public func ~ <Object: RecordObject, Value: RecordValue>(
    lhs: KeyPath<Object, Value>,
    rhs: Record.Path
) -> Schema<Object, Record>.Property<Value> {
    return Property<Object, Record, Value>(
        keyPath: lhs,
        path: rhs,
        value: Value.record
    )
}

extension String: RecordValue {
    public static let record = Value<String, Record>(
        decode: { value in
            if case let .string(value) = value {
                return .success(value)
            } else {
                fatalError()
            }
        },
        encode: Record.Value.string
    )
}
