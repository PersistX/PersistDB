extension Collection {
    internal func group<Key, Value>(
        _ block: @escaping (Element) -> (Key, Value)
    ) -> [Group<Key, Value>] {
        let tuples = map(block)
        guard let first = tuples.first else { return [] }

        var result: [Group<Key, Value>] = []

        var group = Group(key: first.0, values: [ first.1 ])
        for (key, value) in tuples.dropFirst() {
            if key == group.key {
                group.values.append(value)
            } else {
                result.append(group)
                group = Group(key: key, values: [ value ])
            }
        }
        result.append(group)

        return result
    }
}
