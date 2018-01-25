import UIKit

final class TaskCell: UITableViewCell {
    var task: Task? {
        didSet {
            guard let task = task else {
                accessoryType = .none
                textLabel?.text = nil
                return
            }
            accessoryType = task.isCompleted ? .checkmark : .none
            textLabel?.text = task.text
            textLabel?.textColor = task.isCompleted ? UIColor(white: 0.3, alpha: 1) : .darkText
        }
    }
}
