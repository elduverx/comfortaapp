import SwiftUI
import Combine

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text(message)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Button(action: {
                dismissToast()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.lg)
        .padding(.vertical, ComfortaDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                .fill(type.backgroundColor)
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            showToast()
        }
    }

    private func showToast() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = 0
            opacity = 1
        }

        // Auto dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismissToast()
        }
    }

    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            offset = -100
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success:
            return ComfortaDesign.Colors.primaryGreen
        case .error:
            return ComfortaDesign.Colors.error
        case .warning:
            return ComfortaDesign.Colors.warning
        case .info:
            return ComfortaDesign.Colors.accent
        }
    }
}

// MARK: - Toast Manager

class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: ToastMessage?

    private init() {}

    func show(_ message: String, type: ToastType = .info) {
        currentToast = ToastMessage(message: message, type: type)
    }

    func dismiss() {
        currentToast = nil
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toastManager.currentToast {
                VStack {
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        onDismiss: {
                            toastManager.dismiss()
                        }
                    )
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
                    .padding(.top, ComfortaDesign.Spacing.xl)

                    Spacer()
                }
                .zIndex(1000)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

#Preview {
    VStack {
        Spacer()

        Button("Show Success Toast") {
            ToastManager.shared.show("Viaje confirmado exitosamente", type: .success)
        }
        .padding()

        Button("Show Error Toast") {
            ToastManager.shared.show("Error al procesar el pago", type: .error)
        }
        .padding()

        Button("Show Warning Toast") {
            ToastManager.shared.show("Sin conexión a internet", type: .warning)
        }
        .padding()

        Button("Show Info Toast") {
            ToastManager.shared.show("Calculando ruta...", type: .info)
        }
        .padding()

        Spacer()
    }
    .background(ComfortaDesign.Colors.background)
    .withToast()
}
