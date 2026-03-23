import Foundation

enum RideExperience: String, CaseIterable {
    case simple
    case modern
    case professional
}

final class RideExperienceService {
    static let shared = RideExperienceService()
    private init() {}

    private let storageKey = "ride_experience"

    var current: RideExperience {
        if let stored = UserDefaults.standard.string(forKey: storageKey),
           let experience = RideExperience(rawValue: stored) {
            return experience
        }

        return FeatureFlagService.shared.isEnabled(.newMapDesign) ? .professional : .simple
    }

    func setExperience(_ experience: RideExperience) {
        UserDefaults.standard.set(experience.rawValue, forKey: storageKey)
    }
}
