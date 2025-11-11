# @Route マクロ

`@Route`マクロでルート定義を自動生成しましょう。

## 概要

`@Route`マクロは、enum定義からNavigatableプロトコルの実装を自動生成します。手動実装と比較して、ボイラープレートコードを大幅に削減できます。

**所要時間:** 5分
**レベル:** 初級

## 学習内容
- `@Route`マクロの基本的な使い方
- カスタムパスの設定
- 生成されるコードの理解
- 手動実装との比較

---

## セクション1: 基本的な使い方

### ステップ1.1: シンプルなルート定義

```swift
import Navigator

@Route
enum AppRoute {
    case home
    case profile(userId: String)
    case settings
}
```

**これだけで以下が自動生成されます:**
- `path` プロパティ
- `url(scheme:)` メソッド
- `parse(from:)` 静的メソッド
- `Navigatable` プロトコル準拠
- `Sendable` プロトコル準拠
- `nonisolated` な `Hashable` 実装

### ステップ1.2: 生成されるコード

上記の定義から、以下のようなコードが自動生成されます:

```swift
extension AppRoute: Navigatable, Sendable {
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
        let routeKey = URLParser.routeKey(from: url.path)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch routeKey {
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

**所要時間:** 1分

---

## セクション2: パラメータの扱い

### ステップ2.1: 必須パラメータ

Associated valueは自動的にクエリパラメータとして扱われます:

```swift
@Route
enum AppRoute {
    case article(id: String)           // ?id=xxx
    case user(userId: Int)             // ?userId=123
    case product(code: String, qty: Int) // ?code=xxx&qty=123
}
```

**サポートされる型:**
- `String`
- `Int`
- `Bool`
- その他の`LosslessStringConvertible`準拠型

### ステップ2.2: オプショナルパラメータ

オプショナル型のパラメータもサポートされています:

```swift
@Route
enum AppRoute {
    case article(id: String, section: String?)
    case search(query: String, page: Int?)
}
```

**生成されるURL:**
- `.article(id: "123", section: nil)` → `myapp://article?id=123`
- `.article(id: "123", section: "intro")` → `myapp://article?id=123&section=intro`

**所要時間:** 1分

---

## セクション3: カスタムパス

### ステップ3.1: customPathsパラメータ

デフォルトではケース名がパスになりますが、カスタムパスを指定できます:

```swift
@Route(customPaths: [
    "profile": "user/profile",
    "settings": "app/settings"
])
enum AppRoute {
    case home           // パス: "home"
    case profile(id: String)  // パス: "user/profile"
    case settings       // パス: "app/settings"
}
```

**生成されるURL:**
- `.home` → `myapp://home`
- `.profile(id: "123")` → `myapp://user/profile?id=123`
- `.settings` → `myapp://app/settings`

### ステップ3.2: カスタムパスの使い所

- 既存のDeep Linkスキームとの互換性
- RESTful風のURL構造
- 階層的なルーティング

**所要時間:** 1分

---

## セクション4: Swift 6 Concurrency対応

### ステップ4.1: デフォルトの動作

`@Route`マクロは自動的にSwift 6のConcurrency要件に対応します:

```swift
@Route
enum AppRoute {
    case home
    case profile(id: String)
}
// 自動的に @unchecked Sendable が付与される
// nonisolated な hash(into:) と == が生成される
```

### ステップ4.2: MainActor分離

Xcodeプロジェクトで`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`を設定している場合:

```swift
// 追加の属性は不要
@Route
enum AppRoute {
    case home
}
```

設定していない場合:

```swift
// @MainActor を明示的に追加
@Route
@MainActor
enum AppRoute {
    case home
}
```

**所要時間:** 1分

---

## セクション5: 手動実装との比較

### マクロ使用 (推奨)

```swift
@Route
enum AppRoute {
    case home
    case profile(userId: String)
    case article(id: String, section: String?)
}
// 3行で完了！
```

### 手動実装

```swift
enum AppRoute: Navigatable, Sendable, Hashable {
    case home
    case profile(userId: String)
    case article(id: String, section: String?)

    var path: String {
        switch self {
        case .home: return "home"
        case .profile: return "profile"
        case .article: return "article"
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
        case .article(let id, let section):
            var queryItems = [URLQueryItem(name: "id", value: id)]
            if let section = section {
                queryItems.append(URLQueryItem(name: "section", value: section))
            }
            return try URLParser.constructURL(path: path, queryItems: queryItems, scheme: scheme)
        }
    }

    static func parse(from url: URL) -> Self? {
        let routeKey = URLParser.routeKey(from: url.path)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch routeKey {
        case "home": return .home
        case "profile":
            guard let userId: String = URLParser.optionalParam("userId", from: queryItems) else { return nil }
            return .profile(userId: userId)
        case "article":
            guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
            let section: String? = URLParser.optionalParam("section", from: queryItems)
            return .article(id: id, section: section)
        default:
            return nil
        }
    }
}
// 40行以上必要...
```

**マクロのメリット:**
- ボイラープレートの削減
- タイプミスの防止
- ケース追加時の自動対応
- Swift 6 Concurrency対応の自動化

**所要時間:** 1分

---

## チュートリアル完了！

### 学習した内容
- `@Route`マクロの基本的な使い方
- パラメータの扱い（必須・オプショナル）
- `customPaths`によるカスタムパス設定
- Swift 6 Concurrency対応
- 手動実装との比較

### ベストプラクティス

1. **新規プロジェクト**: `@Route`マクロを使用
2. **既存プロジェクト**: 段階的にマクロへ移行
3. **特殊な要件**: 手動実装を検討

## 次のステップ

**学習を続ける:**
- <doc:QuickStart> - 実際にアプリを構築（10分）
- <doc:Navigation> - ナビゲーションパターン（15分）

**APIを探索:**
- ``Route`` - マクロ定義
- ``Navigatable`` - プロトコル定義
- ``URLParser`` - URL解析ユーティリティ

**ヘルプが必要ですか？**
- <doc:Troubleshooting>
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)
