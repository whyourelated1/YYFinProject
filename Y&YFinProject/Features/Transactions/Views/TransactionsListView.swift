/* Реализовать экраны Доходы сегодня / Расходы сегодня
 реализовать TransactionsListView, который параметризован направлением (доходы или расходы)
 использовать TransactionsListView для табов расходы и доходы
 в качестве источника данных использовать TransactionsService (создан в домашке 1)
 операции загружать за сегодняшний день, т е передавать в сервис начало и конец текущего дня
 "Всего" содержит сумму по всем операциям за сегодня
 ячейки списка должны загружаться лениво, потому как список операций не ограничен*/

import SwiftUI

import SwiftUI

struct TransactionsListView: View {
    let direction: TransactionCategory.Direction
    @StateObject private var viewModel = TransactionsListViewModel()
    @State private var isCreating = false
    @State private var isShowingHistory = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
              Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                VStack(spacing: 20) {
                    //заголовок и сумма
                    HStack {
                        Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
                            .font(.title)
                            .bold()
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.top)
                    
                    HStack {
                        Text("Всего")
                            .font(.body)
                        Spacer()
                        Text(viewModel.totalAmount.formatted(.currency(code: "RUB")
                            .locale(Locale(identifier: "ru_RU"))
                            .precision(.fractionLength(0))))
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    //операции
                    List {
                        Section(header: Text("ОПЕРАЦИИ").foregroundColor(.gray)) {
                            ForEach(viewModel.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }

                //"+"
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color("Accent"))
                        .clipShape(Circle())
                }
                .padding(.trailing, 25)
                .padding(.bottom, 50)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingHistory = true
                    } label: {
                        Image(systemName: "clock")
                    }
                    .foregroundStyle(.indigo)                }
            }
            .navigationDestination(isPresented: $isShowingHistory) {
                HistoryView(direction: direction)
            }
            .navigationDestination(isPresented: $isCreating) {
                CreateTransactionView(direction: direction)
            }
            .onAppear {
                let today = Calendar.current.startOfDay(for: Date())
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
                viewModel.loadTransactions(direction: direction, from: today, to: tomorrow)
            }
        }
    }
}

#Preview {
    TransactionsListView(direction: .outcome)
}
