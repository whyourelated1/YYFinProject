//добавлено, чтобы не создавалась новая структара, а обновлялись конкретные поля
import Foundation
extension BankAccount{
    func updated(
        name: String? = nil,
        balance: Decimal? = nil,
        currency: String? = nil
    ) -> BankAccount{
        return BankAccount(
            id: self.id,
            userId: self.userId,
            name: name ?? self.name,
            balance: balance ?? self.balance,
            currency: currency ?? self.currency,
            createdAt: self.createdAt,
            updatedAt: Date())
    }
}
