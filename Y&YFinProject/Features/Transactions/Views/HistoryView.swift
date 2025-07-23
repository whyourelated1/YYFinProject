import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable, Identifiable {
    case date = "По дате"
    case amount = "По сумме"
    var id: Self {
        self
    }
}

private enum Constants {
    static let sectionSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let verticalPaddingPeriod: CGFloat = 6
    static let periodRowHeight: CGSize = CGSize(width: 120, height: 36)
    static let periodRowCornerRadius: CGFloat = 8
    static let segmentPickerWidth: CGFloat = 200
    static let periodVerticalDividerPadding: CGFloat = 12
    static let amountSectionVerticalPadding: CGFloat = 12
    static let captionSpacing: CGFloat = 16
    static let operationIconSize: CGFloat = 32
    static let operationIconOverlayPadding: CGFloat = 12
    static let operationRowSpacing: CGFloat = 12
    static let operationRowVerticalPadding: CGFloat = 8
    static let dividerIndent: CGFloat = 44
}

struct HistoryView: View {
    let direction: Direction
    let client: NetworkClient
    let accountId: Int
    let modelContainer: ModelContainer

    @AppStorage("selectedCurrency") private var currencyCode: String = Currency.rub.rawValue
    @StateObject private var vm: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sortBy: SortOption = .date
    @State private var activeForm: AddTransactionForm?

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    init(direction: Direction, client: NetworkClient, accountId: Int, modelContainer: ModelContainer) {
        self.direction = direction
        self.client = client
        self.accountId = accountId
        self.modelContainer = modelContainer
        _vm = StateObject(wrappedValue: HistoryViewModel(
            direction: direction,
            client: client,
            accountId: accountId,
            modelContainer: modelContainer
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if vm.isLoading {
                    LoadingView()
                } else {
                    VStack(spacing: Constants.sectionSpacing) {
                        Text("Моя история")
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Constants.horizontalPadding)

                        VStack(spacing: 0) {
                            periodRow(title: "Начало", date: $vm.startDate)
                            Divider()
                            periodRow(title: "Конец", date: $vm.endDate)
                            Divider()
                            HStack {
                                Text("Сортировка").font(.body)
                                Spacer()
                                Picker("", selection: $sortBy) {
                                    ForEach(SortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: Constants.segmentPickerWidth)
                            }
                            .padding(.vertical, Constants.periodVerticalDividerPadding)
                            .padding(.horizontal, Constants.horizontalPadding)
                            Divider()
                            HStack {
                                Text("Сумма")
                                Spacer()
                                let formattedTotal = vm.total.formatted(
                                    .currency(code: currencyCode)
                                        .locale(Locale(identifier: "ru_RU"))
                                        .precision(.fractionLength(0))
                                )
                                Text(formattedTotal)
                            }
                            .padding(.vertical, Constants.amountSectionVerticalPadding)
                            .padding(.horizontal, Constants.horizontalPadding)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(Constants.periodRowCornerRadius)
                        .padding(.horizontal, Constants.horizontalPadding)

                        Text("ОПЕРАЦИИ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Constants.horizontalPadding)

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(sortedTransactions, id: \.id) { tx in
                                    operationRow(tx)
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(Constants.periodRowCornerRadius)
                            .padding(.horizontal, Constants.horizontalPadding)
                        }

                        Spacer(minLength: Constants.sectionSpacing)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(Color(hex: "#6F5DB7"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AnalysisViewControllerWrapper(
                            client: client,
                            accountId: accountId,
                            direction: direction,
                            modelContainer: modelContainer
                        )
                        .edgesIgnoringSafeArea(.top)
                        .navigationBarBackButtonHidden(true)
                    } label: {
                        Image(systemName: "doc")
                            .foregroundColor(Color(hex: "#6F5DB7"))
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $activeForm) { form in
            AddTransactionView(
                mode: form,
                client: client,
                accountId: accountId,
                modelContainer: modelContainer
            )
        }
        .onChange(of: activeForm) {
            if $1 == nil {
                Task { await vm.load() }
            }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { vm.alertError != nil },
            set: { _ in vm.alertError = nil }
        )) {
            Button("Ок", role: .cancel) { }
        } message: {
            Text(vm.alertError ?? "")
        }
        .onChange(of: vm.startDate) { _ in Task { await vm.load() } }
        .onChange(of: vm.endDate) { _ in Task { await vm.load() } }
    }

    private var sortedTransactions: [Transaction] {
        switch sortBy {
        case .date:
            return vm.transactions.sorted { $0.transactionDate < $1.transactionDate }
        case .amount:
            return vm.transactions.sorted { $0.amount < $1.amount }
        }
    }

    @ViewBuilder
    private func periodRow(title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            ZStack {
                Text(df.string(from: date.wrappedValue))
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(width: Constants.periodRowHeight.width, height: Constants.periodRowHeight.height)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(Constants.periodRowCornerRadius)
                DatePicker("", selection: date, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.accentColor)
                    .frame(width: Constants.periodRowHeight.width, height: Constants.periodRowHeight.height)
                    .blendMode(.destinationOver)
            }
        }
        .padding(.vertical, Constants.verticalPaddingPeriod)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    private func operationRow(_ tx: Transaction) -> some View {
        Button {
            activeForm = .edit(transaction: tx)
        } label: {
            HStack(spacing: Constants.operationRowSpacing) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: Constants.operationIconSize, height: Constants.operationIconSize)
                    .overlay(Text(String(tx.category.emoji)).font(.body))

                VStack(alignment: .leading, spacing: Constants.captionSpacing) {
                    Text(tx.category.name).font(.body)
                    if let c = tx.comment {
                        Text(c).font(.caption2).foregroundColor(.gray)
                    }
                }

                Spacer()

                let formattedAmount = tx.amount.formatted(
                    .currency(code: currencyCode)
                        .locale(Locale(identifier: "ru_RU"))
                        .precision(.fractionLength(0))
                )
                Text(formattedAmount)
                    .font(.body)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, Constants.operationRowVerticalPadding)
            .padding(.horizontal, Constants.operationIconOverlayPadding)
        }
        .buttonStyle(.plain)
        Divider().padding(.leading, Constants.dividerIndent)
    }
}
