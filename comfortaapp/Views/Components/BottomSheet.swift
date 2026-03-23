import SwiftUI

// MARK: - Bottom Sheet Component

struct BottomSheet<Content: View>: View {
    @Binding var position: BottomSheetPosition
    let content: Content
    let showHandle: Bool
    let backgroundColor: Color

    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    private let handleHeight: CGFloat = 5
    private let handleWidth: CGFloat = 40

    init(
        position: Binding<BottomSheetPosition>,
        showHandle: Bool = true,
        backgroundColor: Color = ComfortaDesign.Colors.surface,
        @ViewBuilder content: () -> Content
    ) {
        self._position = position
        self.showHandle = showHandle
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if showHandle {
                    handleView
                        .padding(.top, 8)
                }

                content
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
            )
            .offset(y: max(0, currentOffset(in: geometry) + dragOffset))
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        snapToNearestPosition(
                            currentOffset: dragOffset,
                            velocity: velocity,
                            screenHeight: geometry.size.height
                        )
                        dragOffset = 0
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: position)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        }
    }

    private var handleView: some View {
        RoundedRectangle(cornerRadius: handleHeight / 2)
            .fill(Color.white.opacity(0.3))
            .frame(width: handleWidth, height: handleHeight)
            .padding(.bottom, 8)
    }

    private func currentOffset(in geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height

        switch position {
        case .hidden:
            return screenHeight
        case .peek:
            return screenHeight * 0.85
        case .middle:
            return screenHeight * 0.5
        case .full:
            return screenHeight * 0.1
        }
    }

    private func snapToNearestPosition(currentOffset: CGFloat, velocity: CGFloat, screenHeight: CGFloat) {
        let positions: [BottomSheetPosition] = [.peek, .middle, .full]
        let currentPosition = self.position

        // Si el usuario arrastra rápido hacia abajo, colapsar
        if velocity > 500 {
            if currentPosition == .full {
                position = .middle
            } else if currentPosition == .middle {
                position = .peek
            }
            return
        }

        // Si el usuario arrastra rápido hacia arriba, expandir
        if velocity < -500 {
            if currentPosition == .peek {
                position = .middle
            } else if currentPosition == .middle {
                position = .full
            }
            return
        }

        // Snap al más cercano basado en el offset
        let currentPositionY = offsetForPosition(currentPosition, screenHeight: screenHeight)
        let currentY = currentPositionY + currentOffset

        var closestPosition = currentPosition
        var minDistance = CGFloat.infinity

        for pos in positions {
            let posY = offsetForPosition(pos, screenHeight: screenHeight)
            let distance = abs(currentY - posY)

            if distance < minDistance {
                minDistance = distance
                closestPosition = pos
            }
        }

        position = closestPosition
    }

    private func offsetForPosition(_ position: BottomSheetPosition, screenHeight: CGFloat) -> CGFloat {
        switch position {
        case .hidden:
            return screenHeight
        case .peek:
            return screenHeight * 0.85
        case .middle:
            return screenHeight * 0.5
        case .full:
            return screenHeight * 0.1
        }
    }
}

enum BottomSheetPosition {
    case hidden
    case peek
    case middle
    case full
}

// MARK: - Compact Search Bar (for map view)

struct CompactSearchBar: View {
    let pickupText: String
    let destinationText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(destinationText.isEmpty ? "¿A dónde vas?" : destinationText)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(destinationText.isEmpty ? ComfortaDesign.Colors.textSecondary : ComfortaDesign.Colors.textPrimary)
                        .lineLimit(1)

                    if !pickupText.isEmpty {
                        Text(pickupText)
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    @State var position: BottomSheetPosition = .middle

    return ZStack {
        Color.gray.ignoresSafeArea()

        BottomSheet(position: $position) {
            VStack(spacing: 20) {
                Text("Bottom Sheet Content")
                    .font(.title2)
                    .padding()

                HStack {
                    Button("Peek") { position = .peek }
                    Button("Middle") { position = .middle }
                    Button("Full") { position = .full }
                    Button("Hide") { position = .hidden }
                }
                .padding()

                Spacer()
            }
        }
    }
}
