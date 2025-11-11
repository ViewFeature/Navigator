import Navigator
import SwiftUI

private extension AppTab {
  var title: String {
    switch self {
    case .home: return "Home"
    case .settings: return "Settings"
    }
  }

  var icon: String {
    switch self {
    case .home: return "house"
    case .settings: return "gearshape"
    }
  }
}

struct AppTabView: View {
  @Binding var selectedTab: AppTab
  @Binding var homePath: [AppRoute]
  let homeNavigator: Navigator<AppRoute>
  @Binding var settingsPath: [AppRoute]
  let settingsNavigator: Navigator<AppRoute>

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack(path: $homePath) {
        HomeView()
          .appNavigationDestination()
      }
      .tabItem {
        Image(systemName: AppTab.home.icon)
        Text(AppTab.home.title)
      }
      .tag(AppTab.home)
      .environment(homeNavigator)

      NavigationStack(path: $settingsPath) {
        SettingsView()
          .appNavigationDestination()
      }
      .tabItem {
        Image(systemName: AppTab.settings.icon)
        Text(AppTab.settings.title)
      }
      .tag(AppTab.settings)
      .environment(settingsNavigator)
    }
  }
}
