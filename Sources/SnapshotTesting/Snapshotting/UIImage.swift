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
      guard !compare(old, new, precision: precision) else { return nil }
      let difference = SnapshotTesting.diff(old, new, scale: imageScale)
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

private func compare(_ old: UIImage, _ new: UIImage, precision: Float) -> Bool {
  guard let oldCgImage = old.cgImage else { return false }
  guard let newCgImage = new.cgImage else { return false }
  guard oldCgImage.width != 0 else { return false }
  guard newCgImage.width != 0 else { return false }
  guard oldCgImage.width == newCgImage.width else { return false }
  guard oldCgImage.height != 0 else { return false }
  guard newCgImage.height != 0 else { return false }
  guard oldCgImage.height == newCgImage.height else { return false }

  let resultImage = computeImageDifference(image1: old, image2: new)
    let result2 = try? ImageDiff().compare(leftImage: old.cgImage!, rightImage: new.cgImage!)

    let comp3 = try? compare(tolerance: 60, expectedUIImage: old, observedUIImage: new)

  // Values between images may differ due to padding to multiple of 64 bytes per row,
  // because of that a freshly taken view snapshot may differ from one stored as PNG.
  // At this point we're sure that size of both images is the same, so we can go with minimal `bytesPerRow` value
  // and use it to create contexts.
  let minBytesPerRow = min(oldCgImage.bytesPerRow, newCgImage.bytesPerRow)
  let byteCount = minBytesPerRow * oldCgImage.height

  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: oldCgImage, bytesPerRow: minBytesPerRow, data: &oldBytes) else { return false }
  guard let oldData = oldContext.data else { return false }
  if let newContext = context(for: newCgImage, bytesPerRow: minBytesPerRow), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 { return true }
  }
  let newer = UIImage(data: new.pngData()!)!
  guard let newerCgImage = newer.cgImage else { return false }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newerCgImage, bytesPerRow: minBytesPerRow, data: &newerBytes) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  if precision >= 1 { return false }
  var differentPixelCount = 0
  let threshold = 1 - precision
  for byte in 0..<byteCount {
    if oldBytes[byte] != newerBytes[byte] { differentPixelCount += 1 }
    if Float(differentPixelCount) / Float(byteCount) > threshold { return false}
  }
  return true
}


typealias Percentage = Float

enum CompareError: Error {
    case unableToGetCGImageFromData, unableToGetColorSpaceFromCGImage, imagesHasDifferentSizes, unableToInitializeContext
}

// See: https://github.com/facebookarchive/ios-snapshot-test-case/blob/master/FBSnapshotTestCase/Categories/UIImage%2BCompare.m
private func compare(tolerance: Percentage, expectedUIImage: UIImage, observedUIImage: UIImage) throws -> Bool {
//    guard let expectedUIImage = UIImage(data: expected), let observedUIImage = UIImage(data: observed) else {
//        throw CompareError.unableToGetUIImageFromData
//    }
    guard let expectedCGImage = expectedUIImage.cgImage, let observedCGImage = observedUIImage.cgImage else {
        throw CompareError.unableToGetCGImageFromData
    }
    guard let expectedColorSpace = expectedCGImage.colorSpace, let observedColorSpace = observedCGImage.colorSpace else {
        throw CompareError.unableToGetColorSpaceFromCGImage
    }
    if expectedCGImage.width != observedCGImage.width || expectedCGImage.height != observedCGImage.height {
        throw CompareError.imagesHasDifferentSizes
    }
    let imageSize = CGSize(width: expectedCGImage.width, height: expectedCGImage.height)
    let numberOfPixels = Int(imageSize.width * imageSize.height)

    // Checking that our `UInt32` buffer has same number of bytes as image has.
    let bytesPerRow = min(expectedCGImage.bytesPerRow, observedCGImage.bytesPerRow)
    assert(MemoryLayout<UInt32>.stride == bytesPerRow / Int(imageSize.width))

    let expectedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
    let observedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)

    let expectedPixelsRaw = UnsafeMutableRawPointer(expectedPixels)
    let observedPixelsRaw = UnsafeMutableRawPointer(observedPixels)

    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let expectedContext = CGContext(data: expectedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                          bitsPerComponent: expectedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                          space: expectedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        expectedPixels.deallocate()
        observedPixels.deallocate()
        throw CompareError.unableToInitializeContext
    }
    guard let observedContext = CGContext(data: observedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                          bitsPerComponent: observedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                          space: observedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        expectedPixels.deallocate()
        observedPixels.deallocate()
        throw CompareError.unableToInitializeContext
    }

    expectedContext.draw(expectedCGImage, in: CGRect(origin: .zero, size: imageSize))
    observedContext.draw(observedCGImage, in: CGRect(origin: .zero, size: imageSize))

    let expectedBuffer = UnsafeBufferPointer(start: expectedPixels, count: numberOfPixels)
    let observedBuffer = UnsafeBufferPointer(start: observedPixels, count: numberOfPixels)

    var isEqual = true
    if tolerance == 0 {
        isEqual = expectedBuffer.elementsEqual(observedBuffer)
    } else {
        // Go through each pixel in turn and see if it is different
        var numDiffPixels = 0
        for pixel in 0 ..< numberOfPixels where expectedBuffer[pixel] != observedBuffer[pixel] {
            // If this pixel is different, increment the pixel diff count and see if we have hit our limit.
            numDiffPixels += 1
            let percentage = 100 * Float(numDiffPixels) / Float(numberOfPixels)
            if percentage > tolerance {
                isEqual = false
                break
            }
        }
    }

    expectedPixels.deallocate()
    observedPixels.deallocate()

    return isEqual
}


