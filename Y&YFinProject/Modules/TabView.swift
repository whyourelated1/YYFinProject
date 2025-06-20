/*Добавить таб бар
 с помощью asset catalog задать акцентный цвет приложения #2AE881
 добавить таб бар, содержащий все вкладки из дизайна с заглушками
 иконки имеют акцентный цвет*/
import SwiftUI
struct MainTabView: View {
    enum Tab: String, CaseIterable {
        case todayOutcome = "Расходы"
        case todayIncome = "Доходы"
        case Calc = "Счет"
        case analysis = "Статьи"
        case setting = "Настройки"

        var icon: String {
            switch self {
            case .todayOutcome: return "TabUp"
            case .todayIncome: return "TabDown"
            case .Calc: return "TabCalc"
            case .analysis: return "TabStat"
            case .setting: return "TabSetting"
            }
        }
    }

    @State private var selectedTab: Tab = .todayOutcome

    var body: some View {
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
            
            Text("Счет")
                .tabItem {
                    Label(Tab.Calc.rawValue, image: Tab.Calc.icon)
                }
            Text("Статьи")
                .tabItem {
                    Label(Tab.analysis.rawValue, image: Tab.analysis.icon)
                }

            Text("Настройки")
                .tabItem {
                    Label(Tab.setting.rawValue, image: Tab.setting.icon)
                }
        }
        .accentColor(Color("Accent"))
    }
}

#Preview {
    MainTabView()
}
