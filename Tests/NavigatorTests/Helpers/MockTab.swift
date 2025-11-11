import Foundation
@testable import Navigator

/// Mock tab type for testing tabbed navigation.
enum MockTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case search
    case profile

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .profile: return "person.fill"
        }
    }

    var title: String {
        rawValue.capitalized
    }

    var badge: Int? {
        nil
    }
}
