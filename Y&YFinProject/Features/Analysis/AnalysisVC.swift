import UIKit
import Combine
import SwiftUI
import SwiftData

final class AnalysisViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    private let viewModel: AnalysisViewModel
    private var cancellables = Set<AnyCancellable>()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let sumLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let sortControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["По дате", "По сумме"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentTintColor = .white
        control.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
        return control
    }()

    init(client: NetworkClient, accountId: Int, direction: Direction, modelContainer: ModelContainer) {
        self.viewModel = AnalysisViewModel(
            client: client,
            accountId: accountId,
            direction: direction,
            modelContainer: modelContainer
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.tintColor = UIColor(hex: "#6F5DB7")

        setupCustomHeader()
        setupSubviews()
        bindViewModel()
    }

    private func setupCustomHeader() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("Назад", for: .normal)
        backButton.setTitleColor(UIColor(hex: "#6F5DB7"), for: .normal)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: "#6F5DB7")
        backButton.titleLabel?.font = .systemFont(ofSize: 17)
        backButton.semanticContentAttribute = .forceLeftToRight
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        let backStack = UIStackView(arrangedSubviews: [backButton, UIView()])
        backStack.axis = .horizontal
        backStack.spacing = 8
        backStack.alignment = .center
        backStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Анализ"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backStack)
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: backStack.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    private func setupSubviews() {
        for picker in [startDatePicker, endDatePicker] {
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .compact
            picker.tintColor = UIColor(named: "AccentColor") ?? .systemGreen
            clearDatePickerBackground(picker)
        }

        startDatePicker.addTarget(self, action: #selector(didChangeStart), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(didChangeEnd), for: .valueChanged)
        sortControl.addTarget(self, action: #selector(sortOptionChanged(_:)), for: .valueChanged)

        sumLabel.font = .systemFont(ofSize: 19)
        sumLabel.textAlignment = .right

        let periodStack = UIStackView(arrangedSubviews: [
            labeledRow(title: "Период: начало", control: pickerContainer(startDatePicker)),
            separatorView(),
            labeledRow(title: "Период: конец", control: pickerContainer(endDatePicker)),
            separatorView(),
            labeledRow(title: "Сортировка", control: sortControl),
            separatorView(),
            labeledRow(title: "Сумма", control: sumLabel)
        ])
        periodStack.axis = .vertical
        periodStack.spacing = 1
        periodStack.layer.cornerRadius = 12
        periodStack.backgroundColor = .systemBackground
        periodStack.clipsToBounds = true
        periodStack.translatesAutoresizingMaskIntoConstraints = false

        let operationsHeader = UILabel()
        operationsHeader.text = "ОПЕРАЦИИ"
        operationsHeader.font = UIFont.preferredFont(forTextStyle: .caption1)
        operationsHeader.textColor = .secondaryLabel
        operationsHeader.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(AnalysisCell.self, forCellReuseIdentifier: AnalysisCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true

        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        view.addSubview(periodStack)
        view.addSubview(operationsHeader)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            periodStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            periodStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            periodStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            operationsHeader.topAnchor.constraint(equalTo: periodStack.bottomAnchor, constant: 16),
            operationsHeader.leadingAnchor.constraint(equalTo: periodStack.leadingAnchor),
            operationsHeader.trailingAnchor.constraint(equalTo: periodStack.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: operationsHeader.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func bindViewModel() {
        startDatePicker.date = viewModel.startDate
        endDatePicker.date = viewModel.endDate
        updateSum()

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                loading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$alertMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showErrorAlert(message)
            }
            .store(in: &cancellables)

        viewModel.onUpdate = { [weak self] in
            self?.updateSum()
            self?.tableView.reloadData()
        }
    }

    private func updateSum() {
        let currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "RUB"
        sumLabel.text = formatCurrency(viewModel.total, code: currencyCode)
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .cancel))
        present(alert, animated: true)
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    private func labeledRow(title: String, control: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        if title.contains("начало") || title.contains("конец") {
            label.widthAnchor.constraint(equalToConstant: 200).isActive = true
        }

        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        return row
    }

    private func pickerContainer(_ picker: UIDatePicker) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(named: "AccentColor")?.withAlphaComponent(0.2)
            ?? UIColor.systemGreen.withAlphaComponent(0.15)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.setContentHuggingPriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)

        container.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])

        return container
    }

    private func clearDatePickerBackground(_ picker: UIDatePicker) {
        func clearSubviewsRecursively(_ view: UIView) {
            view.backgroundColor = .clear
            view.subviews.forEach { clearSubviewsRecursively($0) }
        }
        clearSubviewsRecursively(picker)
    }

    private func separatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1)
        ])
        return view
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didChangeStart() {
        let newDate = startDatePicker.date
        viewModel.startDate = newDate
        if newDate > viewModel.endDate {
            viewModel.endDate = newDate
            endDatePicker.date = newDate
        }
    }

    @objc private func didChangeEnd() {
        let newDate = endDatePicker.date
        viewModel.endDate = newDate
        if newDate < viewModel.startDate {
            viewModel.startDate = newDate
            startDatePicker.date = newDate
        }
    }

    @objc private func sortOptionChanged(_ sender: UISegmentedControl) {
        viewModel.sortOption = sender.selectedSegmentIndex == 0 ? .date : .amount
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Task {
            await viewModel.load()
        }
    }
}

extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = viewModel.transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AnalysisCell.reuseIdentifier, for: indexPath) as! AnalysisCell
        let currencyCode = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "RUB"
        cell.configure(with: tx, total: viewModel.total, currencyCode: currencyCode)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tx = viewModel.transactions[indexPath.row]
        let addTransactionView = AddTransactionView(
            mode: .edit(transaction: tx),
            client: viewModel.service.client,
            accountId: viewModel.accountId,
            modelContainer: viewModel.modelContainer
        )

        let vc = UIHostingController(rootView: addTransactionView)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) {
            vc.presentationController?.delegate = self
        }
    }

}
