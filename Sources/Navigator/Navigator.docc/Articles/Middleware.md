# 高度なミドルウェア

本番アプリ向けの高度なミドルウェアパターンをマスターしましょう。

## 概要

アナリティクス、ログ、デバッグなどの様々な用途に向けて、カスタムミドルウェアを構築する方法を学習します。

**所要時間:** 20分
**レベル:** 中級-上級
**前提条件:** <doc:Navigation>を完了していること

## 学習内容
- NavigationMiddlewareの実装
- TabNavigationMiddlewareの実装
- 複数ミドルウェアの組み合わせ
- ミドルウェアの動的管理（トークンベースの削除）
- 非同期ミドルウェア処理
- ミドルウェアのテスト

## 構築するもの
完全なアナリティクス追跡とログ機能を持つミドルウェアシステム。

## 準備: ルート定義

このチュートリアルでは、以下のルート定義を使用します:

```swift
import Navigator

@Route
enum AppRoute {
    case home
    case articleDetail(id: String)
    case authorProfile(id: String)
    case settings
    case search
    case category(name: String)
}

enum AppTab: String, CaseIterable, Hashable {
    case home
    case search
    case profile
}
```

---

## セクション1: NavigationMiddlewareの基本

### ステップ1.1: 基本的なミドルウェアの作成

`NavigationMiddleware`プロトコルを実装してナビゲーションイベントを追跡:

```swift
import Navigator

struct LoggingMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        print("🧭 Navigate: \(route)")
    }

    func onPop(route: AppRoute) {
        print("⬅️ Pop: \(route)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        print("🏠 Pop to root, removed: \(removedRoutes.count) routes")
    }
}
```

**重要なポイント**:
- `NavigationMiddleware`プロトコルに準拠
- `typealias Route`でルート型を指定
- `onNavigate(to:)`で新規ナビゲーションを追跡
- `onPop(route:)`でポップ操作を追跡
- `onPopToRoot(removedRoutes:)`でルートへの戻りを追跡

**所要時間:** 2分

### ステップ1.2: アナリティクスミドルウェアの作成

```swift
// 注: Analyticsは実際のアナリティクスSDK（Firebase Analytics, Mixpanel, Amplitudeなど）に
// 置き換えてください。以下は概念を示すための擬似コードです。
struct AnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        let screenName = screenName(for: route)

        Analytics.logEvent("screen_viewed", parameters: [
            "screen": screenName,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func onPop(route: AppRoute) {
        let screenName = screenName(for: route)

        Analytics.logEvent("screen_dismissed", parameters: [
            "screen": screenName,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        for route in removedRoutes {
            Analytics.logEvent("screen_dismissed", parameters: [
                "screen": screenName(for: route),
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }

    private func screenName(for route: AppRoute) -> String {
        switch route {
        case .home: return "Home"
        case .articleDetail(let id): return "Article/\(id)"
        case .authorProfile(let id): return "Author/\(id)"
        case .settings: return "Settings"
        case .search: return "Search"
        case .category(let name): return "Category/\(name)"
        }
    }
}
```

**所要時間:** 2分

---

## セクション2: TabNavigationMiddleware

### ステップ2.1: タブミドルウェアの作成

`TabNavigationMiddleware`プロトコルを実装してタブ切り替えを追跡:

```swift
struct TabAnalyticsMiddleware: TabNavigationMiddleware {
    typealias Tab = AppTab

    func onTabSwitch(fromTab oldTab: AppTab, toTab newTab: AppTab) {
        print("📊 タブ変更: \(oldTab) → \(newTab)")

        Analytics.logEvent("tab_changed", parameters: [
            "from": oldTab.rawValue,
            "to": newTab.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}
```

### ステップ2.2: タブミドルウェアの登録

```swift
@State private var tabNavigator: TabNavigator<AppTab> = {
    let navigator = TabNavigator<AppTab>(defaultTab: .home)
    navigator.addMiddleware(TabAnalyticsMiddleware())
    return navigator
}()
```

**所要時間:** 2分

---

## セクション3: 複数ミドルウェアの組み合わせ

### ステップ3.1: 異なる関心事向けのミドルウェア作成

```swift
// アナリティクス用
struct AnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        Analytics.logEvent("screen_viewed", screen: screenName(for: route))
    }

    func onPop(route: AppRoute) {
        Analytics.logEvent("screen_dismissed", screen: screenName(for: route))
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        for route in removedRoutes {
            Analytics.logEvent("screen_dismissed", screen: screenName(for: route))
        }
    }

    private func screenName(for route: AppRoute) -> String {
        return "\(route)"
    }
}

// ログ用
struct LoggingMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        print("🧭 Navigate: \(route)")
    }

    func onPop(route: AppRoute) {
        print("⬅️ Pop: \(route)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        print("🏠 Pop to root: \(removedRoutes)")
    }
}

// デバッグ用（DEBUG時のみ）
struct DebugMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        #if DEBUG
        print("🐛 [DEBUG] Navigate: \(route)")
        #endif
    }

    func onPop(route: AppRoute) {
        #if DEBUG
        print("🐛 [DEBUG] Pop: \(route)")
        #endif
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        #if DEBUG
        print("🐛 [DEBUG] Pop to root: \(removedRoutes)")
        #endif
    }
}
```

