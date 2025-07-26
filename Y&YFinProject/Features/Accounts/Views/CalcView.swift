import SwiftUI
import UIKit
import SwiftData

struct BankAccountView: View {
    let client: NetworkClient
    let modelContainer: ModelContainer

    @StateObject private var vm: BankAccountViewModel
    @FocusState private var isFocused: Bool
    @State private var showCurrencyDialog = false
    @State private var hideBalance = true

    init(client: NetworkClient, modelContainer: ModelContainer) {
        self.client = client
        self.modelContainer = modelContainer
        _vm = StateObject(wrappedValue: BankAccountViewModel(client: client, modelContainer: modelContainer))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if vm.isLoading {
                    LoadingView()
                } else {
                    VStack(spacing: 16) {
                        Text("Мой счёт")
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                        ScrollView {
                            VStack(spacing: 8) {
                                balanceRow
                                currencyRow
                                    .onTapGesture {
                                        if vm.isEditing {
                                            showCurrencyDialog = true
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .refreshable { await vm.loadAccount() }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(vm.isEditing ? "Сохранить" : "Редактировать") {
                        if vm.isEditing {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                            hideBalance = true
                        }
                        vm.toggleEditing()
                        isFocused = false
                    }
                    .foregroundColor(Color(hex: "#6F5DB7"))
                }
            }
            .confirmationDialog("Валюта", isPresented: $showCurrencyDialog, titleVisibility: .visible) {
                ForEach(Currency.allCases) { cur in
                    Button(cur.displayName) {
                        vm.selectedCurrency = cur
                    }
                    .foregroundColor(Color(hex: "#6F5DB7"))
                }
            }
            .tint(Color(hex: "#6F5DB7"))
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                withAnimation { hideBalance.toggle() }
            }
            .overlay(
                ShakeDetectorView()
                    .allowsHitTesting(false)
                    .id(vm.isEditing)
            )
        }
        .onChange(of: vm.isEditing) { _, editing in
            if !editing { hideBalance = true }
        }
        .onAppear {
            Task { await vm.loadAccount() }
        }
        .alert("Ошибка", isPresented: Binding(get: {
            vm.alertError != nil
        }, set: { _ in
            vm.alertError = nil
        })) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text(vm.alertError ?? "")
        }
    }

    private var balanceRow: some View {
        HStack {
            Text("💰 Баланс")
            Spacer()

            if vm.isEditing {
                TextField("", text: $vm.balanceInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .onChange(of: vm.balanceInput) { _, new in
                        vm.balanceInput = vm.sanitize(new)
                    }
            } else {
                Text(vm.account?.balance.formatted(
                    .currency(code: vm.selectedCurrency.rawValue)
                        .locale(Locale(identifier: "ru_RU"))
                        .precision(.fractionLength(0))
                ) ?? "—")
                .foregroundColor(.black)
                .spoiler(isOn: $hideBalance)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            vm.isEditing ? Color(.systemBackground) : Color.accentColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { if vm.isEditing { isFocused = true } }
    }

    private var currencyRow: some View {
        HStack {
            Text("Валюта")
            Spacer()
            Text(vm.selectedCurrency.symbol)
                .foregroundColor(vm.isEditing ? Color(hex: "#6F5DB7") : .primary)

            if vm.isEditing {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            vm.isEditing
            ? Color(.systemBackground)
            : Color.accentColor.opacity(0.20)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
