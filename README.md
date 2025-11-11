# Navigator

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS-blue.svg)](https://github.com/ViewFeature/Navigator)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[日本語版](README_jp.md)

A type-safe navigation library for SwiftUI applications. Navigator provides declarative routing with the `@Route` macro and supports deep linking, middleware, and Swift 6 Concurrency.

### Quick Example

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
            Button("View Profile") {
                navigator.push(.profile(userId: "123"))
            }

            Button("Back") {
                navigator.pop()
            }
        }
    }
}
```

## The 4 Core Principles

### 1. Declarative Route Definition

Define routes with a simple enum and the `@Route` macro. The macro automatically generates URL parsing, path generation, and `Hashable` conformance.

```swift
@Route
enum AppRoute {
    case home
    case profile(userId: String)
    case article(id: String, section: String?)
}

// Auto-generated properties:
AppRoute.home.path           // → "home"
AppRoute.profile(userId: "123").url(scheme: "myapp")
// → myapp://profile?userId=123
```

- No boilerplate for URL handling
- Type-safe parameters
- Optional parameters supported

### 2. Separation of Concerns

Navigator separates stack navigation from tab management. `Navigator` handles push/pop operations, while `TabNavigator` manages tab selection.

```swift
// Stack navigation
@State private var navigator = Navigator<AppRoute>()

// Tab management
@State private var tabNavigator = TabNavigator<AppTab>(defaultTab: .home)

// Each has its own focused API
navigator.push(.profile(userId: "123"))
navigator.pop()

tabNavigator.switchTo(.settings)
```

- Single responsibility for each component
- Clean, focused APIs
- Easy to test and reason about

### 3. Deep Linking Built-in

Every route automatically supports deep linking. Parse URLs into routes and generate URLs from routes—all type-safe.

```swift
// Generate URLs
let url = AppRoute.profile(userId: "123").url(scheme: "myapp")
// → myapp://profile?userId=123

// Parse URLs
let route = AppRoute.parse(from: url)
// → Optional(.profile(userId: "123"))

// Handle in SwiftUI
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

- Automatic URL generation
- Type-safe URL parsing
- Built-in SwiftUI integration

### 4. MainActor Isolation

Navigator is designed for Swift 6's strict concurrency. All navigation operations are `@MainActor` isolated, ensuring thread safety at compile time.

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

- Compile-time thread safety
- No data races
- Works with `defaultIsolation(MainActor.self)`

## Advanced Features

### Tab Navigation

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
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)
            .environment(homeNav)

            NavigationStack(path: $profileNav.path) {
                ProfileView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeView(for: route)
                    }
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(AppTab.profile)
            .environment(profileNav)
        }
        .environment(tabNav)
    }
}
```

### Middleware

Add cross-cutting concerns like logging, analytics, or validation:

```swift
struct LoggingMiddleware: NavigationMiddleware {
    typealias Route = AppRoute

    func onNavigate(to route: AppRoute) {
        print("Navigate: \(route.path)")
    }

    func onPop(route: AppRoute) {
        print("Pop: \(route.path)")
    }

    func onPopToRoot(removedRoutes: [AppRoute]) {
        print("Pop to root: \(removedRoutes.count) routes removed")
    }
}

// Add middleware
let token = navigator.addMiddleware(LoggingMiddleware())

// Remove later using token
navigator.removeMiddleware(token: token)
```

Tab navigation also supports middleware:

```swift
struct TabLoggingMiddleware: TabNavigationMiddleware {
    typealias Tab = AppTab

    func onTabSwitch(fromTab: AppTab, toTab: AppTab) {
        print("Tab switch: \(fromTab) → \(toTab)")
    }
}

tabNav.addMiddleware(TabLoggingMiddleware())
```

## API Reference

### Navigator

| Method | Description |
|--------|-------------|
| `push(_:)` | Push a route onto the stack |
| `pop()` | Pop the current route |
| `pop(count:)` | Pop multiple routes |
| `pop(to:)` | Pop to a specific route |
| `popToRoot()` | Clear the navigation stack |
| `addMiddleware(_:)` | Add middleware (returns token) |
| `removeMiddleware(token:)` | Remove middleware by token |
| `removeMiddleware(_:)` | Remove middleware by type |
| `clearMiddlewares()` | Remove all middlewares |

### TabNavigator

| Method | Description |
|--------|-------------|
| `switchTo(_:)` | Switch to a tab |
| `isSelected(_:)` | Check if tab is selected |
| `addMiddleware(_:)` | Add middleware (returns token) |
| `removeMiddleware(token:)` | Remove middleware by token |
| `removeMiddleware(_:)` | Remove middleware by type |
| `clearMiddlewares()` | Remove all middlewares |

## Installation

### Swift Package Manager

Add Navigator to your `Package.swift`:

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
            .defaultIsolation(MainActor.self)  // Recommended
        ]
    )
]
```

### Xcode

- Select **File → Add Package Dependencies**
- Enter the URL: `https://github.com/ViewFeature/Navigator.git`
- Select version: `0.1.0` or later

**Recommended**: Add `-default-isolation MainActor` to your target's **Build Settings → Other Swift Flags**.

### Requirements

- iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+
- Swift 6.2+
- Xcode 16.2+

## Contributing

Contributions are welcome!

Before submitting a pull request, please review the [Contributing Guide](CONTRIBUTING.md). If you have questions or ideas, start a [Discussion](https://github.com/ViewFeature/Navigator/discussions).

### Community

- **[Report Issues](https://github.com/ViewFeature/Navigator/issues)** - Bug reports and feature requests
- **[Discussions](https://github.com/ViewFeature/Navigator/discussions)** - Share questions and ideas

## Credits

Navigator is inspired by the following libraries and communities:

- [SwiftUI NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) - Apple's native navigation API
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - Navigation patterns in Swift
- [swift-syntax](https://github.com/apple/swift-syntax) - Swift macro infrastructure

## Maintainers

- [Takeshi SHIMADA](https://github.com/takeshishimada)

## License

Navigator is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
