# タブ & 複数スタック

独立したナビゲーションスタックを持つマルチタブアプリを構築しましょう。

## 概要

別々のナビゲーションスタックを各タブで管理し、タブ間の連携について学習します。

**所要時間:** 15分
**レベル:** 中級
**前提条件:** <doc:Navigation>を完了していること

## 学習内容
- TabNavigatorでのタブ設定
- 各タブでの独立したナビゲーションスタック
- タブ切り替えとナビゲーション状態管理
- TabNavigationMiddlewareでのタブイベント追跡

## 構築するもの
ホーム、検索、プロフィールタブを持つアプリ。各タブは独立したナビゲーション履歴を持ちます。

## 準備: ルート定義

このチュートリアルでは、以下のルート定義を使用します:

```swift
import Navigator

@Route
enum AppRoute {
    case home
    case articleDetail(id: String)
    case category(name: String)
    case searchResults(query: String)
    case trending
}
```

---

## セクション1: タブ設定

### ステップ1.1: タブ型の定義

タブ型を定義するため、必要なプロトコルに準拠:

```swift
import Navigator

enum AppTab: String, CaseIterable, Hashable {
    case home
    case search
    case profile

    var title: String {
        switch self {
        case .home: return "ホーム"
        case .search: return "検索"
        case .profile: return "プロフィール"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .profile: return "person"
        }
    }
}
```

**重要な要件**:
- `Hashable`への準拠が必要
- `CaseIterable`でタブ一覧を取得可能
- `title`、`icon`プロパティでタブの表示内容を定義

**所要時間:** 1分

### ステップ1.2: ルーターの作成

各タブに独立したNavigatorを作成:

```swift
@main
struct MyApp: App {
    // タブ管理用のTabNavigator
    @State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

    // 各タブ用の独立したNavigator
    @State private var homeNavigator = Navigator<AppRoute>()
    @State private var searchNavigator = Navigator<AppRoute>()
    @State private var profileNavigator = Navigator<AppRoute>()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabNavigator.selectedTab) {
                // ホームタブ
                NavigationStack(path: $homeNavigator.path) {
                    HomeTabView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

                // 検索タブ
                NavigationStack(path: $searchNavigator.path) {
                    SearchTabView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label(AppTab.search.title, systemImage: AppTab.search.icon)
                }
                .tag(AppTab.search)

                // プロフィールタブ
                NavigationStack(path: $profileNavigator.path) {
                    ProfileTabView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
            }
            .environment(tabNavigator)
            .environment(homeNavigator)
            .environment(searchNavigator)
            .environment(profileNavigator)
        }
    }

    // ... destinationView(for:) ...
}
```

**重要なポイント**:
- `TabNavigator<Tab>`でタブ選択状態を管理
- 各タブに独立した`Navigator<Route>`を作成
- 各NavigatorをEnvironmentに注入
- タブ切り替えでナビゲーション状態が保持される

**所要時間:** 2分

### ステップ1.3: タブをテスト

タブ設定をテスト:

1. タブ間切り替え
2. 各タブに初期ビューが表示
3. タブバーが正しく表示

**所要時間:** 30秒

---

## セクション2: 独立したナビゲーションスタック

### ステップ2.1: 各タブ内での独立したナビゲーション

```swift
struct HomeTabView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Text("ホームタブ")
                .font(.largeTitle)

            Text("現在のパス深度: \(navigator.path.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("記事を見る") {
                navigator.push(.articleDetail(id: "home-article-1"))
            }

            Button("カテゴリを見る") {
                navigator.push(.category(name: "技術"))
            }
        }
        .navigationTitle("ホーム")
    }
}

struct SearchTabView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Text("検索タブ")
                .font(.largeTitle)

            Text("現在のパス深度: \(navigator.path.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("検索結果を見る") {
                navigator.push(.searchResults(query: "SwiftUI"))
            }

            Button("トレンドを見る") {
                navigator.push(.trending)
            }
        }
        .navigationTitle("検索")
    }
}
```

**重要なポイント**:
- 各タブ内で対応するNavigatorをEnvironmentから取得
- `navigator.push()`で現在のタブ内をナビゲーション
- 各タブが独立したナビゲーション状態を保持

**注意**: 上記の例では、各タブのビューが同じ`Navigator<AppRoute>`型を使用しています。この場合、SwiftUIは最も近い祖先から注入されたNavigatorを取得するため、各タブ内のNavigationStackに`.environment()`で注入されたNavigatorが正しく取得されます。タブごとに異なるルート型（例: `HomeRoute`, `SearchRoute`）を使う場合は、それぞれのNavigator型が異なるため自然に区別されます。

### ステップ2.2: 独立したナビゲーションのテスト

独立したナビゲーションをテスト:

