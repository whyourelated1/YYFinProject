/*Добавить таб бар
 с помощью asset catalog задать акцентный цвет приложения #2AE881
 добавить таб бар, содержащий все вкладки из дизайна с заглушками
 иконки имеют акцентный цвет*/
import SwiftUI
import SwiftData
struct MainTabView: View {
    
    let client: NetworkClient
    let accountId: Int
    let modelContainer: ModelContainer

    init(client: NetworkClient, accountId: Int, modelContainer: ModelContainer) {
        self.client = client
        self.accountId = accountId
        self.modelContainer = modelContainer

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    enum Tab: String, CaseIterable {
        case todayOutcome = "Расходы"
        case todayIncome = "Доходы"
        case сalc = "Счет"
        case analysis = "Статьи"
        case setting = "Настройки"

        var icon: String {
            switch self {
            case .todayOutcome: return "TabUp"
            case .todayIncome: return "TabDown"
            case .сalc: return "TabCalc"
            case .analysis: return "TabStat"
            case .setting: return "TabSetting"
            }
        }
    }

    @State private var selectedTab: Tab = .todayOutcome

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                TransactionsListView(
                    direction: .outcome,
                    client: client,
                    accountId: accountId,
                    modelContainer: modelContainer
                )
                .tabItem {
                    Label(Tab.todayOutcome.rawValue, image: Tab.todayOutcome.icon)
                }
                .tag(Tab.todayOutcome)

                TransactionsListView(
                    direction: .income,
                    client: client,
                    accountId: accountId,
                    modelContainer: modelContainer
                )
                    .tabItem {
                        Label(Tab.todayIncome.rawValue, image: Tab.todayIncome.icon)
                    }
                    .tag(Tab.todayIncome)

                BankAccountView(
                    client: client,
                    modelContainer: modelContainer
                )
                    .tabItem {
                        Label(Tab.сalc.rawValue, image: Tab.сalc.icon)
                    }
                    .tag(Tab.сalc)
                        
                CategoriesView(
                    client: client,
                    modelContainer: modelContainer
                )
                    .tabItem {
                        Label(Tab.analysis.rawValue, image: Tab.analysis.icon)
                    }
                    .tag(Tab.analysis)

                Text("Настройки")
                    .tabItem {
                        Label(Tab.setting.rawValue, image: Tab.setting.icon)
                    }
            }
            .accentColor(Color("Accent"))
        }
    }
}


