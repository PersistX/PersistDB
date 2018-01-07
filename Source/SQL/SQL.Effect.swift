extension SQL {
    /// An observable effect from a SQL database.
    ///
    /// This represents the effect of an `Action`.
    internal enum Effect {
        case inserted(SQL.Insert, id: SQL.Value)
        case deleted(SQL.Delete)
        case updated(SQL.Update)
    }
}
