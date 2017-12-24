extension SQL {
    internal enum Action {
        case insert(SQL.Insert)
        case delete(SQL.Delete)
        case update(SQL.Update)
    }
}

extension SQL.Action {
    var table: SQL.Table {
        switch self {
        case let .insert(insert):
            return insert.table
        case let .delete(delete):
            return delete.table
        case let .update(update):
            return update.table
        }
    }
}
