import SwiftUI
import MapKit

struct SearchSuggestionsList: View {
    let suggestions: [SearchSuggestion]
    let isSearching: Bool
    let onSuggestionSelected: (SearchSuggestion) -> Void
    
    var body: some View {
        if isSearching || !suggestions.isEmpty {
            VStack(spacing: 0) {
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Buscando...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(suggestions.prefix(5)) { suggestion in
                            SearchSuggestionRow(
                                suggestion: suggestion,
                                isLast: suggestion == suggestions.prefix(5).last,
                                onTap: { onSuggestionSelected(suggestion) }
                            )
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            )
            .animation(.easeInOut(duration: 0.2), value: isSearching)
            .animation(.easeInOut(duration: 0.2), value: suggestions.count)
        }
    }
}

private struct SearchSuggestionRow: View {
    let suggestion: SearchSuggestion
    let isLast: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
        .onTapGesture(perform: onTap)
    }
}

struct SearchSuggestionsList_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchSuggestionsList(
                suggestions: [
                    SearchSuggestion(completion: MockMKLocalSearchCompletion(title: "Plaza Mayor", subtitle: "Madrid, España")),
                    SearchSuggestion(completion: MockMKLocalSearchCompletion(title: "Aeropuerto Madrid-Barajas", subtitle: "Madrid, España")),
                    SearchSuggestion(completion: MockMKLocalSearchCompletion(title: "Estación de Atocha", subtitle: "Madrid, España"))
                ],
                isSearching: false,
                onSuggestionSelected: { _ in }
            )
            
            SearchSuggestionsList(
                suggestions: [],
                isSearching: true,
                onSuggestionSelected: { _ in }
            )
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// Mock for preview
private class MockMKLocalSearchCompletion: MKLocalSearchCompletion {
    private let _title: String
    private let _subtitle: String
    
    override var title: String { _title }
    override var subtitle: String { _subtitle }
    
    init(title: String, subtitle: String) {
        self._title = title
        self._subtitle = subtitle
        super.init()
    }
}