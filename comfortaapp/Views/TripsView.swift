import SwiftUI
import CoreLocation

struct TripsView: View {
    @StateObject private var tripService = TripServiceAPI.shared
    @State private var selectedFilter: TripFilter = .all
    @State private var showingTripDetails = false
    @State private var selectedTrip: APITrip?
    @State private var isViewReady = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ComfortaDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Filter Pills
                        filterSection
                        
                        // Trip List
                        tripsListSection
                    }
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
                    .padding(.top, ComfortaDesign.Spacing.sm)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Ensure view is properly initialized
            isViewReady = true
            Task {
                await tripService.loadTripHistory()
            }
        }
        .sheet(isPresented: $showingTripDetails) {
            if let trip = selectedTrip {
                APITripDetailsView(trip: trip)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
            HStack {
                Text("Mis Viajes")
                    .font(ComfortaDesign.Typography.hero)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    // Search action
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(ComfortaDesign.Colors.glassBackground)
                                .background(.ultraThinMaterial, in: Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                        )
                }
            }
            
            Text("Historial de viajes y reservas")
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ComfortaDesign.Spacing.sm) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(ComfortaDesign.Animation.spring) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
    }
    
    private var tripsListSection: some View {
        LazyVStack(spacing: ComfortaDesign.Spacing.md) {
            if filteredTrips.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredTrips) { trip in
                    TripCard(
                        trip: trip,
                        onTap: {
                            selectedTrip = trip
                            showingTripDetails = true
                        }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Image(systemName: "car.circle")
                    .font(.system(size: 60))
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    Text("No hay viajes")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Text("Cuando hagas tu primer viaje, aparecerá aquí")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, ComfortaDesign.Spacing.xl)
        }
    }
    
    private var filteredTrips: [APITrip] {
        let allTrips = tripService.tripHistory

        switch selectedFilter {
        case .all:
            return allTrips
        case .completed:
            return allTrips.filter { $0.isCompleted }
        case .cancelled:
            return allTrips.filter { $0.isCancelled }
        case .upcoming:
            return allTrips.filter { $0.isUpcoming }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textSecondary)
                .padding(.horizontal, ComfortaDesign.Spacing.md)
                .padding(.vertical, ComfortaDesign.Spacing.sm)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [ComfortaDesign.Colors.glassBackground],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected 
                                ? Color.clear 
                                : ComfortaDesign.Colors.glassBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TripCard: View {
    let trip: APITrip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ModernCard(style: .glass) {
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                    // Header with status and date
                    HStack {
                        HStack(spacing: ComfortaDesign.Spacing.xs) {
                            Circle()
                                .fill(trip.statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(trip.statusDisplayName)
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(trip.statusColor)
                        }
                        
                        Spacer()
                        
                        Text(formatDate(trip.createdAtDate))
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                    
                    // Route info
                    VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                        RouteRow(
                            icon: "location.circle.fill",
                            iconColor: ComfortaDesign.Colors.primaryGreen,
                            text: trip.lugarRecogida ?? "-",
                            isDestination: false
                        )
                        
                        RouteRow(
                            icon: "flag.checkered",
                            iconColor: ComfortaDesign.Colors.error,
                            text: trip.destino,
                            isDestination: true
                        )
                    }
                    
                    Divider().background(ComfortaDesign.Colors.glassBorder)
                    
                    // Trip details
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.formattedPrice)
                                .font(ComfortaDesign.Typography.title3)
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            
                            Text("\(trip.formattedDistance) • \(trip.formattedDuration)")
                                .font(ComfortaDesign.Typography.caption2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RouteRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    let isDestination: Bool
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(text)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

enum TripFilter: CaseIterable {
    case all
    case completed
    case cancelled
    case upcoming
    
    var title: String {
        switch self {
        case .all:
            return "Todos"
        case .completed:
            return "Completados"
        case .cancelled:
            return "Cancelados"
        case .upcoming:
            return "Próximos"
        }
    }
}

#Preview {
    TripsView()
}
