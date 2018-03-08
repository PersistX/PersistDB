/// A `Hashable` version of Swift's `Optional`.
///
/// `Optional` won't conform to `Optional` until Swift 4.2, so this type will serve as a workaround
/// until then.
public enum Maybe<Value: Hashable> {
    case some(Value)
    case none
}

extension Maybe {
    /// Convert to an optional
    public var optional: Value? {
        switch self {
        case let .some(value):
            return value
        case .none:
            return nil
        }
    }
}

extension Maybe: Hashable {
    public var hashValue: Int {
        switch self {
        case let .some(value):
            return value.hashValue
        case .none:
            return 0
        }
    }
    
    public static func == (lhs: Maybe, rhs: Maybe) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs == rhs
        case (.none, .none):
            return true
        case (.some, .none), (.none, .some):
            return false
        }
    }
}
