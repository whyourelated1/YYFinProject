import UIKit

final class AnalysisTransactionCell: UITableViewCell {
    static let reuseIdentifier = "AnalysisTransactionCell"
    
    private let emojiLabel = UILabel()
    private let categoryLabel = UILabel()
    private let commentLabel = UILabel()
    private let amountLabel = UILabel()
    private let percentageLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16.5
        view.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        emojiLabel.font = .preferredFont(forTextStyle: .title2)
        emojiLabel.textAlignment = .center
        
        bubbleView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
        
        categoryLabel.font = .preferredFont(forTextStyle: .body)
        
        commentLabel.font = .preferredFont(forTextStyle: .caption2)
        commentLabel.textColor = .gray
        
        amountLabel.font = .preferredFont(forTextStyle: .body)
        amountLabel.textAlignment = .right
        
        percentageLabel.font = .preferredFont(forTextStyle: .caption2)
        percentageLabel.textColor = .gray
        percentageLabel.textAlignment = .right
        
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .gray
        chevronImageView.contentMode = .scaleAspectFit
        
        let textStack = UIStackView(arrangedSubviews: [categoryLabel, commentLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        
        let amountStack = UIStackView(arrangedSubviews: [percentageLabel, amountLabel])
        amountStack.axis = .vertical
        amountStack.spacing = 2
        amountStack.alignment = .trailing
        
        let mainStack = UIStackView(arrangedSubviews: [bubbleView, textStack, UIView(), amountStack, chevronImageView])
        mainStack.axis = .horizontal
        mainStack.spacing = 15
        mainStack.alignment = .center
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bubbleView.widthAnchor.constraint(equalToConstant: 33),
            bubbleView.heightAnchor.constraint(equalToConstant: 33),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with transaction: Transaction, totalAmount: Decimal) {
        // Обработка категории
        if let category = transaction.category {
            emojiLabel.text = category.emoji.description
            categoryLabel.text = category.name
        } else {
            emojiLabel.text = "❓"
            categoryLabel.text = "Без категории"
        }
        
        commentLabel.text = transaction.comment
        commentLabel.isHidden = transaction.comment?.isEmpty ?? true
        
        let currencySymbol: String
        if let account = transaction.account {
            currencySymbol = account.currency
        } else {
            currencySymbol = "₽"
        }
        
        amountLabel.text = "\(transaction.amount.description) \(currencySymbol)"
        
        if totalAmount > 0 {
            let percentage = (transaction.amount as NSDecimalNumber)
                .dividing(by: totalAmount as NSDecimalNumber)
                .multiplying(by: 100)
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            
            percentageLabel.text = "\(formatter.string(from: percentage) ?? "0")%"
        } else {
            percentageLabel.text = "0%"
        }
    }
}
