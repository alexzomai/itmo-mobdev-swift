import SwiftUI

@main struct MyApp: App {
    @StateObject private var viewModel = CalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
