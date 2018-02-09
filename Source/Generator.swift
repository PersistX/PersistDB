import Schemata

/// A type-erased generator.
internal enum AnyGenerator {
    case uuid
}

extension AnyGenerator: Hashable {
    internal var hashValue: Int {
        switch self {
        case .uuid:
            return 1
        }
    }

    internal static func == (lhs: AnyGenerator, rhs: AnyGenerator) -> Bool {
        switch (lhs, rhs) {
        case (.uuid, .uuid):
            return true
        }
    }
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
public struct Generator<Value: ModelValue> {
    /// The type-erased generator that backs this generator.
    internal var generator: AnyGenerator

    internal init(_ generator: AnyGenerator) {
        self.generator = generator
    }
}

extension Generator: Hashable {
    public var hashValue: Int {
        return generator.hashValue
    }

    public static func == (lhs: Generator, rhs: Generator) -> Bool {
        return lhs.generator == rhs.generator
    }
}

extension Generator where Value == UUID {
    /// A generator that creates a new UUID.
    public static func uuid() -> Generator {
        return Generator(.uuid)
    }
}
