import SwiftUI

/// Fareway's identity: a sun-warmed travel-poster palette — sunset-orange
/// mercury against a tropical-teal backdrop, with a brass-luggage-tag gold
/// for milestones. Deliberately distinct from every sibling app's palette
/// (Envelo's coral/teal envelope-flap look, Beacon's slate/amber, Ream's
/// red-tape/pencil-yellow, any cream/ink-navy/amber "luxury ledger" family).
enum FWTheme {
    static let backdrop = Color(red: 0.976, green: 0.949, blue: 0.918)     // warm sand
    static let card = Color.white
    static let cardBorder = Color(red: 0.878, green: 0.792, blue: 0.706)

    static let ink = Color(red: 0.129, green: 0.157, blue: 0.180)          // deep travel-poster charcoal
    static let inkFaded = Color(red: 0.129, green: 0.157, blue: 0.180).opacity(0.56)

    // Classic mercury-thermometer sunset gradient.
    static let mercuryTop = Color(red: 0.933, green: 0.325, blue: 0.286)    // sunset red
    static let mercuryMid = Color(red: 0.973, green: 0.573, blue: 0.184)   // sunset orange
    static let mercuryBottom = Color(red: 0.996, green: 0.792, blue: 0.298) // sunset gold

    static let teal = Color(red: 0.106, green: 0.443, blue: 0.451)         // tropical teal accent
    static let tealDeep = Color(red: 0.071, green: 0.322, blue: 0.333)

    static let brass = Color(red: 0.769, green: 0.588, blue: 0.235)        // luggage-tag brass, for milestones/confetti

    static let danger = Color(red: 0.780, green: 0.271, blue: 0.243)
    static let rule = Color.black.opacity(0.06)

    static let titleFont = Font.system(.title2, design: .serif).weight(.bold)
    static let displayFont = Font.system(size: 40, weight: .bold, design: .serif)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
