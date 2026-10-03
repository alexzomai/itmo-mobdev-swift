import Foundation

struct Parser {
    let tokens: [Token]
    var position = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func peek() -> Token? {
        position < tokens.count ? tokens[position] : nil
    }

    mutating func next() -> Token? {
        guard let token = peek() else { return nil }
        position += 1
        return token
    }

    mutating func parse() throws -> Double {
        let value = try parseExpression()
        if peek() != nil {
            throw CalculatorError.unexpectedToken
        }
        return value
    }

    mutating func parseExpression() throws -> Double {
        var result = try parseTerm()
        while let token = peek() {
            if case .plus = token {
                _ = next()
                result += try parseTerm()
            } else if case .minus = token {
                _ = next()
                result -= try parseTerm()
            } else {
                break
            }
        }
        return result
    }

    mutating func parseTerm() throws -> Double {
        var result = try parseFactor()
        while let token = peek() {
            if case .multiply = token {
                _ = next()
                result *= try parseFactor()
            } else if case .divide = token {
                _ = next()
                let right = try parseFactor()
                if right == 0 {
                    throw CalculatorError.divisionByZero
                }
                result /= right
            } else {
                break
            }
        }
        return result
    }

    mutating func parseFactor() throws -> Double {
        if case .minus? = peek() {
            _ = next()
            return -(try parseFactor())
        }
        var value = try parsePrimary()
        while case .percent? = peek() {
            _ = next()
            value /= 100
        }
        return value
    }

    mutating func parsePrimary() throws -> Double {
        guard let token = next() else {
            throw CalculatorError.unexpectedToken
        }
        switch token {
        case .number(let value):
            return value
        case .leftParen:
            let value = try parseExpression()
            guard case .rightParen? = next() else {
                throw CalculatorError.unbalancedParentheses
            }
            return value
        default:
            throw CalculatorError.unexpectedToken
        }
    }
}

func evaluate(_ input: String) throws -> Double {
    let tokens = try tokenize(input)
    try validate(tokens)
    var parser = Parser(tokens: tokens)
    return try parser.parse()
}
