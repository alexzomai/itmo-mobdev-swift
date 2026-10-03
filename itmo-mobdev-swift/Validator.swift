import Foundation

extension Token {
    var isOperator: Bool {
        switch self {
        case .plus, .minus, .multiply, .divide: return true
        default: return false
        }
    }
}

func validate(_ tokens: [Token]) throws {
    if tokens.isEmpty {
        throw CalculatorError.emptyExpression
    }

    var depth = 0
    var prev: Token? = nil

    for t in tokens {
        switch t {
        case .leftParen:
            depth += 1
        case .rightParen:
            depth -= 1
            if depth < 0 {
                throw CalculatorError.unbalancedParentheses
            }
        default:
            break
        }

        if t.isOperator, let p = prev, p.isOperator {
            throw CalculatorError.consecutiveOperators
        }
        prev = t
    }

    if depth != 0 {
        throw CalculatorError.unbalancedParentheses
    }
    if let p = prev, p.isOperator {
        throw CalculatorError.trailingOperator
    }
}
