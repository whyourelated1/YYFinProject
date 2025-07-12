/*Добавить раздел счет на SwiftUI https://www.figma.com/... в таббар
 
 На экране "Мой счет" добавляем строку с балансом
 На экране "Мой счет" добавляем строку с валютой
 График не реализовываем
 По нажатию на кнопку "Редактировать" в навбаре переходим в режим редактирования
 По нажатию на ячейку с валютой поднимается попап со списком валют (https://www.figma.com/...). При выборе новой должен обновить экран. При нажатии на уже выбранную валюту ничего не делаем.
 По нажатию на ячейку с балансом отображаем клавиатуру. Клавиатура отображается с цифрами и скрывается при свайпе по экрану.
 По нажатию на кнопку "Сохранить" (https://www.figma.com/...) в режиме редактирования возвращаемся в обычный режим
 Задание со звездочкой
 На экран "Мой счет" добавить pull to refresh и прокинуть в модель действие обновления данных.

 Задания с двумя звездочками
 Скрывать и отображать баланс по тряске девайса. Скрытие баланса сделать с эффектом анимированного спойлера (как в Telegram).
 Дать возможность вставлять баланс из буфера обмена и фильтровать невалидные для баланса символы
*/
import SwiftUI

enum Currency: String, CaseIterable, Identifiable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Американский доллар $"
        case .eur: return "Евро €"
        }
    }
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

final class CalcViewModel: ObservableObject {
    @Published var balance: String = "0"
    @Published var currency: Currency = .rub
    @Published var isEditing = false
    @Published var account: BankAccount?
    @Published var isBalanceHidden = false
    private let service = BankAccountsService()

    init() {
        Task { await refresh() }
    }
    
    func refresh() async {
        do {
            let acc = try await service.getAccount()
            account = acc
            balance = acc.balance.description
            currency = Currency(rawValue: acc.currency) ?? .rub
        } catch {
            print("Failed to refresh:", error)
        }
    }
}

struct CalcView: View {
    @StateObject private var vm = CalcViewModel()
    @Environment(\.editMode) private var editMode
    @FocusState private var balanceFieldFocused: Bool
    @State private var showCurrencyPicker = false

    var body: some View {
        ScreenContainer(title: "Мой счет") {
            VStack(alignment: .leading, spacing: 20) {
                //баланс
                HStack {
                    HStack(spacing: 8) {
                        Text("💰")
                        Text("Баланс")
                    }
                    Spacer()
                    if vm.isEditing {
                        HStack(spacing: 4) {
                            TextField("0", text: $vm.balance)
                                .keyboardType(.decimalPad)
                                .focused($balanceFieldFocused)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black)
                                .onChange(of: vm.balance) {_, newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    let parts = filtered.split(separator: ".")
                                    let cleaned: String
                                    if parts.count > 1 {
                                        cleaned = parts[0] + "." + parts[1..<parts.count].joined()
                                    } else {
                                        cleaned = filtered
                                    }
                                    if cleaned != newValue {
                                        vm.balance = cleaned
                                    }
                                }
                            Text(vm.currency.symbol)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text(vm.balance)
                                .onShake {
                                    withAnimation { vm.isBalanceHidden.toggle() }
                                }
                            Text(vm.currency.symbol)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(vm.isEditing ? Color.white : Color("Accent"))
                .cornerRadius(12)
                .onTapGesture {
                    if vm.isEditing {
                        balanceFieldFocused = true
                    }
                }
                //валюта
                HStack {
                    Text("Валюта")
                        .font(.body)
                    Spacer()
                    Text(vm.currency.symbol)
                        .font(.body)
                    if vm.isEditing {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(vm.isEditing ? Color.white : Color("Accent").opacity(0.15))
                .cornerRadius(12)
                .onTapGesture {
                    guard vm.isEditing else { return }
                    showCurrencyPicker = true
                }
                .accentColor(.indigo)
                .confirmationDialog(
                    "Валюта",
                    isPresented: $showCurrencyPicker
                ) {
                    ForEach(Currency.allCases) { cur in
                        Button(cur.displayName) {
                            if cur != vm.currency {
                                vm.currency = cur
                            }
                        }
                        .foregroundColor(.indigo)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(vm.isEditing ? "Сохранить" : "Редактировать") {
                    withAnimation {
                        if vm.isEditing {
                            editMode?.wrappedValue = .inactive
                            balanceFieldFocused = false
                        } else {
                            editMode?.wrappedValue = .active
                            balanceFieldFocused = true
                        }
                        vm.isEditing.toggle()
                    }
                }
                .foregroundColor(.indigo)
            }
        }
        .refreshable {
            await vm.refresh()
        }
    }
}

#Preview {
    CalcView()
}

