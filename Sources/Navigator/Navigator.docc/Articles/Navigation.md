# ナビゲーション & ルーティング

ナビゲーションパターンとURL基盤ルーティングをマスターしましょう。

## 概要

このガイドでは、ナビゲーションスタックの操作、Deep Linkの処理、ミドルウェアでのユーザー行動追跡について学習します。

**所要時間:** 15分
**レベル:** 初級
**前提条件:** <doc:QuickStart>を完了していること

## 学習内容
- 戻る操作とルートへの戻る操作
- URLからのDeep Link処理
- 共有可能なURLの生成
- ミドルウェアでのナビゲーション追跡
- 高度なナビゲーションパターン

## 構築するもの
記事ブラウジング、カテゴリフィルタリング、共有可能な記事リンクを持つニュースアプリ。

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
```

---

## セクション1: スタックナビゲーション

### ステップ1.1: ナビゲーションコントロールの追加

現在のスタックを表示するように`HomeView`を更新:

```swift
struct HomeView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            // スタック深度インジケーター
            Text("スタック深度: \(navigator.path.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("ホーム")
                .font(.largeTitle)

            Button("記事1を見る") {
                navigator.push(.articleDetail(id: "article-1"))
            }

            Button("記事2を見る") {
                navigator.push(.articleDetail(id: "article-2"))
            }
        }
        .navigationTitle("ホーム")
    }
}
```

**変更点**: `navigator.path.count`を追加してナビゲーションスタックの深度を可視化。

**試してみる**: 「記事1を見る」をタップ → スタック深度が1に増加

**所要時間:** 1分

### ステップ1.2: ナビゲーションを持つ記事ビューの実装

`ArticleView.swift`を作成:

```swift
struct ArticleView: View {
    let articleId: String
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Text("記事: \(articleId)")
                .font(.title)

            // さらに深くナビゲーション
            Button("著者プロフィールを見る") {
                navigator.push(.authorProfile(id: "author-123"))
            }

            // ルートへのポップ
            Button("ルートへポップ") {
                navigator.popToRoot()
            }

            // 戻る操作
            Button("前の画面に戻る") {
                navigator.pop()
            }
        }
        .navigationTitle("記事")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

Appの`destinationView(for:)`を更新:

```swift
@ViewBuilder
private func destinationView(for route: AppRoute) -> some View {
    switch route {
    case .home:
        HomeView()
    case .articleDetail(let id):
        ArticleView(articleId: id)
    case .authorProfile(let id):
        Text("著者: \(id)")
            .navigationTitle("著者")
    case .settings:
        Text("設定")
            .navigationTitle("設定")
    case .search:
        Text("検索")
            .navigationTitle("検索")
    case .category:
        Text("カテゴリ")
            .navigationTitle("カテゴリ")
    }
}
```

**何が起こっているか**:
- `push(_:)` - 新しい目的地をプッシュ
- `pop()` - 1つ前に戻る
- `pop(to:)` - 指定したルートまで戻る
- `popToRoot()` - すべての目的地を削除

**試してみる**:
1. ホーム → 記事1 → 著者プロフィール (スタック: 3)
2. 「ルートへポップ」をタップ → 即座にルートへ戻る (スタック: 0)

**成功確認**: すべてのナビゲーションメソッドが正しく動作

**所要時間:** 3分

---

## セクション2: URL基盤ナビゲーション

### ステップ2.1: Deep Linkの処理

入力URLを処理するように`App.swift`を更新:

```swift
@main
struct MyApp: App {
    @State private var navigator = Navigator<AppRoute>()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigator.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .environment(navigator)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let route = AppRoute.parse(from: url) else {
            print("URLの解析に失敗: \(url)")
            return
        }
        navigator.push(route)
        print("ナビゲート完了: \(url)")
    }

    // ... destinationView(for:) ...
}
```

**何が起こっているか**: `onOpenURL`が入力URLをキャプチャし、Navigatorの双方向ルーティングを使用してナビゲーション。

**テスト**:
1. アプリを実行
2. Safari（シミュレータ）を開く
3. 入力: `yourapp://article?id=article-42`
4. アプリが開いて記事42にナビゲーション

**成功確認**: Deep Linkが正しい画面にナビゲーション

**所要時間:** 1分

### ステップ2.2: 共有可能なURLの生成

`ArticleView`に共有機能を追加:

```swift
struct ArticleView: View {
    let articleId: String
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Text("記事: \(articleId)")
                .font(.title)

            // 共有可能なURLの生成
            Button("記事を共有") {
                shareArticle()
            }

            // ... 他のボタン ...
        }
        .navigationTitle("記事")
    }

    private func shareArticle() {
        let route = AppRoute.articleDetail(id: articleId)
        guard let url = try? route.url(scheme: "myapp") else { return }

        // クリップボードにコピー
        #if os(iOS)
        UIPasteboard.general.string = url.absoluteString
        #elseif os(macOS)
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #endif

        print("コピー完了: \(url.absoluteString)")
    }
}
```

