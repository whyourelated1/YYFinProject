import Foundation

extension Transaction {
    var jsonObject: Any {
        var dict: [String: Any] = [
            "id": id,
            "accountId": accountId,
            "amount": amount.description,
            "comment": comment ?? "",
            "transactionDate": ISO8601DateFormatter().string(from: transactionDate),
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt),
            "hidden": hidden
        ]
        
        if !hidden, let categoryId = categoryId {
            dict["categoryId"] = categoryId
        }
        
        if let account = account {
            dict["account"] = account.jsonObject
        }
        
        if let category = category {
            dict["category"] = category.jsonObject
        }
        
        return dict
    }

    static func parse(jsonObject: Any) -> Transaction? {
        guard let dict = jsonObject as? [String: Any],
              let id = dict["id"] as? Int,
              let accountId = dict["accountId"] as? Int,
              let amountString = dict["amount"] as? String,
              let amount = Decimal(string: amountString),
              let comment = dict["comment"] as? String,
              let transactionDateStr = dict["transactionDate"] as? String,
              let transactionDate = ISO8601DateFormatter().date(from: transactionDateStr),
              let createdAtStr = dict["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtStr),
              let updatedAtStr = dict["updatedAt"] as? String,
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtStr),
              let hidden = dict["hidden"] as? Bool
        else {
            return nil
        }

        let categoryId = dict["categoryId"] as? Int

        let account: BankAccount? = {
            if let acc = dict["account"] as? [String: Any] {
                return BankAccount.parse(jsonObject: acc)
            }
            return nil
        }()

        let category: TransactionCategory? = {
            if let cat = dict["category"] as? [String: Any] {
                return TransactionCategory.parse(jsonObject: cat)
            }
            return nil
        }()

        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            comment: comment,
            transactionDate: transactionDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            hidden: hidden,
            account: account,
            category: category
        )
    }
}
