# Navigator

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS-blue.svg)](https://github.com/ViewFeature/Navigator)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md)

SwiftUIアプリ向けの型安全なナビゲーションライブラリ。`@Route`マクロによる宣言的なルーティングと、ディープリンク、ミドルウェア、Swift 6 Concurrencyをサポートします。

### クイック例

```swift
import Navigator
import SwiftUI

@Route
enum AppRoute {
    case home
    case profile(userId: String)
    case article(id: String, section: String?)
}

struct ContentView: View {
    @State private var navigator = Navigator<AppRoute>()

    var body: some View {
        NavigationStack(path: $navigator.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .profile(let userId):
                        ProfileView(userId: userId)
                    case .article(let id, let section):
                        ArticleView(id: id, section: section)
                    }
                }
        }
        .environment(navigator)
    }
}

struct HomeView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Button("プロフィールを見る") {
                navigator.push(.profile(userId: "123"))
            }

            Button("戻る") {
                navigator.pop()
            }
        }
    }
}
```

## 4つのコアプリンシプル

### 1. 宣言的なルート定義

シンプルなenumと`@Route`マクロでルートを定義。マクロがURL解析、パス生成、`Hashable`準拠を自動生成します。

```swift
@Route
enum AppRoute {
    case home
    case profile(userId: String)
    case article(id: String, section: String?)
}

// 自動生成されるプロパティ:
AppRoute.home.path           // → "home"
AppRoute.profile(userId: "123").url(scheme: "myapp")
// → myapp://profile?userId=123
```

- URL処理のボイラープレート不要
- 型安全なパラメータ
- オプショナルパラメータ対応

### 2. 責任分離

Navigatorはスタックナビゲーションとタブ管理を分離。`Navigator`がpush/pop操作を、`TabNavigator`がタブ選択を管理します。

```swift
// スタックナビゲーション
@State private var navigator = Navigator<AppRoute>()

// タブ管理
@State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

// それぞれが専用のAPIを持つ
navigator.push(.profile(userId: "123"))
navigator.pop()

tabNavigator.switchTo(.settings)
```

- 各コンポーネントが単一の責任
- クリーンで焦点を絞ったAPI
- テストと理解が容易

### 3. ディープリンク内蔵

すべてのルートが自動的にディープリンクをサポート。URLをルートに解析し、ルートからURLを生成—すべて型安全。

```swift
// URL生成
let url = AppRoute.profile(userId: "123").url(scheme: "myapp")
// → myapp://profile?userId=123

// URL解析
let route = AppRoute.parse(from: url)
// → Optional(.profile(userId: "123"))

// SwiftUIでの処理
NavigationStack(path: $navigator.path) {
    HomeView()
        .navigationDestination(for: AppRoute.self) { ... }
}
.onOpenURL { url in
    if let route = AppRoute.parse(from: url) {
        navigator.push(route)
    }
}
```

- 自動URL生成
- 型安全なURL解析
- SwiftUI統合済み

### 4. MainActor分離

NavigatorはSwift 6の厳密なConcurrencyに対応。すべてのナビゲーション操作が`@MainActor`分離され、コンパイル時にスレッド安全性を保証します。

```swift
@MainActor
@Observable
public final class Navigator<Route: Navigatable> {
    public var path: [Route] = []

    public func push(_ route: Route) {
        path.append(route)
        // ...
    }
}
```

- コンパイル時のスレッド安全性
- データ競合なし
- `defaultIsolation(MainActor.self)`と連携

## 高度な機能

### タブナビゲーション

```swift
enum AppTab: Hashable {
    case home, profile, settings
}

struct ContentView: View {
    @State private var homeNav = Navigator<AppRoute>()
    @State private var profileNav = Navigator<AppRoute>()
    @State private var tabNav = TabNavigator<AppTab>(defaultTab: .home)

    var body: some View {
        TabView(selection: $tabNav.selectedTab) {
            NavigationStack(path: $homeNav.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeView(for: route)
                    }
            }
            .tabItem { Label("ホーム", systemImage: "house") }
            .tag(AppTab.home)
            .environment(homeNav)

            NavigationStack(path: $profileNav.path) {
                ProfileView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeView(for: route)
                    }
            }
            .tabItem { Label("プロフィール", systemImage: "person") }
            .tag(AppTab.profile)
            .environment(profileNav)
        }
        .environment(tabNav)
    }
}
```

### ミドルウェア

ログ、アナリティクス、バリデーションなどの横断的関心事を追加:

```swift
struct LoggingMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        print("ナビゲート: \(route.path)")
    }

    func onPop(route: AppRoute) {
        print("ポップ: \(route.path)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        print("ルートへポップ: \(removedRoutes.count)件削除")
    }
}

// ミドルウェアを追加
let token = navigator.addMiddleware(LoggingMiddleware())

// 後でトークンを使って削除
navigator.removeMiddleware(token: token)
```

タブナビゲーションもミドルウェアをサポート:

```swift
struct TabLoggingMiddleware: TabNavigationMiddleware {
    typealias Tab = AppTab

    func onTabSwitch(fromTab: AppTab, toTab: AppTab) {
        print("タブ切替: \(fromTab) → \(toTab)")
    }
}

tabNav.addMiddleware(TabLoggingMiddleware())
```

## APIリファレンス

### Navigator

| メソッド | 説明 |
|---------|------|
| `push(_:)` | ルートをスタックにプッシュ |
| `pop()` | 現在のルートをポップ |
| `pop(count:)` | 複数のルートをポップ |
| `pop(to:)` | 指定ルートまでポップ |
| `popToRoot()` | ナビゲーションスタックをクリア |
| `addMiddleware(_:)` | ミドルウェアを追加（トークンを返す） |
| `removeMiddleware(token:)` | トークンでミドルウェアを削除 |
| `removeMiddleware(_:)` | 型でミドルウェアを削除 |
| `clearMiddlewares()` | 全ミドルウェアを削除 |

### TabNavigator

| メソッド | 説明 |
|---------|------|
| `switchTo(_:)` | タブを切り替え |
| `isSelected(_:)` | タブが選択中か確認 |
| `addMiddleware(_:)` | ミドルウェアを追加（トークンを返す） |
| `removeMiddleware(token:)` | トークンでミドルウェアを削除 |
| `removeMiddleware(_:)` | 型でミドルウェアを削除 |
| `clearMiddlewares()` | 全ミドルウェアを削除 |

## インストール

### Swift Package Manager

`Package.swift`にNavigatorを追加:

```swift
dependencies: [
    .package(url: "https://github.com/ViewFeature/Navigator.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "Navigator", package: "Navigator")
        ],
        swiftSettings: [
            .defaultIsolation(MainActor.self)  // 推奨
        ]
    )
]
```

### Xcode

- **File → Add Package Dependencies** を選択
- URLを入力: `https://github.com/ViewFeature/Navigator.git`
- バージョン: `0.1.0` 以降を選択

**推奨**: ターゲットの **Build Settings → Other Swift Flags** に `-default-isolation MainActor` を追加。

### 要件

- iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+
- Swift 6.2+
- Xcode 16.2+

## コントリビュート

コントリビュートを歓迎します！

プルリクエストを送信する前に、[Contributing Guide](CONTRIBUTING.md)をご確認ください。質問やアイデアがあれば、[Discussion](https://github.com/ViewFeature/Navigator/discussions)を開始してください。

### コミュニティ

- **[Issue報告](https://github.com/ViewFeature/Navigator/issues)** - バグ報告と機能リクエスト
- **[Discussions](https://github.com/ViewFeature/Navigator/discussions)** - 質問とアイデアの共有

## クレジット

Navigatorは以下のライブラリとコミュニティからインスピレーションを受けています:

- [SwiftUI NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) - AppleのネイティブナビゲーションAPI
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - Swiftでのナビゲーションパターン
- [swift-syntax](https://github.com/apple/swift-syntax) - Swiftマクロ基盤

## メンテナー

- [Takeshi SHIMADA](https://github.com/takeshishimada)

## ライセンス

NavigatorはMITライセンスの下で配布されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。
