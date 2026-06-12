import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    /// App Store numeric ID for the iOS listing, used to deep-link to the review
    /// page. Empty until the app is on the Store — the Rate button stays hidden
    /// while it's empty. TODO: fill in once the iOS app has a listing.
    private static let appStoreID = ""
    /// Address feedback is sent to.
    private static let feedbackEmail = "matranc03+ruler@gmail.com"

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Ruler"
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            icon

            Text(appName)
                .font(.title2.weight(.semibold))

            Text(version)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("Made in 🇨🇦 with ❤️")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if !Self.appStoreID.isEmpty {
                    Button("Rate App", action: rateApp)
                }
                Button("Send Feedback", action: sendFeedback)
            }
            .buttonStyle(.bordered)
            .padding(.top, 6)

            Button("Done") { dismiss() }
                .padding(.top, 2)
        }
        .padding(28)
        .presentationDetents([.medium])
    }

    private var icon: some View {
        Group {
            if let ui = Self.appIconImage() {
                Image(uiImage: ui).resizable()
            } else {
                Image(systemName: "ruler")
                    .resizable()
                    .scaledToFit()
                    .padding(16)
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Best-effort load of the bundle's app icon for display; falls back to an
    /// SF Symbol via the `icon` view when unavailable (e.g. in some simulators).
    private static func appIconImage() -> UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let last = files.last else { return nil }
        return UIImage(named: last)
    }

    private func rateApp() {
        guard !Self.appStoreID.isEmpty,
              let url = URL(string: "itms-apps://apps.apple.com/app/id\(Self.appStoreID)?action=write-review")
        else { return }
        UIApplication.shared.open(url)
    }

    private func sendFeedback() {
        let subject = "\(appName) Feedback"
        let allowed = CharacterSet.urlQueryAllowed
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? subject
        if let url = URL(string: "mailto:\(Self.feedbackEmail)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url)
        }
    }
}
