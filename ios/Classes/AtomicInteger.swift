//
//  AtomicInteger.swift
//  package_info
//
//  Created by Adam on 2/8/20.
//

import Foundation

public final class AtomicInteger {
    private let lock = DispatchSemaphore(value: 1)
    private var localValue: Int

    public init(value initialValue: Int = 0) {
        localValue = initialValue
    }

    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return localValue
        }
        set {
            lock.wait()
            defer { lock.signal() }
            localValue = newValue
        }
    }

    public func increment() {
        lock.wait()
        defer { lock.signal() }
        localValue += 1
    }
}
