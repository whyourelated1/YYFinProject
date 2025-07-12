import UIKit

final class AnalysisViewController: UIViewController {
    private let direction: TransactionCategory.Direction
    private let tableView = UITableView()
    private let viewModel: HistoryViewModel
    private let filterHeaderView = FilterHeaderView()

    init(direction: TransactionCategory.Direction) {
        self.direction = direction
        self.viewModel = HistoryViewModel(direction: direction)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupFilterHeader()
        setupTableView()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Анализ"
        navigationItem.largeTitleDisplayMode = .always

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        backButton.tintColor = UIColor(named: "Accent")
        navigationItem.leftBarButtonItem = backButton
    }

    
    private func setupFilterHeader() {
        filterHeaderView.configure(
            startDate: viewModel.startDate,
            endDate: viewModel.endDate,
            selectedSort: viewModel.selectedSort,
            totalAmount: viewModel.totalAmount
        )
        
        filterHeaderView.onStartDateChanged = { [weak self] date in
            self?.viewModel.startDate = date
        }
        
        filterHeaderView.onEndDateChanged = { [weak self] date in
            self?.viewModel.endDate = date
        }
        
        filterHeaderView.onSortOptionSelected = { [weak self] option in
            self?.viewModel.selectedSort = option
        }
        
        view.addSubview(filterHeaderView)
        filterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filterHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            filterHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filterHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.register(
            AnalysisTransactionCell.self,
            forCellReuseIdentifier: AnalysisTransactionCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 65
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterHeaderView.bottomAnchor, constant: 50),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "Операции"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .lightGray
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: -10)
        ])
    }
    
    private func setupBindings() {
        viewModel.onTransactionsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.filterHeaderView.configure(
                    startDate: self?.viewModel.startDate ?? Date(),
                    endDate: self?.viewModel.endDate ?? Date(),
                    selectedSort: self?.viewModel.selectedSort ?? .byDate,
                    totalAmount: self?.viewModel.totalAmount ?? 0
                )
            }
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(viewModel.visibleTransactions.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.visibleTransactions.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "За данный период транзакций нет"
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AnalysisTransactionCell.reuseIdentifier,
            for: indexPath
        ) as? AnalysisTransactionCell else {
            return UITableViewCell()
        }
        
        let transaction = viewModel.visibleTransactions[indexPath.row]
        cell.configure(with: transaction, totalAmount: viewModel.totalAmount)
        
        if indexPath.row == 0 {
            cell.roundCorners(.top, radius: 12)
        }
        
        if indexPath.row == viewModel.visibleTransactions.count - 1 {
            cell.roundCorners(.bottom, radius: 12)
        }
        
        return cell
    }
}
