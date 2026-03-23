import Foundation

final class MonitoringService {
    static let shared = MonitoringService()
    private init() {}

    func record(error: Error, context: String? = nil) {
        guard AppEnvironment.current.enableLogging else { return }

        if let context = context, !context.isEmpty {
            print("📉 [Monitoring] \(context): \(error.localizedDescription)")
        } else {
            print("📉 [Monitoring] \(error.localizedDescription)")
        }
    }

    func startTrace(_ name: String) -> MonitoringTrace {
        PerformanceMonitor.shared.startMeasuring(name)
        return MonitoringTrace(name: name)
    }
}

struct MonitoringTrace {
    let name: String

    func stop() {
        PerformanceMonitor.shared.endMeasuring(name)
    }
}
