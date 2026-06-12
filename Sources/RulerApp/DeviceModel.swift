import UIKit

/// Identifies the running device and exposes its physical pixel density (PPI),
/// which is the basis for drawing a true-to-life ruler.
///
/// iOS has no public API for a screen's physical size (unlike macOS's
/// `CGDisplayScreenSize`), so we map the hardware model identifier to a known,
/// published PPI. Every device this app ships to is a known iPhone/iPad, so
/// there is no runtime credit-card calibration — the table is the source of truth.
enum DeviceModel {
    /// Hardware model identifier, e.g. `"iPhone16,2"` or `"iPad14,2"`.
    ///
    /// In the Simulator `uname` reports the host architecture (`arm64`/`x86_64`),
    /// so we prefer the simulated model id the Simulator publishes in its
    /// environment, falling back to `uname` on device.
    static let identifier: String = {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
           !simulated.isEmpty {
            return simulated
        }
        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { raw -> String in
            let ptr = raw.baseAddress!.assumingMemoryBound(to: CChar.self)
            return String(cString: ptr)
        }
    }()

    /// Physical pixel density (pixels-per-inch) for the current device.
    static var ppi: CGFloat { ppi(for: identifier) }

    /// Whether we recognized the current device. `false` means `ppi` is the
    /// generic fallback — useful for surfacing a "scale may be approximate" note.
    static var isRecognized: Bool { ppiTable[identifier] != nil || identifier.hasPrefix("iPad") }

    /// Typical Retina phone density; used only for identifiers we don't recognize.
    static let fallbackPPI: CGFloat = 326

    static func ppi(for id: String) -> CGFloat {
        if let exact = ppiTable[id] { return exact }
        // iPads are uniform: 326 for mini, 264 for every other Retina iPad
        // (all iPadOS 16+ models are Retina).
        if id.hasPrefix("iPad") {
            return iPadMiniIDs.contains(id) ? 326 : 264
        }
        return fallbackPPI
    }

    /// iPad mini hardware ids (326 ppi). Every other iPad is 264 ppi.
    private static let iPadMiniIDs: Set<String> = [
        "iPad4,4", "iPad4,5", "iPad4,6",   // mini 2
        "iPad4,7", "iPad4,8", "iPad4,9",   // mini 3
        "iPad5,1", "iPad5,2",              // mini 4
        "iPad11,1", "iPad11,2",            // mini 5
        "iPad14,1", "iPad14,2",            // mini 6
        "iPad16,1", "iPad16,2",            // mini 7 (A17 Pro)
    ]

    /// iPhone hardware id → physical PPI. iPads are handled by `ppi(for:)` above.
    /// Values are Apple's published panel densities; note the downsampled
    /// "Plus"/"mini" panels (401 / 458 / 476) — `DisplayMetrics` divides by
    /// `nativeScale` so these resolve to the correct points-per-mm.
    private static let ppiTable: [String: CGFloat] = [
        // iPhone 8 / 8 Plus
        "iPhone10,1": 326, "iPhone10,4": 326,
        "iPhone10,2": 401, "iPhone10,5": 401,
        // iPhone X
        "iPhone10,3": 458, "iPhone10,6": 458,
        // iPhone XS / XS Max / XR
        "iPhone11,2": 458,
        "iPhone11,4": 458, "iPhone11,6": 458,
        "iPhone11,8": 326,
        // iPhone 11 / 11 Pro / 11 Pro Max
        "iPhone12,1": 326,
        "iPhone12,3": 458,
        "iPhone12,5": 458,
        // iPhone SE (2nd gen)
        "iPhone12,8": 326,
        // iPhone 12 mini / 12 / 12 Pro / 12 Pro Max
        "iPhone13,1": 476,
        "iPhone13,2": 460,
        "iPhone13,3": 460,
        "iPhone13,4": 458,
        // iPhone 13 Pro / 13 Pro Max / 13 mini / 13 / SE 3rd gen
        "iPhone14,2": 460,
        "iPhone14,3": 458,
        "iPhone14,4": 476,
        "iPhone14,5": 460,
        "iPhone14,6": 326,
        // iPhone 14 / 14 Plus / 14 Pro / 14 Pro Max
        "iPhone14,7": 460,
        "iPhone14,8": 458,
        "iPhone15,2": 460,
        "iPhone15,3": 460,
        // iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max
        "iPhone15,4": 460,
        "iPhone15,5": 460,
        "iPhone16,1": 460,
        "iPhone16,2": 460,
        // iPhone 16 Pro / 16 Pro Max / 16 / 16 Plus / 16e
        "iPhone17,1": 460,
        "iPhone17,2": 460,
        "iPhone17,3": 460,
        "iPhone17,4": 460,
        "iPhone17,5": 460,
    ]
}
