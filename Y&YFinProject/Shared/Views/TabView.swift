/*Добавить таб бар
 с помощью asset catalog задать акцентный цвет приложения #2AE881
 добавить таб бар, содержащий все вкладки из дизайна с заглушками
 иконки имеют акцентный цвет*/
import SwiftUI

struct MainTabView: View {
    
    enum Tab: String, CaseIterable, Hashable {
        case todayOutcome = "Расходы"
        case todayIncome  = "Доходы"
        case calc         = "Счет"
        case analysis     = "Статьи"
        case setting      = "Настройки"
        
        var icon: String {
            switch self {
            case .todayOutcome: return "TabUp"
            case .todayIncome:  return "TabDown"
            case .calc:         return "TabCalc"
            case .analysis:     return "TabStat"
            case .setting:      return "TabSetting"
            }
        }
    }

    @State private var selectedTab: Tab = .todayOutcome

    var body: some View {
        TabView(selection: $selectedTab) {
            
            NavigationStack {
                TransactionsListView(direction: .outcome)
            }
            .tabItem {
                Label(Tab.todayOutcome.rawValue, image: Tab.todayOutcome.icon)
            }
            .tag(Tab.todayOutcome)
            
            NavigationStack {
                TransactionsListView(direction: .income)
            }
            .tabItem {
                Label(Tab.todayIncome.rawValue, image: Tab.todayIncome.icon)
            }
            .tag(Tab.todayIncome)
            
            NavigationStack {
                CalcView()
            }
            .tabItem {
                Label(Tab.calc.rawValue, image: Tab.calc.icon)
            }
            .tag(Tab.calc)
            
            NavigationStack {
                AnalysisView()
            }
            .tabItem {
                Label(Tab.analysis.rawValue, image: Tab.analysis.icon)
            }
            .tag(Tab.analysis)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.setting.rawValue, image: Tab.setting.icon)
            }
            .tag(Tab.setting)
        }
        .tint(Color("Accent"))
    }
}

#Preview {
    MainTabView()
}
