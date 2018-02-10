/// A type-erased action.
internal enum AnyAction {
    case insert(AnyInsert)
    case delete(AnyDelete)
    case update(AnyUpdate)
}

extension AnyAction: Hashable {
    var hashValue: Int {
        switch self {
        case let .insert(insert):
            return insert.hashValue
        case let .delete(delete):
            return delete.hashValue
        case let .update(update):
            return update.hashValue
        }
    }

    static func == (lhs: AnyAction, rhs: AnyAction) -> Bool {
        switch (lhs, rhs) {
        case let (.insert(lhs), .insert(rhs)):
            return lhs == rhs
        case let (.delete(lhs), .delete(rhs)):
            return lhs == rhs
        case let (.update(lhs), .update(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

/// An action to modify that database.
public struct Action {
    internal var action: AnyAction

    public init<M>(_ insert: Insert<M>) {
        action = .insert(insert.insert)
    }

    public init<M>(_ delete: Delete<M>) {
        action = .delete(delete.delete)
    }

    public init<M>(_ update: Update<M>) {
        action = .update(update.update)
    }
}

extension Action: Hashable {
    public var hashValue: Int {
        return action.hashValue
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.action == rhs.action
    }
}
