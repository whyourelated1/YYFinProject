import Foundation
import Testing
@testable import Y_YFinProject

struct Y_YFinProjectTests {
    @Test func transactionEncodeDecode() async throws {
        let now = Date()
        let transaction = Transaction(
            id: 100,
            accountId: 1,
            categoryId: 10,
            amount: Decimal(string: "2500.00")!,
            comment: "Покупка ноутбука",
            transactionDate: now,
            createdAt: now,
            updatedAt: now,
            hidden: false,
            account: nil,
            category: nil
        )

        let json = transaction.jsonObject
        let parsed = try #require(Transaction.parse(jsonObject: json))

        #expect(parsed.id == transaction.id)
        #expect(parsed.accountId == transaction.accountId)
        #expect(parsed.categoryId == transaction.categoryId)
        #expect(parsed.amount == transaction.amount)
        #expect(parsed.comment == transaction.comment)
        #expect(parsed.hidden == transaction.hidden)
        
        let accuracy: TimeInterval = 1.0
        #expect(abs(parsed.createdAt.timeIntervalSince(transaction.createdAt)) < accuracy)
        #expect(abs(parsed.updatedAt.timeIntervalSince(transaction.updatedAt)) < accuracy)
        #expect(abs(parsed.transactionDate.timeIntervalSince(transaction.transactionDate)) < accuracy)
    }

    @Test func hiddenTransactionIncorrect() async throws {
        let now = Date()
        let hiddenTransaction = Transaction(
            id: 200,
            accountId: 2,
            categoryId: nil,
            amount: Decimal(string: "500.00")!,
            comment: nil,
            transactionDate: now,
            createdAt: now,
            updatedAt: now,
            hidden: true,
            account: nil,
            category: nil
        )

        let json = try #require(hiddenTransaction.jsonObject as? [String: Any])

        #expect(json["categoryId"] == nil)

        let parsed = try #require(Transaction.parse(jsonObject: json))
        #expect(parsed.hidden == true)
        #expect(parsed.categoryId == nil)
    }
    
    @Test func withNestedObjects() async throws {
        let now = Date()
        
        let testAccount = BankAccount(
            id: 1,
            userId: 100,
            name: "Мои сбережения",
            balance: Decimal(string: "157568850.85")!,
            currency: "RUB",
            createdAt: now,
            updatedAt: now
        )
        
        let testCategory = TransactionCategory(
            id: 5,
            name: "Подарок",
            emoji: "🎁",
            direction: .income
        )
        
        let originalTransaction = Transaction(
            id: 42,
            accountId: testAccount.id,
            categoryId: testCategory.id,
            amount: Decimal(string: "500.00")!,
            comment: "Подарок на день рождения",
            transactionDate: now,
            createdAt: now,
            updatedAt: now,
            hidden: false,
            account: testAccount,
            category: testCategory
        )
        
        let json = originalTransaction.jsonObject
        
        let parsedTransaction = try #require(Transaction.parse(jsonObject: json))
        
        let parsedAccount = try #require(parsedTransaction.account)
        let parsedCategory = try #require(parsedTransaction.category)
        
        #expect(parsedTransaction.id == originalTransaction.id)
        #expect(parsedTransaction.amount == originalTransaction.amount)
        
        #expect(parsedAccount.id == testAccount.id)
        #expect(parsedAccount.name == testAccount.name)
        #expect(parsedAccount.balance == testAccount.balance)
        #expect(parsedAccount.currency == testAccount.currency)
        
        #expect(parsedCategory.id == testCategory.id)
        #expect(parsedCategory.name == testCategory.name)
        #expect(parsedCategory.emoji == testCategory.emoji)
        #expect(parsedCategory.direction == testCategory.direction)
        
        let accuracy: TimeInterval = 1.0
        #expect(abs(parsedAccount.createdAt.timeIntervalSince(testAccount.createdAt)) < accuracy)
        #expect(abs(parsedAccount.updatedAt.timeIntervalSince(testAccount.updatedAt)) < accuracy)
    }

}
