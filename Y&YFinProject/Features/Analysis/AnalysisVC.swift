import UIKit
import Combine
import SwiftUI
import SwiftData
import PieChart


final class AnalysisViewController: UIViewController {
    // MARK: – UI
    private let pieChartView = PieChartView()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker   = UIDatePicker()
    private let sortControl     = UISegmentedControl(items: ["По дате", "По сумме"])
    private let sumLabel        = UILabel()
    private let tableView       = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: – State / VM
    private let viewModel: AnalysisViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: – Init
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
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: – VC lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupSubviews()
        bindViewModel()
    }

    // MARK: – Setup
    private func configureAppearance() {
        view.backgroundColor = .systemGroupedBackground
        view.tintColor       = UIColor(hex: "#6F5DB7")
    }

    private func setupSubviews() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("Назад", for: .normal)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: "#6F5DB7")
        backButton.titleLabel?.font = .systemFont(ofSize: 17)
        backButton.semanticContentAttribute = .forceLeftToRight
        backButton.addTarget(self, action: #selector(onBackTap), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [backButton, UIView()])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Анализ"
        titleLabel.font = .boldSystemFont(ofSize: 34)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        configureDatePicker(startDatePicker)
        configureDatePicker(endDatePicker)
        sortControl.selectedSegmentTintColor = .white
        sortControl.selectedSegmentIndex = 0
        sortControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        sortControl.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
        sortControl.addTarget(self, action: #selector(onSortChanged), for: .valueChanged)

        sumLabel.font = .systemFont(ofSize: 19)
        sumLabel.textAlignment = .right

        let periodStack = UIStackView(arrangedSubviews: [
            makeRow(title: "Период: начало", control: wrapPicker(startDatePicker)),
            separator(),
            makeRow(title: "Период: конец",   control: wrapPicker(endDatePicker)),
            separator(),
            makeRow(title: "Сортировка",       control: sortControl),
            separator(),
            makeRow(title: "Сумма",            control: sumLabel)
        ])
        periodStack.axis = .vertical
        periodStack.spacing = 1
        periodStack.layer.cornerRadius = 12
        periodStack.backgroundColor = .systemBackground
        periodStack.translatesAutoresizingMaskIntoConstraints = false

        pieChartView.translatesAutoresizingMaskIntoConstraints = false

        let operationsHeader = UILabel()
        operationsHeader.text = "ОПЕРАЦИИ"
        operationsHeader.font = UIFont.preferredFont(forTextStyle: .caption1)
        operationsHeader.textColor = .secondaryLabel
        operationsHeader.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(AnalysisCell.self, forCellReuseIdentifier: AnalysisCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        [headerStack, titleLabel, periodStack, pieChartView, operationsHeader, tableView, activityIndicator]
            .forEach(view.addSubview)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            periodStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            periodStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            periodStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            pieChartView.topAnchor.constraint(equalTo: periodStack.bottomAnchor, constant: 16),
            pieChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pieChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor,
                                                     multiplier: 0.6),

            operationsHeader.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
            operationsHeader.leadingAnchor.constraint(equalTo: pieChartView.leadingAnchor),

            tableView.topAnchor.constraint(equalTo: operationsHeader.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        startDatePicker.date = viewModel.startDate
        endDatePicker.date   = viewModel.endDate
    }

    // MARK: – Binding
    private func bindViewModel() {
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
            .sink { [weak self] msg in self?.presentAlert(msg) }
            .store(in: &cancellables)

        viewModel.onUpdate = { [weak self] in
            self?.updateSum()
            self?.updateChart()
            self?.tableView.reloadData()
        }
    }

    // MARK: – Chart / Sum helpers
    private func updateChart() {
        let groups = Dictionary(grouping: viewModel.transactions, by: { $0.category.name })

        guard groups.isEmpty == false else {
            pieChartView.entities = [Entity(value: 1, label: "Нет данных")]
            pieChartView.isHidden = false
            return
        }

        let entities = groups.map { name, txs -> Entity in
            let sum = txs.reduce(Decimal.zero) { $0 + $1.amount }
            return Entity(value: sum, label: name)
        }.sorted { $0.value > $1.value }

        pieChartView.isHidden = false
        pieChartView.entities = entities
    }

    private func updateSum() {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "RUB"
        sumLabel.text = formatCurrency(viewModel.total, code: code)
    }

    // MARK: – Actions
    @objc private func onBackTap() { navigationController?.popViewController(animated: true) }

    @objc private func onSortChanged(_ sender: UISegmentedControl) {
        viewModel.sortOption = sender.selectedSegmentIndex == 0 ? .date : .amount
    }

    @objc private func onStartChanged() {
        let d = startDatePicker.date
        viewModel.startDate = d
        if d > viewModel.endDate {
            viewModel.endDate = d
            endDatePicker.date = d
        }
    }

    @objc private func onEndChanged() {
        let d = endDatePicker.date
        viewModel.endDate = d
        if d < viewModel.startDate {
            viewModel.startDate = d
            startDatePicker.date = d
        }
    }

    // MARK: – Utils
    private func configureDatePicker(_ picker: UIDatePicker) {
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.tintColor = UIColor(named: "AccentColor") ?? .systemGreen
        picker.translatesAutoresizingMaskIntoConstraints = false
        clearBg(for: picker)
        if picker === startDatePicker {
            picker.addTarget(self, action: #selector(onStartChanged), for: .valueChanged)
        } else {
            picker.addTarget(self, action: #selector(onEndChanged), for: .valueChanged)
        }
    }

    private func makeRow(title: String, control: UIView) -> UIStackView {
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
        row.layoutMargins = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return row
    }

    private func wrapPicker(_ picker: UIDatePicker) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(named: "AccentColor")?.withAlphaComponent(0.2)
            ?? UIColor.systemGreen.withAlphaComponent(0.15)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        picker.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        return container
    }

    private func separator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func clearBg(for picker: UIDatePicker) {
        func clear(_ v: UIView) {
            v.backgroundColor = .clear
            v.subviews.forEach(clear)
        }
        clear(picker)
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = code
        nf.locale = Locale(identifier: "ru_RU")
        nf.maximumFractionDigits = 2
        return nf.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: – Table
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = viewModel.transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AnalysisCell.reuseIdentifier, for: indexPath) as! AnalysisCell
        let code = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "RUB"
        cell.configure(with: tx, total: viewModel.total, currencyCode: code)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = viewModel.transactions[indexPath.row]
        let addView = AddTransactionView(
            mode: .edit(transaction: tx),
            client: viewModel.service.client,
            accountId: viewModel.accountId,
            modelContainer: viewModel.modelContainer
        )
        let vc = UIHostingController(rootView: addView)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) {
            vc.presentationController?.delegate = self
        }
    }
}

// MARK: – Adaptive dismissal
extension AnalysisViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Task { await viewModel.load() }
    }
}
