import SwiftUI
import UIKit

struct ImageCropperView: View {
    let image: UIImage
    var onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero

    private let cropDiameter: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(drag.simultaneously(with: magnify))

                // Dim overlay with circle cutout
                Rectangle()
                    .fill(.black.opacity(0.55))
                    .mask {
                        Rectangle()
                            .overlay {
                                Circle()
                                    .frame(width: cropDiameter, height: cropDiameter)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .allowsHitTesting(false)

                Circle()
                    .stroke(.white.opacity(0.7), lineWidth: 1.5)
                    .frame(width: cropDiameter, height: cropDiameter)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding()

                    Spacer()

                    Button {
                        cropAndDismiss(screenSize: geo.size)
                    } label: {
                        Text("Use Photo")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear { viewSize = geo.size }
            .onChange(of: geo.size) { _, newSize in viewSize = newSize }
        }
        .ignoresSafeArea()
    }

    // MARK: - Gestures

    private var drag: some Gesture {
        DragGesture()
            .onChanged { v in
                offset = CGSize(
                    width: lastOffset.width + v.translation.width,
                    height: lastOffset.height + v.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private var magnify: some Gesture {
        MagnificationGesture()
            .onChanged { v in scale = max(lastScale * v, 0.5) }
            .onEnded { _ in lastScale = scale }
    }

    // MARK: - Crop

    private func cropAndDismiss(screenSize: CGSize) {
        let sw = screenSize.width
        let sh = screenSize.height
        let imgSize = image.size

        let fitScale = min(sw / imgSize.width, sh / imgSize.height)
        let fittedW = imgSize.width * fitScale
        let fittedH = imgSize.height * fitScale

        let cropOriginX = (sw - cropDiameter) / 2
        let cropOriginY = (sh - cropDiameter) / 2
        let imgOriginX = (sw - fittedW * scale) / 2 + offset.width
        let imgOriginY = (sh - fittedH * scale) / 2 + offset.height

        let relX = (cropOriginX - imgOriginX) / (fittedW * scale)
        let relY = (cropOriginY - imgOriginY) / (fittedH * scale)
        let relW = cropDiameter / (fittedW * scale)
        let relH = cropDiameter / (fittedH * scale)

        let srcRect = CGRect(
            x: relX * imgSize.width,
            y: relY * imgSize.height,
            width: relW * imgSize.width,
            height: relH * imgSize.height
        )

        let out: CGFloat = 400
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: out, height: out))
        let cropped = renderer.image { ctx in
            ctx.cgContext.addEllipse(in: CGRect(x: 0, y: 0, width: out, height: out))
            ctx.cgContext.clip()
            image.draw(in: CGRect(
                x: -srcRect.origin.x * (out / srcRect.width),
                y: -srcRect.origin.y * (out / srcRect.height),
                width: imgSize.width * (out / srcRect.width),
                height: imgSize.height * (out / srcRect.height)
            ))
        }

        onCrop(cropped)
        dismiss()
    }
}
