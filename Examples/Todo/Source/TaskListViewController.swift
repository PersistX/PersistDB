import PersistDB
import ReactiveSwift
import Schemata
import UIKit

/// The view controller responsible for showing the list of tasks.
final class TaskListViewController: UIViewController {
    /// The different segments/tabs within the task list.
    enum Segment: Int {
        /// All tasks--whether incomplete or complete
        case all
        /// The incomplete tasks
        case active
        /// The completed tasks
        case completed

        /// The title of the segment.
        var title: String {
            switch self {
            case .all:
                return "All"
            case .active:
                return "Active"
            case .completed:
                return "Completed"
            }
        }

        /// The query matching the tasks for the segment.
        var query: Query<Task> {
            switch self {
            case .all:
                return Task.all
            case .active:
                return Task.active
            case .completed:
                return Task.completed
            }
        }
    }

    /// The store backing the application.
    let store: Store

    /// The currently viewed segment.
    ///
    /// `MutableProperty` comes from ReactiveSwift. It allows this property to be observed,
    /// making updating the query and store observation easy.
    var segment = MutableProperty<Segment>(.all)

    /// The table model backing the table view.
    var table: Table<None, Task> = .init() {
        didSet {
            let diff = table.diff(from: oldValue)

            tableView.performBatchUpdates({
                tableView.insertSections(diff.insertedSections, with: .fade)
                tableView.deleteSections(diff.deletedSections, with: .fade)
                diff.movedSections.forEach(tableView.moveSection)

                tableView.insertRows(at: diff.insertedRows, with: .fade)
                tableView.deleteRows(at: diff.deletedRows, with: .fade)
                diff.movedRows.forEach(tableView.moveRow)
            })

            for indexPath in diff.updatedRows {
                let cell = tableView.cellForRow(at: indexPath) as? TaskCell
                if let cell = cell {
                    cell.task = table[indexPath]
                }
            }
        }
    }

    /// The control to switch between the different segments.
    let segmentedControl = UISegmentedControl(items: [
        Segment.all.title,
        Segment.active.title,
        Segment.completed.title,
    ])

    /// The text field for adding tasks.
    let inputField = UITextField()

    /// The table of tasks.
    let tableView = UITableView()

    init(store: Store) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = Segment.all.rawValue
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentDidChange), for: .valueChanged)

        inputField.placeholder = "What needs to be done?"
        inputField.returnKeyType = .done
        inputField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputField)
        inputField.delegate = self

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            TaskCell.self,
            forCellReuseIdentifier: String(describing: Task.self)
        )

        let constraints = [
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            inputField.topAnchor
                .constraintEqualToSystemSpacingBelow(segmentedControl.bottomAnchor, multiplier: 2),
            inputField.leadingAnchor
                .constraintEqualToSystemSpacingAfter(view.leadingAnchor, multiplier: 1),
            view.trailingAnchor
                .constraintEqualToSystemSpacingAfter(inputField.trailingAnchor, multiplier: 1),

            tableView.topAnchor.constraint(equalTo: inputField.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]
        constraints.forEach(view.addConstraint)

        // Observe the tasks matching the query for the currently selected segment.
        segment
            .producer
            .map { $0.query }
            .flatMap(.latest) { [store = self.store] query in
                return store.observe(query)
            }
            .startWithValues { [weak self] resultSet in
                self?.table.resultSet = resultSet
            }
    }

    @objc func segmentDidChange() {
        segment.value = Segment(rawValue: segmentedControl.selectedSegmentIndex)!
    }
}

extension TaskListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        store.insert(Task.newTask(text: textField.text ?? ""))
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

extension TaskListViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return table.sectionCount
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return table.rowCount(inSection: section)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: String(describing: Task.self), for: indexPath)
            as! TaskCell // swiftlint:disable:this force_cast
        cell.task = table[indexPath]
        return cell
    }

    func tableView(
        _: UITableView,
        commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            store.delete(Delete(\Task.id == table[indexPath].id))
        }
    }
}

extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let task = table[indexPath]
        store.update(Update(
            predicate: \Task.id == task.id,
            valueSet: task.isCompleted ? Task.incomplete : Task.complete
        ))
    }
}
