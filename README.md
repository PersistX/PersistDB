# PersistDB ✊️🗄
Projection-based Database Persistence in Swift

1. [Core Values](#core-values)
2. [Overview](#overview)
    1. [Define `Model`s](#1-define-models)
    2. [Define a `Projection`](#2-define-a-projection)
    3. [Create a `Store`](#3-create-a-store)
    4. [`fetch` or `observe` data](#4-fetch-or-observe-data)
    5. [Mutate with Actions](#5-mutate-with-actions)
3. [Installation](#installation)
4. [License](#license)

## Core Values
* **_Type-safety_**: Compile-time errors prevent runtime errors

* **_Concurrency_**: It’s hard to block a thread without synchronous APIs

* **_Consistency_**: Viewed data should always be internally consistent

* **_Value Semantics_**: Data can be passed across threads, transformed, and easily tested

* **_Typed Errors_**: Exhaustiveness checking prevents failures on the sad path

## Overview
Traditional ORMs map a row from a SQL table directly onto an object. Each property on the object represents either a column in the table or a relationship.

PersistDB _defines_ schemas like a traditional ORM. But data is fetched as a _projection_, much like a GraphQL query. This guarantees that the loaded data will be consistent.

Every operation—inserting, deleting, or changing data—can be represented by a _value_. This makes it possible to write code without side effects, making
testing easy.

### 1. Define `Model`s
Schemas are defined using Swift types. These types are typically never instantiated, but are used to filter, sort, and query the database. They are often defined as `final class`s so that Swift can construct memory layouts for one-to-one relationships.

```swift
final class Book {
    let id: ID<Book>
    let title: String
    let author: Author
    
    init(id: Int, title: String, author: Author) {
        self.id = id
        self.title = title
        self.author = author
    }
}

final class Author {
    let id: ID<Author>
    let name: String
    let books: Set<Book>
    
    init(id: Int, name: String, books: Set<Book>) {
        self.id = id
        self.name = name
        self.books = books
    }
}
```

Once you’ve made your types, you can declare them to be `Model`s and construct the `Schema` for the type. This is done in a type-safe way by using the type’s `init` and Swift’s smart keypaths.

```swift
extension Book: PersistDB.Model {
    static let schema = Schema(
        Book.init,
        \.id ~ "id",        // The strings here are the names that the columns
        \.title ~ "title",  // will have in the database.
        \.author ~ "author"
    )
}

extension Author: PersistDB.Model {
    static let schema = Schema(
        Author.init,
        \.id ~ "id"
        \.name ~ "name",
        \.books ~ \Book.author
    )
}
```

### 2. Define a `Projection`
Once you’ve made your models, you can create `Projection`s, which are how you load information from the database. A projection resembles a view model: it has the data you actually want to present in a given context.

```swift
struct BookViewModel {
    let title: String
    let authorName: String
    let authorBookCount: Int
}

extension BookViewModel: ModelProjection {
    static let projection = Projection<Book, BookViewModel>(
        BookViewModel.init,
        \.title,
        \.author.name,
        \.author.books.count
    )
}
```

### 3. Create a `Store`
The `Store` is the interface to the database; it is the source of all side-effects. Creating a `Store` is simple:

```swift
Store
    .store(at: URL(…), for: [Book.self, Author.self])
    .startWithResult { result in
        switch result {
        case let .success(store):
            …
        case let .failure(error):
            print("Failed to load store: \(error)")
        }
    }
```

Stores can only be loaded asynchronously so the main thread can’t accidentally be blocked.

### 4. `fetch` or `observe` data
Sets of objects are fetched with `Query`s, which use `Predicate`s to filter the available models and `SortDescriptor`s to sort them.

```swift
let harryPotter: Query<Book> = Book.all
    .filter(\.author.name == "J.K. Rowling")
    .sort(by: \.title)
```

Actual fetches are done with a [`Projection`](#define-a-projection).

```swift
store
    // A `ReactiveSwift.SignalProducer` that fetches the data
    .fetch(harryPotter)
    // Do something the the array or error
    .startWithResult { result in
        switch result {
        case let .success(resultSet):
            …
        case let .failure(error):
            …
        }
    }
```

You can also observe the object(s) to receive updated values if changes are made:

```swift
store
    .observe(harryPotter)
    .startWithResult { result in
        …
    }
```

PersistDB provides `Table` to help you build collection UIs. It includes built-in intelligent diffing to help you with incremental updates.

### 5. Mutate with Actions
Inserts, updates, and deletes are all built on value types: `Insert`, `Update`, and `Delete`. This makes it easy to test that your actions will have the right effect without trying to verify actual side effects.

`Insert` and `Update` are built on `ValueSet`: a set of values that can be assigned to a model entity.

```swift
struct Task {
    public let id: UUID
    public let createdAt: Date
    public var text: String
    public var url: URL?
    
    public static func newTask(text: String, url: URL? = nil) -> Insert<Task> {
        return Insert([
            \Task.id == .uuid(),
            \Task.createdAt == .now,
            \Task.text == text,
            \Task.url == url,
        ])
    }
}

store.insert(Task.newTask(text: "Ship!!!"))
```

PersistDB includes `TestStore`, which makes it easy to test your inserts and updates against queries to verify that they’ve set the right properties.

## Installation
The easiest way to add PersistDB to your project is with [Carthage](https://github.com/Carthage/Carthage). Follow the instructions there.

## License
PersistDB is available under [the MIT license](LICENSE.md).
