import Foundation

enum PaymentEmailMappingResult: Equatable {
    case completed(SubscriptionImportDraft)
    case rejected(PaymentDocumentType)
    case insufficient
}

struct PaymentEmailExtractionMapper {

    // MARK: - Methods

    func map(
        _ extraction: PaymentEmailExtractionCandidate,
        ocrLines: [String]
    ) -> PaymentEmailMappingResult {
        guard extraction.documentType == .completedPayment else {
            return .rejected(extraction.documentType)
        }

        let ocrText = ocrLines.joined(separator: "\n")
        var draft = SubscriptionImportDraft()

        if let name = validatedServiceName(from: extraction, ocrText: ocrText) {
            if let preset = matchedPreset(for: name) {
                draft.name = .preset(preset.name)
                draft.category = .preset(preset.category)
                draft.iconName = preset.iconName
            } else {
                draft.name = .detected(name, needsReview: true)
            }
        }

        if let amount = validatedAmount(from: extraction, ocrText: ocrText) {
            draft.amount = .detected(amount)
        }

        if let currency = validatedCurrency(from: extraction, ocrText: ocrText) {
            draft.currencyCode = .detected(currency.code, needsReview: currency.needsReview)
        }

        if let paymentDate = validatedPaymentDate(from: extraction, ocrText: ocrText) {
            draft.firstPaymentDate = .detected(paymentDate)
        }

        if let billingCycle = validatedBillingCycle(from: extraction, ocrText: ocrText) {
            draft.billingCycle = .detected(billingCycle)
        }

        return draft.hasDetectedValue ? .completed(draft) : .insufficient
    }

    // MARK: - Private Methods

    private func validatedServiceName(
        from extraction: PaymentEmailExtractionCandidate,
        ocrText: String
    ) -> String? {
        guard let value = extraction.serviceName?.trimmingCharacters(in: .whitespacesAndNewlines),
              value.isEmpty == false,
              value.count <= 60,
              let evidence = extraction.serviceEvidence,
              evidenceIsPresent(evidence, in: ocrText),
              normalize(evidence).contains(normalize(value))
        else {
            return nil
        }
        return value
    }

    private func validatedAmount(
        from extraction: PaymentEmailExtractionCandidate,
        ocrText: String
    ) -> Decimal? {
        guard let amountText = extraction.amount,
              let evidence = extraction.amountEvidence,
              evidenceIsPresent(evidence, in: ocrText),
              let amount = decimal(from: amountText),
              amount > 0,
              numericValues(in: evidence).contains(amount)
        else {
            return nil
        }
        return amount
    }

    private func validatedCurrency(
        from extraction: PaymentEmailExtractionCandidate,
        ocrText: String
    ) -> ValidatedCurrency? {
        guard let evidence = extraction.amountEvidence,
              evidenceIsPresent(evidence, in: ocrText),
              let code = extraction.currencyCode?.uppercased()
        else {
            return nil
        }

        let uppercasedEvidence = evidence.uppercased()
        return switch code {
        case "KRW" where uppercasedEvidence.contains("KRW") || evidence.contains("원"):
            ValidatedCurrency(code: code, needsReview: false)
        case "KRW" where evidence.contains("₩"):
            ValidatedCurrency(code: code, needsReview: false)
        case "USD" where uppercasedEvidence.contains("USD"):
            ValidatedCurrency(code: code, needsReview: false)
        case "USD" where evidence.contains("$"):
            ValidatedCurrency(code: code, needsReview: true)
        case "JPY" where uppercasedEvidence.contains("JPY") || evidence.contains("円"):
            ValidatedCurrency(code: code, needsReview: false)
        case "JPY" where evidence.contains("¥"):
            ValidatedCurrency(code: code, needsReview: true)
        default:
            nil
        }
    }

    private func validatedPaymentDate(
        from extraction: PaymentEmailExtractionCandidate,
        ocrText: String
    ) -> Date? {
        guard let value = extraction.paymentDate,
              let evidence = extraction.paymentDateEvidence,
              evidenceIsPresent(evidence, in: ocrText),
              let date = isoDate(from: value),
              dateEvidence(evidence, matches: date)
        else {
            return nil
        }
        return date
    }

    private func validatedBillingCycle(
        from extraction: PaymentEmailExtractionCandidate,
        ocrText: String
    ) -> BillingCycle? {
        guard let extractedCycle = extraction.billingCycle,
              let evidence = extraction.billingCycleEvidence,
              evidenceIsPresent(evidence, in: ocrText)
        else {
            return nil
        }

        let detectedCycle = billingCycle(in: evidence)
        return switch (extractedCycle, detectedCycle) {
        case (.monthly, .monthly): .monthly
        case (.yearly, .yearly): .yearly
        default: nil
        }
    }

    private func evidenceIsPresent(_ evidence: String, in ocrText: String) -> Bool {
        let normalizedEvidence = normalize(evidence)
        return normalizedEvidence.isEmpty == false && normalize(ocrText).contains(normalizedEvidence)
    }

    private func decimal(from value: String) -> Decimal? {
        let normalized = value
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func numericValues(in text: String) -> [Decimal] {
        let pattern = #"(?<![0-9])([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)(?![0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)

        return regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
            return decimal(from: String(text[swiftRange]))
        }
    }

    private func isoDate(from value: String) -> Date? {
        let pattern = #"^(20[0-9]{2})-([0-9]{2})-([0-9]{2})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let year = integerCapture(1, match: match, in: value),
              let month = integerCapture(2, match: match, in: value),
              let day = integerCapture(3, match: match, in: value)
        else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year == year && components.month == month && components.day == day ? date : nil
    }

    private func dateEvidence(_ evidence: String, matches date: Date) -> Bool {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              containsNumber(year, in: evidence),
              containsNumber(day, in: evidence)
        else {
            return false
        }

        let monthNames = [
            1: ["january", "jan"], 2: ["february", "feb"], 3: ["march", "mar"],
            4: ["april", "apr"], 5: ["may"], 6: ["june", "jun"],
            7: ["july", "jul"], 8: ["august", "aug"], 9: ["september", "sep", "sept"],
            10: ["october", "oct"], 11: ["november", "nov"], 12: ["december", "dec"],
        ]
        let lowercasedEvidence = evidence.lowercased()
        return containsNumber(month, in: evidence)
            || monthNames[month, default: []].contains { lowercasedEvidence.contains($0) }
    }

    private func containsNumber(_ value: Int, in text: String) -> Bool {
        let pattern = #"(?<![0-9])0?"# + String(value) + #"(?![0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private func billingCycle(in text: String) -> BillingCycle? {
        let monthlyTokens = ["월간", "매월", "월 구독", "monthly", "month:", "per month", "every month", "/mo", "1개월"]
        if monthlyTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            return .monthly
        }

        let yearlyTokens = ["연간", "매년", "년 구독", "yearly", "annual", "per year", "every year", "/yr", "12개월"]
        if yearlyTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            return .yearly
        }
        return nil
    }

    private func integerCapture(_ index: Int, match: NSTextCheckingResult, in text: String) -> Int? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else {
            return nil
        }
        return Int(text[swiftRange])
    }

    private func matchedPreset(for serviceName: String) -> PresetService? {
        let normalizedName = normalize(serviceName)
        return PresetService.all.first { preset in
            let normalizedPreset = normalize(preset.name)
            return normalizedName.contains(normalizedPreset) || normalizedPreset.contains(normalizedName)
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber || $0 == "+" }
    }
}

private struct ValidatedCurrency {
    let code: String
    let needsReview: Bool
}
