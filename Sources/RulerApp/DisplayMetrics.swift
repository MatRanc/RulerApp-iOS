import UIKit

/// Converts the device's physical pixel density into the points-per-millimeter
/// the ruler draws with. This is the single source of scale — there is no user
/// calibration; accuracy comes from `DeviceModel`'s PPI table.
enum DisplayMetrics {
    /// Points-per-millimeter for the current device's main screen.
    ///
    /// `DeviceModel.ppi` is a *physical* pixels-per-inch figure. SwiftUI draws in
    /// points, and `UIScreen.nativeScale` is exactly the number of physical pixels
    /// per point (it already accounts for the downsampling on "Plus"/"mini"
    /// panels, where `nativeScale` ≠ the nominal `scale`). So:
    ///
    ///     points-per-inch = physicalPPI / nativeScale
    ///     points-per-mm   = physicalPPI / nativeScale / 25.4
    static func pointsPerMillimeter() -> CGFloat {
        let nativeScale = UIScreen.main.nativeScale
        guard nativeScale > 0 else { return DeviceModel.fallbackPPI / 2 / 25.4 }
        return DeviceModel.ppi / nativeScale / 25.4
    }
}
