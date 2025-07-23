import UIKit

final class FilterHeaderView: UIView {
    var onStartDateChanged: ((Date) -> Void)?
    var onEndDateChanged: ((Date) -> Void)?
    var onSortOptionSelected: ((SortOption) -> Void)?
    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let sortButton = UIButton(type: .system)
    private let totalAmountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 12
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        
        let startDateStack = createDateRow(title: "Период: начало", datePicker: startDatePicker)
        startDatePicker.datePickerMode = .date
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        let endDateStack = createDateRow(title: "Период: конец", datePicker: endDatePicker)
        endDatePicker.datePickerMode = .date
        endDatePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        
        sortButton.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        sortButton.contentHorizontalAlignment = .center
        
        let sumStack = createSumRow()
        
        stackView.addArrangedSubview(startDateStack)
        stackView.addArrangedSubview(endDateStack)
        stackView.addArrangedSubview(sortButton)
        stackView.addArrangedSubview(sumStack)
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func createDateRow(title: String, datePicker: UIDatePicker) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        datePicker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [label, datePicker])
        stack.axis = .horizontal
        return stack
    }
    
    private func createSumRow() -> UIStackView {
        let label = UILabel()
        label.text = "Сумма"
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        totalAmountLabel.textAlignment = .right
        
        let stack = UIStackView(arrangedSubviews: [label, totalAmountLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }
    
    func configure(startDate: Date, endDate: Date, selectedSort: SortOption, totalAmount: Decimal) {
        startDatePicker.date = startDate
        endDatePicker.date = endDate
        sortButton.setTitle("Сортировка: \(selectedSort.rawValue)", for: .normal)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        totalAmountLabel.text = "\(formatter.string(from: totalAmount as NSDecimalNumber) ?? "0") ₽"
    }
    
    @objc private func startDateChanged() {
        onStartDateChanged?(startDatePicker.date)
    }
    
    @objc private func endDateChanged() {
        onEndDateChanged?(endDatePicker.date)
    }
    
    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        SortOption.allCases.forEach { option in
            alert.addAction(UIAlertAction(title: option.rawValue, style: .default) { _ in
                self.onSortOptionSelected?(option)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sortButton
            popover.sourceRect = sortButton.bounds
        }
        
        window?.rootViewController?.present(alert, animated: true)
    }
}