### ステップ3.2: 複数ミドルウェアの登録

```swift
@State private var navigator: Navigator<AppRoute> = {
    let nav = Navigator<AppRoute>()
    nav.addMiddleware(AnalyticsMiddleware())
    nav.addMiddleware(LoggingMiddleware())
    #if DEBUG
    nav.addMiddleware(DebugMiddleware())
    #endif
    return nav
}()
```

**分離の利点**:
- 各ミドルウェアが単一の責任を持つ
- 独立してテスト・デバッグ可能
- 必要に応じて個別に有効化/無効化

**所要時間:** 3分

---

## セクション4: ミドルウェアの動的管理

### ステップ4.1: トークンベースのミドルウェア削除

`addMiddleware`はトークンを返し、そのトークンを使って特定のミドルウェアインスタンスを削除できます:

```swift
// ミドルウェアを追加し、トークンを保持
let loggingToken = navigator.addMiddleware(LoggingMiddleware())
let analyticsToken = navigator.addMiddleware(AnalyticsMiddleware())

// 後で特定のミドルウェアだけを削除
navigator.removeMiddleware(token: loggingToken)
// AnalyticsMiddlewareは引き続き動作
```

### ステップ4.2: 型ベースのミドルウェア削除

同じ型のミドルウェアをすべて削除する場合:

```swift
// 特定の型のミドルウェアをすべて削除
let removedCount = navigator.removeMiddleware(LoggingMiddleware.self)
print("Removed \(removedCount) logging middlewares")

// すべてのミドルウェアをクリア
navigator.clearMiddlewares()
```

### ステップ4.3: 実践的なユースケース

```swift
class FeatureFlagManager {
    private var analyticsToken: NavigationMiddlewareToken?
    private let navigator: Navigator<AppRoute>

    init(navigator: Navigator<AppRoute>) {
        self.navigator = navigator
    }

    /// アナリティクスを有効化
    func enableAnalytics() {
        guard analyticsToken == nil else { return }
        analyticsToken = navigator.addMiddleware(AnalyticsMiddleware())
    }

    /// アナリティクスを無効化
    func disableAnalytics() {
        guard let token = analyticsToken else { return }
        navigator.removeMiddleware(token: token)
        analyticsToken = nil
    }
}

// TabNavigatorも同様にトークンベースの削除が可能
let tabToken = tabNavigator.addMiddleware(TabAnalyticsMiddleware())
tabNavigator.removeMiddleware(token: tabToken)
```

**重要なポイント**:
- トークンを保持することで、特定のインスタンスを正確に削除可能
- 型ベース削除は同じ型のすべてのインスタンスを削除
- `clearMiddlewares()`はテストやリセット時に便利

**所要時間:** 2分

---

## セクション5: 条件付きミドルウェア

### ステップ5.1: 条件に基づいて動作が変わるミドルウェア

```swift
struct ConditionalMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    let isDebugMode: Bool
    let isAnalyticsEnabled: Bool

    func onNavigate(to route: AppRoute) {
        // デバッグログ（デバッグモード時のみ）
        if isDebugMode {
            print("🔍 [CONDITIONAL] Navigate: \(route)")
        }

        // アナリティクス（ユーザー同意時のみ）
        if isAnalyticsEnabled {
            Analytics.logEvent("navigation", screen: "\(route)")
        }
    }

    func onPop(route: AppRoute) {
        if isDebugMode {
            print("🔍 [CONDITIONAL] Pop: \(route)")
        }
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        if isDebugMode {
            print("🔍 [CONDITIONAL] Pop to root: \(removedRoutes)")
        }
    }
}

// 使用例
let middleware = ConditionalMiddleware(
    isDebugMode: ProcessInfo.processInfo.environment["DEBUG"] != nil,
    isAnalyticsEnabled: UserDefaults.standard.bool(forKey: "analytics_enabled")
)
navigator.addMiddleware(middleware)
```

**所要時間:** 2分

---

## セクション6: 非同期ミドルウェア

### ステップ6.1: 非同期操作を実行するミドルウェア

ミドルウェアメソッドは同期的に呼ばれますが、内部で非同期タスクを起動できます:

