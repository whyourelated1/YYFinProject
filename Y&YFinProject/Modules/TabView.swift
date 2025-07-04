/*Добавить таб бар
 с помощью asset catalog задать акцентный цвет приложения #2AE881
 добавить таб бар, содержащий все вкладки из дизайна с заглушками
 иконки имеют акцентный цвет*/
import SwiftUI
struct MainTabView: View {
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
                TransactionsListView(direction: .outcome)
                .tabItem {
                    Label(Tab.todayOutcome.rawValue, image: Tab.todayOutcome.icon)
                }
                .tag(Tab.todayOutcome)

                TransactionsListView(direction: .income)
                    .tabItem {
                        Label(Tab.todayIncome.rawValue, image: Tab.todayIncome.icon)
                    }
                    .tag(Tab.todayIncome)

                CalcView()
                    .tabItem {
                        Label(Tab.сalc.rawValue, image: Tab.сalc.icon)
                    }
                    .tag(Tab.сalc)
                        
                AnalysisView()
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

#Preview {
    MainTabView()
}
