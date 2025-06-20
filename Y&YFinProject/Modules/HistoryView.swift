/*Реализовать экран Моя история
 в качестве начала периода задается день без времени. Началом считается 00:00 указанного дня
 в качестве конца периода задается день без времени. Концом считается 23:59 указанного дня. Таким образом если указать одну и туже дату в начале и конце перода, то следует выводить операции с 00:00 по 23:59 этого дня
 в качестве конца периода по-умолчанию использовать текущий день
 в качестве начала периода по-умолчанию использовать дату месяц назад, т е период по-умолчанию - месяц
 оба поля можно редактировать
 "сумма" содержит сумму по всем операциям за период
 при открытии экрана и при каждом изменении полей следует актуализировать список с помощью TransactionsService
 экран должен быть параметризован направлением операций Direction. При переходе с экрана "Доходы сегодня" отображать только доходы, а при переходе с "Расходы сегодня" - только расходы
 элементы списка должны загружаться лениво*/

import SwiftUI

struct HistoryView: View {
    let direction: TransactionCategory.Direction
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Моя история")
                                .font(.title)
                                .bold()
                            Spacer()
                        }
                        .padding(.top)
                        .padding(.horizontal)
                        //выбор даты
                        VStack(spacing: 0) {
                            DatePicker(selection: $viewModel.startDate, displayedComponents: .date) {
                                Text("Начало")
                            }
                            .padding()
                            
                            Divider().padding(.leading)
                            
                            DatePicker(selection: $viewModel.endDate, displayedComponents: .date) {
                                Text("Конец")
                            }
                            .padding()

                            Divider().padding(.leading)
                            
                            HStack {
                                Text("Сумма")
                                Spacer()
                                Text(viewModel.totalAmount.formatted(.currency(code: "RUB").locale(Locale(identifier: "ru_RU"))))
                            }
                            .padding()
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        Spacer()
                        //cортировка (**)
                        Section(
                            header:
                                HStack {
                                    Text("ОПЕРАЦИИ")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.leading)
                        ) {
                            if !viewModel.transactions.isEmpty {
                                Picker("Сортировка", selection: $viewModel.sortingOption) {
                                    Text("По дате").tag(HistoryViewModel.SortingOption.date)
                                    Text("По сумме").tag(HistoryViewModel.SortingOption.amount)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal)
                                .onChange(of: viewModel.sortingOption) {
                                    viewModel.sortTransactions()
                                }
                            }
                        }
                        //cписок (ленивый)
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button{
                            dismiss()
                        } label: {
                            HStack {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                            }
                        }
                        .foregroundStyle(.indigo)
                        }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                        } label: {
                            Image(systemName: "doc")
                        }
                        .foregroundStyle(.indigo)
                    }
                    
                    }
                    
                }
                .onAppear {
                    viewModel.direction = direction
                    viewModel.loadTransactions()
                }
            }
        .navigationBarBackButtonHidden(true)
        }
    }

@MainActor
final class HistoryViewModel: ObservableObject, Sendable {
    enum SortingOption {
        case date
        case amount
    }
    
    var direction: TransactionCategory.Direction = .outcome
    @Published var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var endDate = Date()
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var sortingOption: SortingOption = .date
    
    private let service = TransactionsService()
    
    func loadTransactions() {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!

        Task {
            do {
                let transactions = try await service.fetchTransactions(direction: direction, from: start, to: end)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.transactions = transactions
                    self.totalAmount = transactions.reduce(0) { $0 + $1.amount }
                    self.sortTransactions()
                }
            } catch {
                print("Error loading transactions: \(error)")
            }
        }
    }
    
    func sortTransactions() {
        switch sortingOption {
        case .date:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .amount:
            transactions.sort { $0.amount > $1.amount }
        }
    }
    
    //подгон дат (*)
    func adjustDates() {
        if startDate > endDate {
            endDate = startDate
        }
    }
}

#Preview {
    HistoryView(direction: .outcome)
}
