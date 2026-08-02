@preconcurrency import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct CameraImagePicker: UIViewControllerRepresentable {

    // MARK: - Callbacks

    let onImagePicked: (Data) -> Void
    let onCancel: () -> Void

    // MARK: - Methods

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            return context.coordinator.makePhotoPicker()
        }

        return CameraViewController(
            onImagePicked: onImagePicked,
            onCancel: onCancel
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        // MARK: - Properties

        private let onImagePicked: (Data) -> Void
        private let onCancel: () -> Void
        private var didFinish = false

        init(onImagePicked: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        // MARK: - Methods

        func makePhotoPicker() -> PHPickerViewController {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = 1
            configuration.preferredAssetRepresentationMode = .current

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            return picker
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard didFinish == false else { return }
            guard let provider = results.first?.itemProvider else {
                didFinish = true
                onCancel()
                return
            }

            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                guard let self, let data else { return }
                Task { @MainActor in
                    guard self.didFinish == false else { return }
                    self.didFinish = true
                    self.onImagePicked(data)
                }
            }
        }
    }
}

private final class CameraPreviewView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class CameraViewController: UIViewController,
    AVCapturePhotoCaptureDelegate,
    PHPickerViewControllerDelegate
{
    private let onImagePicked: (Data) -> Void
    private let onCancel: () -> Void
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.moolab.Papamoo.CameraSession")
    private let photoOutput = AVCapturePhotoOutput()
    private let previewView = CameraPreviewView()
    private var videoInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false
    private var didFinish = false
    private var currentPosition: AVCaptureDevice.Position = .back
    private weak var shutterButton: UIButton?

    init(
        onImagePicked: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onImagePicked = onImagePicked
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePreview()
        configureControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestAccessAndStartSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateVideoRotation()
    }

    private func configurePreview() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.previewLayer.session = captureSession
        previewView.previewLayer.videoGravity = .resizeAspectFill
        view.addSubview(previewView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureControls() {
        let closeButton = makeControlButton(
            systemName: "xmark",
            pointSize: 18,
            showsBackground: true,
            accessibilityLabel: String(localized: "Close camera")
        )
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)

        let galleryButton = makeControlButton(
            systemName: "photo.on.rectangle",
            pointSize: 22,
            showsBackground: false,
            accessibilityLabel: String(localized: "Choose from Photos")
        )
        galleryButton.addTarget(self, action: #selector(showPhotoLibrary), for: .touchUpInside)

        let shutterButton = makeShutterButton()
        shutterButton.addTarget(self, action: #selector(takePicture), for: .touchUpInside)
        self.shutterButton = shutterButton

        let switchButton = makeControlButton(
            systemName: "arrow.triangle.2.circlepath.camera",
            pointSize: 24,
            showsBackground: false,
            accessibilityLabel: String(localized: "Switch camera")
        )
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        switchButton.isEnabled = cameraDevice(position: .front) != nil

        [closeButton, galleryButton, shutterButton, switchButton].forEach(view.addSubview)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            shutterButton.widthAnchor.constraint(equalToConstant: 72),
            shutterButton.heightAnchor.constraint(equalToConstant: 72),

            galleryButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            galleryButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            galleryButton.widthAnchor.constraint(equalToConstant: 48),
            galleryButton.heightAnchor.constraint(equalToConstant: 48),

            switchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            switchButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            switchButton.widthAnchor.constraint(equalToConstant: 48),
            switchButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func requestAccessAndStartSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                Task { @MainActor in
                    guard let self else { return }
                    if isGranted {
                        self.startSession()
                    } else {
                        self.finishCancellation()
                    }
                }
            }
        default:
            finishCancellation()
        }
    }

    private func startSession() {
        guard configureSessionIfNeeded() else {
            finishCancellation()
            return
        }

        let captureSession = captureSession
        sessionQueue.async {
            guard captureSession.isRunning == false else { return }
            captureSession.startRunning()
        }
    }

    private func stopSession() {
        let captureSession = captureSession
        sessionQueue.async {
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    private func configureSessionIfNeeded() -> Bool {
        guard isSessionConfigured == false else { return true }
        guard let device = cameraDevice(position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input),
              captureSession.canAddOutput(photoOutput)
        else {
            return false
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(input)
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()

        videoInput = input
        isSessionConfigured = true
        updateVideoRotation()
        return true
    }

    private func cameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    private func updateVideoRotation() {
        let rotationAngle: CGFloat = 90
        if let previewConnection = previewView.previewLayer.connection,
           previewConnection.isVideoRotationAngleSupported(rotationAngle) {
            previewConnection.videoRotationAngle = rotationAngle
        }
        if let photoConnection = photoOutput.connection(with: .video),
           photoConnection.isVideoRotationAngleSupported(rotationAngle) {
            photoConnection.videoRotationAngle = rotationAngle
        }
    }

    private func makeControlButton(
        systemName: String,
        pointSize: CGFloat,
        showsBackground: Bool,
        accessibilityLabel: String
    ) -> UIButton {
        var configuration = showsBackground
            ? UIButton.Configuration.gray()
            : UIButton.Configuration.plain()
        configuration.image = UIImage(
            systemName: systemName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        )
        configuration.baseForegroundColor = .white
        if showsBackground {
            configuration.baseBackgroundColor = UIColor.black.withAlphaComponent(0.46)
            configuration.cornerStyle = .capsule
        }

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    private func makeShutterButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = String(localized: "Take photo")
        button.layer.cornerRadius = 36
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor

        let innerCircle = UIView()
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 29
        innerCircle.isUserInteractionEnabled = false
        button.addSubview(innerCircle)

        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 58),
            innerCircle.heightAnchor.constraint(equalToConstant: 58),
        ])
        return button
    }

    @objc
    private func closeCamera() {
        finishCancellation()
    }

    @objc
    private func showPhotoLibrary() {
        guard presentedViewController == nil else { return }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc
    private func takePicture() {
        guard didFinish == false, captureSession.isRunning else { return }
        shutterButton?.isEnabled = false
        updateVideoRotation()
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    @objc
    private func switchCamera() {
        guard captureSession.isRunning else { return }
        let nextPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        guard let nextDevice = cameraDevice(position: nextPosition),
              let nextInput = try? AVCaptureDeviceInput(device: nextDevice),
              let videoInput
        else {
            return
        }

        captureSession.beginConfiguration()
        captureSession.removeInput(videoInput)
        if captureSession.canAddInput(nextInput) {
            captureSession.addInput(nextInput)
            self.videoInput = nextInput
            currentPosition = nextPosition
        } else {
            captureSession.addInput(videoInput)
        }
        captureSession.commitConfiguration()

        updateVideoRotation()
    }

    private func finishCancellation() {
        guard didFinish == false else { return }
        didFinish = true
        onCancel()
    }

    private func finishImageSelection(_ data: Data) {
        guard didFinish == false else { return }
        didFinish = true
        onImagePicked(data)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let data else {
                self.shutterButton?.isEnabled = true
                return
            }
            self.finishImageSelection(data)
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard didFinish == false else { return }
        guard let provider = results.first?.itemProvider else {
            picker.dismiss(animated: true)
            return
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let self else { return }
            Task { @MainActor in
                guard let data else {
                    picker.dismiss(animated: true)
                    return
                }
                picker.dismiss(animated: false) { [weak self] in
                    self?.finishImageSelection(data)
                }
            }
        }
    }
}
