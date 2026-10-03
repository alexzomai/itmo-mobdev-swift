import Foundation

enum Token {
    case number(Double)
    case plus
    case minus
    case multiply
    case divide
    case percent
    case leftParen
    case rightParen
}

enum CalculatorError: Error {
    case multipleDecimalPoints
    case invalidCharacter(Character)
    case emptyExpression
    case unbalancedParentheses
    case consecutiveOperators
    case trailingOperator
    case divisionByZero
    case unexpectedToken
}

func tokenize(_ input: String) throws -> [Token] {
    let chars = Array(input)
    var tokens: [Token] = []
    var i = 0

    while i < chars.count {
        let c = chars[i]
        
        if c.isNumber || c == "." {
            var text = ""
            while i < chars.count && (chars[i].isNumber || chars[i] == ".") {
                text.append(chars[i])
                i += 1
            }
            guard let value = Double(text) else {
                throw CalculatorError.multipleDecimalPoints
            }
            tokens.append(.number(value))
            continue
        }
        
        switch c {
        case " ": break
        case "+": tokens.append(.plus)
        case "-", "−": tokens.append(.minus)
        case "*", "×": tokens.append(.multiply)
        case "/", "÷": tokens.append(.divide)
        case "%": tokens.append(.percent)
        case "(": tokens.append(.leftParen)
        case ")": tokens.append(.rightParen)
        default: throw CalculatorError.invalidCharacter(c)
        }
        
        i += 1
    }

    return tokens
}
