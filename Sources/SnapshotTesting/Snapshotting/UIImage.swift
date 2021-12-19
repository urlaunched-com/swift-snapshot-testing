#if os(iOS) || os(tvOS)
import UIKit
import XCTest

extension Diffing where Value == UIImage {
  /// A pixel-diffing strategy for UIImage's which requires a 100% match.
  public static let image = Diffing.image(precision: 1, scale: nil)

  /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Parameter scale: Scale to use when loading the reference image from disk. If `nil` or the `UITraitCollection`s default value of `0.0`, the screens scale is used.
  /// - Returns: A new diffing strategy.
  public static func image(precision: Float, scale: CGFloat?) -> Diffing {
    let imageScale: CGFloat
    if let scale = scale, scale != 0.0 {
      imageScale = scale
    } else {
      imageScale = UIScreen.main.scale
    }

    return Diffing(
      toData: { $0.pngData() ?? emptyImage().pngData()! },
      fromData: { UIImage(data: $0, scale: imageScale)! }
    ) { old, new in
        let result = compare(old, new, precision: precision)
        guard !result.isEqual else { return nil }
      let difference = SnapshotTesting.diff(old, new, scale: imageScale)
      let message = new.size == old.size
        ? "Newly-taken snapshot does not match reference."
        : "Newly-taken snapshot@\(new.size) does not match reference@\(old.size)."
      let oldAttachment = XCTAttachment(image: old)
      oldAttachment.name = "reference"
        oldAttachment.lifetime = .deleteOnSuccess

      let newAttachment = XCTAttachment(image: new)
      newAttachment.name = "failure"
        newAttachment.lifetime = .deleteOnSuccess

      let differenceAttachment = XCTAttachment(image: difference)
        differenceAttachment.name = "difference (diff: \(String(format: "%.2f", result.diff))"
        differenceAttachment.lifetime = .deleteOnSuccess

      return (
        message,
        [oldAttachment, newAttachment, differenceAttachment]
      )
    }
  }
  
  
  /// Used when the image size has no width or no height to generated the default empty image
  private static func emptyImage() -> UIImage {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
    label.backgroundColor = .red
    label.text = "Error: No image could be generated for this view as its size was zero. Please set an explicit size in the test."
    label.textAlignment = .center
    label.numberOfLines = 3
    return label.asImage()
  }
}

extension Snapshotting where Value == UIImage, Format == UIImage {
  /// A snapshot strategy for comparing images based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1, scale: nil)
  }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  /// - Parameter scale: The scale of the reference image stored on disk.
  public static func image(precision: Float, scale: CGFloat?) -> Snapshotting {
    return .init(
      pathExtension: "png",
      diffing: .image(precision: precision, scale: scale)
    )
  }
}

func calculateTime(block : (() -> Void)) {
    let start = DispatchTime.now()
    block()
    let end = DispatchTime.now()
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000_000
    print("Time: \(timeInterval) seconds")
}

private func compare(_ old: UIImage, _ new: UIImage, precision: Float) -> (isEqual: Bool, diff: Float) {
  guard let oldCgImage = old.cgImage else { return (false, 0) }
  guard let newCgImage = new.cgImage else { return (false, 0) }
  guard oldCgImage.width != 0 else { return (false, 0) }
  guard newCgImage.width != 0 else { return (false, 0) }
  guard oldCgImage.width == newCgImage.width else { return (false, 0) }
  guard oldCgImage.height != 0 else { return (false, 0) }
  guard newCgImage.height != 0 else { return (false, 0) }
  guard oldCgImage.height == newCgImage.height else { return (false, 0) }

  // Values between images may differ due to padding to multiple of 64 bytes per row,
  // because of that a freshly taken view snapshot may differ from one stored as PNG.
  // At this point we're sure that size of both images is the same, so we can go with minimal `bytesPerRow` value
  // and use it to create contexts.
  let minBytesPerRow = min(oldCgImage.bytesPerRow, newCgImage.bytesPerRow)
  let byteCount = minBytesPerRow * oldCgImage.height

  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: oldCgImage, bytesPerRow: minBytesPerRow, data: &oldBytes) else { return (false, 0) }
  guard let oldData = oldContext.data else { return (false, 0) }
  if let newContext = context(for: newCgImage, bytesPerRow: minBytesPerRow), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 { return (true, 1) }
  }
  let newer = UIImage(data: new.pngData()!)!
  guard let newerCgImage = newer.cgImage else { return (false, 0) }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newerCgImage, bytesPerRow: minBytesPerRow, data: &newerBytes) else { return (false, 0) }
  guard let newerData = newerContext.data else { return (false, 0) }
  if memcmp(oldData, newerData, byteCount) == 0 { return (true, 1) }
  if precision >= 1 { return (false, 0) }
  var differentPixelCount = 0
  let threshold = 1 - precision
  for byte in 0..<byteCount {
    if oldBytes[byte] != newerBytes[byte] { differentPixelCount += 1 }
      let diff = Float(differentPixelCount) / Float(byteCount)
    if diff > threshold {
        return (false, 1 - diff)
    }
  }
  return (true, 1)
}

import CoreImage
import CoreImage.CIFilterBuiltins

func computeImageDifference(image1: UIImage, image2: UIImage) -> UIImage? {
    guard
        let ciImage1 = CIImage(image: image1),
        let ciImage2 = CIImage(image: image2)
    else {
        return nil
    }

    let filter = CIFilter.colorAbsoluteDifference()
    filter.inputImage = ciImage1
    filter.inputImage2 = ciImage2

    guard let output = filter.outputImage else {
        return nil
    }

    let context = CIContext()
    guard let cgImage = context.createCGImage(output, from: output.extent) else {
        return nil
    }
    return UIImage(cgImage: cgImage, scale: image1.scale, orientation: image1.imageOrientation)
}

private func context(for cgImage: CGImage, bytesPerRow: Int, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  guard
    let space = cgImage.colorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diff(_ old: UIImage, _ new: UIImage, scale: CGFloat) -> UIImage {
    let resultImage = computeImageDifference(image1: old, image2: new)
    return resultImage ?? old
}
#endif
