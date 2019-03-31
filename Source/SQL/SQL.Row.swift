extension SQL {
    /// A row from a SQL database.
    internal struct Row: Hashable {
        internal var dictionary: [String: SQL.Value]

        init(_ dictionary: [String: SQL.Value]) {
            self.dictionary = dictionary
        }
    }
}

extension SQL.Row: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, SQL.Value)...) {
        var dictionary: [String: SQL.Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.init(dictionary)
    }
}
