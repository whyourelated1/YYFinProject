import SwiftUI

private enum Constants {
    static let navigationHorizontalPadding: CGFloat = 16
    static let sectionVerticalSpacing: CGFloat = 16
    static let titleHorizontalPadding: CGFloat = 16
    static let totalVerticalPadding: CGFloat = 12
    static let totalHorizontalPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let operationsCaptionHorizontalPadding: CGFloat = 16
    static let cellVerticalPadding: CGFloat = 8
    static let cellHorizontalPadding: CGFloat = 12
    static let iconSize: CGFloat = 32
    static let iconPaddingLeadingOutcome: CGFloat = 44
    static let iconPaddingLeadingIncome: CGFloat = 12
    static let overlayButtonSize: CGFloat = 16
    static let overlayButtonPaddingTrailing: CGFloat = 16
    static let overlayButtonPaddingBottom: CGFloat = 24
    static let overlayButtonFontSize: CGFloat = 20
}


struct TransactionRowView: View {
    let transaction: Transaction
    let currencyCode: String
    let direction: Direction

    var body: some View {
        HStack(spacing: Constants.cellHorizontalPadding) {
            if direction == .outcome {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .overlay(Text(String(transaction.category.emoji)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.name).font(.body)
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
        .padding(.vertical, Constants.cellVerticalPadding)
        .padding(.horizontal, Constants.cellHorizontalPadding)
    }
}

