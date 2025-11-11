import Foundation

/// Thread-safe counter for testing middleware call counts.
final class ThreadSafeCounter: @unchecked Sendable {
	private let queue = DispatchQueue(label: "thread-safe-counter")
	private var _value = 0

	var value: Int {
		queue.sync { _value }
	}

	func increment() {
		queue.sync { _value += 1 }
	}

	func reset() {
		queue.sync { _value = 0 }
	}
}

/// Thread-safe array for tracking ordered values in tests.
final class ThreadSafeArray<T>: @unchecked Sendable {
	private let queue = DispatchQueue(label: "thread-safe-array")
	private var _values: [T] = []

	var values: [T] {
		queue.sync { _values }
	}

	var count: Int {
		queue.sync { _values.count }
	}

	func append(_ value: T) {
		queue.sync { _values.append(value) }
	}

	func removeAll() {
		queue.sync { _values.removeAll() }
	}
}

/// Thread-safe tracker for tab switches.
final class TabSwitchTracker: @unchecked Sendable {
	private let lock = NSLock()
	private var _count = 0
	private var _lastFromTab: (any Hashable)?
	private var _lastToTab: (any Hashable)?

	var count: Int {
		lock.withLock { _count }
	}

	func recordSwitch<Tab: Hashable>(from: Tab, to: Tab) {
		lock.withLock {
			_count += 1
			_lastFromTab = from
			_lastToTab = to
		}
	}

	func lastFromTab<Tab: Hashable>(as type: Tab.Type) -> Tab? {
		lock.withLock { _lastFromTab as? Tab }
	}

	func lastToTab<Tab: Hashable>(as type: Tab.Type) -> Tab? {
		lock.withLock { _lastToTab as? Tab }
	}
}
