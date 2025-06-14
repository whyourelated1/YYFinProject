/*содержит асинхронный метод для получения единственного банковского счета пользователя. Не смотря на то, что бэкенд предоставляет список, для упрощения задачи будем использовать только первый аккаунт в списке
 содержит асинхронный метод для изменения счета*/
import Foundation

final class BankAccountsService {
    private var account: BankAccount = MockData.account

    func getAccount() async throws -> BankAccount {
        return account
    }

    func updateAccount(_ updated: BankAccount) async throws -> BankAccount {
        account = updated
        return account
    }
}
