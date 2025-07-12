import Foundation
import SwiftUICore

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 16) {
            //иконка
            if let category = transaction.category {
                Text(String(category.emoji))
                    .font(.title)
                    .frame(width: 48, height: 48)
                    .background(Color("Accent").opacity(0.2))
                    .clipShape(Circle())
            }

            //название и комментарий
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category?.name ?? "Без категории")
                    .font(.headline)
                
                if let comment = transaction.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            //cумма и время
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount.formatted(.currency(code: "RUB")
                        .locale(Locale(identifier: "ru_RU"))
                        .precision(.fractionLength(0))))
                        .font(.headline)
                
                Text(transaction.transactionDate, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
        }
    }
}
