#if os(iOS) || os(tvOS)
import UIKit
import XCTest

extension Diffing where Value == UIImage {
  /// A pixel-diffing strategy for UIImage's which requires a 100% match.
    public static let image = Diffing.image(precision: 1, scale: nil, png: true, perceptualPrecision: 0)

  /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Parameter scale: Scale to use when loading the reference image from disk. If `nil` or the `UITraitCollection`s default value of `0.0`, the screens scale is used.
  /// - Returns: A new diffing strategy.
    public static func image(precision: Float, scale: CGFloat?, png: Bool, perceptualPrecision: Float = 0) -> Diffing {
    let imageScale: CGFloat
    if let scale = scale, scale != 0.0 {
      imageScale = scale
    } else {
      imageScale = UIScreen.main.scale
    }

    return Diffing(
      toData: {
          if png {
              return $0.pngData() ?? emptyImage().pngData()!
          } else {
              return $0.jpegData(compressionQuality: 0.8) ?? emptyImage().jpegData(compressionQuality: 0.8)!
          }
      },
      fromData: {
          let old = UIImage(data: $0, scale: imageScale)!

          let srgb = UIImage(
            cgImage: old.cgImage!.copy(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)!
          )

          return srgb
      }
    ) { old, new in
        guard let message = compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision) else { return nil }
        let difference = SnapshotTesting.diff(old, new, scale: imageScale)
        let oldAttachment = XCTAttachment(image: old)
        oldAttachment.name = "reference"
        oldAttachment.lifetime = .deleteOnSuccess

        let newAttachment = XCTAttachment(image: new)
        newAttachment.name = "failure"
        newAttachment.lifetime = .deleteOnSuccess

        let differenceAttachment = XCTAttachment(image: difference)
        differenceAttachment.name = "difference"
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
        return .image(precision: 1, scale: nil, png: true, perceptualPrecision: 0)
    }

    /// A snapshot strategy for comparing images based on pixel equality.
    ///
    /// - Parameter precision: The percentage of pixels that must match.
    /// - Parameter scale: The scale of the reference image stored on disk.
    public static func image(precision: Float, scale: CGFloat?, png: Bool, perceptualPrecision: Float = 0) -> Snapshotting {
        return .init(
            pathExtension: png ? "png" : "jpg",
            diffing: .image(precision: precision, scale: scale, png: png, perceptualPrecision: perceptualPrecision)
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

//import iOSSnapshotTestCase

//private func compare(_ old: UIImage, _ new: UIImage, precision: Float) -> Bool {
//    var result = true
//    do {
//        try FBSnapshotTestController().compareReferenceImage(old, to: new, overallTolerance: CGFloat(1.0 - precision))
//    } catch {
//        Swift.print(error)
//        result = false
//    }
//
//    return result
//}

// remap snapshot & reference to same colorspace
let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
let imageContextBitsPerComponent = 8
let imageContextBytesPerPixel = 4

private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> String? {
    guard let oldCgImage = old.cgImage else {
        return "Reference image could not be loaded."
    }
    guard let newCgImage = new.cgImage else {
        return "Newly-taken snapshot could not be loaded."
    }
    guard newCgImage.width != 0, newCgImage.height != 0 else {
        return "Newly-taken snapshot is empty."
    }
    guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
        return "Newly-taken snapshot@\(new.size) does not match reference@\(old.size)."
    }
    let pixelCount = oldCgImage.width * oldCgImage.height
    let byteCount = imageContextBytesPerPixel * pixelCount
    var oldBytes = [UInt8](repeating: 0, count: byteCount)
    guard let oldData = context(for: oldCgImage, data: &oldBytes)?.data else {
        return "Reference image's data could not be loaded."
    }

    if let newContext = context(for: newCgImage), let newData = newContext.data {
        if memcmp(oldData, newData, byteCount) == 0 { return nil }
    }

    var newerBytes = [UInt8](repeating: 0, count: byteCount)
    guard
        let pngData = new.pngData(),
        let newerCgImage = UIImage(data: pngData)?.cgImage,
        let newerContext = context(for: newerCgImage, data: &newerBytes),
        let newerData = newerContext.data
    else {
        return "Newly-taken snapshot's data could not be loaded."
    }
    if memcmp(oldData, newerData, byteCount) == 0 { return nil }
    if precision >= 1, perceptualPrecision >= 1 {
        return "Newly-taken snapshot does not match reference."
    }
    if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
        return perceptuallyCompare(
            CIImage(cgImage: oldCgImage),
            CIImage(cgImage: newCgImage),
            pixelPrecision: precision,
            perceptualPrecision: perceptualPrecision
        )
    } else {
        let byteCountThreshold = Int((1 - precision) * Float(byteCount))
        var differentByteCount = 0
        for offset in 0..<byteCount {
            if oldBytes[offset] != newerBytes[offset] {
                differentByteCount += 1
            }
        }
        if differentByteCount > byteCountThreshold {
            let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
            return "Actual image precision \(actualPrecision) is less than required \(precision)"
        }
    }
    return nil
}


#if os(iOS) || os(tvOS) || os(macOS)
import CoreImage.CIKernel
import MetalPerformanceShaders

@available(iOS 10.0, tvOS 10.0, macOS 10.13, *)
func perceptuallyCompare(_ old: CIImage, _ new: CIImage, pixelPrecision: Float, perceptualPrecision: Float) -> String? {
    let deltaOutputImage = old.applyingFilter("CILabDeltaE", parameters: ["inputImage2": new])
    let thresholdOutputImage: CIImage
    do {
        thresholdOutputImage = try ThresholdImageProcessorKernel.apply(
            withExtent: new.extent,
            inputs: [deltaOutputImage],
            arguments: [ThresholdImageProcessorKernel.inputThresholdKey: (1 - perceptualPrecision) * 100]
        )
    } catch {
        return "Newly-taken snapshot's data could not be loaded. \(error)"
    }
    var averagePixel: Float = 0
    let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
    context.render(
        thresholdOutputImage.applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: new.extent]),
        toBitmap: &averagePixel,
        rowBytes: MemoryLayout<Float>.size,
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
        format: .Rf,
        colorSpace: nil
    )
    let actualPixelPrecision = 1 - averagePixel
    guard actualPixelPrecision < pixelPrecision else { return nil }
    var maximumDeltaE: Float = 0
    context.render(
        deltaOutputImage.applyingFilter("CIAreaMaximum", parameters: [kCIInputExtentKey: new.extent]),
        toBitmap: &maximumDeltaE,
        rowBytes: MemoryLayout<Float>.size,
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
        format: .Rf,
        colorSpace: nil
    )
    let actualPerceptualPrecision = 1 - maximumDeltaE / 100
    if pixelPrecision < 1 {
        return """
    Actual image precision \(actualPixelPrecision) is less than required \(pixelPrecision)
    Actual perceptual precision \(actualPerceptualPrecision) is less than required \(perceptualPrecision)
    """
    } else {
        return "Actual perceptual precision \(actualPerceptualPrecision) is less than required \(perceptualPrecision)"
    }
}

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


