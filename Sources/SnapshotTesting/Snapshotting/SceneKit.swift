#if os(iOS) || os(macOS) || os(tvOS)
import SceneKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Snapshotting where Value == SCNScene, Format == NSImage {
    /// A snapshot strategy for comparing SceneKit scenes based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - size: The size of the scene.
    public static func image(precision: Float = 1, size: CGSize, png: Bool) -> Snapshotting {
        return .scnScene(precision: precision, size: size, png: png)
    }
}
#elseif os(iOS) || os(tvOS)
extension Snapshotting where Value == SCNScene, Format == UIImage {
    /// A snapshot strategy for comparing SceneKit scenes based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - size: The size of the scene.
    public static func image(precision: Float = 1, subpixelThreshold: UInt8 = 0, size: CGSize, png: Bool) -> Snapshotting {
        return .scnScene(precision: precision, subpixelThreshold: subpixelThreshold, size: size, png: png)
    }
}
#endif

fileprivate extension Snapshotting where Value == SCNScene, Format == Image {
    static func scnScene(precision: Float, subpixelThreshold: UInt8 = 0, size: CGSize, png: Bool) -> Snapshotting {
        return Snapshotting<View, Image>.image(precision: precision, subpixelThreshold: subpixelThreshold, png: png, interfaceStyle: .light).pullback { scene in
            let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
            view.scene = scene
            return view
        }
    }
}
#endif
