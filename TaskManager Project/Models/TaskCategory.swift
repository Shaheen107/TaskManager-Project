import SwiftUI

//Task Categorys
enum TaskCategory: String, CaseIterable, Codable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case finance = "Finance"
    case learning = "Learning"
    case shopping = "Shopping"
    case travel = "Travel"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .green
        case .health: return .red
        case .finance: return .orange
        case .learning: return .purple
        case .shopping: return .pink
        case .travel: return .cyan
        case .other: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .learning: return "book.fill"
        case .shopping: return "cart.fill"
        case .travel: return "airplane"
        case .other: return "folder.fill"
        }
    }
}
