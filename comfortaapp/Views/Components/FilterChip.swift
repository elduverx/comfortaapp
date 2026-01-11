import SwiftUI

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String?
    let count: Int?
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String,
        isSelected: Bool = false,
        icon: String? = nil,
        count: Int? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.icon = icon
        self.count = count
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: ComfortaDesign.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }

                Text(title)
                    .font(ComfortaDesign.Typography.caption1)

                if let count = count {
                    Text("\(count)")
                        .font(ComfortaDesign.Typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(countBackgroundColor)
                        )
                }
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(ComfortaDesign.Radius.round)
            .overlay(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.round)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(ComfortaDesign.Animation.fast, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(ComfortaDesign.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var backgroundColor: Color {
        if isSelected {
            return ComfortaDesign.Colors.primaryGreen.opacity(0.15)
        } else {
            return ComfortaDesign.Colors.surfaceSecondary
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return ComfortaDesign.Colors.primaryGreen
        } else {
            return ComfortaDesign.Colors.textSecondary
        }
    }

    private var borderColor: Color {
        if isSelected {
            return ComfortaDesign.Colors.primaryGreen
        } else {
            return ComfortaDesign.Colors.glassBorder
        }
    }

    private var countBackgroundColor: Color {
        if isSelected {
            return ComfortaDesign.Colors.primaryGreen.opacity(0.3)
        } else {
            return ComfortaDesign.Colors.glassBackground
        }
    }
}

// MARK: - Filter Chips Container

struct FilterChipsContainer: View {
    let filters: [FilterOption]
    @Binding var selectedFilters: Set<String>
    let multiSelect: Bool

    init(
        filters: [FilterOption],
        selectedFilters: Binding<Set<String>>,
        multiSelect: Bool = true
    ) {
        self.filters = filters
        self._selectedFilters = selectedFilters
        self.multiSelect = multiSelect
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ComfortaDesign.Spacing.sm) {
                ForEach(filters) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilters.contains(filter.id),
                        icon: filter.icon,
                        count: filter.count
                    ) {
                        toggleFilter(filter.id)
                    }
                }
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
    }

    private func toggleFilter(_ id: String) {
        if multiSelect {
            if selectedFilters.contains(id) {
                selectedFilters.remove(id)
            } else {
                selectedFilters.insert(id)
            }
        } else {
            if selectedFilters.contains(id) {
                selectedFilters.removeAll()
            } else {
                selectedFilters.removeAll()
                selectedFilters.insert(id)
            }
        }
    }
}

struct FilterOption: Identifiable {
    let id: String
    let title: String
    let icon: String?
    let count: Int?

    init(id: String, title: String, icon: String? = nil, count: Int? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.count = count
    }
}

// MARK: - Sort Chip

struct SortChip: View {
    let title: String
    let isSelected: Bool
    let direction: SortDirection?
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: ComfortaDesign.Spacing.xs) {
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)

                if isSelected, let direction = direction {
                    Image(systemName: direction.icon)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(isSelected ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textSecondary)
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(
                isSelected ?
                ComfortaDesign.Colors.primaryGreen.opacity(0.15) :
                ComfortaDesign.Colors.surfaceSecondary
            )
            .cornerRadius(ComfortaDesign.Radius.round)
            .overlay(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.round)
                    .stroke(
                        isSelected ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.glassBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SortDirection {
    case ascending
    case descending

    var icon: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

// MARK: - Advanced Search Bar

struct AdvancedSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedFilters: Set<String>
    let placeholder: String
    let filters: [FilterOption]
    let onSearch: (String, Set<String>) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.md) {
            // Search Field
            HStack(spacing: ComfortaDesign.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textTertiary)

                TextField(placeholder, text: $searchText)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        onSearch(newValue, selectedFilters)
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onSearch("", selectedFilters)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                            .stroke(
                                isFocused ? ComfortaDesign.Colors.primaryGreen.opacity(0.6) : ComfortaDesign.Colors.glassBorder,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )

            // Filter Chips
            if !filters.isEmpty {
                FilterChipsContainer(
                    filters: filters,
                    selectedFilters: $selectedFilters
                )
                .onChange(of: selectedFilters) { _, _ in
                    onSearch(searchText, selectedFilters)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Filter Chips") {
    @State var selectedFilters: Set<String> = ["completed"]

    return VStack(spacing: ComfortaDesign.Spacing.lg) {
        FilterChipsContainer(
            filters: [
                FilterOption(id: "all", title: "Todos", icon: "list.bullet", count: 150),
                FilterOption(id: "completed", title: "Completados", icon: "checkmark.circle", count: 120),
                FilterOption(id: "pending", title: "Pendientes", icon: "clock", count: 25),
                FilterOption(id: "cancelled", title: "Cancelados", icon: "xmark.circle", count: 5)
            ],
            selectedFilters: $selectedFilters
        )

        Text("Selected: \(selectedFilters.joined(separator: ", "))")
            .font(ComfortaDesign.Typography.caption1)
            .foregroundColor(ComfortaDesign.Colors.textSecondary)
    }
    .padding()
    .background(ComfortaDesign.Colors.background)
}

#Preview("Advanced Search") {
    @State var searchText = ""
    @State var selectedFilters: Set<String> = []

    return AdvancedSearchBar(
        searchText: $searchText,
        selectedFilters: $selectedFilters,
        placeholder: "Buscar viajes...",
        filters: [
            FilterOption(id: "today", title: "Hoy", icon: "calendar"),
            FilterOption(id: "week", title: "Esta semana", icon: "calendar.badge.clock"),
            FilterOption(id: "month", title: "Este mes", icon: "calendar.circle")
        ],
        onSearch: { text, filters in
            print("Search: \(text), Filters: \(filters)")
        }
    )
    .padding()
    .background(ComfortaDesign.Colors.background)
}
