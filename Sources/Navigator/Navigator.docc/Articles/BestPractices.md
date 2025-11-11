# 本番環境のベストプラクティス

本番品質のNavigatorアプリを構築するための実証済みパターンとガイドライン。

## 概要

このガイドでは、Navigatorを使用して本番環境で信頼性とパフォーマンスを確保するためのベストプラクティスを提供します。

**所要時間:** 10分
**レベル:** 中級-上級
**前提条件:** <doc:Middleware>を完了していること

## 学習内容
- エラー処理のベストプラクティス
- テスト戦略とパターン
- パフォーマンス最適化
- セキュリティ考慮事項
- モジュラーアーキテクチャ

---

## エラー処理

### Deep Linkエラーの適切な処理

```swift
// Bad - エラーを無視
.onOpenURL { url in
    if let route = AppRoute.parse(from: url) {
        navigator.push(route)
    }
}

// Good - ユーザーにエラーを通知
@State private var errorMessage = ""
@State private var showError = false

.onOpenURL { url in
    guard let route = AppRoute.parse(from: url) else {
        errorMessage = "無効なリンクです: \(url)"
        showError = true
        return
    }
    navigator.push(route)
}
.alert("エラー", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

### ルート解析の堅牢性

```swift
// 型安全なパラメータ抽出
static func parse(from url: URL) -> Self? {
    let routeKey = URLParser.routeKey(from: url.path)
    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    switch routeKey {
    case "article":
        // 必須パラメータの検証
        guard let id: String = URLParser.optionalParam("id", from: queryItems),
              !id.isEmpty else {
            return nil
        }
        return .articleDetail(id: id)

    case "user":
        // 数値パラメータの検証
        guard let userIdString: String = URLParser.optionalParam("userId", from: queryItems),
              let userId = Int(userIdString),
              userId > 0 else {
            return nil
        }
        return .userProfile(userId: userId)

    default:
        return nil
    }
}
```

---

## テスト戦略

### ルートのユニットテスト

```swift
import XCTest
@testable import YourApp

class AppRouteTests: XCTestCase {
    func testArticleRouteParsingSuccess() {
        // Given
        let url = URL(string: "myapp://article?id=test-123")!

        // When
        let route = AppRoute.parse(from: url)

        // Then
        XCTAssertNotNil(route)
        if case .articleDetail(let id) = route {
            XCTAssertEqual(id, "test-123")
        } else {
            XCTFail("Expected articleDetail route")
        }
    }

    func testArticleRouteParsingFailure() {
        // Given
        let url = URL(string: "myapp://article")! // IDが不足

        // When
        let route = AppRoute.parse(from: url)

        // Then
        XCTAssertNil(route, "IDが不足しているURLはnilを返すべき")
    }

    func testBidirectionalRouting() throws {
        // Given
        let originalRoute = AppRoute.articleDetail(id: "test-456")

        // When - Route to URL
        let url = try originalRoute.url(scheme: "myapp")

        // Then - URL back to Route
        let parsedRoute = AppRoute.parse(from: url)
        XCTAssertEqual(originalRoute, parsedRoute)
    }
}
```

### ナビゲーションの統合テスト

```swift
class NavigationFlowTests: XCTestCase {
    @MainActor
    func testCompleteUserFlow() async {
        // Given - 空のスタック状態
        let navigator = Navigator<AppRoute>()
        XCTAssertTrue(navigator.path.isEmpty)

        // When - ユーザーフローをシミュレート
        navigator.push(.home)
        navigator.push(.articleDetail(id: "article-1"))
        navigator.push(.authorProfile(id: "author-1"))

        // Then - スタック状態を確認
        XCTAssertEqual(navigator.path.count, 3)

        // When - 戻る操作
        navigator.popToRoot()

        // Then - 正しい状態
        XCTAssertTrue(navigator.path.isEmpty)
    }
}
```

### ミドルウェアのテスト

```swift
class MiddlewareTests: XCTestCase {
    @MainActor
    func testMiddlewareCalledOnNavigation() async {
        // Given
        let mockMiddleware = MockMiddleware()
        let navigator = Navigator<AppRoute>()
        navigator.addMiddleware(mockMiddleware)

        // When
        navigator.push(.home)

        // Then
        XCTAssertTrue(mockMiddleware.onNavigateCalled)
        XCTAssertEqual(mockMiddleware.lastNavigatedRoute, .home)
    }
}

class MockMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    var onNavigateCalled = false
    var lastNavigatedRoute: AppRoute?

    func onNavigate(to route: AppRoute) {
        onNavigateCalled = true
        lastNavigatedRoute = route
    }

    func onPop(route: AppRoute) { }

    func onPopToRoot(removedRoutes: [AppRoute]) { }
}
```

---

## パフォーマンス最適化

### 大きなナビゲーションスタックの処理

```swift
extension Navigator {
    /// スタックが深すぎる場合の警告
    func checkStackDepth(maxDepth: Int = 20) {
        if path.count > maxDepth {
            print("Warning: Navigation stack is \(path.count) deep")
        }
    }
}

