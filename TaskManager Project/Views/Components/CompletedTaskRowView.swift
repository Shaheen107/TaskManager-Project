
struct CompletedTaskRowView: View {
    let task: TaskItems
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .strikethrough()
                
                HStack(spacing: 8) {
                    if let completedDate = task.completedDate {
                        Text(completedDate, formatter: RelativeDateTimeFormatter())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Show time spent
                    if task.timeSpent > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text(task.formattedTimeSpent)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}
