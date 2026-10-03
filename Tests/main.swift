import Foundation

var passed = 0
var failed = 0

func check(_ condition: Bool, _ name: String) {
    if condition { passed += 1 } else { failed += 1; print("FAIL:", name) }
}

func value(_ s: String) -> Double? { try? evaluate(s) }

func error(_ s: String) -> CalculatorError? {
    do { _ = try evaluate(s); return nil } catch { return error as? CalculatorError }
}

func isError(_ s: String, _ expected: CalculatorError) -> Bool {
    guard let e = error(s) else { return false }
    return "\(e)" == "\(expected)"
}

// MARK: - Движок

check(value("12 + 5 × 3") == 27, "приоритет × над +")
check(value("(12 + 5) × 3") == 51, "скобки")
check(value("20 ÷ 4 + 7") == 12, "÷ и +")
check(value("15.5 × 2") == 31, "вещественные числа")
check(value("15.5*2") == 31, "* как ×")
check(value("10 - 4 - 3") == 3, "вычитание слева направо")
check(value("100 / 4 / 5") == 5, "деление слева направо")
check(value("2 × (3 + 4) × 5") == 70, "несколько множителей")
check(value("((2 + 3) × (4 − 1))") == 15, "вложенные скобки")
check(value("-5 + 2") == -3, "унарный минус в начале")
check(value("(−2) × 3") == -6, "унарный минус в скобках")
check(value("200 × 10%") == 20, "процент")
check(value("50%") == 0.5, "процент одиночный")
check(value("0.1 + 0.2") != nil, "дробные")

check(isError("5 / 0", .divisionByZero), "деление на ноль")
check(isError("5 / (3 − 3)", .divisionByZero), "деление на ноль через скобки")
check(isError("(5", .unbalancedParentheses), "не закрыта скобка")
check(isError("5)", .unbalancedParentheses), "лишняя закрывающая")
check(isError(")5(", .unbalancedParentheses), "скобки в неверном порядке")
check(isError("5 + × 3", .consecutiveOperators), "два оператора подряд")
check(isError("1.2.3", .multipleDecimalPoints), "две точки в числе")
check(isError("", .emptyExpression), "пустое выражение")
check(isError("   ", .emptyExpression), "только пробелы")
check(isError("5 +", .trailingOperator), "оператор в конце")
check(isError("5 a", .invalidCharacter("a")), "недопустимый символ")
check(isError("()", .unexpectedToken), "пустые скобки")
check(isError("5 5", .unexpectedToken), "два числа подряд")
check(isError("(2)(3)", .unexpectedToken), "скобки без оператора")
check(isError("× 5", .unexpectedToken), "оператор в начале")
check(isError(".", .multipleDecimalPoints), "одиночная точка")

// MARK: - ViewModel

func makeVM() -> CalculatorViewModel {
    let defaults = UserDefaults(suiteName: "calc-tests-\(UUID().uuidString)")!
    return CalculatorViewModel(defaults: defaults)
}

func type(_ vm: CalculatorViewModel, _ text: String) {
    for ch in text { vm.append(String(ch)) }
}

do {
    let vm = makeVM()
    type(vm, "12+5×3")
    vm.equals()
    check(vm.expression == "27", "equals: выражение заменяется результатом")
    check(vm.lastResult == 27, "equals: lastResult")
    check(vm.history.count == 1 && vm.history[0].expression == "12+5×3" && vm.history[0].result == 27, "equals: запись истории")
    check(vm.errorMessage == nil, "equals: без ошибки")
}

do {
    let vm = makeVM()
    type(vm, "5÷0")
    vm.equals()
    check(vm.errorMessage == "Деление на ноль", "ошибка показана")
    check(vm.expression == "5÷0", "выражение сохраняется при ошибке")
    check(vm.history.isEmpty, "ошибка не попадает в историю")
    vm.backspace()
    check(vm.errorMessage == nil, "ошибка сбрасывается при вводе")
}

do {
    let vm = makeVM()
    vm.equals()
    check(vm.errorMessage == "Пустое выражение", "= на пустом вводе")
}

do {
    let vm = makeVM()
    type(vm, "2+3")
    vm.equals()
    type(vm, "7")
    check(vm.expression == "7", "цифра после результата начинает новый ввод")
    vm.equals()
    type(vm, "+1")
    vm.equals()
    check(vm.expression == "8", "оператор продолжает результат")
}

