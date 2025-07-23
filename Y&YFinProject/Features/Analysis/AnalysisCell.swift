import UIKit

final class AnalysisCell: UITableViewCell {
    static let reuseIdentifier = "AnalysisCell"

    private let iconView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let commentLabel = UILabel()
    private let percentLabel = UILabel()
    private let amountLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        setupSubviews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupSubviews() {
        // Icon
        iconView.backgroundColor = .systemGreen.withAlphaComponent(0.2)
        iconView.layer.cornerRadius = 16
        emojiLabel.font = .systemFont(ofSize: 17)
        iconView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])

        titleLabel.font = .systemFont(ofSize: 17)
        commentLabel.font = .systemFont(ofSize: 13)
        commentLabel.textColor = .secondaryLabel
        percentLabel.font = .systemFont(ofSize: 13)
        percentLabel.textColor = .secondaryLabel
        percentLabel.textAlignment = .right
        amountLabel.font = .systemFont(ofSize: 17)
        amountLabel.textAlignment = .right
        chevron.tintColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, commentLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let valueStack = UIStackView(arrangedSubviews: [percentLabel, amountLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 2
        valueStack.alignment = .trailing

        let rightSideStack = UIStackView(arrangedSubviews: [valueStack, chevron])
        rightSideStack.axis = .horizontal
        rightSideStack.spacing = 8
        rightSideStack.alignment = .center

        let hStack = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), rightSideStack])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.isLayoutMarginsRelativeArrangement = true
        hStack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }


    func configure(with tx: Transaction, total: Decimal, currencyCode: String) {
        emojiLabel.text = String(tx.category.emoji)
        titleLabel.text = tx.category.name
        commentLabel.text = tx.comment
        commentLabel.isHidden = (tx.comment == nil)

        let fraction = (total == 0) ? 0 : (tx.amount / total * 100) as NSDecimalNumber
        percentLabel.text = String(format: "%.0f%%", fraction.doubleValue)

        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = currencyCode
        fmt.locale = Locale(identifier: "ru_RU")
        amountLabel.text = fmt.string(from: tx.amount as NSDecimalNumber)
    }

}
