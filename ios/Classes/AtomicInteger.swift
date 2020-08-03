//
//  AtomicInteger.swift
//  package_info
//
//  Created by Adam on 2/8/20.
//

import Foundation

public final class AtomicInteger {
    private let lock = DispatchSemaphore(value: 1)
    private var value: Int

    public init(value initialValue: Int = 0) {
        value = initialValue
    }

    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            value = newValue
        }
    }

    public func increment() {
        lock.wait()
        defer { lock.signal() }
        value += 1
    }
}