class ImageDiff {

    func compare(leftImage: CGImage, rightImage: CGImage) throws -> Int {

        let left = CIImage(cgImage: leftImage)
        let right = CIImage(cgImage: rightImage)

        guard let diffFilter = CIFilter(name: "CIDifferenceBlendMode") else {
            throw ImageDiffError.failedToCreateFilter
        }
        diffFilter.setDefaults()
        diffFilter.setValue(left, forKey: kCIInputImageKey)
        diffFilter.setValue(right, forKey: kCIInputBackgroundImageKey)

        // Create the area max filter and set its properties.
        guard let areaMaxFilter = CIFilter(name: "CIAreaMaximum") else {
            throw ImageDiffError.failedToCreateFilter
        }
        areaMaxFilter.setDefaults()
        areaMaxFilter.setValue(diffFilter.value(forKey: kCIOutputImageKey),
                               forKey: kCIInputImageKey)
        let compareRect = CGRect(x: 0, y: 0, width: CGFloat(leftImage.width), height: CGFloat(leftImage.height))

        let extents = CIVector(cgRect: compareRect)
        areaMaxFilter.setValue(extents, forKey: kCIInputExtentKey)

        // The filters have been setup, now set up the CGContext bitmap context the
        // output is drawn to. Setup the context with our supplied buffer.
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var buf: [CUnsignedChar] = Array<CUnsignedChar>(repeating: 255, count: 16)

        guard let context = CGContext(
            data: &buf,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw ImageDiffError.failedToCreateContext
        }

        // Now create the core image context CIContext from the bitmap context.
        let ciContextOpts = [
            CIContextOption.workingColorSpace : colorSpace,
            CIContextOption.useSoftwareRenderer : false
        ] as [CIContextOption : Any]
        let ciContext = CIContext(cgContext: context, options: ciContextOpts)

        // Get the output CIImage and draw that to the Core Image context.
        let valueImage = areaMaxFilter.value(forKey: kCIOutputImageKey)! as! CIImage
        ciContext.draw(valueImage, in: CGRect(x: 0, y: 0, width: 1, height: 1),
                       from: valueImage.extent)

        // This will have modified the contents of the buffer used for the CGContext.
        // Find the maximum value of the different color components. Remember that
        // the CGContext was created with a Premultiplied last meaning that alpha
        // is the fourth component with red, green and blue in the first three.
        let maxVal = max(buf[0], max(buf[1], buf[2]))
        let diff = Int(maxVal)

        return diff
    }
}

// MARK: - Supporting Types

enum ImageDiffError: LocalizedError {
    case failedToCreateFilter
    case failedToCreateContext
}


//func getPixelData(from uiimage: UIImage) -> CFData? {
//    if let cgImage = uiimage.cgImage {
//        let provider = cgImage.dataProvider
//        let providerData = provider?.data
//        return providerData
//    }
//
//    guard let ciImage = uiimage.ciImage else {
//        return nil
//    }
//
//    let convertedCGImage = convertCGImageToCGImage(inputImage: ciImage)
//    return convertedCGImage?.dataProvider?.data
//}
//
//func convertCGImageToCGImage(inputImage: CIImage) -> CGImage? {
//    let context = CIContext(options: nil)
//    return context.createCGImage(inputImage, from: inputImage.extent)
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
