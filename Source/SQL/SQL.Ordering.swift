import Foundation

extension SQL {
    /// A value representing how results should be sorted.
    internal struct Ordering: Hashable {
        /// The direction of the sort.
        internal enum Direction: Hashable {
            case ascending
            case descending

            fileprivate var sql: SQL {
                switch self {
                case .ascending:
                    return SQL("ASC")
                case .descending:
                    return SQL("DESC")
                }
            }
        }

        let expression: Expression
        let direction: Direction

        internal init(_ expression: Expression, _ direction: Direction) {
            self.expression = expression
            self.direction = direction
        }

        internal var sql: SQL {
            return expression.sql + " " + direction.sql
        }
    }
}
