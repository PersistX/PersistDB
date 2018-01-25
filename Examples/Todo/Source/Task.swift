import PersistDB
import Schemata

/// A task in the app and in the database, the central model of the application.
///
/// Please also see the tests for this class.
struct Task {
    /// The id for the task.
    let id: UUID
    /// When the task was created.
    let createdAt: Date
    /// When the task was completed, or `nil` if it's incomplete.
    let completedAt: Date?
    /// The text content of the task.
    let text: String
}

extension Task {
    var isCompleted: Bool {
        return completedAt != nil
    }
}

extension Task: Hashable {
    var hashValue: Int {
        return id.hashValue
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
            && lhs.createdAt == rhs.createdAt
            && lhs.completedAt == rhs.completedAt
            && lhs.text == rhs.text
    }
}

extension Task: PersistDB.Model {
    // Define the schema for `Task`.
    // The strings will be the names of the columns in the database.
    static let schema = Schema(
        Task.init,
        \.id ~ "id",
        \.createdAt ~ "createdAt",
        \.completedAt ~ "completedAt",
        \.text ~ "text"
    )

    static let defaultOrder: [Ordering<Task>] = [
        Ordering(\Task.completedAt),
        Ordering(\Task.createdAt),
    ]
}

// Task is its own projection. This is convenient when you always want all of the model's
// properties (including it's relationships and their properties, recursively).
extension Task: PersistDB.ModelProjection {
    typealias Model = Task

    static let projection = Projection<Task, Task>(
        Task.init,
        \.id,
        \.createdAt,
        \.completedAt,
        \.text
    )
}

extension Task {
    /// A query matching the incomplete tasks.
    static let active = Task.all.filter(\.completedAt == nil)

    /// A query matching the completed tasks.
    static let completed = Task.all.filter(\.completedAt != nil)
}

extension Task {
    /// Create a value that represents the task to be inserted into the database.
    static func newTask(text: String) -> Insert<Task> {
        return [
            \.id == .uuid(),
            \.createdAt == .now,
            \.text == text,
        ]
    }

    /// Values to mark a task as complete.
    static let complete: ValueSet<Task> = [\.completedAt == .now ]

    /// Values to mark a task as incomplete.
    static let incomplete: ValueSet<Task> = [\.completedAt == nil ]
}
