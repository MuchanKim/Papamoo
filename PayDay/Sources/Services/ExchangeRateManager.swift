import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.moolab.PayDay") ?? .standard
}

@Observable
final class ExchangeRateManager {
    static let shared = ExchangeRateManager()

    /// 기본 환율: 1 USD = N KRW, 1 USD = N JPY
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

    /// 1 USD = N 외화 (USD 기준).
    var ratesFromUSD: [String: Double] {
        didSet {
            if let data = try? JSONEncoder().encode(ratesFromUSD) {
                UserDefaults.appGroup.set(data, forKey: ratesKey)
            }
        }
    }

    var lastUpdated: Date? {
        didSet { UserDefaults.appGroup.set(lastUpdated, forKey: lastUpdatedKey) }
    }

    var baseCurrency: String {
        didSet { UserDefaults.appGroup.set(baseCurrency, forKey: baseCurrencyKey) }
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

    func currencySymbol(for code: String) -> String {
        switch code {
        case "KRW": "₩"
        case "USD": "$"
        case "JPY": "¥"
        default: code
        }
    }

    // MARK: - Display

    /// 1 USD = ₩N
    var krwPerUSD: Int {
        Int(ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!)
    }

    /// 1 USD = ¥N
    var jpyPerUSD: Int {
        Int(ratesFromUSD["JPY"] ?? Self.defaultRatesFromUSD["JPY"]!)
    }

    // MARK: - Conversion

    /// 임의의 통화 금액을 KRW로 환산.
    private func toKRW(amount: Decimal, from code: String) -> Decimal {
        switch code {
        case "KRW": return amount
        case "USD":
            let rate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
            return amount * Decimal(rate)
        case "JPY":
            // 1 USD = krwRate KRW, 1 USD = jpyRate JPY
            // → 1 JPY = krwRate / jpyRate KRW
            let krwRate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
            let jpyRate = ratesFromUSD["JPY"] ?? Self.defaultRatesFromUSD["JPY"]!
            return amount * Decimal(krwRate / jpyRate)
        default: return amount
        }
    }

    /// 임의의 통화 금액을 기준 통화로 환산.
    func convertToBase(amount: Decimal, from currencyCode: String) -> Decimal {
        guard currencyCode != baseCurrency else { return amount }
        // 일단 KRW로 환산
        let krwAmount = toKRW(amount: amount, from: currencyCode)
        // 기준 통화가 KRW면 그대로
        guard baseCurrency != "KRW" else { return krwAmount }
        // KRW → 기준 통화
        let baseRate = ratesFromUSD[baseCurrency] ?? 1
        let krwRate = ratesFromUSD["KRW"] ?? Self.defaultRatesFromUSD["KRW"]!
        return krwAmount * Decimal(baseRate / krwRate)
    }

    /// 환율 수동 업데이트.
    func updateRate(for currencyCode: String, rate: Double) {
        var current = ratesFromUSD
        current[currencyCode] = rate
        ratesFromUSD = current
        lastUpdated = .now
    }

    // MARK: - API

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
