# トラブルシューティング

よくある問題と解決策の完全ガイド。

## 概要

Navigatorを使用する際によく遭遇する問題の解決策を提供します。問題が解決しない場合は、[GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)でサポートを求めてください。

**所要時間:** 5分
**レベル:** すべて

---

## ビルドエラー

### "Cannot find 'Navigator' in scope"

**症状**: `import Navigator`でエラーが発生

**原因**: パッケージが正しく追加されていない

**解決策**:
```swift
// Package.swiftを確認
dependencies: [
    .package(url: "https://github.com/ViewFeature/Navigator", from: "0.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["Navigator"])  // この行を確認
]
```

### "'Navigatable' requires that 'AppRoute' conform to 'Sendable'"

**症状**: Sendable準拠エラー

**解決策**:
```swift
// 正しい準拠
enum AppRoute: Navigatable, Sendable, Hashable {
    case home
    case profile(userId: String)
}
```

### "'NavigationMiddleware' requires 'Route' type"

**症状**: ミドルウェアの型エラー

**解決策**:
```swift
// typealiasを追加
struct MyMiddleware: NavigationMiddleware {
    typealias Route = AppRoute  // この行が必要

    func onNavigate(to route: AppRoute) {
        // ...
    }

    func onPop(route: AppRoute) {
        // ...
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        // ...
    }
}
```

---

## ルート定義の問題

### "Missing parameter 'id' in query items"

**症状**: パラメータが見つからない

**デバッグ**:
```swift
static func parse(from url: URL) -> Self? {
    let routeKey = URLParser.routeKey(from: url.path)
    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    // デバッグ出力を追加
    print("Parsing path: \(routeKey)")
    print("Query items: \(queryItems)")

    switch routeKey {
    case "article":
        // パラメータの存在確認
        guard let id: String = URLParser.optionalParam("id", from: queryItems) else {
            print("Missing 'id' parameter in: \(queryItems)")
            return nil
        }
        return .articleDetail(id: id)
    // ...
    default:
        return nil
    }
}
```

---

## ナビゲーションの問題

### ナビゲーションが動作しない

**症状**: `navigator.push()`を呼んでも画面が変わらない

**チェックリスト**:

1. **NavigatorがEnvironmentに正しく注入されているか**:
```swift
// App.swift
.environment(navigator)  // この行があるか確認
```

2. **NavigationStackが正しく設定されているか**:
```swift
NavigationStack(path: $navigator.path) {  // Bindingを確認
    HomeView()
        .navigationDestination(for: AppRoute.self) { route in  // AppRouteを確認
            destinationView(for: route)
        }
}
```

3. **destinationView(for:)が実装されているか**:
```swift
@ViewBuilder
private func destinationView(for route: AppRoute) -> some View {
    switch route {
    case .home:
        HomeView()
    case .profile(let userId):
        ProfileView(userId: userId)
    // 他のケースも必要
    }
}
```

### "Environment value not found"

**症状**: `@Environment(Navigator<AppRoute>.self)`でクラッシュ

**原因**: NavigatorがEnvironmentに注入されていない

**解決策**:
```swift
// App.swift で必ず注入
NavigationStack(path: $navigator.path) {
    // ...
}
.environment(navigator)  // この行が必要

// View で使用
struct SomeView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator  // 型を確認
}
```

### 戻るボタンが動作しない

**症状**: 戻るボタンをタップしても前の画面に戻らない

**原因**: NavigationStackのpath bindingの問題

**解決策**:
```swift
// 正しい書き方
NavigationStack(path: $navigator.path) {  // $ bindingが必要

// 間違った書き方
NavigationStack(path: navigator.path) {   // bindingなし
```

---

## Deep Linkの問題

### Deep Linkが動作しない

**症状**: URLをタップしてもアプリが開かない

**解決策**:

1. **URL Schemesの設定確認** (iOS):
```xml
<!-- Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourapp.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

2. **onOpenURLの実装確認**:
```swift
.onOpenURL { url in
    print("Received URL: \(url)")  // デバッグ出力を追加
    guard let route = AppRoute.parse(from: url) else {
        print("Navigation failed: Invalid URL")
        return
    }
    navigator.push(route)
    print("Navigation successful")
}
```

### "Invalid URL format"

**症状**: URL解析でエラー

**デバッグ**:
```swift
// URL形式を確認
let testURL = URL(string: "myapp://article?id=123")!
print("Scheme: \(testURL.scheme)")      // "myapp"
print("Host: \(testURL.host)")          // nil (正常)
print("Path: \(testURL.path)")          // "/article"
print("Query: \(testURL.query)")        // "id=123"

