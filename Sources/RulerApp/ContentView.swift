import SwiftUI

/// Root screen: the full-screen ruler with a floating controls strip
/// (unit + grid) and an info button that opens the About sheet. On iOS there's
/// no menu bar, so these on-screen controls replace the macOS menu/hotkeys.
struct ContentView: View {
    @StateObject private var state = RulerState()
    @State private var showAbout = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RulerView(state: state)

            controls
                .padding(14)
        }
        .overlay(alignment: .topTrailing) { infoButton }
        .sheet(isPresented: $showAbout) { AboutView() }
        .onAppear { state.pointsPerMm = DisplayMetrics.pointsPerMillimeter() }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button(state.unit.label) { state.unit = state.unit.next }
                .keyboardShortcut("u", modifiers: [])
            Button(gridLabel) { state.gridMode = state.gridMode.next }
                .keyboardShortcut("g", modifiers: [])
        }
        .font(.callout.weight(.medium))
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.regularMaterial)
        )
    }

    private var infoButton: some View {
        Button {
            showAbout = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .padding(12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(6)
    }

    private var gridLabel: String {
        switch state.gridMode {
        case .off: return "Grid"
        case .major: return "Grid •"
        case .majorAndMinor: return "Grid ••"
        }
    }
}