1. ホームタブ: ホーム → 記事 → 詳細 (深度: 2)
2. 検索タブに切り替え
3. 検索タブ: 検索 → 結果 (深度: 1)
4. ホームタブに戻る
5. ホームタブは依然として: ホーム → 記事 → 詳細 (深度: 2)

**各タブが自身のナビゲーション状態を保持！**

**所要時間:** 3分

---

## セクション3: タブ切り替え

### ステップ3.1: プログラマティックなタブ切り替え

`TabNavigator.switchTo(_:)`を使用してタブを切り替え:

```swift
struct ArticleView: View {
    let articleId: String
    @Environment(TabNavigator<AppTab>.self) private var tabNavigator

    var body: some View {
        VStack(spacing: 20) {
            Text("記事: \(articleId)")
                .font(.title)

            Button("検索タブに移動") {
                tabNavigator.switchTo(.search)
            }

            Button("プロフィールタブに移動") {
                tabNavigator.switchTo(.profile)
            }
        }
        .navigationTitle("記事")
    }
}
```

**重要なポイント**:
- `switchTo(_:)`でプログラマティックにタブ切り替え
- 切り替え先タブのナビゲーション状態は保持される

### ステップ3.2: タブ切り替えのテスト

タブ切り替えをテスト:

1. ホームタブで「検索タブに移動」をタップ
2. アプリが検索タブに切り替わる
3. 検索タブの状態が保持されている

**所要時間:** 1.5分

---

## セクション4: タブミドルウェア

### ステップ4.1: タブ切り替えを追跡するミドルウェアの作成

`TabAnalyticsMiddleware.swift`を作成:

```swift
import Navigator

struct TabAnalyticsMiddleware: TabNavigationMiddleware {
    typealias Tab = AppTab

    func onTabSwitch(fromTab oldTab: AppTab, toTab newTab: AppTab) {
        print("タブ変更: \(oldTab.title) → \(newTab.title)")
        // Analytics.logEvent("tab_changed", from: oldTab.rawValue, to: newTab.rawValue)
    }
}
```

**何が追跡されるか**:
- すべてのタブ切り替えイベント
- 前のタブと新しいタブの情報

### ステップ4.2: タブミドルウェアの登録

TabNavigatorにタブミドルウェアを登録:

```swift
@State private var tabNavigator: TabNavigator<AppTab> = {
    let navigator = TabNavigator<AppTab>(defaultTab: .home)
    navigator.addMiddleware(TabAnalyticsMiddleware())
    return navigator
}()
```

### ステップ4.3: タブ切り替え追跡のテスト

タブ切り替え追跡をテスト:

コンソール出力:
```
タブ変更: ホーム → 検索
タブ変更: 検索 → プロフィール
```

**完全なタブナビゲーション追跡！**

**所要時間:** 2分

---

## セクション5: 高度なタブパターン

### パターン1: 条件付きタブ表示

```swift
var availableTabs: [AppTab] {
    var tabs: [AppTab] = [.home, .search]
    if user.isLoggedIn {
        tabs.append(.profile)
    }
    return tabs
}

// TabViewで:
ForEach(availableTabs, id: \.self) { tab in
    // ...
}
```

### パターン2: タブごとのミドルウェア

```swift
// 特定タブ用のナビゲーションミドルウェア
homeNavigator.addMiddleware(HomeAnalyticsMiddleware())
searchNavigator.addMiddleware(SearchAnalyticsMiddleware())
```

### パターン3: タブ選択状態の確認

```swift
// 現在のタブを確認
if tabNavigator.isSelected(.home) {
    // ホームタブが選択されている
}

// 選択状態で条件分岐
switch tabNavigator.selectedTab {
case .home:
    // ホームタブの処理
case .search:
    // 検索タブの処理
case .profile:
    // プロフィールタブの処理
}
```

**所要時間:** 2分

---

## チュートリアル完了！

### 学習した内容
- `TabNavigator<Tab>`でタブ状態管理
- 各タブでの独立したNavigator
- `switchTo(_:)`によるプログラマティックなタブ切り替え
- `TabNavigationMiddleware`によるタブ切り替え追跡

### あなたのアプリの新機能
- 独立したタブナビゲーション
- 完全なタブ切り替え追跡
- 各タブのナビゲーション状態保持

## 次のステップ

**学習を続ける:**
- <doc:Middleware> - 高度なミドルウェアパターン（20分）
- <doc:BestPractices> - 本番環境パターン（10分）
- <doc:Troubleshooting> - よくある問題と解決策（5分）

**APIを探索:**
- ``TabNavigator`` - タブ状態管理
- ``TabNavigationMiddleware`` - タブイベント追跡
- ``Navigator`` - ナビゲーションスタック管理

**ヘルプが必要ですか？**
- <doc:Troubleshooting>
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)
