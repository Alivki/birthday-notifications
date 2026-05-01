import SwiftUI
import UIKit

// MARK: - Camera picker

/// Wraps `UIImagePickerController` for camera capture. Library picking goes
/// through the standard `.photosPicker` modifier, which doesn't support the
/// camera source type.
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = UIImagePickerController.isCameraDeviceAvailable(.rear) ? .rear : .front
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Cropper view

struct ImageCropperView: View {
    let image: UIImage
    var onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var controller = CropperController()

    private let cropDiameter: CGFloat = 300

    var body: some View {
        // The visual cropper layer (ScrollView, dim, ring) lives inside the
        // safe area so they all share the same coordinate system and the
        // ring on screen lines up with the ScrollView's bounds center. The
        // controls live alongside them — they sit below the dynamic island
        // automatically. Only the black background extends to the edges.
        ZStack {
            Color.black.ignoresSafeArea()

            ZoomableImageScrollView(
                image: image,
                cropDiameter: cropDiameter,
                controller: controller
            )

            Rectangle()
                .fill(.black.opacity(0.55))
                .mask(
                    Rectangle()
                        .overlay(
                            Circle()
                                .frame(width: cropDiameter, height: cropDiameter)
                                .blendMode(.destinationOut)
                        )
                )
                .allowsHitTesting(false)

            Circle()
                .stroke(.white.opacity(0.85), lineWidth: 2)
                .frame(width: cropDiameter, height: cropDiameter)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("Drag and pinch")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button {
                        controller.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                Button {
                    if let cropped = controller.crop() {
                        onCrop(cropped)
                    }
                    dismiss()
                } label: {
                    Text("Use Photo")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.brand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Controller

@Observable
final class CropperController {
    weak var scrollView: UIScrollView?
    weak var imageView: UIImageView?
    var coordinator: ZoomableImageScrollView.Coordinator?

    func reset() {
        coordinator?.fitImage()
    }

    /// Crops the source image to whatever is currently inside the crop circle.
    /// Uses `UIImage.draw(in:)` so EXIF orientation is applied correctly —
    /// `cgImage.cropping(to:)` would crop the raw unoriented buffer and pick
    /// the wrong region for portrait-camera photos.
    func crop() -> UIImage? {
        guard let scrollView,
              let imageView,
              let coordinator,
              let image = imageView.image else { return nil }

        let cropDim = coordinator.cropDiameter
        let bounds = scrollView.bounds
        let zoom = scrollView.zoomScale

        // Crop top-left in scroll-view content coords. The image view sits at
        // content (0, 0) and the crop circle is centered in the visible
        // viewport. contentInset doesn't shift content origin — only the
        // scrollable range — so we don't subtract it.
        let cropInContent = CGRect(
            x: scrollView.contentOffset.x + (bounds.width - cropDim) / 2,
            y: scrollView.contentOffset.y + (bounds.height - cropDim) / 2,
            width: cropDim,
            height: cropDim
        )

        // Convert from post-zoom content coords to image display-points.
        // imageView.bounds.size is the layout size set at zoom = 1.
        let displayedWidth = imageView.bounds.width
        guard displayedWidth > 0, zoom > 0 else { return nil }
        let pointsPerContentPoint = image.size.width / (displayedWidth * zoom)

        let sourceRect = CGRect(
            x: cropInContent.origin.x * pointsPerContentPoint,
            y: cropInContent.origin.y * pointsPerContentPoint,
            width: cropInContent.width * pointsPerContentPoint,
            height: cropInContent.height * pointsPerContentPoint
        )

        // Render to a circular bitmap. We map the source region to a unit
        // output rect by drawing the *whole* image at a scaled, offset rect,
        // then clipping to the circle. Because we use UIImage.draw, the
        // image's EXIF orientation is honored and the visible region matches
        // what was inside the ring.
        let outSize: CGFloat = 480
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outSize, height: outSize), format: format)
        return renderer.image { ctx in
            let outRect = CGRect(x: 0, y: 0, width: outSize, height: outSize)
            ctx.cgContext.addEllipse(in: outRect)
            ctx.cgContext.clip()

            let scaleFactor = outSize / sourceRect.width
            let drawRect = CGRect(
                x: -sourceRect.origin.x * scaleFactor,
                y: -sourceRect.origin.y * scaleFactor,
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )
            image.draw(in: drawRect)
        }
    }
}

// MARK: - Zoomable scroll view

struct ZoomableImageScrollView: UIViewRepresentable {
    let image: UIImage
    let cropDiameter: CGFloat
    let controller: CropperController

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        context.coordinator.scrollView = scrollView
        context.coordinator.imageView = imageView
        context.coordinator.image = image
        context.coordinator.cropDiameter = cropDiameter

        controller.scrollView = scrollView
        controller.imageView = imageView
        controller.coordinator = context.coordinator

        DispatchQueue.main.async {
            context.coordinator.fitImage()
        }

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?
        var image: UIImage?
        var cropDiameter: CGFloat = 300

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) { updateInsets() }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.05 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let target = min(scrollView.maximumZoomScale, scrollView.minimumZoomScale * 2.5)
                let location = gr.location(in: imageView)
                let size = CGSize(
                    width: scrollView.bounds.width / target,
                    height: scrollView.bounds.height / target
                )
                let rect = CGRect(
                    x: location.x - size.width / 2,
                    y: location.y - size.height / 2,
                    width: size.width,
                    height: size.height
                )
                scrollView.zoom(to: rect, animated: true)
            }
        }

        /// Sizes the imageView so the image fits the screen while always being
        /// at least as large as the crop circle.
        func fitImage() {
            guard let scrollView, let imageView, let image else { return }
            let bounds = scrollView.bounds
            guard bounds.width > 0, bounds.height > 0 else {
                DispatchQueue.main.async { [weak self] in self?.fitImage() }
                return
            }

            let imgSize = image.size
            let fitToBounds = min(bounds.width / imgSize.width, bounds.height / imgSize.height)
            let fitToCrop = max(cropDiameter / imgSize.width, cropDiameter / imgSize.height)
            let baseScale = max(fitToBounds, fitToCrop)

            let displaySize = CGSize(
                width: imgSize.width * baseScale,
                height: imgSize.height * baseScale
            )

            imageView.bounds = CGRect(origin: .zero, size: displaySize)
            imageView.frame = CGRect(origin: .zero, size: displaySize)
            scrollView.contentSize = displaySize
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 6
            scrollView.zoomScale = 1
            scrollView.contentOffset = CGPoint(
                x: (displaySize.width - bounds.width) / 2,
                y: (displaySize.height - bounds.height) / 2
            )
            updateInsets()
        }

        /// contentInset is set so the user can scroll *any* edge of the image
        /// up to the edge of the crop circle. Standard cropper trick: pad each
        /// side by (boundsSize - cropDiameter) / 2, with extra centering space
        /// added when the image happens to be smaller than the viewport.
        private func updateInsets() {
            guard let scrollView, let imageView else { return }
            let bounds = scrollView.bounds.size
            let content = imageView.frame.size

            let edgeH = max(0, (bounds.width - cropDiameter) / 2)
            let edgeV = max(0, (bounds.height - cropDiameter) / 2)
            let centerH = max(0, (bounds.width - content.width) / 2)
            let centerV = max(0, (bounds.height - content.height) / 2)

            scrollView.contentInset = UIEdgeInsets(
                top: max(edgeV, centerV),
                left: max(edgeH, centerH),
                bottom: max(edgeV, centerV),
                right: max(edgeH, centerH)
            )
        }
    }
}
