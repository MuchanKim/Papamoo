import Foundation

// MARK: - Extensions

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
}

@Observable
final class ExchangeRateManager {

    // MARK: - Properties

    static let shared = ExchangeRateManager()

    private static let defaultRatesFromUSD: [String: Double] = [
        "KRW": 1380,
        "JPY": 150,
    ]

    private let ratesKey = "exchangeRatesFromUSD"
    private let lastUpdatedKey = "exchangeRatesLastUpdated"
    private let baseCurrencyKey = "baseCurrency"

    var isLoading = false
    var lastError: String?
    var isUsingFallbackRates = false

    var ratesFromUSD: [String: Double] {
        didSet {
            if let data = try? JSONEncoder().encode(ratesFromUSD) {
                UserDefaults.appGroup.set(data, forKey: ratesKey)
            }
            NotificationCenter.default.post(name: .exchangeRateDidChange, object: nil)
        }
    }

    var lastUpdated: Date? {
        didSet { UserDefaults.appGroup.set(lastUpdated, forKey: lastUpdatedKey) }
    }

    var baseCurrency: String {
        didSet {
            UserDefaults.appGroup.set(baseCurrency, forKey: baseCurrencyKey)
            NotificationCenter.default.post(name: .exchangeRateDidChange, object: nil)
        }
    }

    var supportedCurrencies: [String] { ["KRW", "USD", "JPY"] }

    private init() {
        let defaults = UserDefaults.appGroup

        if let data = defaults.data(forKey: ratesKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.ratesFromUSD = decoded
        } else {
            self.ratesFromUSD = Self.defaultRatesFromUSD
        }

        self.lastUpdated = defaults.object(forKey: lastUpdatedKey) as? Date
        self.baseCurrency = defaults.string(forKey: baseCurrencyKey) ?? "KRW"
    }

    var krwPerUSD: Int {
        Int(ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!)
    }

    var jpyPerUSD: Int {
        Int(ratesFromUSD["JPY"] ?? Self.defaultRatesFromUSD["JPY"]!)
    }

    // MARK: - Methods

    func currencySymbol(for code: String) -> String {
        switch code {
        case "KRW": "₩"
        case "USD": "$"
        case "JPY": "¥"
        default: code
        }
    }

    func convertToBase(amount: Decimal, from currencyCode: String) -> Decimal {
        guard currencyCode != baseCurrency else { return amount }
        let krwAmount = toKRW(amount: amount, from: currencyCode)
        guard baseCurrency != "KRW" else { return krwAmount }
        let baseRate = ratesFromUSD[baseCurrency] ?? 1
        let krwRate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
        return krwAmount * Decimal(baseRate / krwRate)
    }

    func updateRate(for currencyCode: String, rate: Double) {
        var current = ratesFromUSD
        current[currencyCode] = rate
        ratesFromUSD = current
        lastUpdated = .now
    }

    func fetchIfStale(maxAge: TimeInterval = 24 * 60 * 60) async {
        if let last = lastUpdated, Date.now.timeIntervalSince(last) < maxAge {
            return
        }
        await fetchLatestRates()
    }

    func fetchLatestRates() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(APIResponse.self, from: data)

            guard response.result == "success",
                  let krw = response.rates["KRW"],
                  let jpy = response.rates["JPY"],
                  krw > 0, jpy > 0
            else {
                applyFallback()
                return
            }

            ratesFromUSD = ["KRW": krw, "JPY": jpy]
            lastUpdated = .now
            isUsingFallbackRates = false
        } catch {
            applyFallback()
        }
    }

    // MARK: - Private Methods

    private func toKRW(amount: Decimal, from code: String) -> Decimal {
        switch code {
        case "KRW": return amount
        case "USD":
            let rate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
            return amount * Decimal(rate)
        case "JPY":
            // USD 기준 두 환율을 나누어 JPY의 KRW 교차 환율을 계산한다.
            let krwRate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
            let jpyRate = ratesFromUSD["JPY"] ?? Self.defaultRatesFromUSD["JPY"]!
            return amount * Decimal(krwRate / jpyRate)
        default: return amount
        }
    }

    private func applyFallback() {
        if ratesFromUSD["KRW"] == nil || ratesFromUSD["KRW"] == 0 {
            ratesFromUSD = Self.defaultRatesFromUSD
        }
        isUsingFallbackRates = true
        lastError = String(localized: "Network error. Using temporary rates.")
    }
}

private struct APIResponse: Decodable {
    let result: String
    let rates: [String: Double]
}
