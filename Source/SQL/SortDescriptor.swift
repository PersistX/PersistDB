import Foundation

extension SQL {
    /// A value representing how results should be sorted.
    public struct SortDescriptor {
        /// The direction of the sort.
        public enum Direction {
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
        
        public init<Value>(_ expression: Expression<Value>, _ direction: Direction) {
            self.expression = expression.expression
            self.direction = direction
        }
        
        internal var sql: SQL {
            return expression.sql + " " + direction.sql
        }
    }
}

extension SQL.SortDescriptor: Hashable {
    public var hashValue: Int {
        return expression.hashValue
    }
    
    public static func ==(lhs: SQL.SortDescriptor, rhs: SQL.SortDescriptor) -> Bool {
        return lhs.expression == rhs.expression && lhs.direction == rhs.direction
    }
}
