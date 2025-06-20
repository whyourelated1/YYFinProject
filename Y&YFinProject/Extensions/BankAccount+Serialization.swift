import Foundation

extension BankAccount {
    var jsonObject: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "name": name,
            "balance": balance.description,
            "currency": currency,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
    
    static func parse(jsonObject: [String: Any]) -> BankAccount? {
        guard let id = jsonObject["id"] as? Int,
              let userId = jsonObject["userId"] as? Int,
              let name = jsonObject["name"] as? String,
              let balanceStr = jsonObject["balance"] as? String,
              let balance = Decimal(string: balanceStr),
              let currency = jsonObject["currency"] as? String,
              let createdAtStr = jsonObject["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtStr),
              let updatedAtStr = jsonObject["updatedAt"] as? String,
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtStr) else {
            return nil
        }
        
        return BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
