import SwiftUI

/// SwiftUI entry point. Replaces the macOS AppKit lifecycle (`main.swift` +
/// `AppDelegate`): on iOS the app is always full-screen, has no menu bar, and
/// needs no window management or multi-display handling.
@main
struct RulerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
