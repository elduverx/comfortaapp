import Foundation

enum FeatureFlag: String, CaseIterable {
    case newMapDesign
    case enhancedAdminPanel
    case aiRouteSuggestions
    case webSocketTracking
    case offlineMode
}

final class FeatureFlagService {
    static let shared = FeatureFlagService()
    private init() {}

    private let overridesKey = "feature_flag_overrides"

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let overrides = UserDefaults.standard.dictionary(forKey: overridesKey) as? [String: Bool],
           let override = overrides[flag.rawValue] {
            return override
        }

        return defaultValue(for: flag)
    }

    func setOverride(_ flag: FeatureFlag, enabled: Bool) {
        var overrides = UserDefaults.standard.dictionary(forKey: overridesKey) as? [String: Bool] ?? [:]
        overrides[flag.rawValue] = enabled
        UserDefaults.standard.set(overrides, forKey: overridesKey)
    }

    func clearOverrides() {
        UserDefaults.standard.removeObject(forKey: overridesKey)
    }

    private func defaultValue(for flag: FeatureFlag) -> Bool {
        switch flag {
        case .newMapDesign:
            return true
        case .enhancedAdminPanel:
            return true
        case .aiRouteSuggestions:
            return false
        case .webSocketTracking:
            return false
        case .offlineMode:
            return AppConfiguration.Features.enableOfflineMode
        }
    }
}
