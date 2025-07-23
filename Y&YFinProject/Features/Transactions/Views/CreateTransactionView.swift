import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddTransactionViewModel
    @FocusState private var amountFocused: Bool
    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.rub.rawValue
    @State private var showValidationAlert = false

    init(mode: AddTransactionForm, client: NetworkClient, accountId: Int, modelContainer: ModelContainer) {
        _vm = StateObject(wrappedValue: .init(
            mode: mode,
            client: client,
            accountId: accountId,
            modelContainer: modelContainer
        ))
    }

    private var currencySymbol: String {
        Currency(rawValue: storedCurrency)?.symbol ?? ""
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    CategoryRowView(category: $vm.category, showPicker: $vm.showCategoryPicker)
                    AmountRowView(
                        amountString: $vm.amountString,
                        onChange: filterAmount,
                        isFocused: $amountFocused
                    )
                    DateRowView(date: $vm.date)
                    TimeRowView(date: $vm.date)
                    CommentSectionView(comment: $vm.comment)
                }
                .listSectionSeparator(.hidden)

                if vm.mode.isEdit {
                    DeleteSectionView(action: { Task { await vm.delete(); dismiss() } },
                                      isOutcome: vm.direction == .outcome)
                        .listSectionSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vm.mode.isCreate ? "Создание" : "Редактирование")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(Color(hex: "6F5DB7"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.mode.isCreate ? "Создать" : "Сохранить") {
                        if vm.canSave {
                            Task {
                                await vm.save()
                                dismiss()
                            }
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .foregroundColor(Color(hex: "6F5DB7"))
                }
            }
            .alert("Заполните все поля", isPresented: $showValidationAlert) {
                Button("ОК", role: .cancel) {}
            }
            .sheet(isPresented: $vm.showCategoryPicker) {
                CategoryPickerView(
                    selected: $vm.category,
                    categories: vm.categories,
                    onDismiss: { vm.showCategoryPicker = false }
                )
            }
            .onAppear {
                if vm.mode.isCreate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        amountFocused = true
                    }
                }
            }
        }
    }

    private func filterAmount(_ newValue: String) {
        let sep = Locale.current.decimalSeparator ?? "."
        let allowedChars = CharacterSet(charactersIn: "0123456789" + sep)
        let filtered = newValue.filter { String($0).rangeOfCharacter(from: allowedChars) != nil }
        let parts = filtered.components(separatedBy: sep)
        let result = parts.prefix(2).joined(separator: sep)
        if result != vm.amountString {
            vm.amountString = result
        }
    }
}


struct CategoryRowView: View {
    @Binding var category: Category?
    @Binding var showPicker: Bool

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text("Категория")
                    .foregroundStyle(.black)
                Spacer()
                Text(category?.name ?? "Не выбрана")
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.white)
    }
}

struct AmountRowView: View {
    @Binding var amountString: String
    let onChange: (String) -> Void
    @FocusState.Binding var isFocused: Bool
    @AppStorage("currencyCode") private var currencyCode = Currency.rub.rawValue

    private var currencySymbol: String {
        Currency(rawValue: currencyCode)?.symbol ?? ""
    }

    var body: some View {
        HStack {
            Text("Сумма")
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $amountString)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .frame(width: 60)

                Text(currencySymbol)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .frame(height: Constants.periodRowHeight.height)
            .cornerRadius(Constants.periodRowCornerRadius)
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: 24)
        .onChange(of: amountString) { _, newValue in
            onChange(newValue)
        }
    }
}

struct DateRowView: View {
    @Binding var date: Date

    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.locale = Locale(identifier: "ru_RU")
        return df
    }()

    var body: some View {
        HStack {
            Text("Дата")
            Spacer()
            ZStack {
                Text(formatter.string(from: date))
                    .frame(alignment: .leading)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(width: Constants.periodRowHeight.width, height: Constants.periodRowHeight.height)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(Constants.periodRowCornerRadius)

                DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.accentColor)
                    .frame(width: Constants.periodRowHeight.width, height: Constants.periodRowHeight.height)
                    .blendMode(.destinationOver)
                    .clipped()
                    .opacity(0.01)
                    .allowsHitTesting(true)
            }
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: 24)
    }
}

struct TimeRowView: View {
    @Binding var date: Date

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack {
            Text("Время")
            Spacer()
            ZStack {
                Text(formatter.string(from: date))
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(width: 56, height: Constants.periodRowHeight.height)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(Constants.periodRowCornerRadius)

                DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.accentColor)
                    .frame(width: 56, height: Constants.periodRowHeight.height)
                    .blendMode(.destinationOver)
            }
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: 24)
    }
}

struct CommentSectionView: View {
    @Binding var comment: String

    var body: some View {
        TextField("Комментарий", text: $comment, prompt: Text("Комментарий").foregroundColor(.gray))
    }
}

struct DeleteSectionView: View {
    let action: () -> Void
    let isOutcome: Bool

    var body: some View {
        Button(role: .destructive, action: action) {
            Text("Удалить \(isOutcome ? "расход" : "доход")")
                .foregroundStyle(.red)
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selected: Category?
    let categories: [Category]
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(categories, id: \.id) { cat in
                        Button {
                            selected = cat
                            onDismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(String(cat.emoji))
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(Circle())

                                Text(cat.name)
                                    .foregroundColor(.primary)
                                    .font(.body)

                                Spacer()

                                if cat.id == selected?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Категории")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onDismiss() } .foregroundColor(Color(hex: "6F5DB7"))
                }
            }
        }
    }
}

private enum Constants {
    static let periodRowHeight = CGSize(width: 120, height: 36)
    static let periodRowCornerRadius: CGFloat = 8
    static let verticalPadding: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
}
