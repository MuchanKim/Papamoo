enum ShareImportPhase: Equatable {
    case loading
    case review
    case crop
    case preparingCrop
    case scanning
    case form(ShareImportFormMode)
    case failed(ShareFailureKind)
}

enum ShareImportFormMode: Equatable {
    case complete
    case partial
    case manual
}
