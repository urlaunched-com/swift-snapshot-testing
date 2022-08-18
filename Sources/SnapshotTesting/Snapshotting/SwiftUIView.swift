#if canImport(SwiftUI)
import Foundation
import SwiftUI

/// The size constraint for a snapshot (similar to `PreviewLayout`).
public enum SwiftUISnapshotLayout {
  #if os(iOS) || os(tvOS)
  /// Center the view in a device container described by`config`.
  case device(config: ViewImageConfig)
  #endif
  /// Center the view in a fixed size container.
  case fixed(width: CGFloat, height: CGFloat)
  /// Fit the view to the ideal size that fits its content.
  case sizeThatFits
}

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
      return .image(png: true, interfaceStyle: .light)
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
    public static func image(
        renderingMode: RenderingMode = .snapshot(afterScreenUpdates: true),
        precision: Float = 1,
        subpixelThreshold: UInt8 = 0,
        png: Bool,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init(),
        interfaceStyle: UIUserInterfaceStyle = .light
    )
    -> Snapshotting {
        let config: ViewImageConfig

        switch layout {
#if os(iOS) || os(tvOS)
        case let .device(config: deviceConfig):
            config = deviceConfig
#endif
        case .sizeThatFits:
            config = .init(safeArea: .zero, size: nil, traits: traits, name: "sizeThatFits", options: .none)
        case let .fixed(width: width, height: height):
            let size = CGSize(width: width, height: height)
            config = .init(safeArea: .zero, size: size, traits: traits, name: "\(size)", options: .none)
        }

        return SimplySnapshotting.image(precision: precision, scale: traits.displayScale, png: png, subpixelThreshold: subpixelThreshold).asyncPullback { view in
            guard let size = config.size else {
                let controller = SizeToFitViewController(rootView: view)

                return snapshot(
                    view: { controller.viewToRender! },
                    viewController: controller,
                    renderingMode: renderingMode,
                    config: config,
                    traits: traits,
                    interfaceStyle: interfaceStyle
                )
            }

            let sizedController = SizedViewController(rootView: view, size: size)
            return snapshot(
                view: { sizedController.viewToRender! },
                viewController: sizedController,
                renderingMode: renderingMode,
                config: config,
                traits: traits,
                interfaceStyle: interfaceStyle
            )
        }
    }

    static func snapshot(
        view: @escaping () -> UIView,
        viewController: UIViewController,
        renderingMode: RenderingMode,
        config: ViewImageConfig,
        traits: UITraitCollection,
        interfaceStyle: UIUserInterfaceStyle
    ) -> Async<UIImage> {

        ViewImageConfig.global = config
        let dispose = prepareView(
            config: config,
            drawHierarchyInKeyWindow: false,
            view: viewController.view,
            viewController: viewController,
            interfaceStyle: interfaceStyle
        )

        return (viewController.view.snapshot ?? Async { callback in
            addImagesForRenderedViews(view()).sequence().run { views in
                ViewImageConfig.global = config

                let old = renderer(bounds: view().bounds, for: traits).image { ctx in
                    switch renderingMode {
                    case .snapshot(let afterScreenUpdates):
                        view()
                            .snapshotView(afterScreenUpdates: afterScreenUpdates)?
                            .drawHierarchy(in: view().bounds, afterScreenUpdates: afterScreenUpdates)

                    case .drawHierarchy(let afterScreenUpdates):
                        view().drawHierarchy(in: view().bounds, afterScreenUpdates: afterScreenUpdates)

                    case .renderInContext:
                        view().layer.render(in: ctx.cgContext)
                    }
                }

                let srgb = UIImage(
                    cgImage: old.cgImage!.copy(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)!
                )
                callback(
                    srgb
                )
                views.forEach { $0.removeFromSuperview() }
            }
        }).map { dispose(); return $0 }
    }
}

final class SizedViewController<Content: SwiftUI.View>: UIViewController {
    let size: CGSize
    let contentView: Content
    var viewToRender: UIView!

    init(rootView: Content, size: CGSize) {
        self.contentView = rootView
        self.size = size
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let hosting = UIHostingController(rootView: contentView)
        view.addSubview(hosting.view)

        self.addChild(hosting)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
//            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            //hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hosting.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hosting.view.widthAnchor.constraint(equalToConstant: size.width),
            hosting.view.heightAnchor.constraint(equalToConstant: size.height)
        ])
        hosting.didMove(toParent: self)

        viewToRender = hosting.view
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SizeToFitViewController<Content: SwiftUI.View>: UIViewController {
    let contentView: Content
    var viewToRender: UIView!

    init(rootView: Content) {
        self.contentView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let hosting = UIHostingController(rootView: contentView)

        view.addSubview(hosting.view)
        addChild(hosting)
        hosting.didMove(toParent: self)

        viewToRender = hosting.view
        let maxSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        let size = viewToRender.sizeThatFits(maxSize)

        updateFrame(size: size)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let maxSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        let size = viewToRender.sizeThatFits(maxSize)

        updateFrame(size: size)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateFrame(size: CGSize) {
        var frame = viewToRender.frame
        frame.origin = .zero
        frame.size = size
        viewToRender.frame = frame
    }
}

#endif
#endif
