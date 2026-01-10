import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
