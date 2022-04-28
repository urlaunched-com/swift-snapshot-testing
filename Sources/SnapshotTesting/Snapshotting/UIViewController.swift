#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIViewController, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
      return .image(interfaceStyle: .light)
  }

  public static func image(scale: CGFloat) -> Snapshotting {
      return .image(drawHierarchyInKeyWindow: true, precision: 1, scale: scale, traits: .init(displayScale: scale), interfaceStyle: .light)
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    on config: ViewImageConfig,
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init(),
    interfaceStyle: UIUserInterfaceStyle = .light
    )
    -> Snapshotting {

    return SimplySnapshotting.image(precision: precision, scale: config.traits.displayScale).asyncPullback { viewController in
        snapshotView(
          config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits, name: "\($0)") } ?? config,
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: config.traits,
          view: viewController.view,
          viewController: viewController,
          interfaceStyle: interfaceStyle
        )
      }
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init(),
    interfaceStyle: UIUserInterfaceStyle = .light
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { viewController in
        snapshotView(
          config: .init(safeArea: .zero, size: size, traits: traits, name: String(describing: size)),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: viewController.view,
          viewController: viewController,
          interfaceStyle: interfaceStyle
        )
      }
  }

    public static func image(
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1,
        size: CGSize? = nil,
        scale: CGFloat,
        traits: UITraitCollection = .init(),
        interfaceStyle: UIUserInterfaceStyle = .light
    )
    -> Snapshotting {

        return SimplySnapshotting.image(precision: precision, scale: scale).asyncPullback { viewController in
            snapshotView(
                config: .init(safeArea: .zero, size: size, traits: traits, name: String(describing: size)),
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                traits: .init(displayScale: scale),
                view: viewController.view,
                viewController: viewController,
                interfaceStyle: interfaceStyle
            )
        }
    }
}

extension Snapshotting where Value == UIViewController, Format == String {
  /// A snapshot strategy for comparing view controllers based on their embedded controller hierarchy.
  public static var hierarchy: Snapshotting {
    return Snapshotting<String, String>.lines.pullback { viewController in
      let dispose = prepareView(
        config: .init(name: "hierarchy"),
        drawHierarchyInKeyWindow: false,
        view: viewController.view,
        viewController: viewController,
        interfaceStyle: .light //TODO: as param
      )
      defer { dispose() }
      return purgePointers(
        viewController.perform(Selector(("_printHierarchy"))).retain().takeUnretainedValue() as! String
      )
    }
  }

  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func recursiveDescription(
    on config: ViewImageConfig = .init(name: "recursiveDescription"),
    size: CGSize? = nil,
    interfaceStyle: UIUserInterfaceStyle = .light
  )
    -> Snapshotting<UIViewController, String> {
      return SimplySnapshotting.lines.pullback { viewController in
        let dispose = prepareView(
          config: .init(safeArea: config.safeArea, size: size ?? config.size, traits: config.traits, name: String(describing: size ?? config.size)),
          drawHierarchyInKeyWindow: false,
          view: viewController.view,
          viewController: viewController,
          interfaceStyle: interfaceStyle
        )
        defer { dispose() }
        return purgePointers(
          viewController.view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
            as! String
        )
      }
  }
}
#endif