// AppRoute.parseでデバッグ
if let route = AppRoute.parse(from: testURL) {
    print("Parsed route: \(route)")
} else {
    print("Parse failed: Could not parse URL")
}
```

---

## パフォーマンスの問題

### ナビゲーションが遅い

**症状**: `push()`の実行が遅い

**原因と解決策**:

1. **重いミドルウェア**:
```swift
// Bad - メインスレッドをブロック
struct SlowMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        // 重い同期処理
        heavyComputation()
    }
}

// Good - バックグラウンドで実行
struct FastMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        Task {
            await heavyComputationAsync()
        }
    }
}
```

2. **大きなナビゲーションスタック**:
```swift
// スタックサイズを監視するミドルウェア
struct StackMonitorMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        #if DEBUG
        print("Navigation to: \(route)")
        #endif
    }
}
```

---

## Concurrencyの問題

### "Call to main actor-isolated function in a synchronous nonisolated context"

**症状**: MainActor isolationエラー

**原因**: Swift 6 concurrency

**解決策**:
```swift
// Navigator は @MainActor 注釈付き
// 使用時も @MainActor コンテキストで
@MainActor
func navigateToProfile() {
    navigator.push(.profile(userId: "123"))
}

// または Task で MainActor を指定
Task { @MainActor in
    navigator.push(.profile(userId: "123"))
}
```

### Sendable conformance warnings

**症状**: Sendable準拠の警告

**解決策**:
```swift
// すべてのRoute型でSendableを明示的に準拠
enum AppRoute: Navigatable, Sendable, Hashable {
    case home
    case profile(userId: String)  // Stringは自動的にSendable
}

// カスタム型もSendableに準拠
struct CustomData: Sendable {
    let id: String
    let name: String
}

enum AppRoute: Navigatable, Sendable, Hashable {
    case custom(CustomData)  // これでSendable
}
```

---

## よくある設定ミス

### タブが切り替わらない

**症状**: `tabNavigator.switchTo()`でタブが変わらない

**解決策**:
```swift
// TabViewのselection bindingを確認
TabView(selection: $tabNavigator.selectedTab) {  // $ binding必須
    // ...
}

// タブのtagが正しく設定されているか
.tag(tab)  // 各タブに必要
```

---

## デバッグのヒント

### ナビゲーション状態の可視化

```swift
#if DEBUG
struct NavigationDebugView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(alignment: .leading) {
            Text("Navigation Stack (\(navigator.path.count)):")
            ForEach(Array(navigator.path.enumerated()), id: \.offset) { index, route in
                Text("\(index): \(route)")
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.3))
    }
}

// 任意のビューに追加
SomeView()
    .overlay(alignment: .topTrailing) {
        NavigationDebugView()
    }
#endif
```

### ログの有効化

```swift
struct DebugMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        print("Navigate: \(route)")
    }

    func onPop(route: AppRoute) {
        print("Pop: \(route)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        print("Pop to root: \(removedRoutes)")
    }
}

// デバッグビルドでのみ追加
#if DEBUG
navigator.addMiddleware(DebugMiddleware())
#endif
```

---

## サポートを求める前に

問題が解決しない場合は、以下の情報を準備してください:

### 基本情報
- Swift version: `swift --version`
- Xcode version
- Navigator version
- プラットフォーム (iOS/macOS/tvOS/watchOS)
- デバイス/シミュレータ

### エラー情報
- 完全なエラーメッセージ
- スタックトレース
- 再現手順

### コード例
```swift
// 最小限の再現可能な例
enum TestRoute: Navigatable, Sendable, Hashable {
    case test

    var path: String { "test" }

    func url(scheme: String) throws -> URL {
        try URLParser.constructURL(path: path, queryItems: [], scheme: scheme)
    }

    static func parse(from url: URL) -> Self? {
        // 問題のある実装
        return .test
    }
}
```

## サポートリソース

- **[GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)** - 質問とコミュニティサポート
- **[GitHub Issues](https://github.com/ViewFeature/Navigator/issues)** - バグ報告と機能要求

---

**問題が解決しましたか？** 解決した場合は、[Discussions](https://github.com/ViewFeature/Navigator/discussions)で解決策を共有して、他の開発者を助けてください！
