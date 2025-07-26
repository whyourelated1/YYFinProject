import SwiftUI
import SwiftData

struct TransactionsListView: View {
    let direction: Direction
    let client: NetworkClient
    let accountId: Int
    let modelContainer: ModelContainer

    @StateObject private var viewModel: TransactionsListViewModel
    @AppStorage("selectedCurrency") private var currencyCode: String = Currency.rub.rawValue
    @State private var activeForm: AddTransactionForm?

    init(direction: Direction, client: NetworkClient, accountId: Int, modelContainer: ModelContainer) {
        self.direction = direction
        self.client = client
        self.accountId = accountId
        self.modelContainer = modelContainer
        _viewModel = StateObject(
            wrappedValue: TransactionsListViewModel(
                direction: direction,
                client: client,
                accountId: accountId,
                modelContainer: modelContainer
            )
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HistoryView(
                            direction: direction,
                            client: client,
                            accountId: accountId,
                            modelContainer: modelContainer
                        )
                    } label: {
                        Image(systemName: "clock")
                            .foregroundColor(Color(hex: "#6F5DB7"))
                    }
                }
            }
            .overlay(addButton, alignment: .bottomTrailing)
            .fullScreenCover(item: $activeForm) { form in
                AddTransactionView(mode: form, client: client, accountId: accountId, modelContainer: modelContainer )
            }
            .onChange(of: activeForm) {
                if $1 == nil {
                    Task { await viewModel.loadToday() }
                }
            }
            .alert("Ошибка", isPresented: Binding(get: {
                viewModel.alertError != nil
            }, set: { _ in
                viewModel.alertError = nil
            })) {
                Button("Ок", role: .cancel) { }
            } message: {
                Text(viewModel.alertError ?? "")
            }
            .onAppear {
                Task { await viewModel.loadToday() }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            totalView
            Text("ОПЕРАЦИИ")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.transactions, id: \.id) { tx in
                        Button {
                            activeForm = .edit(transaction: tx)
                        } label: {
                            TransactionRowView(
                                transaction: tx,
                                currencyCode: currencyCode,
                                direction: direction
                            )
                        }
                        .buttonStyle(.plain)

                        if tx.id != viewModel.transactions.last?.id {
                            Divider()
                                .padding(.leading, direction == .outcome ? 44 : 12)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
            Spacer(minLength: 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var headerView: some View {
        Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .font(.largeTitle.bold())
            .padding(.horizontal, 16)
    }

    private var totalView: some View {
        HStack {
            Text("Всего").font(.headline)
            Spacer()
            Text(viewModel.total.formatted(
                .currency(code: currencyCode)
                    .locale(Locale(identifier: "ru_RU"))
                    .precision(.fractionLength(0))
            ))
            .font(.headline)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var addButton: some View {
        Button {
            activeForm = .create(direction: direction)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(16)
                .background(Circle().fill(Color.accentColor))
        }
        .padding(.trailing, 16)
        .padding(.bottom, 24)
    }
}
