import Foundation

extension SQL {
    /// A value representing how results should be sorted.
    internal struct SortDescriptor {
        /// The direction of the sort.
        internal enum Direction {
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
        
        let expression: AnyExpression
        let direction: Direction
        
        internal init(_ expression: AnyExpression, _ direction: Direction) {
            self.expression = expression
            self.direction = direction
        }
        
        internal var sql: SQL {
            return expression.sql + " " + direction.sql
        }
    }
}

extension SQL.SortDescriptor: Hashable {
    internal var hashValue: Int {
        return expression.hashValue
    }
    
    internal static func ==(lhs: SQL.SortDescriptor, rhs: SQL.SortDescriptor) -> Bool {
        return lhs.expression == rhs.expression && lhs.direction == rhs.direction
    }
}