//private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> Bool {
//    guard let oldCgImage = old.cgImage else { return false }
//    guard let newCgImage = new.cgImage else { return false }
//    guard oldCgImage.width != 0 else { return false }
//    guard newCgImage.width != 0 else { return false }
//    guard oldCgImage.width == newCgImage.width else { return false }
//    guard oldCgImage.height != 0 else { return false }
//    guard newCgImage.height != 0 else { return false }
//    guard oldCgImage.height == newCgImage.height else { return false }
//
//    let byteCount = imageContextBytesPerPixel * oldCgImage.width * oldCgImage.height
//    var oldBytes = [UInt8](repeating: 0, count: byteCount)
//    guard let oldContext = context(for: oldCgImage, data: &oldBytes) else { return false }
//    guard let oldData = oldContext.data else { return false }
//    if let newContext = context(for: newCgImage), let newData = newContext.data {
//        if memcmp(oldData, newData, byteCount) == 0 { return true }
//    }
//    let newer = UIImage(data: new.pngData()!)!
//    guard let newerCgImage = newer.cgImage else { return false }
//    var newerBytes = [UInt8](repeating: 0, count: byteCount)
//    guard let newerContext = context(for: newerCgImage, data: &newerBytes) else { return false }
//    guard let newerData = newerContext.data else { return false }
//    if memcmp(oldData, newerData, byteCount) == 0 { return true }
//    if precision >= 1 && perceptualPrecision == 0 { return false }
//    var differentPixelCount = 0
//    let threshold = Int(round((1.0 - precision) * Float(byteCount)))
//
//    var byte = 0
//    while byte < byteCount {
//        if oldBytes[byte].diff(between: newerBytes[byte]) > perceptualPrecision {
//            differentPixelCount += 1
//            if differentPixelCount >= threshold {
//                return false
//            }
//        }
//        byte += 1
//    }
//    return true
//}

//extension UInt8 {
//    func diff(between other: UInt8) -> UInt8 {
//        if other > self {
//            return other - self
//        } else {
//            return self - other
//        }
//    }
//}


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

//private func diff(_ old: UIImage, _ new: UIImage, scale: CGFloat) -> UIImage {
//    let resultImage = computeImageDifference(image1: old, image2: new)
//    return resultImage ?? old
//}

private func diff(_ old: UIImage, _ new: UIImage, scale: CGFloat) -> UIImage {
    let width = max(old.size.width, new.size.width)
    let height = max(old.size.height, new.size.height)

    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
    new.draw(at: .zero)
    old.draw(at: .zero, blendMode: .difference, alpha: 1)
    let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return differenceImage
}
#endif
