# クイックスタート

10分で最初のナビゲーション可能なアプリを構築しましょう。

## 概要

このガイドでは、Navigatorルーティングを使用してシンプルなアプリを作成する手順を説明します。ルートの定義、ルーターの設定、画面間のナビゲーションを学習します。

**所要時間:** 10分
**前提条件:** Navigatorがインストールされていること（<doc:GettingStarted>を参照）

## 構築するもの

以下の機能を持つシンプルなアプリ:
- 3画面間の型安全ルーティング
- 双方向URLサポート（解析と生成）
- Deep Link処理
- パラメータ付きナビゲーション

## ステップ1: パッケージの追加

**Xcode:**
1. File → Add Package Dependencies
2. 入力: `https://github.com/ViewFeature/Navigator.git`
3. バージョン0.1.0以降を選択
4. ターゲットに追加

**Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/ViewFeature/Navigator.git", from: "0.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["Navigator"])
]
```

**成功確認**: エラーなしでビルドが成功

**所要時間:** 1分

## ステップ2: ルートの定義

`AppRoute.swift`を作成:

```swift
import Navigator
import Foundation

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
        let routeKey = URLParser.routeKey(from: url.path)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch routeKey {
        case "home":
            return .home
        case "profile":
            guard let userId: String = URLParser.optionalParam("userId", from: queryItems) else { return nil }
            return .profile(userId: userId)
        case "settings":
            return .settings
        default:
            return nil
        }
    }
}
```

**これで何ができるか**: 3つの画面間のナビゲーション、URLからルートへの自動解析（Deep Link）、ルートからURLへの自動生成（共有機能）

**成功確認**: ファイルがエラーなしでコンパイル

**所要時間:** 2.5分

## ステップ3: ルーターの設定

`App.swift`を更新:

```swift
import SwiftUI
import Navigator

@main
struct MyApp: App {
    // ナビゲーション専用ルーターを作成（責任分離設計）
    @State private var navigator = Navigator<AppRoute>()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigator.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .environment(navigator)        // 全ViewでNavigator使用可能
            .onOpenURL { url in            // Deep Link自動対応
                guard let route = AppRoute.parse(from: url) else {
                    print("Invalid deep link: \(url)")
                    return
                }
                navigator.push(route)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView()
        case .profile(let userId):
            ProfileView(userId: userId)
        case .settings:
            SettingsView()
        }
    }
}

// 画面コンポーネント
struct ProfileView: View {
    let userId: String

    var body: some View {
        Text("プロフィール: \(userId)")
            .navigationTitle("プロフィール")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("設定")
            .navigationTitle("設定")
    }
}
```

**これで何ができるか**:
- NavigatorがSwiftUIのNavigationStackと連携
- 全ViewでEnvironment経由でNavigator使用可能
- Deep Linkの自動処理

**成功確認**: アプリが起動してHomeViewが表示

**所要時間:** 2分

## ステップ4: ナビゲーションの実装

`HomeView.swift`を作成:

```swift
import SwiftUI
import Navigator

struct HomeView: View {
    @Environment(Navigator<AppRoute>.self) private var navigator

    var body: some View {
        VStack(spacing: 20) {
            Text("ホーム")
                .font(.largeTitle)

            // 基本的なナビゲーション
            Button("プロフィールを見る") {
                navigator.push(.profile(userId: "123"))
            }

            Button("設定を開く") {
                navigator.push(.settings)
            }

            // URL生成と共有
            Button("プロフィールを共有") {
                shareProfile()
            }

            // ナビゲーション状態表示
            Text("現在のパス: \(navigator.path.count)画面")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("ホーム")
    }

    private func shareProfile() {
        let profileRoute = AppRoute.profile(userId: "123")
        guard let url = try? profileRoute.url(scheme: "myapp") else { return }
        print("共有用URL: \(url)")
        // 実際のアプリ: UIActivityViewControllerで共有
    }
}
```

**これで何ができるか**:
- Environment経由でNavigatorを注入
- `push(_:)`メソッドによる安全なナビゲーション
- 共有可能なURLの直接生成
- @Observable による自動UI更新
- SwiftUIが自動でプッシュ/ポップアニメーション処理

**成功確認**:
- 「プロフィールを見る」ボタン → プロフィール画面に遷移
- 「設定を開く」ボタン → 設定画面に遷移
- 「プロフィールを共有」ボタン → コンソールにURLが出力
- パス数が正しく表示される
- 戻るボタンが自動で動作

**所要時間:** 2.5分

## Deep Linkのテスト

アプリがDeep Linkを自動処理できることを確認:

**テスト手順**:
1. アプリをシミュレータで起動
2. Safariを開く
3. `myapp://profile?userId=456`を入力
4. アプリが開いてプロフィール画面（userId: 456）に遷移

**仕組み**:
- `onOpenURL`が受信したURLをキャプチャ
- `AppRoute.parse(from: url)`でURLをルートに変換
- `navigator.push(route)`でナビゲーション実行

**所要時間:** 2分

## 完成！

**10分間で習得した内容**:
- 型安全なルーティング実装
- SwiftUIとの完全統合
- Deep Link自動対応
- URL生成と共有機能

**あなたのアプリは以下が可能になりました**:
- プログラマティックな画面遷移
- Deep Link対応（URL、プッシュ通知、QRコードから）
- 共有可能なURL生成
- コンパイル時のナビゲーションエラー検出

## 次のステップ

### より詳細な学習

さらに深く学習する準備はできましたか？これらのチュートリアルは今学んだ内容を基に構築されます:

**<doc:Navigation>** (15分)
- スタック操作（pop、popToRoot、複数pop）
- 高度なURL処理
- ナビゲーションミドルウェア
- アナリティクス統合

**<doc:Tabs>** (15分)
- マルチタブナビゲーション
- 独立したナビゲーションスタック
- タブ切り替え管理

### APIの探索

完全なドキュメントをブラウズ:

- ``Navigatable`` - コアルーティングプロトコル
- ``Navigator`` - ナビゲーションスタック管理
- ``TabNavigator`` - タブ状態管理
- ``NavigationMiddleware`` - ミドルウェアシステム

### サンプルアプリ

本番でのNavigatorを確認:

- [Demo](https://github.com/ViewFeature/Navigator/tree/main/Examples/Demo) - 包括的機能デモ

## ヘルプが必要ですか？

- <doc:Troubleshooting> - よくある問題と解決策
- [GitHub Discussions](https://github.com/ViewFeature/Navigator/discussions) - 質問する

## トピック

### ステップ

- ステップ1: パッケージの追加
- ステップ2: ルートの定義
- ステップ3: ルーターの設定
- ステップ4: ナビゲーションの実装

### 次のステップ

- <doc:Navigation>
- <doc:Tabs>

### APIリファレンス

- ``Navigator``
- ``TabNavigator``
- ``Navigatable``
- ``NavigationMiddleware``
