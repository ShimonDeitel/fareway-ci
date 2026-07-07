import Foundation

enum TripTheme: String, Codable, CaseIterable, Identifiable {
    case beach = "Beach"
    case city = "City"
    case mountains = "Mountains"
    case roadTrip = "Road Trip"
    case cruise = "Cruise"
    case camping = "Camping"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .beach: return "sun.max.fill"
        case .city: return "building.2.fill"
        case .mountains: return "mountain.2.fill"
        case .roadTrip: return "car.fill"
        case .cruise: return "ferry.fill"
        case .camping: return "tent.fill"
        }
    }
}

struct Deposit: Identifiable, Codable, Equatable {
    let id: UUID
    var amount: Double
    var date: Date
    var note: String

    init(id: UUID = UUID(), amount: Double, date: Date = Date(), note: String = "") {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct TripFund: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var theme: TripTheme
    var createdDate: Date
    var deposits: [Deposit]

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        theme: TripTheme,
        createdDate: Date = Date(),
        deposits: [Deposit] = []
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.theme = theme
        self.createdDate = createdDate
        self.deposits = deposits
    }

    var currentAmount: Double {
        deposits.reduce(0) { $0 + $1.amount }
    }

    /// Real progress, uncapped (can exceed 1.0 for an over-funded trip).
    var rawProgress: Double {
        guard targetAmount > 0 else { return 0 }
        return currentAmount / targetAmount
    }

    /// Display progress, clamped to [0, 1] for the thermometer fill visual.
    var displayProgress: Double {
        min(1.0, max(0.0, rawProgress))
    }

    var isGoalReached: Bool {
        currentAmount >= targetAmount && targetAmount > 0
    }

    var overageAmount: Double {
        max(0, currentAmount - targetAmount)
    }
}
