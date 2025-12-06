import Foundation
@testable import Navigator

/// Mock route for testing Navigatable protocol implementation.
///
/// This enum provides comprehensive test cases for URL parsing and generation:
/// - Simple routes without parameters
/// - Routes with required query parameters
/// - Routes with optional query parameters
/// - Routes with multiple parameters
/// - Routes with different parameter types (String, Int, Bool)
///
/// ## URL Format
///
/// URLs use the format: `scheme://host?query`
/// - `scheme://home` → host is "home", path is ""
/// - This matches standard deep link behavior
enum MockRoute: Navigatable {
	case home
	case profile(userId: String)
	case search(query: String, limit: Int)
	case article(id: Int, showComments: Bool)
	case settings
	case detail(id: String)
	case list(filter: String)
	case settingsDetail(section: String)

	var path: String {
		switch self {
		case .home:
			return "/home"
		case .profile:
			return "/profile"
		case .search:
			return "/search"
		case .article:
			return "/article"
		case .settings:
			return "/settings"
		case .detail:
			return "/detail"
		case .list:
			return "/list"
		case .settingsDetail:
			return "/settings/detail"
		}
	}

	static func parse(from url: URL) -> MockRoute? {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}

		let host = components.host ?? ""
		let queryItems = components.queryItems ?? []

		return parseRoute(host: host, path: url.path, queryItems: queryItems)
	}

	private static func parseRoute(host: String, path: String, queryItems: [URLQueryItem]) -> MockRoute? {
		switch host {
		case "home":
			return .home
		case "settings":
			return parseSettings(path: path, queryItems: queryItems)
		default:
			return parseParameterizedRoute(host: host, queryItems: queryItems)
		}
	}

	private static func parseSettings(path: String, queryItems: [URLQueryItem]) -> MockRoute? {
		if path.hasPrefix("/detail") {
			guard let section: String = URLParser.optionalParam("section", from: queryItems) else { return nil }
			return .settingsDetail(section: section)
		}
		return .settings
	}

	private static func parseParameterizedRoute(host: String, queryItems: [URLQueryItem]) -> MockRoute? {
		switch host {
		case "profile":
			guard let userId: String = URLParser.optionalParam("userId", from: queryItems) else { return nil }
			return .profile(userId: userId)
		case "search":
			guard let query: String = URLParser.optionalParam("query", from: queryItems) else { return nil }
			let limit: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10
			return .search(query: query, limit: limit)
		case "article":
			guard let id: Int = URLParser.optionalParam("id", from: queryItems) else { return nil }
			let showComments: Bool = URLParser.optionalParam("showComments", from: queryItems) ?? false
			return .article(id: id, showComments: showComments)
		case "detail":
			guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
			return .detail(id: id)
		case "list":
			guard let filter: String = URLParser.optionalParam("filter", from: queryItems) else { return nil }
			return .list(filter: filter)
		default:
			return nil
		}
	}

	func url(scheme: String) throws -> URL {
		// settingsDetail needs special handling for host + path
		if case .settingsDetail(let section) = self {
			var components = URLComponents()
			components.scheme = scheme
			components.host = "settings"
			components.path = "/detail"
			components.queryItems = [URLQueryItem(name: "section", value: section)]
			guard let url = components.url else {
				throw NavigatorParseError.invalidURL("\(scheme)://settings/detail")
			}
			return url
		}
		return try URLParser.constructURL(path: path, queryItems: urlQueryItems, scheme: scheme)
	}

	private var urlQueryItems: [URLQueryItem] {
		switch self {
		case .home, .settings:
			return []
		case .profile(let userId):
			return [URLQueryItem(name: "userId", value: userId)]
		case .search(let query, let limit):
			return [
				URLQueryItem(name: "query", value: query),
				URLQueryItem(name: "limit", value: String(limit))
			]
		case .article(let id, let showComments):
			return [
				URLQueryItem(name: "id", value: String(id)),
				URLQueryItem(name: "showComments", value: String(showComments))
			]
		case .detail(let id):
			return [URLQueryItem(name: "id", value: id)]
		case .list(let filter):
			return [URLQueryItem(name: "filter", value: filter)]
		case .settingsDetail:
			return []  // Handled specially in url(scheme:)
		}
	}
}
