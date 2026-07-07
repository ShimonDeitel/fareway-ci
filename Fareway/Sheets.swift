import SwiftUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum FundSheetMode: Identifiable {
    case add
    case edit(TripFund)
    case deposit(TripFund)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let fund): return "edit-\(fund.id.uuidString)"
        case .deposit(let fund): return "deposit-\(fund.id.uuidString)"
        case .paywall: return "paywall"
        }
    }
}

struct FundEditSheet: View {
    let mode: FundSheetMode
    let onSave: (String, Double, TripTheme) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var targetText: String
    @State private var theme: TripTheme

    init(mode: FundSheetMode, onSave: @escaping (String, Double, TripTheme) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let fund):
            _name = State(initialValue: fund.name)
            _targetText = State(initialValue: String(format: "%.2f", fund.targetAmount))
            _theme = State(initialValue: fund.theme)
        default:
            _name = State(initialValue: "")
            _targetText = State(initialValue: "")
            _theme = State(initialValue: .beach)
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Trip Fund" }
        return "New Trip Fund"
    }

    private var parsedTarget: Double {
        Double(targetText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTarget > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Trip name", text: $name)
                        .accessibilityIdentifier("fundNameField")

                    TextField("Goal amount", text: $targetText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("fundTargetField")
                }

                Section("Theme") {
                    Picker("Theme", selection: $theme) {
                        ForEach(TripTheme.allCases) { t in
                            Label(t.rawValue, systemImage: t.symbolName).tag(t)
                        }
                    }
                    .accessibilityIdentifier("fundThemePicker")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, parsedTarget, theme)
                        dismiss()
                    }
                    .accessibilityIdentifier("fundSaveButton")
                    .disabled(!isValid)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

struct DepositLogSheet: View {
    let fund: TripFund
    let onLog: (Double, Date, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    private var parsedAmount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var isValid: Bool { parsedAmount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deposit") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("depositAmountField")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("depositDatePicker")
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .accessibilityIdentifier("depositNoteField")
                }
            }
            .navigationTitle("Log Deposit — \(fund.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onLog(parsedAmount, date, note)
                        dismiss()
                    }
                    .accessibilityIdentifier("depositSaveButton")
                    .disabled(!isValid)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
