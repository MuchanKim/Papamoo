import Foundation
import Testing
@testable import Papamoo

@MainActor
struct AppCoordinatorTests {
    @Test("카메라에서 고른 이미지는 카메라 종료 후 분석 흐름으로 전달한다")
    func forwardsSelectedCameraImageToImportFlow() throws {
        let coordinator = AppCoordinator()
        let imageData = Data("payment-image".utf8)

        coordinator.showCamera()
        coordinator.selectImageForImport(imageData)

        #expect(coordinator.isShowingCamera == false)
        #expect(coordinator.imageImportSelection == nil)

        coordinator.finishCameraPresentation()

        let selection = try #require(coordinator.imageImportSelection)
        #expect(selection.data == imageData)
    }

    @Test("카메라 취소 시 분석 흐름을 열지 않는다")
    func cancelingCameraDoesNotOpenImportFlow() {
        let coordinator = AppCoordinator()

        coordinator.showCamera()
        coordinator.cancelCamera()
        coordinator.finishCameraPresentation()

        #expect(coordinator.isShowingCamera == false)
        #expect(coordinator.imageImportSelection == nil)
    }
}
