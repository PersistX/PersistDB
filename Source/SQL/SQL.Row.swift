extension SQL {
    /// A row from a SQL database.
    internal struct Row {
        internal var dictionary: [String: SQL.Value]

        init(_ dictionary: [String: SQL.Value]) {
            self.dictionary = dictionary
        }
    }
}

extension SQL.Row: Hashable {
    var hashValue: Int {
        return dictionary.reduce(0) { $0 ^ $1.key.hashValue ^ $1.value.hashValue }
    }

    static func == (lhs: SQL.Row, rhs: SQL.Row) -> Bool {
        return lhs.dictionary == rhs.dictionary
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