// ミドルウェアでの監視
struct StackDepthMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    let maxDepth: Int = 20

    func onNavigate(to route: AppRoute) {
        // スタック深度の監視は別途行う
        #if DEBUG
        print("Navigation to: \(route)")
        #endif
    }

    func onPop(route: AppRoute) { }

    func onPopToRoot(removedRoutes: [AppRoute]) { }
}
```

### ミドルウェアパフォーマンス

```swift
struct OptimizedAnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        // メインスレッドをブロックしない
        Task.detached(priority: .utility) {
            await AnalyticsService.shared.trackNavigation(
                screen: "\(route)",
                timestamp: Date()
            )
        }
    }

    func onPop(route: AppRoute) {
        Task.detached(priority: .utility) {
            await AnalyticsService.shared.trackPop(screen: "\(route)")
        }
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        Task.detached(priority: .utility) {
            for route in removedRoutes {
                await AnalyticsService.shared.trackPop(screen: "\(route)")
            }
        }
    }
}
```

---

## セキュリティ考慮事項

### Deep Linkの検証

```swift
struct SecureRouteParser {
    enum ValidationError: Error {
        case invalidScheme
        case unauthorizedPath
        case parseFailed
    }

    /// セキュリティ検証付きのURL解析
    /// - Returns: 検証済みルートまたはエラー
    static func parse(_ url: URL) -> Result<AppRoute, ValidationError> {
        // スキーム検証
        guard url.scheme == "myapp" else {
            return .failure(.invalidScheme)
        }

        // パス検証
        let allowedPaths = ["home", "article", "profile", "settings"]
        let routeKey = URLParser.routeKey(from: url.path)
        guard allowedPaths.contains(routeKey) else {
            return .failure(.unauthorizedPath)
        }

        // 標準のparse(from:)でルート解析
        guard let route = AppRoute.parse(from: url) else {
            return .failure(.parseFailed)
        }

        return .success(route)
    }

    /// シンプルなOptional版
    static func parseSecurely(_ url: URL) -> AppRoute? {
        // スキーム検証
        guard url.scheme == "myapp" else { return nil }

        // パス検証
        let allowedPaths = ["home", "article", "profile", "settings"]
        let routeKey = URLParser.routeKey(from: url.path)
        guard allowedPaths.contains(routeKey) else { return nil }

        // 標準のparse(from:)でルート解析
        return AppRoute.parse(from: url)
    }
}

// 使用例
.onOpenURL { url in
    switch SecureRouteParser.parse(url) {
    case .success(let route):
        navigator.push(route)
    case .failure(let error):
        print("Deep link validation failed: \(error)")
    }
}
```

### 機密情報の保護

```swift
// Bad - URLに機密情報
enum BadRoute: Navigatable {
    case userProfile(userId: String, accessToken: String) // 危険！
}

// Good - IDのみ、詳細は安全に取得
enum SecureRoute: Navigatable {
    case userProfile(userId: String)
}

struct ProfileView: View {
    let userId: String
    @State private var profile: UserProfile?

    var body: some View {
        Text("Profile: \(userId)")
        // 認証済みAPIから安全にデータ取得
        .task {
            profile = await UserService.shared.getProfile(userId: userId)
        }
    }
}
```

---

## モジュラーアーキテクチャ

### フィーチャーベースのルート組織化

```swift
// 各フィーチャーモジュールが独自のルートを定義
enum HomeFeatureRoute: Navigatable, Sendable, Hashable {
    case dashboard
    case notifications
    // ...Navigatable実装
}

enum ArticleFeatureRoute: Navigatable, Sendable, Hashable {
    case list
    case detail(id: String)
    case editor
    // ...Navigatable実装
}

// メインアプリルートが統合
enum AppRoute: Navigatable, Sendable, Hashable {
    case home(HomeFeatureRoute)
    case articles(ArticleFeatureRoute)
    // ...Navigatable実装
}
```

### 依存性注入パターン

```swift
// ルーターをサービスレイヤーに注入
protocol NavigationService {
    func navigateToArticle(id: String)
    func navigateToProfile(userId: String)
}

@MainActor
class AppNavigationService: NavigationService {
    private let navigator: Navigator<AppRoute>

    init(navigator: Navigator<AppRoute>) {
        self.navigator = navigator
    }

    func navigateToArticle(id: String) {
        navigator.push(.articleDetail(id: id))
    }

    func navigateToProfile(userId: String) {
        navigator.push(.userProfile(userId: userId))
    }
}
```

---

## チェックリスト

### 本番リリース前のチェック

- [ ] **エラー処理**: すべてのDeep Linkエラーが適切に処理される
- [ ] **テストカバレッジ**: ルート解析、ナビゲーションフローのテストが完成
- [ ] **パフォーマンス**: 大きなスタック、頻繁なナビゲーションでのテスト完了
- [ ] **セキュリティ**: Deep Linkの検証とサニタイズが実装済み
- [ ] **アナリティクス**: すべての重要な画面とフローが追跡される

### 継続的な保守

- [ ] **定期的なパフォーマンスレビュー**: ナビゲーション遅延の監視
- [ ] **エラー率の追跡**: NavigatorParseErrorの頻度と原因分析
- [ ] **ユーザーフロー分析**: よく使われるパスの最適化
- [ ] **依存関係の更新**: Navigatorライブラリの最新バージョン適用

---

## まとめ

本番環境でのNavigator使用には以下の原則が重要です:

1. **ユーザー第一**: エラーを適切に処理し、常に回復可能にする
2. **監視とメトリクス**: 問題を早期発見し、データ駆動で改善する
3. **テストの徹底**: 重要なユーザーフローを確実に保護する
4. **パフォーマンス意識**: スケールしても高速なナビゲーションを維持する

## 次のステップ

- <doc:Troubleshooting> - よくある問題と解決策（5分）
- [GitHub Issues](https://github.com/ViewFeature/Navigator/issues) - バグ報告や機能要求
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions) - コミュニティサポート
