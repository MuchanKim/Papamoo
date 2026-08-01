import Foundation

enum ShareImportError: LocalizedError {
    case missingInput
    case unsupportedImage
    case imageDecodeFailed
    case recognitionFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .missingInput:
            "공유된 이미지를 찾을 수 없습니다."
        case .unsupportedImage:
            "지원하지 않는 이미지 형식입니다."
        case .imageDecodeFailed:
            "이미지를 불러오지 못했습니다."
        case .recognitionFailed:
            "결제 정보를 인식하지 못했습니다."
        case .userCancelled:
            "사용자가 가져오기를 취소했습니다."
        }
    }
}
