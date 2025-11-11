# はじめに

Navigatorをプロジェクトに追加して、基本概念を学習しましょう。

## 概要

このガイドでは、Navigatorをプロジェクトに追加し、型安全ルーティングの基本概念を理解します。

**所要時間:** 2分

## インストール

### Swift Package Manager（推奨）

#### Xcode

1. Xcodeで **File → Add Package Dependencies...** を選択
2. リポジトリURLを入力:
   ```
   https://github.com/ViewFeature/Navigator.git
   ```
3. バージョン **0.1.0** 以降を選択
4. **Add Package** をクリック
5. ターゲットを選択して **Add Package** をクリック

#### Package.swift

Navigatorを`Package.swift`に追加:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    dependencies: [
        .package(url: "https://github.com/ViewFeature/Navigator.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["Navigator"]
        )
    ]
)
```

### インストールの確認

プロジェクトをビルドしてインストールを確認:

```bash
swift build
```

ビルドが成功すれば、Navigatorが正しくインストールされています。

## 基本概念

### Navigatableプロトコル

Navigatorの基礎となるプロトコル。`Navigatable`に準拠した型は、URLから解析され、URLに変換できます:

```swift
enum AppRoute: Navigatable, Sendable, Hashable {
    case home
    case profile(userId: String)
    case settings

    var path: String {
        switch self {
        case .home: return "home"
        case .profile: return "profile"
        case .settings: return "settings"
        }
    }

    func url(scheme: String) throws -> URL {
        switch self {
        case .home:
            return try URLParser.constructURL(path: path, queryItems: [], scheme: scheme)
        case .profile(let userId):
            return try URLParser.constructURL(path: path, queryItems: [
                URLQueryItem(name: "userId", value: userId)
            ], scheme: scheme)
        case .settings:
            return try URLParser.constructURL(path: path, queryItems: [], scheme: scheme)
        }
    }

    static func parse(from url: URL) -> Self? {
        let path = URLParser.routeKey(from: url.path)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch path {
        case "home": return .home
        case "profile":
            guard let userId: String = URLParser.optionalParam("userId", from: queryItems) else { return nil }
            return .profile(userId: userId)
        case "settings": return .settings
        default:
            return nil
        }
    }
}
```

**重要なポイント:**
- enum基盤で型安全
- 双方向: URL <-> Route 変換
- Associated valueでルートパラメータを表現
- `Sendable, Hashable`準拠が必須

**注意**: `@Route`マクロを使用すると、これらの実装を自動生成できます。

### 責任分離ルーター設計

Navigatorは責任分離の原則に基づき、専用ルーターを提供:

#### Navigator - ナビゲーション専用

```swift
@MainActor
@Observable
public final class Navigator<Route: Navigatable> {
    public var path: [Route] = []           // ナビゲーションスタック
    public private(set) var middlewares: [any NavigationMiddleware<Route>] = []

    // 専用ナビゲーションAPI
    public func push(_ route: Route)
    public func pop()
    public func pop(count: Int)
    public func pop(to route: Route)
    public func popToRoot()
    public func addMiddleware(_ middleware: any NavigationMiddleware<Route>)
}
```

#### TabNavigator - タブ管理専用

```swift
@MainActor
@Observable
public final class TabNavigator<Tab: Hashable> {
    public var selectedTab: Tab             // 選択中のタブ

    // 専用タブ管理API
    public func switchTo(_ tab: Tab)
    public func isSelected(_ tab: Tab) -> Bool
}
```

**重要なポイント:**
- 責任の明確な分離: ナビゲーション と タブ管理
- 各タブが独立したNavigatorを持つ設計
- Swift 6の`@MainActor`で完全なConcurrency対応
- `@Observable`でSwiftUIとの自動UI同期

### ルーターの作成

用途に応じて専用ルーターを組み合わせ:

| パターン | ルーター構成 | 用途 |
|---------|-------------|-----|
| ナビゲーションのみ | `Navigator<Route>` | 基本画面遷移 |
| タブ管理のみ | `TabNavigator<Tab>` | タブ切り替えのみ |
| フルアプリ | `Navigator<Route>` x N + `TabNavigator<Tab>` | タブ + 独立ナビゲーション |

```swift
// フルアプリでの例（責任分離）
@State private var homeNavigator = Navigator<AppRoute>()
@State private var profileNavigator = Navigator<AppRoute>()
@State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

// ミドルウェアは各Navigatorに個別設定
homeNavigator.addMiddleware(LoggingMiddleware())
profileNavigator.addMiddleware(AnalyticsMiddleware())
```

### ミドルウェアシステム

型安全な`NavigationMiddleware`でナビゲーションイベントを観察・拡張:

```swift
struct AnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        Analytics.logEvent("screen_viewed", screen: "\(route)")
    }

    func onPop(route: AppRoute) {
        Analytics.logEvent("screen_dismissed", screen: "\(route)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        for route in removedRoutes {
            Analytics.logEvent("screen_dismissed", screen: "\(route)")
        }
    }
}
```

**重要なポイント:**
- 型安全なルート特化ミドルウェア
- `onNavigate`、`onPop`、`onPopToRoot`の3つのイベントを追跡
- アナリティクス、ログ、デバッグに最適
- 各Navigatorに個別に設定可能

## アーキテクチャ概要

Navigatorは責任分離による明確なアーキテクチャ:

```
SwiftUI Views
    ↓ uses @Observable
Navigator<Route> + TabNavigator<Tab>
    ↓ implements
Core Protocols (Navigatable)
    ↓ uses
Foundation (URL, URLComponents)
```

**利点:**
- **責任分離**: 明確な役割分担で理解しやすい
- **独立性**: 各タブが独立したナビゲーション履歴
- **型安全性**: ジェネリクスによる完全な型チェック
- **性能**: @Observable による効率的なUI更新
- **テスト容易**: ミドルウェアによる振る舞い観察

## 次のステップ

### クイックスタート

実際にナビゲーション可能なアプリを構築する準備はできましたか？

<doc:QuickStart> は10分で基本的なナビゲーションアプリを作成します。

### チュートリアル

Navigatorを段階的に学習:

- <doc:Navigation> - ナビゲーションパターン（15分）
- <doc:Tabs> - マルチタブアプリ（15分）
- <doc:Middleware> - 高度なミドルウェア（20分）

### APIドキュメント

完全なAPIを探索:

- ``Navigator`` - ナビゲーション専用ルーター
- ``TabNavigator`` - タブ管理専用ルーター
- ``Navigatable`` - ルート用コアプロトコル
- ``NavigationMiddleware`` - ナビゲーションミドルウェア
- ``TabNavigationMiddleware`` - タブミドルウェア

### サンプルアプリ

完全なアプリを確認:

- [Demo](https://github.com/ViewFeature/Navigator/tree/main/Examples/Demo) - 包括的機能デモ

## トピック

### インストール

- Swift Package Manager
- 要件
- プラットフォームサポート

### 基本概念

- ``Navigator``
- ``TabNavigator``
- ``Navigatable``
- ``NavigationMiddleware``

### 次のステップ

- <doc:QuickStart>
- <doc:Navigation>
