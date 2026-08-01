import SwiftUI

/// Navigation 상태만 보유. ViewModel 생성은 ViewModelFactory가 담당.
@Observable
final class AppCoordinator {
    enum Tab { case home, calendar, settings }

    struct ImageImportSelection: Identifiable {
        let id = UUID()
        let data: Data
    }

    var selectedTab: Tab = .home
    var isShowingAddSheet = false
    var isShowingCamera = false
    var imageImportSelection: ImageImportSelection?
    var selectedSubscription: Subscription?
    private var pendingImageData: Data?

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
