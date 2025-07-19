import Foundation
import SwiftData

@Model
final class AccountEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var balance: Decimal
    var currency: String

    init(id: Int, name: String, balance: Decimal, currency: String) {
        self.id = id
        self.name = name
        self.balance = balance
        self.currency = currency
    }

    func toModel() -> BankAccount {
        BankAccount(id: id, name: name, balance: balance, currency: currency)
    }
}
