import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let currencyCode: String
    let direction: Direction

    var body: some View {
        HStack(spacing: 10) {
            if direction == .outcome {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .overlay(Text(String(transaction.category.emoji)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.name)
                    .font(.body)

                if let comment = transaction.comment {
                    Text(comment)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(
                transaction.amount.formatted(
                    .currency(code: currencyCode)
                        .locale(Locale(identifier: "ru_RU"))
                        .precision(.fractionLength(0))
                )
            )
            .font(.body)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
}
