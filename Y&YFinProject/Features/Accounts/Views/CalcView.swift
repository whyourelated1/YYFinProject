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
import Combine
import SwiftData
import Foundation
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
@MainActor
final class CalcViewModel: ObservableObject {
    @Published var bankAccount: BankAccount?
    @Published var editingBalance: String = ""
    @Published var editingCurrency: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published var alertMessage: String? = nil
    @Environment(\.editMode) private var editMode

    private var bankAccountService: BankAccountsService?
    private var modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    var formatedBalance: String {
        guard let account = bankAccount else { return "0 $" }
        return "\(account.balance) \(account.currencySymbol)"
    }

    func loadBankAccount() async {
        if bankAccountService == nil {
            guard
                let baseURL = APIKeysStorage.shared.getBaseURL(),
                let token = APIKeysStorage.shared.getToken()
            else {
                self.alertMessage = "Нет данных для подключения к API"
                return
            }
            let network = NetworkService(baseURL: baseURL, token: token, session: .shared)
            self.bankAccountService = BankAccountsService(network: network, modelContainer: modelContainer)
        }

        isLoading = true
        defer { isLoading = false }

        guard let bankAccountService else {
            alertMessage = "Сервис аккаунта не инициализирован"
            return
        }

        do {
            let account = try await bankAccountService.get()
            self.bankAccount = account
            self.editingBalance = String(describing: account.balance)
            self.editingCurrency = account.currencySymbol
        } catch {
            self.alertMessage = error.localizedDescription
        }
    }

    func saveChanges() async {
        isLoading = true
        defer { isLoading = false }

        guard let bankAccountService = bankAccountService,
              let account = bankAccount else { return }

        let updatedAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: Decimal(string: editingBalance) ?? account.balance,
            currency: editingCurrency,
            createdAt: account.createdAt,
            updatedAt: Date()
        )

        do {
            self.bankAccount = try await bankAccountService.update(updatedAccount)
        } catch {
            self.alertMessage = error.localizedDescription
        }
    }

    func refresh() {
        Task {
            isLoading = true
            defer { isLoading = false }

            guard let bankAccountService = bankAccountService else { return }

            do {
                var updatedAccount = try await bankAccountService.get()
                try? await Task.sleep(nanoseconds: 1_500_000_000)

                if let newBalance = Decimal(string: self.editingBalance) {
                    updatedAccount.balance = newBalance
                }

                updatedAccount.currency = currencyCode(for: editingCurrency)

                _ = try await bankAccountService.update(updatedAccount)

                self.bankAccount = updatedAccount
                self.editingBalance = String(describing: updatedAccount.balance)
                self.editingCurrency = updatedAccount.currencySymbol
            } catch {
                self.alertMessage = error.localizedDescription
            }
        }
    }

    private func currencyCode(for symbol: String) -> String {
        switch symbol {
        case "$": return "USD"
        case "€": return "EUR"
        case "₽": return "RUB"
        default: return "RUB"
        }
    }

    func filterBalanceInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let filteredScalars = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        var filtered = String(String.UnicodeScalarView(filteredScalars))

        var separatorCount = 0
        filtered = filtered.filter { char in
            if char == "." {
                separatorCount += 1
                return separatorCount == 1
            }
            return true
        }

        if filtered.count > 1 && filtered.first == "0" {
            let secondChar = filtered[filtered.index(after: filtered.startIndex)]
            if secondChar != "." {
                filtered = String(filtered.drop { $0 == "0" })
            }
        }

        if filtered.isEmpty {
            filtered = "0"
        }

        return filtered
    }

    func dismissAlert() {
        alertMessage = nil
    }
}


struct CalcView: View {
    @Environment(\.editMode) private var editMode
    @StateObject var viewModel: CalcViewModel
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    @FocusState private var balanceFieldFocused: Bool
    init(modelContainer: ModelContainer) {
        _viewModel = StateObject(wrappedValue: CalcViewModel(modelContainer: modelContainer))
    }
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
                    if isEditing {
                        HStack(spacing: 4) {
                            TextField("0", text: _viewModel.balance)
                                .keyboardType(.decimalPad)
                                .focused($balanceFieldFocused)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black)
                                .onChange(of: _viewModel.balance) {_, newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    let parts = filtered.split(separator: ".")
                                    let cleaned: String
                                    if parts.count > 1 {
                                        cleaned = parts[0] + "." + parts[1..<parts.count].joined()
                                    } else {
                                        cleaned = filtered
                                    }
                                    if cleaned != newValue {
                                        _viewModel.balance = cleaned
                                    }
                                }
                            Text(_viewModel.currency.symbol)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text(_viewModel.balance)
                                .onShake {
                                    withAnimation { _viewModel.isBalanceHidden.toggle() }
                                }
                            Text(_viewModel.currency.symbol)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(isEditing ? Color.white : Color("Accent"))
                .cornerRadius(12)
                .onTapGesture {
                    if isEditing {
                        balanceFieldFocused = true
                    }
                }
                //валюта
                HStack {
                    Text("Валюта")
                        .font(.body)
                    Spacer()
                    Text(_viewModel.currency.symbol)
                        .font(.body)
                    if _viewModel.isEditing {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(_viewModel.isEditing ? Color.white : Color("Accent").opacity(0.15))
                .cornerRadius(12)
                .onTapGesture {
                    guard _viewModel.isEditing else { return }
                    showCurrencyPicker = true
                }
                .accentColor(.indigo)
                .confirmationDialog(
                    "Валюта",
                    isPresented: $showCurrencyPicker
                ) {
                    ForEach(Currency.allCases) { cur in
                        Button(cur.displayName) {
                            if cur != _viewModel.currency {
                                _viewModel.currency = cur
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
                Button(isEditing ? "Сохранить" : "Редактировать") {
                    withAnimation {
                        if isEditing {
                            editMode?.wrappedValue = .inactive
                            balanceFieldFocused = false
                        } else {
                            editMode?.wrappedValue = .active
                            balanceFieldFocused = true
                        }
                        _viewModel.isEditing.toggle()
                    }
                }
                .foregroundColor(.indigo)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}


