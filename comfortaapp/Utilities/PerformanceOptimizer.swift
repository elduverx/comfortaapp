import Foundation
import Combine
import CoreLocation

// MARK: - Performance Utilities

final class PerformanceOptimizer {
    
    // MARK: - Debounce Utility
    static func debounce<T: Equatable>(
        _ publisher: Published<T>.Publisher,
        for seconds: Double = AppConfiguration.Location.searchDebounceDelay
    ) -> AnyPublisher<T, Never> {
        publisher
            .removeDuplicates()
            .debounce(for: .seconds(seconds), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Throttle Utility
    static func throttle<T>(
        _ publisher: Published<T>.Publisher,
        for interval: Double = 1.0,
        latest: Bool = true
    ) -> AnyPublisher<T, Never> {
        publisher
            .throttle(
                for: .seconds(interval),
                scheduler: DispatchQueue.main,
                latest: latest
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Memory Management
    static func performMemoryCleanup() {
        // Force garbage collection
        autoreleasepool {
            // Clear any cached data that might be consuming memory
            URLCache.shared.removeAllCachedResponses()
        }
    }
}

// MARK: - Cache Manager

final class CacheManager<Key: Hashable, Value> {
    private var cache: [Key: CacheEntry<Value>] = [:]
    private let lock = NSRecursiveLock()
    private let retentionTime: TimeInterval
    
    private struct CacheEntry<V> {
        let value: V
        let timestamp: Date
    }
    
    init(retentionTime: TimeInterval = AppConfiguration.Performance.cacheRetentionTime) {
        self.retentionTime = retentionTime
        
        // Set up periodic cleanup
        Timer.scheduledTimer(withTimeInterval: retentionTime / 2, repeats: true) { _ in
            self.cleanupExpiredEntries()
        }
    }
    
    func set(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        cache[key] = CacheEntry(value: value, timestamp: Date())
    }
    
    func value(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = cache[key] else { return nil }
        
        // Check if entry has expired
        if Date().timeIntervalSince(entry.timestamp) > retentionTime {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func removeValue(forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
    }
    
    private func cleanupExpiredEntries() {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let expiredKeys = cache.compactMap { key, entry in
            now.timeIntervalSince(entry.timestamp) > retentionTime ? key : nil
        }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
    }
}

// MARK: - Task Manager

actor TaskManager {
    private var runningTasks: Set<String> = []
    private let maxConcurrentTasks: Int
    
    init(maxConcurrentTasks: Int = AppConfiguration.Performance.maxConcurrentSearchRequests) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    func canStartTask(withId id: String) -> Bool {
        guard !runningTasks.contains(id) else { return false }
        return runningTasks.count < maxConcurrentTasks
    }
    
    func startTask(withId id: String) {
        runningTasks.insert(id)
    }
    
    func finishTask(withId id: String) {
        runningTasks.remove(id)
    }
    
    func cancelAllTasks() {
        runningTasks.removeAll()
    }
}

// MARK: - Error Handling Utilities

struct ErrorHandler {
    static func handleError(_ error: Error, context: String = "") -> String {
        if AppEnvironment.current.enableLogging {
            print("Error in \(context): \(error.localizedDescription)")
        }
        
        switch error {
        case is URLError:
            return AppConfiguration.ErrorMessages.networkError
        case let clError as CLError:
            switch clError.code {
            case .denied:
                return AppConfiguration.ErrorMessages.locationPermissionDenied
            default:
                return AppConfiguration.ErrorMessages.locationNotAvailable
            }
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Performance Monitoring

final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private init() {}
    
    private var startTimes: [String: CFAbsoluteTime] = [:]
    
    func startMeasuring(_ operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
    }
    
    func endMeasuring(_ operation: String) {
        guard let startTime = startTimes.removeValue(forKey: operation) else { return }
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if AppEnvironment.current.enableLogging {
            print("⏱️ \(operation) took \(String(format: "%.3f", duration * 1000))ms")
        }
    }
    
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try block()
    }
}