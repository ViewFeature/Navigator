import Navigator
import SwiftUI

extension View {
  func appNavigationDestination() -> some View {
    navigationDestination(for: AppRoute.self) { route in
      switch route {
      case .pushScreen(let id): PushView(screenId: id)
      case .pushScreen2(let id): PushView(screenId: id)
      }
    }
  }
}
