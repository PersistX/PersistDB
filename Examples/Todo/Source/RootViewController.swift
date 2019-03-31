import PersistDB
import UIKit

final class RootViewController: UIViewController {
    enum Content {
        case view(UIView)
        case viewController(UIViewController)
    }

    enum State {
        case loading
        case opened(Store<ReadWrite>)
        case failed(OpenError)
    }

    var content: Content? {
        willSet {
            switch content {
            case let .view(view)?:
                view.removeFromSuperview()

            case let .viewController(vc)?:
                vc.willMove(toParent: nil)
                vc.view.removeFromSuperview()
                vc.removeFromParent()

            case nil:
                break
            }
        }
        didSet {
            switch content {
            case let .view(subview)?:
                subview.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(subview)
                view.addConstraint(subview.centerXAnchor.constraint(equalTo: view.centerXAnchor))
                view.addConstraint(subview.centerYAnchor.constraint(equalTo: view.centerYAnchor))

            case let .viewController(vc)?:
                vc.willMove(toParent: self)
                view.addSubview(vc.view)
                let constraints = [
                    vc.view.topAnchor.constraint(equalTo: view.topAnchor),
                    vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                ]
                constraints.forEach(view.addConstraint)
                addChild(vc)

            case nil:
                break
            }
        }
    }

    var state: State = .loading {
        didSet {
            switch state {
            case .loading:
                let loadingView = UIActivityIndicatorView(style: .gray)
                loadingView.translatesAutoresizingMaskIntoConstraints = false
                content = .view(loadingView)
                loadingView.startAnimating()

            case let .opened(store):
                content = .viewController(TaskListViewController(store: store))

            case let .failed(error):
                let errorView = ErrorView(
                    header: "Could not open library",
                    body: error.localizedDescription
                )
                content = .view(errorView)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        state = .loading
        Store<ReadWrite>
            .open(libraryNamed: "Todo", for: [Task.self])
            .startWithResult { result in
                switch result {
                case let .success(store):
                    self.state = .opened(store)
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
    }
}
