import SwiftUI
import MapKit
import Combine

// MARK: - Liquid Search Field

struct LiquidSearchField: View {
    @Binding var text: String
    @Binding var selectedAddress: String
    let placeholder: String
    let icon: String
    let onCurrentLocation: (() -> Void)?
    let onMapSelection: (() -> Void)?
    let onSelection: ((String, CLLocationCoordinate2D) -> Void)?
    let onFocusChange: ((Bool) -> Void)?
    
    @StateObject private var searchCompleter = SearchCompleter()
    @FocusState private var isFocused: Bool
    @State private var showSuggestions = false
    @State private var animateIcon = false
    @State private var searchWorkItem: DispatchWorkItem?
    
    init(
        text: Binding<String>,
        selectedAddress: Binding<String>,
        placeholder: String,
        icon: String = "magnifyingglass",
        onCurrentLocation: (() -> Void)? = nil,
        onMapSelection: (() -> Void)? = nil,
        onSelection: ((String, CLLocationCoordinate2D) -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil
    ) {
        self._text = text
        self._selectedAddress = selectedAddress
        self.placeholder = placeholder
        self.icon = icon
        self.onCurrentLocation = onCurrentLocation
        self.onMapSelection = onMapSelection
        self.onSelection = onSelection
        self.onFocusChange = onFocusChange
    }
    
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.sm) {
            // Search Input
            HStack(spacing: ComfortaDesign.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .rotationEffect(.degrees(animateIcon ? 360 : 0))
                    .animation(ComfortaDesign.Animation.spring, value: animateIcon)
                
                // Text Field
                TextField(placeholder, text: $text)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        searchWorkItem?.cancel()
                        if newValue.isEmpty {
                            searchCompleter.cancel()
                            withAnimation(ComfortaDesign.Animation.medium) {
                                showSuggestions = false
                            }
                            return
                        }
                        let workItem = DispatchWorkItem { [newValue] in
                            searchCompleter.search(query: newValue)
                            withAnimation(ComfortaDesign.Animation.spring) {
                                animateIcon = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(ComfortaDesign.Animation.spring) {
                                    animateIcon = false
                                }
                            }
                        }
                        searchWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
                    }
                    .onChange(of: isFocused) { _, focused in
                        withAnimation(ComfortaDesign.Animation.medium) {
                            showSuggestions = focused && !text.isEmpty && !searchCompleter.results.isEmpty
                        }
                        onFocusChange?(focused)
                    }
                    .onReceive(searchCompleter.$results) { results in
                        withAnimation(ComfortaDesign.Animation.medium) {
                            showSuggestions = isFocused && !text.isEmpty && !results.isEmpty
                        }
                    }
                
                // Clear Button
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(ComfortaDesign.Animation.fast) {
                            text = ""
                            selectedAddress = ""
                            showSuggestions = false
                            searchCompleter.cancel()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Current Location Button
                if let onCurrentLocation = onCurrentLocation, text.isEmpty {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Map Selection Button
                if let onMapSelection = onMapSelection, text.isEmpty {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        isFocused = false
                        onMapSelection()
                    }) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(
                searchFieldBackground
            )
            
            // Suggestions
            if showSuggestions {
                suggestionsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var iconColor: Color {
        if isFocused {
            return ComfortaDesign.Colors.primaryGreen
        } else if !text.isEmpty {
            return ComfortaDesign.Colors.textPrimary
        } else {
            return ComfortaDesign.Colors.textTertiary
        }
    }
    
    private var searchFieldBackground: some View {
        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
            .fill(
                LinearGradient(
                    colors: [
                        ComfortaDesign.Colors.glassBackground.opacity(isFocused ? 0.9 : 0.6),
                        ComfortaDesign.Colors.glassHighlight.opacity(isFocused ? 0.4 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .stroke(
                        isFocused ? ComfortaDesign.Colors.primaryGreen.opacity(0.6) : ComfortaDesign.Colors.glassBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
                    .animation(ComfortaDesign.Animation.fast, value: isFocused)
            )
            .shadow(
                color: isFocused ? 
                    ComfortaDesign.Colors.primaryGreen.opacity(0.2) : 
                    ComfortaDesign.Colors.glassShadow,
                radius: isFocused ? 8 : 4,
                x: 0,
                y: isFocused ? 4 : 2
            )
    }
    
    private var suggestionsView: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(searchCompleter.results.prefix(5).enumerated()), id: \.offset) { index, result in
                SuggestionRow(
                    suggestion: result,
                    isLast: index == min(4, searchCompleter.results.count - 1),
                    onTap: {
                        selectSuggestion(result)
                    }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            ComfortaDesign.Colors.glassBackground.opacity(0.9),
                            ComfortaDesign.Colors.glassHighlight.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(
                    color: ComfortaDesign.Colors.glassShadow,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
    }
    
    private func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        Task {
            do {
                let response = try await search.start()
                if !response.mapItems.isEmpty {
                    let fullAddress = [
                        completion.title,
                        completion.subtitle
                    ].joined(separator: ", ")
                    let coordinate = response.mapItems.first!.placemark.coordinate
                    
                    await MainActor.run {
                        selectedAddress = fullAddress
                        text = completion.title
                        onSelection?(fullAddress, coordinate)
                        
                        withAnimation(ComfortaDesign.Animation.medium) {
                            showSuggestions = false
                            isFocused = false
                        }
                        
                        searchCompleter.cancel()
                    }
                }
            } catch {
                print("Error en búsqueda: \(error)")
            }
        }
    }
}

// MARK: - Suggestion Row

struct SuggestionRow: View {
    let suggestion: MKLocalSearchCompletion
    let isLast: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            HStack(spacing: ComfortaDesign.Spacing.md) {
                // Location Icon
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                
                // Address Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    .rotationEffect(.degrees(isPressed ? -45 : 0))
                    .animation(ComfortaDesign.Animation.fast, value: isPressed)
            }
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(
                Rectangle()
                    .fill(isPressed ? ComfortaDesign.Colors.glassHighlight.opacity(0.2) : Color.clear)
                    .animation(ComfortaDesign.Animation.fast, value: isPressed)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(ComfortaDesign.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
        
        // Divider
        if !isLast {
            Divider()
                .background(ComfortaDesign.Colors.glassBorder)
                .padding(.horizontal, ComfortaDesign.Spacing.md)
        }
    }
}

// MARK: - Search Completer (reusing from AddressSearchField)

// This reuses the SearchCompleter class from AddressSearchField.swift
