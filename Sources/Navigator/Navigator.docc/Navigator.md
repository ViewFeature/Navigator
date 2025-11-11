# ``Navigator``

SwiftUIアプリのナビゲーションを、自信を持って実装しましょう

## Navigatorとは？

**Navigator**は、SwiftUIアプリのナビゲーションを型安全かつ簡単に実装できるルーティングライブラリです。従来の文字列ベースのナビゲーションを、Swift の enum + associated value に置き換えることで、コンパイル時にすべてのナビゲーションエラーを検出できます。

### 主な特徴
- **完全な型安全性** - enum定義でコンパイル時チェック
- **双方向ルーティング** - URL <-> Route の自動変換
- **SwiftUI完全統合** - NavigationStackとネイティブ連携
- **責任分離設計** - 専用ルーターで明確な役割分担
- **Swift 6対応** - 完全なConcurrency対応
- **ゼロ依存関係** - Foundation + SwiftUIのみ使用

### 簡単な例

```swift
// 1. ルートを定義
@Route
enum AppRoute: Sendable, Hashable {
    case home
    case profile(userId: String)
}

// 2. 専用ルーターを作成（責任分離）
@State private var navigator = Navigator<AppRoute>()
@State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

// 3. ナビゲーション
navigator.push(.profile(userId: "123"))

// 4. URLから自動解析
let route = AppRoute.parse(from: url) // Optional(.profile(userId: "123"))

// 5. URL生成
let url = try AppRoute.profile(userId: "123").url(scheme: "myapp")
// "myapp://profile?userId=123"
```

---

## 学習ガイド

### すぐに始める
- <doc:GettingStarted> - **2分** でNavigatorの基本概念を理解
- <doc:RouteMacro> - **5分** で@Routeマクロをマスター
- <doc:QuickStart> - **10分** で初めてのナビゲーションアプリを構築

### 機能を深く学ぶ
- <doc:Navigation> - **15分** でスタック操作、Deep Link、URLルーティング
- <doc:Tabs> - **15分** でマルチタブアプリと独立したナビゲーション

### 本格運用に向けて
- <doc:Middleware> - **20分** でアナリティクス、ログ、本番パターン
- <doc:BestPractices> - **10分** でテスト、エラー処理、セキュリティ
- <doc:Troubleshooting> - **5分** でよくある問題の解決策

---

## Topics

### コアコンポーネント
- ``Navigator`` - ナビゲーション専用ルーター（責任分離設計）
- ``TabNavigator`` - タブ管理専用ルーター（タブ状態管理）
- ``Navigatable`` - ルート定義の基礎プロトコル

### ミドルウェアシステム
- ``NavigationMiddleware`` - ナビゲーションミドルウェアプロトコル
- ``TabNavigationMiddleware`` - タブ切り替えミドルウェアプロトコル

### SwiftUI統合
- SwiftUI Environment値としてのルーター注入
- NavigationStackとの自動連携
- @Observable対応による自動UI更新

### ユーティリティ
- ``NavigatorParseError`` - ルーティングエラー型
- ``URLParser`` - URL解析ユーティリティ
- ``Route`` - ルート自動生成マクロ

---

## サポート

- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions) - 質問・相談
- [GitHub Issues](https://github.com/ViewFeature/Navigator/issues) - バグ報告

**Navigatorで、型安全なナビゲーションを始めましょう！**
