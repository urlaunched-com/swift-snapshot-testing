#if os(iOS) || os(tvOS)
import CoreImage.CIFilterBuiltins
import UIKit
import XCTest

extension Diffing where Value == UIImage {
  /// A pixel-diffing strategy for UIImage's which requires a 100% match.
  public static let image = Diffing.image()

  /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - scale: Scale to use when loading the reference image from disk. If `nil` or the `UITraitCollection`s default value of `0.0`, the screens scale is used.
  /// - Returns: A new diffing strategy.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil) -> Diffing {
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
      guard !compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision) else { return nil }
      let difference = SnapshotTesting.diff(old, new)
      let message = new.size == old.size
        ? "Newly-taken snapshot does not match reference."
        : "Newly-taken snapshot@\(new.size) does not match reference@\(old.size)."
      let oldAttachment = XCTAttachment(image: old)
      oldAttachment.name = "reference"
      let newAttachment = XCTAttachment(image: new)
      newAttachment.name = "failure"
      let differenceAttachment = XCTAttachment(image: difference)
      differenceAttachment.name = "difference"
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
    return .image()
  }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - scale: The scale of the reference image stored on disk.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil) -> Snapshotting {
    return .init(
      pathExtension: "png",
      diffing: .image(precision: precision, perceptualPrecision: perceptualPrecision, scale: scale)
    )
  }
}

// remap snapshot & reference to same colorspace
private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
private let imageContextBitsPerComponent = 8
private let imageContextBytesPerPixel = 4

private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> Bool {
  guard let oldCgImage = old.cgImage else { return false }
  guard let newCgImage = new.cgImage else { return false }
  guard newCgImage.width != 0 else { return false }
  guard oldCgImage.width == newCgImage.width else { return false }
  guard newCgImage.height != 0 else { return false }
  guard oldCgImage.height == newCgImage.height else { return false }

  let pixelCount = oldCgImage.width * oldCgImage.height
  let byteCount = imageContextBytesPerPixel * pixelCount
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: oldCgImage, data: &oldBytes) else { return false }
  guard let oldData = oldContext.data else { return false }
  if let newContext = context(for: newCgImage), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 { return true }
  }
  let newer = UIImage(data: new.pngData()!)!
  guard let newerCgImage = newer.cgImage else { return false }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newerCgImage, data: &newerBytes) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  if precision >= 1, perceptualPrecision >= 1 { return false }
  if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
    let deltaFilter = CIFilter(
      name: "CILabDeltaE",
      parameters: [
        kCIInputImageKey: CIImage(cgImage: newCgImage),
        "inputImage2": CIImage(cgImage: oldCgImage)
      ]
    )
    guard let deltaOutputImage = deltaFilter?.outputImage else { return false }
    let extent = CGRect(x: 0, y: 0, width: oldCgImage.width, height: oldCgImage.height)
    guard
      let thresholdOutputImage = try? ThresholdImageProcessorKernel.apply(
        withExtent: extent,
        inputs: [deltaOutputImage],
        arguments: [ThresholdImageProcessorKernel.inputThresholdKey: (1 - perceptualPrecision) * 100]
      )
    else { return false }
    let averageFilter = CIFilter(
      name: "CIAreaAverage",
      parameters: [
        kCIInputImageKey: thresholdOutputImage,
        kCIInputExtentKey: extent
      ]
    )
    guard let averageOutputImage = averageFilter?.outputImage else { return false }
    var averagePixel: Float = 0
    CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()]).render(
      averageOutputImage,
      toBitmap: &averagePixel,
      rowBytes: MemoryLayout<Float>.size,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .Rf,
      colorSpace: nil
    )
    let pixelCountThreshold = 1 - precision
    if averagePixel > pixelCountThreshold { return false }
  } else {
    let byteCountThreshold = Int((1 - precision) * Float(byteCount))
    var differentByteCount = 0
    for offset in 0..<byteCount {
      if oldBytes[offset] != newerBytes[offset] {
        differentByteCount += 1
        if differentByteCount > byteCountThreshold { return false }
      }
    }
  }
  return true
}

private func context(for cgImage: CGImage, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  let bytesPerRow = cgImage.width * imageContextBytesPerPixel
  guard
    let colorSpace = imageContextColorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: imageContextBitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diff(_ old: UIImage, _ new: UIImage) -> UIImage {
  let width = max(old.size.width, new.size.width)
  let height = max(old.size.height, new.size.height)
  let scale = max(old.scale, new.scale)
  UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
  new.draw(at: .zero)
  old.draw(at: .zero, blendMode: .difference, alpha: 1)
  let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return differenceImage
}
#endif

#if os(iOS) || os(tvOS) || os(macOS)
import CoreImage.CIKernel
import MetalPerformanceShaders

// Copied from https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel
@available(iOS 10.0, tvOS 10.0, macOS 10.13, *)
final class ThresholdImageProcessorKernel: CIImageProcessorKernel {
  static let inputThresholdKey = "thresholdValue"
  static let device = MTLCreateSystemDefaultDevice()

  override class func process(with inputs: [CIImageProcessorInput]?, arguments: [String: Any]?, output: CIImageProcessorOutput) throws {
    guard
      let device = device,
      let commandBuffer = output.metalCommandBuffer,
      let input = inputs?.first,
      let sourceTexture = input.metalTexture,
      let destinationTexture = output.metalTexture,
      let thresholdValue = arguments?[inputThresholdKey] as? Float else {
      return
    }

    let threshold = MPSImageThresholdBinary(
      device: device,
      thresholdValue: thresholdValue,
      maximumValue: 1.0,
      linearGrayColorTransform: nil
    )

    threshold.encode(
      commandBuffer: commandBuffer,
      sourceTexture: sourceTexture,
      destinationTexture: destinationTexture
    )
  }
}
#endif
