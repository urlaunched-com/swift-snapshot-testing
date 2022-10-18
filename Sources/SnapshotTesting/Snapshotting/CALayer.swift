#if os(macOS)
import Cocoa

extension Snapshotting where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float) -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, size: nil).pullback { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.setNeedsLayout()
      layer.layoutIfNeeded()
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == CALayer, Format == UIImage {
    /// A snapshot strategy for comparing layers based on pixel equality.
    public static var image: Snapshotting {
        return .image(png: true, perceptualPrecision: 0)
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameter precision: The percentage of pixels that must match.
    public static func image(precision: Float = 1, traits: UITraitCollection = .init(), png: Bool, perceptualPrecision: Float = 0)
    -> Snapshotting {
        return SimplySnapshotting.image(precision: precision, scale: traits.displayScale, png: png, perceptualPrecision: perceptualPrecision).pullback { layer in
            renderer(bounds: layer.bounds, for: traits).image { ctx in
                layer.setNeedsLayout()
                layer.layoutIfNeeded()
                layer.render(in: ctx.cgContext)
            }
        }
    }
}
#endif
