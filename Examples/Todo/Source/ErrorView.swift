import UIKit

final class ErrorView: UIView {
    init(header: String, body: String) {
        super.init(frame: .zero)

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .preferredFont(forTextStyle: .title1)
        headerLabel.text = header
        headerLabel.textAlignment = .center
        addSubview(headerLabel)
        headerLabel.setContentHuggingPriority(.required, for: .vertical)
        headerLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.text = body
        bodyLabel.numberOfLines = 0
        addSubview(bodyLabel)
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)
        bodyLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let constraints = [
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            bodyLabel.topAnchor
                .constraintEqualToSystemSpacingBelow(headerLabel.bottomAnchor, multiplier: 1),
            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerLabel.widthAnchor.constraint(equalToConstant: 300),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            bodyLabel.widthAnchor.constraint(equalToConstant: 300),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]
        constraints.forEach(addConstraint)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
