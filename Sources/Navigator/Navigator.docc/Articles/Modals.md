# モーダル & シート

NavigatorとSwiftUIのモーダルを組み合わせて使用しましょう。

## 概要

SwiftUIのシートとフルスクリーンカバーとNavigatorを組み合わせて使用し、モーダル内でのナビゲーションを実装する方法を学習します。

**所要時間:** 10分
**レベル:** 初級
**前提条件:** <doc:QuickStart>を完了していること

## 学習内容
- SwiftUIのモーダルとNavigatorの組み合わせ
- モーダル内でのナビゲーション
- NavigationContextによるメイン/モーダル判別
- モーダルナビゲーションの追跡

## 構築するもの
シート表示でナビゲーション可能なモーダルを持つアプリ。

---

## セクション1: 基本的なモーダル表示

### ステップ1.1: SwiftUIのsheetと組み合わせ

SwiftUIの標準的なシート表示とNavigatorを組み合わせます:

```swift
@main
struct MyApp: App {
    @State private var navigator = Navigator<AppRoute>()
    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigator.path) {
                HomeView(showSettings: $showSettings)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .environment(navigator)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
```

**重要なポイント**:
- SwiftUIの`sheet(isPresented:)`を使用
- モーダル表示はSwiftUIの標準機能を活用
- Navigatorはナビゲーションスタック管理に専念

**所要時間:** 1分

### ステップ1.2: モーダル内でのナビゲーション

モーダル内でナビゲーションが必要な場合は、モーダル専用のNavigatorを作成します:

```swift
struct SettingsView: View {
    @State private var modalNavigator = Navigator<SettingsRoute>()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $modalNavigator.path) {
            SettingsMainView()
                .navigationDestination(for: SettingsRoute.self) { route in
                    settingsDestinationView(for: route)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            dismiss()
                        }
                    }
                }
        }
        .environment(modalNavigator)
    }

    @ViewBuilder
    private func settingsDestinationView(for route: SettingsRoute) -> some View {
        switch route {
        case .account:
            AccountView()
        case .privacy:
            PrivacyView()
        case .notifications:
            NotificationView()
        }
    }
}
```

**重要なポイント**:
- モーダル専用のNavigatorを作成
- モーダル専用のルート型を定義可能
- モーダル内で独立したナビゲーションスタック

**所要時間:** 2分

---

## セクション2: モーダルのミドルウェア

### ステップ2.1: モーダル用ミドルウェアの作成

モーダル内のナビゲーションを追跡するミドルウェアを作成できます:

```swift
struct SettingsAnalyticsMiddleware: NavigationMiddleware {
    typealias Route = SettingsRoute

    func onNavigate(to route: SettingsRoute) {
        print("[settings] 画面表示: \(route)")
        // Analytics.logEvent("screen_viewed", screen: "\(route)", context: "modal")
    }

    func onPop(route: SettingsRoute) {
        print("[settings] 画面離脱: \(route)")
    }

    func onPopToRoot(removedRoutes: [SettingsRoute]) {
        for route in removedRoutes {
            print("[settings] 画面離脱: \(route)")
        }
    }
}
```

### ステップ2.2: ミドルウェアの登録

メインNavigatorとモーダルNavigatorの両方にミドルウェアを登録:

```swift
// メインNavigator
@State private var navigator: Navigator<AppRoute> = {
    let nav = Navigator<AppRoute>()
    nav.addMiddleware(AnalyticsMiddleware())
    return nav
}()

// モーダルNavigator（モーダル内で作成時）
@State private var modalNavigator: Navigator<SettingsRoute> = {
    let nav = Navigator<SettingsRoute>()
    nav.addMiddleware(SettingsAnalyticsMiddleware())
    return nav
}()
```

**試してみる**:
1. メイン画面でナビゲーション → 画面表示ログが出力
2. モーダルを開いてナビゲーション → `[settings] 画面表示: ...`

**所要時間:** 2分

---

## セクション3: アイテムベースのモーダル

### ステップ3.1: enum型でモーダルを管理

モーダルの種類を型安全に管理する場合:

```swift
enum ModalType: Identifiable {
    case settings
    case profile(userId: String)
    case compose

    var id: String {
        switch self {
        case .settings: return "settings"
        case .profile(let id): return "profile-\(id)"
        case .compose: return "compose"
        }
    }
}

struct ContentView: View {
    @State private var activeModal: ModalType?

    var body: some View {
        VStack {
            Button("設定を開く") {
                activeModal = .settings
            }

            Button("プロフィールを開く") {
                activeModal = .profile(userId: "123")
            }

            Button("作成") {
                activeModal = .compose
            }
        }
        .sheet(item: $activeModal) { modal in
            modalView(for: modal)
        }
    }

    @ViewBuilder
    private func modalView(for modal: ModalType) -> some View {
        switch modal {
        case .settings:
            SettingsView()
        case .profile(let userId):
            ProfileView(userId: userId)
        case .compose:
            ComposeView()
        }
    }
}
```

**重要なポイント**:
- `Identifiable`に準拠したenum型でモーダル管理
- Associated valueでパラメータを渡せる
- `sheet(item:)`で型安全なモーダル表示

**所要時間:** 2分

---

## セクション4: 高度なモーダルパターン

### パターン1: フルスクリーンカバー

```swift
.fullScreenCover(item: $activeModal) { modal in
    modalView(for: modal)
}
```

### パターン2: モーダル閉じる処理

```swift
struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .padding()
            }
            .navigationTitle("新規作成")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        saveAndDismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        // 保存処理
        dismiss()
    }
}
```

### パターン3: モーダルからメインへのナビゲーション

モーダルを閉じてからメインでナビゲーションする場合:

```swift
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Navigator<AppRoute>.self) private var mainNavigator

    var body: some View {
        List {
            Button("アカウント詳細を見る") {
                // モーダルを閉じる
                dismiss()
                // メインでナビゲーション（遅延実行）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    mainNavigator.push(.accountDetail)
                }
            }
        }
    }
}
```

**所要時間:** 2分

---

## チュートリアル完了！

### 学習した内容
- SwiftUIの標準モーダルとNavigatorの組み合わせ
- モーダル専用のNavigatorの作成
- モーダル専用のミドルウェア設定
- アイテムベースの型安全モーダル管理

### あなたのアプリの新機能
- モーダル内でのナビゲーション
- モーダル専用のナビゲーション追跡
- 型安全なモーダル表示

## 次のステップ

**学習を続ける:**
- <doc:Tabs> - タブと複数スタック（15分）
- <doc:Middleware> - 高度なミドルウェアパターン（20分）
- <doc:BestPractices> - 本番環境パターン（10分）

**APIを探索:**
- ``Navigator`` - ナビゲーションスタック管理
- ``NavigationMiddleware`` - ミドルウェアプロトコル

**ヘルプが必要ですか？**
- <doc:Troubleshooting>
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)
