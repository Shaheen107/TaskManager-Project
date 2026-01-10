import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .accentColor : .secondary)
                .frame(width: 20)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16))
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(textFieldBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isFocused ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var textFieldBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray5)
            : Color(.systemGray6)
    }
}
