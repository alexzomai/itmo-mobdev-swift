import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @State private var showHistory = false

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                HStack(spacing: 16) {
                    display
                    keypad
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    display
                    keypad
                }
                .padding()
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(viewModel: viewModel, isPresented: $showHistory)
        }
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Button {
                    showHistory = true
                } label: {
                    Label("История", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("historyButton")
                Spacer()
                if viewModel.memory != 0 {
                    Text("M = \(formatNumber(viewModel.memory))")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("memoryLabel")
                }
            }
            Spacer(minLength: 0)
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("errorLabel")
            }
            Text(viewModel.expression.isEmpty ? "0" : viewModel.expression)
                .font(.system(size: 44, weight: .light).monospacedDigit())
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("expressionLabel")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var keypad: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            row([key("MC", viewModel.memoryClear, .memory),
                 key("MR", viewModel.memoryRecall, .memory),
                 key("M−", viewModel.memorySubtract, .memory),
                 key("M+", viewModel.memoryAdd, .memory)])
            row([key("C", viewModel.clear, .function),
                 key("⌫", viewModel.backspace, .function),
                 key("(", { viewModel.append("(") }, .function),
                 key(")", { viewModel.append(")") }, .function)])
            row([digit("7"), digit("8"), digit("9"), op("÷")])
            row([digit("4"), digit("5"), digit("6"), op("×")])
            row([digit("1"), digit("2"), digit("3"), op("−")])
            row([digit("0"), digit("."), key("%", { viewModel.append("%") }, .function), op("+")])
            row([key("±", viewModel.toggleSign, .function),
                 key("=", viewModel.equals, .equals, span: 3)])
        }
    }

    private enum KeyStyle { case digit, op, function, memory, equals }

    private struct Key {
        let title: String
        let action: () -> Void
        let style: KeyStyle
        let span: Int
    }

    private func key(_ title: String, _ action: @escaping () -> Void, _ style: KeyStyle, span: Int = 1) -> Key {
        Key(title: title, action: action, style: style, span: span)
    }

    private func digit(_ text: String) -> Key {
        key(text, { viewModel.append(text) }, .digit)
    }

    private func op(_ text: String) -> Key {
        key(text, { viewModel.append(text) }, .op)
    }

    private func row(_ keys: [Key]) -> some View {
        GridRow {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, k in
                Button(action: k.action) {
                    Text(k.title)
                        .font(.title2.weight(.medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(foreground(k.style))
                        .background(background(k.style), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("key_\(k.title)")
                .gridCellColumns(k.span)
            }
        }
    }

    private func foreground(_ style: KeyStyle) -> Color {
        switch style {
        case .equals, .op: return .white
        default: return .primary
        }
    }

    private func background(_ style: KeyStyle) -> Color {
        switch style {
        case .digit: return Color(.secondarySystemFill)
        case .function: return Color(.tertiarySystemFill)
        case .memory: return Color(.quaternarySystemFill)
        case .op: return .orange
        case .equals: return .accentColor
        }
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty {
                    ContentUnavailableView("История пуста", systemImage: "clock")
                } else {
                    List(viewModel.history) { item in
                        Button {
                            viewModel.selectHistory(item)
                            isPresented = false
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.expression)
                                    .foregroundStyle(.secondary)
                                Text("= \(formatNumber(item.result))")
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("historyItem")
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Закрыть") { isPresented = false }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: CalculatorViewModel())
}
