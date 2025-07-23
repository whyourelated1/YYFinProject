import SwiftUI
import Foundation
import SwiftData

enum Currency: String, CaseIterable, Identifiable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    var displayName: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Американский доллар $"
        case .eur: return "Евро €"
        }
    }
}

@MainActor
final class BankAccountViewModel: ObservableObject {

    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var balanceInput = ""
    @Published var showCurrencyPicker = false
    @Published var error: Error?
    @Published var isLoading = false
    @Published var alertError: String?

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.rub.rawValue
    @Published var selectedCurrency = Currency.rub

    private let service: BankAccountsService
    private let modelContext: ModelContext

    init(client: NetworkClient, modelContainer: ModelContainer) {
        let localStore = BankAccountsLocalSwiftDataStore(container: modelContainer)
        self.service = BankAccountsService(client: client, localStore: localStore)
        self.modelContext = ModelContext(modelContainer)
        Task { await loadAccount() }
    }

    func loadAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let acc = try await service.getAccount()
            account = acc
            selectedCurrency = Currency(rawValue: storedCurrency) ?? .rub
            balanceInput = Self.format(acc.balance)
            try? await saveToLocal(acc)
        } catch {
            self.alertError = "Не удалось загрузить счёт: \(error.localizedDescription)"
            print("Ошибка загрузки счёта: \(error)")
            do {
                let descriptor = FetchDescriptor<AccountEntity>()
                let localAccounts = try modelContext.fetch(descriptor)
                if let entity = localAccounts.first {
                    let acc = entity.toModel()
                    account = acc
                    selectedCurrency = Currency(rawValue: acc.currency) ?? .rub
                    balanceInput = Self.format(acc.balance)
                    print("Счёт загружен локально")
                }
            } catch {
                print("Ошибка загрузки локального счёта: \(error)")
            }
        }
    }

    private func saveToLocal(_ acc: BankAccount) async throws {
        let descriptor = FetchDescriptor<AccountEntity>(
            predicate: #Predicate { $0.id == acc.id }
        )
        let existing = try modelContext.fetch(descriptor).first

        if let existing = existing {
            existing.name = acc.name
            existing.balance = acc.balance
            existing.currency = acc.currency
        } else {
            let entity = AccountEntity(
                id: acc.id,
                name: acc.name,
                balance: acc.balance,
                currency: acc.currency
            )
            modelContext.insert(entity)
        }

        try? modelContext.save()
    }

    func toggleEditing() {
        if isEditing {
            Task { await saveChanges() }
        } else if let acc = account {
            balanceInput = Self.format(acc.balance)
            selectedCurrency = Currency(rawValue: storedCurrency) ?? .rub
        }
        isEditing.toggle()
    }

    private func saveChanges() async {
        guard let acc = account,
              let newBal = Decimal(string: sanitize(balanceInput))
        else { return }

        do {
            let updated = try await service.updateAccount(
                id: acc.id,
                name: acc.name,
                balance: newBal,
                currency: selectedCurrency.rawValue
            )
            account = updated
            balanceInput = Self.format(updated.balance)
            storedCurrency = selectedCurrency.rawValue
            try? await saveToLocal(updated)
        } catch {
            self.alertError = "Не удалось сохранить изменения: \(error.localizedDescription)"
        }
    }

    public func saveAccount() async {
        await saveChanges()
    }

    func sanitize(_ text: String) -> String {
        var clean = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        if let dot = clean.firstIndex(of: ".") {
            let after = clean.index(after: dot)
            clean = String(clean[..<after]) + clean[after...].replacingOccurrences(of: ".", with: "")
        }
        return clean
    }

    private static func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(for: value) ?? "0"
    }
}

