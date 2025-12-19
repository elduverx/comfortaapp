import SwiftUI

struct LocationSearchField: View {
    let fieldType: SearchFieldType
    @Binding var text: String
    let isActive: Bool
    let onTap: () -> Void
    let onTextChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: fieldType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fieldType.title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    TextField(fieldType.placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onTapGesture(perform: onTap)
                        .onChange(of: text) { newValue in
                            // Defer the change to avoid publishing from within view updates
                            DispatchQueue.main.async {
                                onTextChange(newValue)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isActive ? .accentColor.opacity(0.3) : .black.opacity(0.05),
                        radius: isActive ? 8 : 4,
                        x: 0,
                        y: isActive ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isActive ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

struct LocationSearchField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            LocationSearchField(
                fieldType: .pickup,
                text: .constant("Ubicación actual"),
                isActive: false,
                onTap: {},
                onTextChange: { _ in }
            )
            
            LocationSearchField(
                fieldType: .destination,
                text: .constant(""),
                isActive: true,
                onTap: {},
                onTextChange: { _ in }
            )
        }
        .padding()
        .background(Color(.systemGray6))
    }
}