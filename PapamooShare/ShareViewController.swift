import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionContext else { return }
        let viewModel = ShareImportViewModel(extensionContext: extensionContext)
        let hostingController = UIHostingController(rootView: ShareRootView(viewModel: viewModel))

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController

        preferredContentSize = CGSize(width: 0, height: 780)
    }
}
