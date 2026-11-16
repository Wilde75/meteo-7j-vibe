import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var refreshCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await WeatherViewModel.shared.refresh() }
        refreshCancellable = Timer.publish(from: Date(), every: 15 * 60)
            .autoconnect()
            .sink { _ in
                Task { await WeatherViewModel.shared.refresh() }
            }
    }
}
