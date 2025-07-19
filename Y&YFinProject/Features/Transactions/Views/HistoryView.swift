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
    let direction: Direction
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAnalysis = false

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

                NavigationLink(
                    destination: AnalysisViewControllerWrapperPush(direction: direction),
                    isActive: $showAnalysis,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
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
                        showAnalysis = true
                    } label: {
                        Image(systemName: "doc")
                    }
                    .foregroundStyle(.indigo)
                }
            }
        }
    }
}


/*struct AnalysisViewControllerWrapperPush: UIViewControllerRepresentable {
    let direction: TransactionCategory.Direction

    func makeUIViewController(context: Context) -> AnalysisViewController {
        return AnalysisViewController(direction: direction)
    }

    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {}
}*/

