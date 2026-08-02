import SwiftUI

/// 화면 전환 상태와 의존성 생성을 분리하기 위해 객체 생성은 AppContainer에 맡긴다.
@Observable
final class AppCoordinator {

    enum Tab { case home, calendar, settings }

    struct ImageImportSelection: Identifiable {
        let id = UUID()
        let data: Data
    }

    // MARK: - Properties

    var selectedTab: Tab = .home
    var isShowingAddSheet = false
    var isShowingCamera = false
    var imageImportSelection: ImageImportSelection?
    var selectedSubscription: Subscription?
    private var pendingImageData: Data?

    // MARK: - Methods

    func showAddSubscription() {
        isShowingAddSheet = true
    }

    func dismissAddSubscription() {
        isShowingAddSheet = false
    }

    func showCamera() {
        pendingImageData = nil
        isShowingCamera = true
    }

    func selectImageForImport(_ data: Data) {
        pendingImageData = data
        isShowingCamera = false
    }

    func cancelCamera() {
        pendingImageData = nil
        isShowingCamera = false
    }

    func finishCameraPresentation() {
        guard let pendingImageData else { return }
        self.pendingImageData = nil
        imageImportSelection = ImageImportSelection(data: pendingImageData)
    }

    func dismissImageImport() {
        imageImportSelection = nil
    }

    func selectSubscription(_ subscription: Subscription) {
        selectedSubscription = subscription
    }
}
