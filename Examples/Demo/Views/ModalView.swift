import Navigator
import SwiftUI

struct ModalView: View {
  let title: String
  @Binding var isPresented: Bool
  @State private var router = Navigator<AppRoute>()

  var body: some View {
    NavigationStack(path: $router.path) {
      VStack(spacing: 40) {
        Text("🎉")
          .font(.system(size: 80))

        Text(title)
          .font(.title.bold())

        Text("This is a modal screen")
          .font(.body)
          .foregroundColor(.secondary)

        Button("Go to Push Screen") {
          router.push(.pushScreen(id: "modal-push"))
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.green)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        Button("Close") {
          isPresented = false
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
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .appNavigationDestination()
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            isPresented = false
          }
        }
      }
    }
    .environment(router)
  }
}

#Preview {
  ModalView(title: "Preview", isPresented: .constant(true))
}
