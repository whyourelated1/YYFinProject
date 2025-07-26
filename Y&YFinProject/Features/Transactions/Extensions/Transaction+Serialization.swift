import Foundation

enum TransactionParseError: Error, LocalizedError {
    case notADictionary
    case missingField(String)
    case invalidField(String)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .notADictionary:
            return "Provided JSON is not a dictionary."
        case .missingField(let field):
            return "Missing required field: \(field)."
        case .invalidField(let field):
            return "Invalid format in field: \(field)."
        case .invalidDate(let field):
            return "Invalid date format in field: \(field)."
        }
    }
}

extension Transaction {

    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    var jsonObject: Any {
        return [
            "id": id,
            "account": [
                "id": account.id,
                "name": account.name,
                "balance": "\(account.balance)",
                "currency": account.currency
            ],
            "category": [
                "id": category.id,
                "name": category.name,
                "emoji": String(category.emoji),
                "isIncome": category.isIncome
            ],
            "amount": "\(amount)",
            "transactionDate": Self.formatter.string(from: transactionDate),
            "comment": comment as Any? ?? NSNull(),
            "createdAt": Self.formatter.string(from: createdAt),
            "updatedAt": Self.formatter.string(from: updatedAt)
        ]
    }

    static func parse(jsonObject: Any) throws -> Transaction {
        guard let dict = jsonObject as? [String: Any] else {
            throw TransactionParseError.notADictionary
        }

        guard let id = dict["id"] as? Int else {
            throw TransactionParseError.missingField("id")
        }
        guard let accountDict = dict["account"] as? [String: Any],
              let accountId = accountDict["id"] as? Int,
              let accountName = accountDict["name"] as? String,
              let accountBalanceString = accountDict["balance"] as? String,
              let accountBalance = Decimal(string: accountBalanceString),
              let accountCurrency = accountDict["currency"] as? String else {
            throw TransactionParseError.invalidField("account")
        }

        // Category
        guard let categoryDict = dict["category"] as? [String: Any],
              let categoryId = categoryDict["id"] as? Int,
              let categoryName = categoryDict["name"] as? String,
              let categoryEmojiString = categoryDict["emoji"] as? String,
              let categoryEmoji = categoryEmojiString.first,
              let categoryIsIncome = categoryDict["isIncome"] as? Bool else {
            throw TransactionParseError.invalidField("category")
        }

        // Amount
        guard let amountString = dict["amount"] as? String,
              let amount = Decimal(string: amountString) else {
            throw TransactionParseError.invalidField("amount")
        }

        // Dates
        guard let transactionDateStr = dict["transactionDate"] as? String,
              let transactionDate = formatter.date(from: transactionDateStr) else {
            throw TransactionParseError.invalidDate("transactionDate")
        }

        guard let createdAtStr = dict["createdAt"] as? String,
              let createdAt = formatter.date(from: createdAtStr) else {
            throw TransactionParseError.invalidDate("createdAt")
        }

        guard let updatedAtStr = dict["updatedAt"] as? String,
              let updatedAt = formatter.date(from: updatedAtStr) else {
            throw TransactionParseError.invalidDate("updatedAt")
        }

        // Optional
        let comment = dict["comment"] as? String

        let account = BankAccount(id: accountId, name: accountName, balance: accountBalance, currency: accountCurrency)
        let category = Category(id: categoryId, name: categoryName, emoji: categoryEmoji, isIncome: categoryIsIncome)

        return Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
