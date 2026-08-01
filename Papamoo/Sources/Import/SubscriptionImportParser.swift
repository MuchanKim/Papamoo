import Foundation

struct SubscriptionImportParser {
    func parse(lines: [String]) -> SubscriptionImportDraft {
        let normalizedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        var draft = SubscriptionImportDraft()
        let combinedText = normalizedLines.joined(separator: "\n")

        guard representsCompletedPayment(combinedText) else {
            return draft
        }

        if let preset = matchedPreset(in: combinedText) {
            draft.name = .preset(preset.name)
            draft.category = .preset(preset.category)
            draft.iconName = preset.iconName
        } else if let merchantName = merchantName(in: normalizedLines) {
            draft.name = .detected(merchantName, needsReview: true)
        }

        if let amountCandidate = amountCandidate(in: normalizedLines) {
            draft.amount = .detected(amountCandidate.amount)
            draft.currencyCode = .detected(amountCandidate.currencyCode)
        }

        if let date = paymentDate(in: normalizedLines) {
            draft.firstPaymentDate = .detected(date)
        }

        if let billingCycle = billingCycle(in: combinedText) {
            draft.billingCycle = .detected(billingCycle)
        }

        return draft
    }

    private func matchedPreset(in text: String) -> PresetService? {
        let normalized = normalizeServiceName(text)
        return PresetService.all.first { preset in
            normalized.contains(normalizeServiceName(preset.name))
        }
    }

    private func representsCompletedPayment(_ text: String) -> Bool {
        let rejectedTokens = [
            "결제 실패", "결제실패", "승인 거절", "승인거절", "환불", "결제 취소",
            "결제 예정", "결제됩니다", "갱신 예정",
            "payment failed", "payment declined", "transaction declined", "refund", "refunded",
            "payment canceled", "payment cancelled", "could not process", "couldn't process",
            "payment due", "upcoming payment", "will be charged", "renewal reminder", "renews",
        ]
        guard rejectedTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) == false else {
            return false
        }