```swift
struct AsyncAnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    private let analyticsService: AnalyticsService

    init(analyticsService: AnalyticsService = .shared) {
        self.analyticsService = analyticsService
    }

    func onNavigate(to route: AppRoute) {
        // 非同期でアナリティクス送信（ナビゲーションをブロックしない）
        Task {
            await analyticsService.trackNavigation(
                screen: screenName(for: route),
                timestamp: Date()
            )
        }
    }

    func onPop(route: AppRoute) {
        Task {
            await analyticsService.trackPop(screen: screenName(for: route))
        }
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        Task {
            for route in removedRoutes {
                await analyticsService.trackPop(screen: screenName(for: route))
            }
        }
    }

    private func screenName(for route: AppRoute) -> String {
        return "\(route)"
    }
}

// AnalyticsServiceの例
actor AnalyticsService {
    static let shared = AnalyticsService()

    func trackNavigation(screen: String, timestamp: Date) async {
        // ネットワーク呼び出し
        try? await Task.sleep(nanoseconds: 100_000_000)
        print("📊 Async analytics sent: \(screen)")
    }

    func trackPop(screen: String) async {
        print("📊 Async pop tracked: \(screen)")
    }
}
```

**重要なポイント**:
- ミドルウェアメソッド自体は同期的
- 内部で`Task`を使って非同期処理を起動
- ナビゲーションをブロックしない

**所要時間:** 3分

---

## セクション7: ユーザーフロー追跡

### ステップ7.1: ナビゲーションパス追跡

```swift
class FlowTrackingMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    private var navigationPath: [String] = []
    private let maxPathLength = 10

    func onNavigate(to route: AppRoute) {
        let screenName = "\(route)"
        navigationPath.append(screenName)

        // 最大長を維持
        if navigationPath.count > maxPathLength {
            navigationPath.removeFirst()
        }

        print("🗺️ User flow: \(navigationPath.joined(separator: " → "))")

        // 特定パターンの検出
        detectNavigationPatterns()
    }

    func onPop(route: AppRoute) {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        print("🔙 User returned, flow: \(navigationPath.joined(separator: " → "))")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        navigationPath.removeAll()
        print("🔙 User returned to root")
    }

    private func detectNavigationPatterns() {
        let pathString = navigationPath.joined(separator: "→")

        if pathString.contains("home→article→author") {
            Analytics.logEvent("common_flow_article_to_author")
        }

        if pathString.contains("search→results→article") {
            Analytics.logEvent("common_flow_search_to_article")
        }
    }
}
```

**所要時間:** 3分

---

## セクション8: ミドルウェアのテスト

### ステップ8.1: ミドルウェアのユニットテスト

```swift
import XCTest
@testable import YourApp

class MiddlewareTests: XCTestCase {

    func testAnalyticsMiddlewareBehavior() {
        // Given
        let mockAnalytics = MockAnalytics()
        let middleware = AnalyticsMiddleware(analytics: mockAnalytics)
        let route = AppRoute.articleDetail(id: "test-123")

        // When
        middleware.onNavigate(to: route)

        // Then
        XCTAssertTrue(mockAnalytics.didLogNavigation)
        XCTAssertEqual(mockAnalytics.lastScreen, "Article/test-123")
    }

    func testPopToRootTracking() {
        // Given
        let mockAnalytics = MockAnalytics()
        let middleware = AnalyticsMiddleware(analytics: mockAnalytics)
        let routes: [AppRoute] = [.home, .articleDetail(id: "test-123")]

        // When
        middleware.onPopToRoot(removedRoutes: routes)

        // Then
        XCTAssertEqual(mockAnalytics.popCount, 2)
    }
}

// モック
class MockAnalytics {
    var didLogNavigation = false
    var lastScreen: String?
    var popCount = 0

    func logEvent(_ name: String, screen: String) {
        didLogNavigation = true
        lastScreen = screen
        if name == "screen_dismissed" {
            popCount += 1
        }
    }
}
```

**所要時間:** 3分

---

## チュートリアル完了！

### 学習した内容
- `NavigationMiddleware`でナビゲーション追跡
- `TabNavigationMiddleware`でタブ切り替え追跡
- `onNavigate`、`onPop`、`onPopToRoot`の3つのイベント
- 複数ミドルウェアの組み合わせ
- トークンベースのミドルウェア動的管理
- 非同期ミドルウェアパターン
- ミドルウェアのテスト

### あなたのアプリの新機能
- 包括的なユーザー行動追跡
- 条件付きアナリティクス
- ユーザーフロー分析
- テスト可能なミドルウェア

## 次のステップ

**学習を続ける:**
- <doc:BestPractices> - 本番環境向けパターン（10分）
- <doc:Troubleshooting> - よくある問題と解決策（5分）

**さらに探索:**
- ``NavigationMiddleware`` - ナビゲーションミドルウェアプロトコル
- ``TabNavigationMiddleware`` - タブミドルウェアプロトコル

**ヘルプが必要ですか？**
- <doc:Troubleshooting>
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)
