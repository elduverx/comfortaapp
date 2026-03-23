import SwiftUI

struct RideHomeView: View {
    let userName: String
    let onLogout: () -> Void
    let onProfileTap: () -> Void

    private var experience: RideExperience {
        RideExperienceService.shared.current
    }

    var body: some View {
        switch experience {
        case .simple:
            SimpleRideView(userName: userName, onLogout: onLogout)
        case .modern:
            ModernRideView(userName: userName, onLogout: onLogout)
        case .professional:
            ProfessionalRideView(
                userName: userName,
                onLogout: onLogout,
                onProfileTap: onProfileTap
            )
        }
    }
}
