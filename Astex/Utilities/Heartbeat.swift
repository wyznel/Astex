import Foundation
import SwiftUI

/// Anonymous, privacy-preserving usage ping for Astex.
/// Sends one POST per launch with two rotating random UUIDs:
/// a daily ID (for DAU) and a monthly ID (for MAU). No persistent
/// identifier, no personal data, fire-and-forget.
enum Heartbeat {
    static let endpoint = URL(string: "https://stats.astex.app/ping")!

    private enum Keys {
        static let dailyID = "heartbeat.dailyID"
        static let dailyIDPeriod = "heartbeat.dailyID.period"
        static let monthlyID = "heartbeat.monthlyID"
        static let monthlyIDPeriod = "heartbeat.monthlyID.period"
        static let optedOut = "heartbeat.optedOut"
    }

    /// Calls once at launch
    static func send() {
        guard !UserDefaults.standard.bool(forKey: Keys.optedOut) else { return }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "d": rotatingID(idKey: Keys.dailyID, periodKey: Keys.dailyIDPeriod, period: currentPeriod(daily: true)),
            "m": rotatingID(idKey: Keys.monthlyID, periodKey: Keys.monthlyIDPeriod, period: currentPeriod(daily: false)),
            "v": version,
        ])

        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - Rotating anonymous IDs (UTC, so client and server agree on boundaries)

    private static func currentPeriod(daily: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = daily ? "yyyy-MM-dd" : "yyyy-MM"
        return formatter.string(from: Date())
    }

    private static func rotatingID(idKey: String, periodKey: String, period: String) -> String {
        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: idKey),
           defaults.string(forKey: periodKey) == period {
            return id
        }
        let id = UUID().uuidString
        defaults.set(id, forKey: idKey)
        defaults.set(period, forKey: periodKey)
        return id
    }
}

/// Settings toggle
struct HeartbeatSettingsToggle: View {
    @AppStorage("heartbeat.optedOut") private var optedOut = false

    var body: some View {
        Toggle("Share anonymous usage count", isOn: Binding(
            get: { !optedOut },
            set: { optedOut = !$0 }
        ))
    }
}
