import Foundation
import CoreGraphics
import Combine

enum RulerGridMode: String {
    case off
    case major
    case majorAndMinor

    var next: RulerGridMode {
        switch self {
        case .off: return .major
        case .major: return .majorAndMinor
        case .majorAndMinor: return .off
        }
    }

    var showsMajor: Bool { self != .off }
    var showsMinor: Bool { self == .majorAndMinor }
}

final class RulerState: ObservableObject {
    /// Persisted across launches so the user keeps their preferred unit/grid.
    @Published var unit: RulerUnit = RulerState.loadUnit() {
        didSet { UserDefaults.standard.set(unit.rawValue, forKey: Keys.unit) }
    }
    @Published var gridMode: RulerGridMode = RulerState.loadGrid() {
        didSet { UserDefaults.standard.set(gridMode.rawValue, forKey: Keys.grid) }
    }

    /// Points-per-mm for the current screen; set on appear from `DisplayMetrics`.
    @Published var pointsPerMm: CGFloat = 6.0
    /// Active measurement point in the ruler view's local coordinate system, or
    /// nil when nothing is being measured. Set by touch drag and pointer hover.
    @Published var cursorLocal: CGPoint? = nil

    private enum Keys {
        static let unit = "ruler.unit"
        static let grid = "ruler.gridMode"
    }

    private static func loadUnit() -> RulerUnit {
        guard let raw = UserDefaults.standard.string(forKey: Keys.unit),
              let unit = RulerUnit(rawValue: raw) else { return .mmcm }
        return unit
    }

    private static func loadGrid() -> RulerGridMode {
        guard let raw = UserDefaults.standard.string(forKey: Keys.grid),
              let mode = RulerGridMode(rawValue: raw) else { return .majorAndMinor }
        return mode
    }
}
