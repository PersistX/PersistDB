/// A type-erased action.
internal enum AnyAction: Hashable {
    case insert(AnyInsert)
    case delete(AnyDelete)
    case update(AnyUpdate)
}

/// An action to modify that database.
public struct Action: Hashable {
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

extension Action {
    internal func makeSQL() -> SQL.Action {
        switch action {
        case let .insert(insert):
            return .insert(insert.makeSQL())
        case let .delete(delete):
            return .delete(delete.makeSQL())
        case let .update(update):
            return .update(update.makeSQL())
        }
    }
}
