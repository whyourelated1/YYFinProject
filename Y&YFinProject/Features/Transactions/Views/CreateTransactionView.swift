import SwiftUI //шаблонка на окно создания транзакции по +

struct CreateTransactionView: View {
    let direction: TransactionCategory.Direction
    
    @Environment(\.dismiss) var dismiss
    @State private var amount: Decimal = 0
    @State private var comment: String = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Сумма")) {
                    TextField("Введите сумму", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Дата")) {
                    DatePicker("Дата", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Комментарий")) {
                    TextField("Например: обед", text: $comment)
                }
                
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Отмена")
                }
            }
            .navigationTitle(direction == .income ? "Мои Доходы" : "Мои Расходы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button{
                        dismiss()
                    } label: {
                        HStack {
                            Text("Назад")
                        }
                    }
                    .foregroundStyle(.indigo)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Text("Сохранить")
                    }
                    .foregroundStyle(.indigo)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
