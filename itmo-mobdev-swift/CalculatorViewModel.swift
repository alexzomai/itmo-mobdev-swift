import Foundation
import Combine

struct HistoryItem: Codable, Equatable, Identifiable {
    var id = UUID()
    let expression: String
    let result: Double
}

struct CalculatorState: Codable, Equatable {
    var expression = ""
    var history: [HistoryItem] = []
    var memory: Double = 0
    var lastResult: Double? = nil
    var errorMessage: String? = nil
    var startsNewInput = false
}

extension CalculatorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .multipleDecimalPoints: return "Несколько десятичных точек в числе"
        case .invalidCharacter(let c): return "Недопустимый символ «\(c)»"
        case .emptyExpression: return "Пустое выражение"
        case .unbalancedParentheses: return "Неверно расставлены скобки"
        case .consecutiveOperators: return "Два оператора подряд"
        case .trailingOperator: return "Выражение заканчивается оператором"
        case .divisionByZero: return "Деление на ноль"
        case .unexpectedToken: return "Некорректное выражение"
        }
    }
}

func formatNumber(_ value: Double) -> String {
    var text: String
    if value == value.rounded() && abs(value) < 1e15 {
        text = String(Int64(value))
    } else {
        text = String(format: "%.10f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        if text == "-0" { text = "0" }
    }
    return text.replacingOccurrences(of: "-", with: "−")
}

class CalculatorViewModel: ObservableObject {
    static let historyLimit = 10
    private static let storageKey = "calculator.state"

    @Published private(set) var state: CalculatorState {
        didSet { save() }
    }

    private let defaults: UserDefaults

    var expression: String { state.expression }
    var history: [HistoryItem] { state.history }
    var memory: Double { state.memory }
    var lastResult: Double? { state.lastResult }
    var errorMessage: String? { state.errorMessage }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(CalculatorState.self, from: data) {
            state = saved
        } else {
            state = CalculatorState()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    func append(_ text: String) {
        state.errorMessage = nil
        let startsValue = text.first.map { $0.isNumber || $0 == "." || $0 == "(" } ?? false
        if state.startsNewInput && startsValue {
            state.expression = text
        } else {
            state.expression += text
        }
        state.startsNewInput = false
    }

    func backspace() {
        state.errorMessage = nil
        state.startsNewInput = false
        if !state.expression.isEmpty {
            state.expression.removeLast()
        }
    }

    func clear() {
        state.expression = ""
        state.errorMessage = nil
        state.startsNewInput = false
    }

    func toggleSign() {
        let chars = Array(state.expression)
        state.errorMessage = nil

        if chars.last == ")" {
            var start = chars.count - 2
            while start >= 0, chars[start].isNumber || chars[start] == "." { start -= 1 }
            let hasNumber = start < chars.count - 2
            if hasNumber, start >= 1, chars[start] == "−", chars[start - 1] == "(" {
                let number = String(chars[(start + 1)..<(chars.count - 1)])
                state.expression = String(chars[..<(start - 1)]) + number
            }
            return
        }

        var start = chars.count
        while start > 0, chars[start - 1].isNumber || chars[start - 1] == "." { start -= 1 }
        if start == chars.count { return }

        let number = String(chars[start...])
        if start == 0 {
            state.expression = "−" + number
        } else if start == 1, chars[0] == "−" {
            state.expression = number
        } else {
            state.expression = String(chars[..<start]) + "(−" + number + ")"
        }
    }

    func equals() {
        do {
            let value = try evaluate(state.expression)
            guard value.isFinite else {
                state.errorMessage = "Слишком большое число"
                return
            }
            state.history.insert(HistoryItem(expression: state.expression, result: value), at: 0)
            if state.history.count > Self.historyLimit {
                state.history.removeLast(state.history.count - Self.historyLimit)
            }
            state.lastResult = value
            state.expression = formatNumber(value)
            state.errorMessage = nil
            state.startsNewInput = true
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    func selectHistory(_ item: HistoryItem) {
        state.expression = item.expression
        state.errorMessage = nil
        state.startsNewInput = false
    }

    private func currentValue() -> Double? {
        do {
            let value = try evaluate(state.expression)
            guard value.isFinite else {
                state.errorMessage = "Слишком большое число"
                return nil
            }
            return value
        } catch {
            state.errorMessage = error.localizedDescription
            return nil
        }
    }

    func memoryAdd() {
        guard let value = currentValue() else { return }
        state.memory += value
        state.errorMessage = nil
    }

    func memorySubtract() {
        guard let value = currentValue() else { return }
        state.memory -= value
        state.errorMessage = nil
    }

    func memoryRecall() {
        let text = state.memory < 0 ? "(\(formatNumber(state.memory)))" : formatNumber(state.memory)
        var chars = Array(state.expression)
        while let last = chars.last, last.isNumber || last == "." { chars.removeLast() }
        state.expression = String(chars) + text
        state.errorMessage = nil
        state.startsNewInput = false
    }

    func memoryClear() {
        state.memory = 0
    }
}
