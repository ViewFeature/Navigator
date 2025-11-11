import Navigator
import SwiftUI

struct AppView: View {
  @State private var homeNavigator = Navigator<AppRoute>()
  @State private var settingsNavigator = Navigator<AppRoute>()
  @State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

  var body: some View {
    AppTabView(
      selectedTab: $tabNavigator.selectedTab,
      homePath: $homeNavigator.path,
      homeNavigator: homeNavigator,
      settingsPath: $settingsNavigator.path,
      settingsNavigator: settingsNavigator
    )
    .environment(tabNavigator)
    .onOpenURL { handleDeepLink($0) }
  }
}

private extension AppRoute {
  var tab: AppTab {
    switch self {
    case .pushScreen: return .home
    case .pushScreen2: return .settings
    }
  }
}

private extension AppView {
  func handleDeepLink(_ url: URL) {
    guard let route = AppRoute.parse(from: url) else {
      print("Deep Link failed: Unable to parse URL \(url)")
      return
    }
    tabNavigator.switchTo(route.tab)

    switch route.tab {
    case .home:
      homeNavigator.push(route)
    case .settings:
      settingsNavigator.push(route)
    }
  }
}
