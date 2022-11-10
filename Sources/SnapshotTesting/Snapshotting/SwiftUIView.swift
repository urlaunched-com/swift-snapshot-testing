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
        renderingMode: RenderingMode = .drawHierarchy(afterScreenUpdates: true),
        precision: Float = 1,
        perceptualPrecision: Float = 0,
        png: Bool,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init(),
        interfaceStyle: UIUserInterfaceStyle = .light,
        delayForLayout: Double = 0.1
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

        return SimplySnapshotting.image(precision: precision, scale: traits.displayScale, png: png, perceptualPrecision: perceptualPrecision).asyncPullback { view in
            guard let size = config.size else {
                let controller = SizeToFitViewController(rootView: view)

                return snapshot(
                    view: { controller.viewToRender! },
                    viewController: controller,
                    renderingMode: renderingMode,
                    config: config,
                    traits: traits,
                    interfaceStyle: interfaceStyle,
                    delayForLayout: delayForLayout
                )
            }

            let sizedController = SizedViewController(rootView: view, size: size)
            return snapshot(
                view: { sizedController.viewToRender! },
                viewController: sizedController,
                renderingMode: renderingMode,
                config: config,
                traits: traits,
                interfaceStyle: interfaceStyle,
                delayForLayout: delayForLayout
            )
        }
    }

    static func snapshot(
        view: @escaping () -> UIView,
        viewController: UIViewController,
        renderingMode: RenderingMode,
        config: ViewImageConfig,
        traits: UITraitCollection,
        interfaceStyle: UIUserInterfaceStyle,
        delayForLayout: Double
    ) -> Async<UIImage> {

        ViewImageConfig.global = config

        let dispose = prepareView(
            config: config,
            drawHierarchyInKeyWindow: false,
            view: viewController.view,
            viewController: viewController,
            interfaceStyle: interfaceStyle
        )

        return Async { callback in
            ViewImageConfig.global = config
            let viewToRender = view()
            viewToRender.setNeedsLayout()
            viewToRender.layoutIfNeeded()

            DispatchQueue.main.asyncAfter(deadline: .now() + delayForLayout) {
                let old = renderer(bounds: viewToRender.bounds, for: traits).image { ctx in
                    ViewImageConfig.global = config

                    switch renderingMode {
                    case .snapshot(let afterScreenUpdates):
                        viewToRender
                            .snapshotView(afterScreenUpdates: afterScreenUpdates)?
                            .drawHierarchy(in: viewToRender.bounds, afterScreenUpdates: afterScreenUpdates)

                    case .drawHierarchy(let afterScreenUpdates):
                        viewToRender.drawHierarchy(in: viewToRender.bounds, afterScreenUpdates: afterScreenUpdates)

                    case .renderInContext:
                        viewToRender.layer.render(in: ctx.cgContext)
                    }
                }

                var newImage: UIImage? = nil
                if let oldCgImage = old.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB), let copy = oldCgImage.copy(colorSpace: space) {
                    newImage = UIImage(cgImage: copy)
                }

                callback(newImage ?? old)
                dispose()
            }
        }
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
        let hosting = SnapshotHostingController(rootView: contentView)
        view.addSubview(hosting.view)

        self.addChild(hosting)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hosting.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hosting.view.widthAnchor.constraint(equalToConstant: size.width),
            hosting.view.heightAnchor.constraint(equalToConstant: size.height)
        ])

        viewToRender = hosting.view
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
        let hosting = SnapshotHostingController(rootView: contentView)

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

final class SnapshotHostingController<Content: SwiftUI.View>: UIHostingController<Content> {
    override init(rootView: Content) {
        super.init(rootView: rootView)

        let _class: AnyClass = view.classForCoder
        let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
            return .zero
        }

        guard let method = class_getInstanceMethod(_class.self, #selector(getter: UIView.safeAreaInsets)) else {
            return
        }

        class_replaceMethod(_class, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
#endif
