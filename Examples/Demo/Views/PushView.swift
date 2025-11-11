import Navigator
import SwiftUI

struct PushView: View {
  let screenId: String
  @Environment(Navigator<AppRoute>.self) private var router
  @State private var showModal = false

  private var nextId: String {
    let currentNumber = Int(screenId.replacingOccurrences(of: "push-", with: "")) ?? 0
    return "push-\(currentNumber + 1)"
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("🎯")
        .font(.system(size: 80))

      Text("Push Screen")
        .font(.title.bold())

      Text("Screen ID: \(screenId)")
        .font(.headline)
        .foregroundColor(.secondary)

      Text("Stack depth: \(router.path.count)")
        .font(.subheadline)
        .foregroundColor(.secondary)

      VStack(spacing: 12) {
        Button("Push Another (\(nextId))") {
          router.push(.pushScreen(id: nextId))
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        Button("Back to First (push-1)") {
          router.pop(to: .pushScreen(id: "push-1"))
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.green)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .disabled(router.path.count <= 1)

        Button("Show Modal") {
          showModal = true
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.red)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Push Screen")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showModal) {
      ModalView(title: "Push Screen Modal", isPresented: $showModal)
    }
  }
}

#Preview {
  NavigationStack {
    PushView(screenId: "demo-1")
  }
  .environment(Navigator<AppRoute>())
}
