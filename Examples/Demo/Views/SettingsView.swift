import Navigator
import SwiftUI

struct SettingsView: View {
  @State private var showModal = false

  var body: some View {
    VStack(spacing: 40) {
      Text("Settings Tab")
        .font(.title.bold())

      Button("Show Modal") {
        showModal = true
      }
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding()
      .background(.orange)
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      Spacer()
    }
    .padding()
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.large)
    .sheet(isPresented: $showModal) {
      ModalView(title: "Settings Modal", isPresented: $showModal)
    }
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
}
