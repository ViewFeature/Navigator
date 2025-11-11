import Navigator
import SwiftUI

struct HomeView: View {
  @Environment(Navigator<AppRoute>.self) private var router

  var body: some View {
    VStack(spacing: 40) {
      Text("Home Tab")
        .font(.title.bold())

      Button("Go to Push Screen") {
        router.push( .pushScreen(id: "push-1"))
      }
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding()
      .background(.blue)
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      Spacer()
    }
    .padding()
    .navigationTitle("Home")
    .navigationBarTitleDisplayMode(.large)
  }
}

#Preview {
  NavigationStack {
    HomeView()
  }
  .environment(Navigator<AppRoute>())
}