do {
    let vm = makeVM()
    for i in 1...12 { vm.clear(); type(vm, "\(i)+0"); vm.equals() }
    check(vm.history.count == 10, "история ограничена 10")
    check(vm.history.first?.result == 12, "новые записи сверху")
    check(vm.history.last?.result == 3, "старые вытесняются")
}

do {
    let vm = makeVM()
    type(vm, "12")
    vm.backspace()
    check(vm.expression == "1", "backspace")
    vm.backspace(); vm.backspace()
    check(vm.expression == "", "backspace на пустом не падает")
    type(vm, "99"); vm.clear()
    check(vm.expression == "", "clear")
}

do {
    let vm = makeVM()
    type(vm, "5"); vm.toggleSign()
    check(vm.expression == "−5", "± в начале")
    vm.toggleSign()
    check(vm.expression == "5", "± обратно")
    type(vm, "+3"); vm.toggleSign()
    check(vm.expression == "5+(−3)", "± в середине")
    vm.toggleSign()
    check(vm.expression == "5+3", "± обратно в середине")
    vm.equals()
    check(vm.expression == "8", "± не ломает вычисление")
    vm.clear(); vm.toggleSign()
    check(vm.expression == "", "± на пустом")
    type(vm, "5+"); vm.toggleSign()
    check(vm.expression == "5+", "± после оператора ничего не делает")
    vm.clear(); type(vm, "2×"); type(vm, "4"); vm.toggleSign(); vm.equals()
    check(vm.expression == "−8", "± и результат")
}

do {
    let vm = makeVM()
    type(vm, "10"); vm.memoryAdd()
    check(vm.memory == 10, "M+")
    vm.clear(); type(vm, "3×2"); vm.memoryAdd()
    check(vm.memory == 16, "M+ считает выражение")
    vm.clear(); type(vm, "4"); vm.memorySubtract()
    check(vm.memory == 12, "M−")
    vm.clear(); vm.memoryRecall()
    check(vm.expression == "12", "MR на пустом вводе")
    type(vm, "+1"); vm.equals()
    check(vm.expression == "13", "MR + вычисление")
    vm.clear(); type(vm, "7"); vm.memoryRecall()
    check(vm.expression == "12", "MR заменяет текущее число")
    vm.memoryClear()
    check(vm.memory == 0, "MC")
    vm.clear(); type(vm, "5÷0"); vm.memoryAdd()
    check(vm.memory == 0 && vm.errorMessage == "Деление на ноль", "M+ на ошибочном выражении")
    vm.clear(); vm.memoryAdd()
    check(vm.memory == 0 && vm.errorMessage == "Пустое выражение", "M+ на пустом выражении")
    vm.clear(); type(vm, "5"); vm.memorySubtract(); vm.memorySubtract()
    vm.clear(); vm.memoryRecall()
    check(vm.expression == "(−10)", "MR отрицательной памяти в скобках")
    vm.equals()
    check(vm.expression == "−10", "отрицательная память вычисляется")
}

do {
    let vm = makeVM()
    type(vm, "(12+5)×3"); vm.equals()
    vm.clear()
    vm.selectHistory(vm.history[0])
    check(vm.expression == "(12+5)×3", "выбор из истории возвращает выражение")
    vm.equals()
    check(vm.expression == "51" && vm.history.count == 2, "повторное вычисление из истории")
}

do {
    let suite = "calc-tests-persist-\(UUID().uuidString)"
    let d1 = UserDefaults(suiteName: suite)!
    let vm = CalculatorViewModel(defaults: d1)
    type(vm, "2+2"); vm.equals(); vm.memoryAdd()
    type(vm, "/0"); vm.equals()
    let restored = CalculatorViewModel(defaults: UserDefaults(suiteName: suite)!)
    check(restored.expression == vm.expression, "сохранено: выражение")
    check(restored.history == vm.history && restored.history.count == 1, "сохранено: история")
    check(restored.memory == 4, "сохранено: память")
    check(restored.lastResult == 4, "сохранено: последний результат")
    check(restored.errorMessage == "Деление на ноль", "сохранено: ошибка")
}

check(formatNumber(27) == "27", "формат целого")
check(formatNumber(0.5) == "0.5", "формат дробного")
check(formatNumber(0.1 + 0.2) == "0.3", "формат шума двоичной дроби")
check(formatNumber(-5) == "−5", "формат отрицательного")
check(formatNumber(-0.0) == "0", "формат минус нуля")

print("passed: \(passed), failed: \(failed)")
exit(failed == 0 ? 0 : 1)