        let completedTokens = [
            "결제 완료", "결제완료", "결제가 완료", "결제되었습니다", "결제 성공",
            "승인 완료", "승인완료",
            "payment complete", "payment completed", "payment confirmed", "payment successful",
            "payment succeeded", "successfully charged", "has been charged", "was charged",
            "payment received", "received your payment", "receipt for your payment",
        ]
        if completedTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            return true
        }

        let purchaseEvidence = ["purchase", "구매"]
        let receiptEvidence = ["receipt", "영수증", "transaction id", "charged to"]
        return purchaseEvidence.contains(where: { text.localizedCaseInsensitiveContains($0) })
            && receiptEvidence.contains(where: { text.localizedCaseInsensitiveContains($0) })
    }

    private func merchantName(in lines: [String]) -> String? {
        let labels = ["상점명", "가맹점", "서비스", "상품명", "merchant", "service"]

        for line in lines {
            let lowercased = line.lowercased()
            guard let label = labels.first(where: { lowercased.contains($0) }) else {
                continue
            }

            let value = line
                .replacingOccurrences(of: label, with: "", options: [.caseInsensitive])
                .trimmingCharacters(in: CharacterSet(charactersIn: " :·-"))

            if value.isEmpty == false, value.count <= 60 {
                return value
            }
        }

        return nil
    }

    private func amountCandidate(in lines: [String]) -> AmountCandidate? {
        let labels = ["결제 금액", "결제금액", "승인 금액", "승인금액", "총액", "합계", "amount", "total"]
        let labeled = uniqueAmountCandidates(
            in: lines.filter { line in
                labels.contains { line.localizedCaseInsensitiveContains($0) }
            }
        )

        if labeled.count == 1 {
            return labeled[0]
        }

        let all = uniqueAmountCandidates(in: lines)
        return all.count == 1 ? all[0] : nil
    }

    private func uniqueAmountCandidates(in lines: [String]) -> [AmountCandidate] {
        var seen = Set<String>()
        var candidates: [AmountCandidate] = []

        for line in lines {
            for candidate in amountCandidates(in: line) {
                let key = "\(candidate.currencyCode):\(candidate.amount)"
                if seen.insert(key).inserted {
                    candidates.append(candidate)
                }
            }
        }

        return candidates
    }

    private func amountCandidates(in line: String) -> [AmountCandidate] {
        var candidates: [AmountCandidate] = []
        let patterns: [(String, String)] = [
            (#"(?:₩|KRW)\s*([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)|([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)\s*(?:원|KRW)"#, "KRW"),
            (#"(?:\$|USD)\s*([0-9]+(?:\.[0-9]{1,2})?)|([0-9]+(?:\.[0-9]{1,2})?)\s*USD"#, "USD"),
            (#"(?:¥|JPY)\s*([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)|([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)\s*JPY"#, "JPY"),
        ]

        for (pattern, currencyCode) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(line.startIndex..., in: line)
            for match in regex.matches(in: line, range: range) {
                for captureIndex in 1..<match.numberOfRanges {
                    let captureRange = match.range(at: captureIndex)
                    guard captureRange.location != NSNotFound,
                          let swiftRange = Range(captureRange, in: line)
                    else {
                        continue
                    }

                    let number = line[swiftRange].replacingOccurrences(of: ",", with: "")
                    if let amount = Decimal(string: number), amount > 0 {
                        candidates.append(AmountCandidate(amount: amount, currencyCode: currencyCode))
                        break
                    }
                }
            }
        }

        return candidates
    }

    private func paymentDate(in lines: [String]) -> Date? {
        let labels = ["결제일", "승인일", "거래일", "거래일시", "payment date", "paid on", "date:"]
        let labeledDates = lines
            .filter { line in labels.contains { line.localizedCaseInsensitiveContains($0) } }
            .compactMap(date(in:))

        if let labeledDate = labeledDates.first {
            return labeledDate
        }

        let allDates = lines.compactMap(date(in:))
        let uniqueDates = Dictionary(grouping: allDates, by: { Calendar(identifier: .gregorian).startOfDay(for: $0) }).keys
        return uniqueDates.count == 1 ? uniqueDates.first : nil
    }

    private func date(in line: String) -> Date? {
        let numericPattern = #"(?<![0-9])(20[0-9]{2})[.\-/년]\s*([0-9]{1,2})[.\-/월]\s*([0-9]{1,2})(?:일)?"#
        if let regex = try? NSRegularExpression(pattern: numericPattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let year = integerCapture(1, match: match, in: line),
           let month = integerCapture(2, match: match, in: line),
           let day = integerCapture(3, match: match, in: line) {
            return calendarDate(year: year, month: month, day: day)
        }

        let dayFirstPattern = #"(?i)(?<![A-Za-z])([0-9]{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Sept|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(20[0-9]{2})(?![0-9])"#
        if let regex = try? NSRegularExpression(pattern: dayFirstPattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let day = integerCapture(1, match: match, in: line),
           let month = monthCapture(2, match: match, in: line),
           let year = integerCapture(3, match: match, in: line) {
            return calendarDate(year: year, month: month, day: day)
        }

        let monthFirstPattern = #"(?i)(?<![A-Za-z])(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Sept|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+([0-9]{1,2}),?\s+(20[0-9]{2})(?![0-9])"#
        guard let regex = try? NSRegularExpression(pattern: monthFirstPattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let month = monthCapture(1, match: match, in: line),
              let day = integerCapture(2, match: match, in: line),
              let year = integerCapture(3, match: match, in: line)
        else { return nil }

        return calendarDate(year: year, month: month, day: day)
    }

    private func calendarDate(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year == year && components.month == month && components.day == day ? date : nil
    }

    private func integerCapture(_ index: Int, match: NSTextCheckingResult, in text: String) -> Int? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else {
            return nil
        }
        return Int(text[swiftRange])
    }

    private func monthCapture(_ index: Int, match: NSTextCheckingResult, in text: String) -> Int? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else {
            return nil
        }
        let month = text[swiftRange].prefix(3).lowercased()
        return [
            "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
            "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
        ][month]
    }

    private func billingCycle(in text: String) -> BillingCycle? {
        let monthlyTokens = ["월간", "매월", "monthly", "month:", "/mo", "1개월"]
        if monthlyTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            return .monthly
        }

        let yearlyTokens = ["연간", "매년", "yearly", "annual", "/yr", "12개월"]
        if yearlyTokens.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            return .yearly
        }

        return nil
    }

    private func normalizeServiceName(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber || $0 == "+" }
    }
}

private struct AmountCandidate: Equatable {
    let amount: Decimal
    let currencyCode: String
}