**何が起こっているか**: `route.url(scheme:)`で任意のルート用のDeep Link URLを直接生成。

**試してみる**:
1. 任意の記事にナビゲーション
2. 「記事を共有」をタップ
3. コンソール確認 → 生成されたURLを確認
4. SafariにURLをペースト → アプリがその記事にナビゲーション

**成功確認**: 生成されたURLが正しい画面を開く

**実世界での使用**: 共有ボタン、QRコード、メールリンク、プッシュ通知

**所要時間:** 1.5分

---

## セクション3: ミドルウェアでのナビゲーション追跡

### ステップ3.1: アナリティクスミドルウェアの作成

`AnalyticsMiddleware.swift`を作成:

```swift
import Navigator

struct AnalyticsMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        let screenName = screenName(for: route)
        print("画面表示: \(screenName)")
        // Analytics.logEvent("screen_viewed", screen: screenName)
    }

    func onPop(route: AppRoute) {
        print("画面離脱: \(screenName(for: route))")
        // Analytics.logEvent("screen_dismissed", screen: screenName(for: route))
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        for route in removedRoutes {
            print("画面離脱: \(screenName(for: route))")
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

**何が追跡されるか**:
- `onNavigate` - 新しい画面へのナビゲーション時に発火
- `onPop` - 画面が閉じられた時に発火
- `onPopToRoot` - ルートに戻った時に発火（削除された全ルートを受け取る）

### ステップ3.2: ミドルウェアの登録

ルーター初期化を更新:

```swift
@State private var navigator: Navigator<AppRoute> = {
    let nav = Navigator<AppRoute>()
    nav.addMiddleware(AnalyticsMiddleware())
    return nav
}()
```

**試してみる**:
1. アプリを実行
2. ナビゲーション: ホーム → 記事 → 著者
3. 戻るボタンをタップ
4. コンソール確認:
```
画面表示: Article/article-1
画面表示: Author/author-123
画面離脱: Author/author-123
画面離脱: Article/article-1
```

**成功確認**: すべてのナビゲーションイベントが正しくログ出力

**実世界での使用**: Google Analytics、Mixpanel、Firebase、カスタムアナリティクス

**所要時間:** 2.5分

---

## セクション4: 高度なナビゲーションパターン

### パターン1: 条件付きナビゲーション

ユーザー状態に基づくナビゲーション:

```swift
Button("プロフィールを見る") {
    if userIsLoggedIn {
        navigator.push(.profile(userId: currentUserId))
    } else {
        navigator.push(.login)
    }
}
```

### パターン2: 複数画面のポップ

複数画面を一度にポップ:

```swift
// 2画面戻る
navigator.pop(count: 2)

// 特定のルートまで戻る
navigator.pop(to: .home)

// ルートまで戻る
navigator.popToRoot()
```

### パターン3: URLからのナビゲーション

URL文字列から直接ナビゲーション:

```swift
// URLからルートを解析してナビゲーション
if let url = URL(string: "myapp://article?id=123") {
    guard let route = AppRoute.parse(from: url) else {
        print("Invalid URL: \(url)")
        return
    }
    navigator.push(route)
}
```

**使用タイミング**:
- **パターン1**: 認証フロー、権限チェック
- **パターン2**: 複雑なナビゲーション状態のリセット
- **パターン3**: プッシュ通知、非同期操作

**所要時間:** 2分

---

## チュートリアル完了！

### 学習した内容
- スタック操作: `push`、`pop`、`pop(count:)`、`pop(to:)`、`popToRoot`
- URL基盤ナビゲーション: Deep Linkの処理、共有可能なURLの生成
- ミドルウェア: ナビゲーション行動の追跡
- 高度なパターン: 条件付きナビゲーション、特定ルートへのポップ

### あなたのアプリの新機能
- 双方向ルーティング（URL <-> ルート）
- 完全なナビゲーション追跡
- Deep Linkサポート
- 共有可能なURL
- 型安全ナビゲーション

## 次のステップ

**学習を続ける:**
- <doc:Tabs> - タブと複数スタック（15分）
- <doc:Middleware> - 高度なミドルウェア（20分）

**さらに探索:**
- ``Navigatable`` - コアルーティングプロトコル
- ``Navigator`` - ナビゲーションスタック管理
- ``NavigationMiddleware`` - ミドルウェアプロトコル

**ヘルプが必要ですか？**
- <doc:Troubleshooting>
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions)
