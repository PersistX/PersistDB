import Foundation
import Schemata

/// A type-erased generator.
internal enum AnyGenerator: Hashable {
    case uuid
}

extension AnyGenerator {
    internal func makeSQL() -> SQL.Value {
        switch self {
        case .uuid:
            return .text(UUID().uuidString)
        }
    }
}

/// A value that describes how to generator a value.
public struct Generator<Value: ModelValue>: Hashable {
    /// The type-erased generator that backs this generator.
    internal var generator: AnyGenerator

    internal init(_ generator: AnyGenerator) {
        self.generator = generator
    }
}

extension Generator where Value == UUID {
    /// A generator that creates a new UUID.
    public static func uuid() -> Generator {
        return Generator(.uuid)
    }
}
