import Foundation

// MARK: - Extensions

extension LocalizedStringResource {
    func localized(for locale: Locale) -> LocalizedStringResource {
        var resource = self
        resource.locale = locale
        return resource
    }
}
