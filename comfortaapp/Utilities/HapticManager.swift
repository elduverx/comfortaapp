import UIKit
import SwiftUI
import AudioToolbox

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft // iOS 13+
        case rigid // iOS 13+
        
        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:
                return .light
            case .medium:
                return .medium
            case .heavy:
                return .heavy
            case .soft:
                if #available(iOS 13.0, *) {
                    return .soft
                } else {
                    return .light
                }
            case .rigid:
                if #available(iOS 13.0, *) {
                    return .rigid
                } else {
                    return .heavy
                }
            }
        }
    }
    
    func impact(_ style: ImpactStyle, intensity: CGFloat = 1.0) {
        let generator = UIImpactFeedbackGenerator(style: style.feedbackStyle)
        generator.prepare()
        
        if #available(iOS 13.0, *) {
            generator.impactOccurred(intensity: intensity)
        } else {
            generator.impactOccurred()
        }
    }
    
    // MARK: - Notification Feedback
    
    enum NotificationStyle {
        case success
        case warning
        case error
        
        var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success:
                return .success
            case .warning:
                return .warning
            case .error:
                return .error
            }
        }
    }
    
    func notification(_ style: NotificationStyle) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style.feedbackType)
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    func buttonTap() {
        impact(.light, intensity: 0.8)
    }
    
    func cardTap() {
        impact(.medium, intensity: 0.6)
    }
    
    func switchToggle() {
        selection()
    }
    
    func successAction() {
        notification(.success)
    }
    
    func errorAction() {
        notification(.error)
    }
    
    func warningAction() {
        notification(.warning)
    }
    
    func liquidPress() {
        impact(.soft, intensity: 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light, intensity: 0.3)
        }
    }
    
    func glassTouch() {
        impact(.rigid, intensity: 0.4)
    }
    
    func slideInteraction() {
        selection()
    }
    
    func swipeGesture() {
        impact(.light, intensity: 0.5)
    }
    
    func longPressStart() {
        impact(.medium, intensity: 0.7)
    }
    
    func longPressEnd() {
        impact(.light, intensity: 0.4)
    }
    
    // MARK: - Advanced Patterns
    
    func doubleTap() {
        impact(.light, intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light, intensity: 0.8)
        }
    }
    
    func rippleEffect() {
        impact(.soft, intensity: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impact(.light, intensity: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light, intensity: 0.3)
        }
    }
    
    func progressStep() {
        impact(.soft, intensity: 0.4)
    }
    
    func pageTransition() {
        impact(.medium, intensity: 0.5)
    }
    
    func modalPresent() {
        impact(.heavy, intensity: 0.7)
    }
    
    func modalDismiss() {
        impact(.medium, intensity: 0.5)
    }
    
    // MARK: - App-Specific Patterns
    
    func rideBookingStart() {
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light, intensity: 0.4)
        }
    }
    
    func addressSelected() {
        impact(.soft, intensity: 0.8)
    }
    
    func mapInteraction() {
        impact(.light, intensity: 0.3)
    }
    
    func routeCalculated() {
        impact(.medium, intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impact(.light, intensity: 0.4)
        }
    }
    
    func priceUpdate() {
        impact(.soft, intensity: 0.5)
    }
    
    func paymentProcessing() {
        impact(.rigid, intensity: 0.8)
    }
    
    func bookingConfirmed() {
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.impact(.medium, intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.impact(.light, intensity: 0.4)
        }
    }
    
    func locationFound() {
        impact(.soft, intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light, intensity: 0.3)
        }
    }
    
    // MARK: - System Sound Effects
    
    func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    func playKeyboardTap() {
        AudioServicesPlaySystemSound(1104) // Keyboard tap
    }
    
    func playLockSound() {
        AudioServicesPlaySystemSound(1100) // Lock sound
    }
    
    func playUnlockSound() {
        AudioServicesPlaySystemSound(1101) // Unlock sound
    }
    
    // MARK: - Conditional Feedback
    
    func conditionalFeedback(enabled: Bool = true, _ closure: () -> Void) {
        guard enabled else { return }
        closure()
    }
    
    // MARK: - Prepared Generators (for performance)
    
    private var preparedImpactGenerator: UIImpactFeedbackGenerator?
    private var preparedSelectionGenerator: UISelectionFeedbackGenerator?
    private var preparedNotificationGenerator: UINotificationFeedbackGenerator?
    
    func prepareImpactGenerator(style: ImpactStyle = .medium) {
        preparedImpactGenerator = UIImpactFeedbackGenerator(style: style.feedbackStyle)
        preparedImpactGenerator?.prepare()
    }
    
    func prepareSelectionGenerator() {
        preparedSelectionGenerator = UISelectionFeedbackGenerator()
        preparedSelectionGenerator?.prepare()
    }
    
    func prepareNotificationGenerator() {
        preparedNotificationGenerator = UINotificationFeedbackGenerator()
        preparedNotificationGenerator?.prepare()
    }
    
    func triggerPreparedImpact(intensity: CGFloat = 1.0) {
        if #available(iOS 13.0, *) {
            preparedImpactGenerator?.impactOccurred(intensity: intensity)
        } else {
            preparedImpactGenerator?.impactOccurred()
        }
        preparedImpactGenerator?.prepare()
    }
    
    func triggerPreparedSelection() {
        preparedSelectionGenerator?.selectionChanged()
        preparedSelectionGenerator?.prepare()
    }
    
    func triggerPreparedNotification(_ type: NotificationStyle) {
        preparedNotificationGenerator?.notificationOccurred(type.feedbackType)
        preparedNotificationGenerator?.prepare()
    }
}

// MARK: - View Extensions for Haptic Feedback

extension View {
    func hapticFeedback(_ style: HapticManager.ImpactStyle, intensity: CGFloat = 1.0) -> some View {
        self.onTapGesture {
            HapticManager.shared.impact(style, intensity: intensity)
        }
    }
    
    func buttonHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.buttonTap()
                }
        )
    }
    
    func cardHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.cardTap()
                }
        )
    }
    
    func liquidHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.liquidPress()
                }
        )
    }
    
    func glassHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.glassTouch()
                }
        )
    }
    
    func selectionHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.selection()
                }
        )
    }
    
    func longPressHaptic() -> some View {
        self.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    HapticManager.shared.longPressStart()
                }
                .onEnded { _ in
                    HapticManager.shared.longPressEnd()
                }
        )
    }
}