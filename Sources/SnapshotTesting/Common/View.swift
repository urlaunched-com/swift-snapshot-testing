#if os(iOS) || os(macOS) || os(tvOS)
#if os(macOS)
import Cocoa
#endif
import SceneKit
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
//import SnapKit
#endif
#if os(iOS) || os(macOS)
import WebKit
import SnapKit
#endif

#if os(iOS) || os(tvOS)

public struct ViewImageConfig {
    public struct Options: OptionSet {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public let rawValue: Int

        public static let none = Options(rawValue: 1 << 0)
        public static let navigationBarLargeTitle = Options(rawValue: 1 << 1)
        public static let navigationBarInline = Options(rawValue: 1 << 2)
    }

    public static var global: ViewImageConfig = .iPhone13

    public enum Name: String {
        case iPhone13 = "iPhone13"
        case iPhone13Mini = "iPhone13Mini"
        case iPhone13ProMax = "iPhone13ProMax"
        case iPhoneSe = "iPhoneSe"
        case iPhoneSE2 = "iPhoneSE2"
        case iPhone8 = "iPhone8"
        case iPhone8Plus = "iPhone8Plus"
        case iPhoneX = "iPhoneX"
        case iPhoneXsMax = "iPhoneXsMax"
        case iPhoneXr = "iPhoneXr"
        case iPadMini = "iPadMini"
        case iPadPro10_5 = "iPadPro10_5"
        case iPadPro11 = "iPadPro11"
        case iPadPro12_9 = "iPadPro12_9"
    }

    public let name: String
    public let options: Options

    public enum Orientation {
        case landscape
        case portrait
    }
    public enum TabletOrientation {
        public enum PortraitSplits {
            case oneThird
            case twoThirds
            case full
        }
        public enum LandscapeSplits {
            case oneThird
            case oneHalf
            case twoThirds
            case full
        }
        case landscape(splitView: LandscapeSplits)
        case portrait(splitView: PortraitSplits)
    }

    public var safeArea: UIEdgeInsets
    public var size: CGSize?
    public var traits: UITraitCollection
    public var nativeScale: CGFloat

    public mutating func setInterfaceStyle(_ style: UIUserInterfaceStyle) {
        traits = .init(traitsFrom: [traits, .init(userInterfaceStyle: style)])
    }

    public init(
        safeArea: UIEdgeInsets = .zero,
        size: CGSize? = nil,
        traits: UITraitCollection = .init(),
        nativeScale: CGFloat? = nil,
        name: String,
        options: Options
    ) {
        self.safeArea = safeArea
        self.size = size
        self.traits = traits
        self.name = name
        self.options = options
        self.nativeScale = nativeScale ?? traits.displayScale
    }

#if os(iOS)

    public static let iPhone13 = ViewImageConfig.iPhone13()
    public static func iPhone13(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 844, height: 390)
        case .portrait:
            safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 390, height: 844)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone13(orientation), name: Name.iPhone13.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhone13Mini = ViewImageConfig.iPhone13Mini()
    public static func iPhone13Mini(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 50, bottom: 21, right: 50)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 812, height: 375)
        case .portrait:
            safeArea = .init(top: 50, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 375, height: 812)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone13Mini(orientation), nativeScale: 2.88, name: Name.iPhone13Mini.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhone13ProMax = ViewImageConfig.iPhone13ProMax()
    public static func iPhone13ProMax(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 926, height: 428)
        case .portrait:
            safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 428, height: 926)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone13ProMax(orientation), name: Name.iPhone13ProMax.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhoneSe = ViewImageConfig.iPhoneSe()

    public static func iPhoneSe(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 568, height: 320)
        case .portrait:
            safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 320, height: 568)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhoneSe(orientation), name: Name.iPhoneSe.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhoneSE2 = ViewImageConfig.iPhoneSE2()
    public static func iPhoneSE2(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 667, height: 375)
        case .portrait:
            safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 375, height: 667)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhoneSE2(orientation), name: Name.iPhoneSE2.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhone8 = ViewImageConfig.iPhone8()

    public static func iPhone8(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 667, height: 375)
        case .portrait:
            safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 375, height: 667)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone8(orientation), name: Name.iPhone8.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhone8Plus = ViewImageConfig.iPhone8Plus()

    public static func iPhone8Plus(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 736, height: 414)
        case .portrait:
            safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 414, height: 736)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone8Plus(orientation), name: Name.iPhone8Plus.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhoneX = ViewImageConfig.iPhoneX()

    public static func iPhoneX(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 812, height: 375)
        case .portrait:
            safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 375, height: 812)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhoneX(orientation), name: Name.iPhoneX.rawValue + "_\(orientation)", options: options)
    }

    public static let iPhoneXsMax = ViewImageConfig.iPhoneXsMax()

    public static func iPhoneXsMax(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 896, height: 414)
        case .portrait:
            safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 414, height: 896)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhoneXsMax(orientation), name: Name.iPhoneXsMax.rawValue + "_\(orientation)", options: options)
    }

    @available(iOS 11.0, *)
    public static let iPhoneXr = ViewImageConfig.iPhoneXr()

    @available(iOS 11.0, *)
    public static func iPhoneXr(_ orientation: Orientation = .portrait, options: Options = .none) -> ViewImageConfig {
        var safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)

            if options.contains(.navigationBarInline) || options.contains(.navigationBarLargeTitle) {
                safeArea.top += 32
            }

            size = .init(width: 896, height: 414)
        case .portrait:
            safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)

            if options.contains(.navigationBarInline) {
                safeArea.top += 44
            } else if options.contains(.navigationBarLargeTitle) {
                safeArea.top += 44 + 52
            }

            size = .init(width: 414, height: 896)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhoneXr(orientation), name: Name.iPhoneXr.rawValue + "_\(orientation)", options: options)
    }

    public static let iPadMini = ViewImageConfig.iPadMini(.landscape)

    public static func iPadMini(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .landscape:
            return ViewImageConfig.iPadMini(.landscape(splitView: .full))
        case .portrait:
            return ViewImageConfig.iPadMini(.portrait(splitView: .full))
        }
    }

    public static func iPadMini(_ orientation: TabletOrientation) -> ViewImageConfig {
        let size: CGSize
        let traits: UITraitCollection
        switch orientation {
        case .landscape(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 320, height: 768)
                traits = .iPadMini_Compact_SplitView
            case .oneHalf:
                size = .init(width: 507, height: 768)
                traits = .iPadMini_Compact_SplitView
            case .twoThirds:
                size = .init(width: 694, height: 768)
                traits = .iPadMini
            case .full:
                size = .init(width: 1024, height: 768)
                traits = .iPadMini
            }
        case .portrait(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 320, height: 1024)
                traits = .iPadMini_Compact_SplitView
            case .twoThirds:
                size = .init(width: 438, height: 1024)
                traits = .iPadMini_Compact_SplitView
            case .full:
                size = .init(width: 768, height: 1024)
                traits = .iPadMini
            }
        }
        return .init(safeArea: .init(top: 20, left: 0, bottom: 0, right: 0), size: size, traits: traits, name: Name.iPadMini.rawValue + "_\(orientation)", options: .none)
    }

    public static let iPadPro10_5 = ViewImageConfig.iPadPro10_5(.landscape)

    public static func iPadPro10_5(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .landscape:
            return ViewImageConfig.iPadPro10_5(.landscape(splitView: .full))
        case .portrait:
            return ViewImageConfig.iPadPro10_5(.portrait(splitView: .full))
        }
    }

    public static func iPadPro10_5(_ orientation: TabletOrientation) -> ViewImageConfig {
        let size: CGSize
        let traits: UITraitCollection
        switch orientation {
        case .landscape(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 320, height: 834)
                traits = .iPadPro10_5_Compact_SplitView
            case .oneHalf:
                size = .init(width: 551, height: 834)
                traits = .iPadPro10_5_Compact_SplitView
            case .twoThirds:
                size = .init(width: 782, height: 834)
                traits = .iPadPro10_5
            case .full:
                size = .init(width: 1112, height: 834)
                traits = .iPadPro10_5
            }
        case .portrait(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 320, height: 1112)
                traits = .iPadPro10_5_Compact_SplitView
            case .twoThirds:
                size = .init(width: 504, height: 1112)
                traits = .iPadPro10_5_Compact_SplitView
            case .full:
                size = .init(width: 834, height: 1112)
                traits = .iPadPro10_5
            }
        }
        return .init(safeArea: .init(top: 20, left: 0, bottom: 0, right: 0), size: size, traits: traits, name: Name.iPadPro10_5.rawValue + "_\(orientation)", options: .none)
    }

    public static let iPadPro11 = ViewImageConfig.iPadPro11(.landscape)

    public static func iPadPro11(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .landscape:
            return ViewImageConfig.iPadPro11(.landscape(splitView: .full))
        case .portrait:
            return ViewImageConfig.iPadPro11(.portrait(splitView: .full))
        }
    }

    public static func iPadPro11(_ orientation: TabletOrientation) -> ViewImageConfig {
        let size: CGSize
        let traits: UITraitCollection
        switch orientation {
        case .landscape(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 375, height: 834)
                traits = .iPadPro11_Compact_SplitView
            case .oneHalf:
                size = .init(width: 592, height: 834)
                traits = .iPadPro11_Compact_SplitView
            case .twoThirds:
                size = .init(width: 809, height: 834)
                traits = .iPadPro11
            case .full:
                size = .init(width: 1194, height: 834)
                traits = .iPadPro11
            }
        case .portrait(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 320, height: 1194)
                traits = .iPadPro11_Compact_SplitView
            case .twoThirds:
                size = .init(width: 504, height: 1194)
                traits = .iPadPro11_Compact_SplitView
            case .full:
                size = .init(width: 834, height: 1194)
                traits = .iPadPro11
            }
        }
        return .init(safeArea: .init(top: 24, left: 0, bottom: 20, right: 0), size: size, traits: traits, name: Name.iPadPro11.rawValue + "_\(orientation)", options: .none)
    }

    public static let iPadPro12_9 = ViewImageConfig.iPadPro12_9(.landscape)

    public static func iPadPro12_9(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .landscape:
            return ViewImageConfig.iPadPro12_9(.landscape(splitView: .full))
        case .portrait:
            return ViewImageConfig.iPadPro12_9(.portrait(splitView: .full))
        }
    }

    public static func iPadPro12_9(_ orientation: TabletOrientation) -> ViewImageConfig {
        let size: CGSize
        let traits: UITraitCollection
        switch orientation {
        case .landscape(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 375, height: 1024)
                traits = .iPadPro12_9_Compact_SplitView
            case .oneHalf:
                size = .init(width: 678, height: 1024)
                traits = .iPadPro12_9
            case .twoThirds:
                size = .init(width: 981, height: 1024)
                traits = .iPadPro12_9
            case .full:
                size = .init(width: 1366, height: 1024)
                traits = .iPadPro12_9
            }

        case .portrait(let splitView):
            switch splitView {
            case .oneThird:
                size = .init(width: 375, height: 1366)
                traits = .iPadPro12_9_Compact_SplitView
            case .twoThirds:
                size = .init(width: 639, height: 1366)
                traits = .iPadPro12_9_Compact_SplitView
            case .full:
                size = .init(width: 1024, height: 1366)
                traits = .iPadPro12_9
            }

        }
        return .init(safeArea: .init(top: 20, left: 0, bottom: 0, right: 0), size: size, traits: traits, name: Name.iPadPro12_9.rawValue + "_\(orientation)", options: .none)
    }
#elseif os(tvOS)
    public static let tv = ViewImageConfig(
        safeArea: .init(top: 60, left: 90, bottom: 60, right: 90),
        size: .init(width: 1920, height: 1080),
        traits: .init()
    )
    public static let tv4K = ViewImageConfig(
        safeArea: .init(top: 120, left: 180, bottom: 120, right: 180),
        size: .init(width: 3840, height: 2160),
        traits: .init()
    )
#endif
}

extension UITraitCollection {
#if os(iOS)
    public static func iPhoneSe(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
            //        .init(displayGamut: .SRGB),
            .init(displayScale: 2),
            .init(forceTouchCapability: .available),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular),
                ]
            )
        }
    }

    public static func iPhoneSE2(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 2),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular),
                ]
            )
        }
    }

    public static func iPhone8(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 2),
            .init(forceTouchCapability: .available),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhone8Plus(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .available),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .regular),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhoneX(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
            //        .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .available),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhone13(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhone13Mini(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhone13ProMax(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
//            .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .large),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .regular),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhoneXr(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
            //        .init(displayGamut: .P3),
            .init(displayScale: 2),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .regular),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static func iPhoneXsMax(_ orientation: ViewImageConfig.Orientation)
    -> UITraitCollection {
        let base: [UITraitCollection] = [
            //        .init(displayGamut: .P3),
            .init(displayScale: 3),
            .init(forceTouchCapability: .available),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .regular),
                    .init(verticalSizeClass: .compact)
                ]
            )
        case .portrait:
            return .init(
                traitsFrom: base + [
                    .init(horizontalSizeClass: .compact),
                    .init(verticalSizeClass: .regular)
                ]
            )
        }
    }

    public static let iPadMini = iPad
    public static let iPadMini_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro10_5 = iPad
    public static let iPadPro10_5_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro11 = iPad
    public static let iPadPro11_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro12_9 = iPad
    public static let iPadPro12_9_Compact_SplitView = iPadCompactSplitView

    private static let iPad = UITraitCollection(
        traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .regular),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .pad)
        ]
    )

    private static let iPadCompactSplitView = UITraitCollection(
        traitsFrom: [
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .pad)
        ]
    )
#elseif os(tvOS)
    // TODO
#endif
}
#endif

func addImagesForRenderedViews(_ view: View) -> [Async<View>] {
    return view.snapshot
        .map { async in
            [
                Async { callback in
                    async.run { image in
                        let imageView = ImageView()
                        imageView.image = image
                        imageView.frame = view.frame
#if os(macOS)
                        view.superview?.addSubview(imageView, positioned: .above, relativeTo: view)
#elseif os(iOS) || os(tvOS)
                        view.superview?.insertSubview(imageView, aboveSubview: view)
#endif
                        callback(imageView)
                    }
                }
            ]
        }
    ?? view.subviews.flatMap(addImagesForRenderedViews)
}

extension View {
    var snapshot: Async<Image>? {
        func inWindow<T>(_ perform: () -> T) -> T {
#if os(macOS)
            let superview = self.superview
            defer { superview?.addSubview(self) }
            let window = ScaledWindow()
            window.contentView = NSView()
            window.contentView?.addSubview(self)
            window.makeKey()
#endif
            return perform()
        }
        if let scnView = self as? SCNView {
            return Async(value: inWindow { scnView.snapshot() })
        } else if let skView = self as? SKView {
            if #available(macOS 10.11, *) {
                let cgImage = inWindow { skView.texture(from: skView.scene!)!.cgImage() }
#if os(macOS)
                let image = Image(cgImage: cgImage, size: skView.bounds.size)
#elseif os(iOS) || os(tvOS)
                let image = Image(cgImage: cgImage)
#endif
                return Async(value: image)
            } else {
                fatalError("Taking SKView snapshots requires macOS 10.11 or greater")
            }
        }
#if os(iOS) || os(macOS)
        if let wkWebView = self as? WKWebView {
            return Async<Image> { callback in
                let delegate = NavigationDelegate()
                let work = {
                    if #available(iOS 11.0, macOS 10.13, *) {
                        inWindow {
                            guard wkWebView.frame.width != 0, wkWebView.frame.height != 0 else {
                                callback(Image())
                                return
                            }
                            wkWebView.takeSnapshot(with: nil) { image, _ in
                                _ = delegate
                                callback(image!)
                            }
                        }
                    } else {
#if os(iOS)
                        fatalError("Taking WKWebView snapshots requires iOS 11.0 or greater")
#elseif os(macOS)
                        fatalError("Taking WKWebView snapshots requires macOS 10.13 or greater")
#endif
                    }
                }

                if wkWebView.isLoading {
                    delegate.didFinish = work
                    wkWebView.navigationDelegate = delegate
                } else {
                    work()
                }
            }
        }
#endif
        return nil
    }
#if os(iOS) || os(tvOS)
    func asImage() -> Image {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
#endif
}

#if os(iOS) || os(macOS)
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    var didFinish: () -> Void

    init(didFinish: @escaping () -> Void = {}) {
        self.didFinish = didFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState") { _, _ in
            self.didFinish()
        }
    }
}
#endif

#if os(iOS) || os(tvOS)
extension UIApplication {
    static var sharedIfAvailable: UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector) else {
            return nil
        }

        let shared = UIApplication.perform(sharedSelector)
        return shared?.takeUnretainedValue() as! UIApplication?
    }
}

func prepareView(
    config: ViewImageConfig,
    drawHierarchyInKeyWindow: Bool,
    view: UIView,
    viewController: UIViewController,
    interfaceStyle: UIUserInterfaceStyle = .light
) -> () -> Void {
    let size = config.size ?? viewController.view.frame.size
    view.frame.size = size
    if view != viewController.view {
        viewController.view.bounds = view.bounds
        viewController.view.addSubview(view)
    }
    let window: UIWindow
    if drawHierarchyInKeyWindow {
        guard let keyWindow = getKeyWindow() else {
            fatalError("'drawHierarchyInKeyWindow' requires tests to be run in a host application")
        }
        window = keyWindow
        window.frame.size = size
    } else {
        window = Window(
            config: .init(safeArea: config.safeArea, size: config.size ?? size, traits: config.traits, name: config.name, options: config.options),
            viewController: viewController,
            interfaceStyle: interfaceStyle
        )
    }

    let dispose = add(traits: config.traits, viewController: viewController, to: window, size: size)

    if size.width == 0 || size.height == 0 {
        // Try to call sizeToFit() if the view still has invalid size
        view.sizeToFit()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    return dispose
}

func snapshotView(
    config: ViewImageConfig,
    renderingMode: RenderingMode = .drawHierarchy(afterScreenUpdates: true),
    traits: UITraitCollection,
    view: @escaping () -> UIView,
    viewController: UIViewController,
    interfaceStyle: UIUserInterfaceStyle = .light
)
-> Async<UIImage> {
    ViewImageConfig.global = config

    let dispose = prepareView(
        config: config,
        drawHierarchyInKeyWindow: false,
        view: view(),
        viewController: viewController,
        interfaceStyle: interfaceStyle
    )

    return Async { callback in
        ViewImageConfig.global = config
        let viewToRender = view()

        DispatchQueue.main.async {
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

private let offscreen: CGFloat = 10_000

func renderer(bounds: CGRect, for traits: UITraitCollection) -> UIGraphicsImageRenderer {
    let renderer: UIGraphicsImageRenderer
    if #available(iOS 11.0, tvOS 11.0, *) {
        renderer = UIGraphicsImageRenderer(bounds: bounds, format: .init(for: traits))
    } else {
        renderer = UIGraphicsImageRenderer(bounds: bounds)
    }
    return renderer
}

/*
private func add(traits: UITraitCollection, viewController: UIViewController, to window: UIWindow) -> () -> Void {
    let rootViewController: UIViewController
    if viewController != window.rootViewController {
        rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        rootViewController.view.frame = window.frame
        rootViewController.view.translatesAutoresizingMaskIntoConstraints =
        viewController.view.translatesAutoresizingMaskIntoConstraints
        rootViewController.preferredContentSize = rootViewController.view.frame.size
        viewController.view.frame = rootViewController.view.frame
        rootViewController.view.addSubview(viewController.view)
        if viewController.view.translatesAutoresizingMaskIntoConstraints {
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else {
            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
            ])
        }
        rootViewController.addChild(viewController)
    } else {
        rootViewController = viewController
    }
    rootViewController.setOverrideTraitCollection(traits, forChild: viewController)
    viewController.didMove(toParent: rootViewController)
    window.rootViewController = rootViewController
    rootViewController.beginAppearanceTransition(true, animated: false)
    rootViewController.endAppearanceTransition()
    rootViewController.view.setNeedsLayout()
    rootViewController.view.layoutIfNeeded()
    viewController.view.setNeedsLayout()
    viewController.view.layoutIfNeeded()

    return {
        rootViewController.beginAppearanceTransition(false, animated: false)
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
        rootViewController.endAppearanceTransition()
        window.rootViewController = nil
    }
}*/


//Prev


private func add(traits: UITraitCollection, viewController: UIViewController, to window: UIWindow, size: CGSize) -> () -> Void {
    window.rootViewController = viewController
    window.frame.size = size

    viewController.beginAppearanceTransition(true, animated: false)
    viewController.endAppearanceTransition()

    viewController.view.setNeedsLayout()
    viewController.view.layoutIfNeeded()
    return {
        viewController.beginAppearanceTransition(false, animated: false)
        viewController.endAppearanceTransition()
        window.rootViewController = nil
    }
    /*
    let rootViewController: UIViewController
    if viewController != window.rootViewController {
        rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        rootViewController.view.frame = window.frame
        rootViewController.view.translatesAutoresizingMaskIntoConstraints =
        viewController.view.translatesAutoresizingMaskIntoConstraints
        rootViewController.preferredContentSize = rootViewController.view.frame.size
        viewController.view.frame = rootViewController.view.frame
        rootViewController.view.addSubview(viewController.view)
        if viewController.view.translatesAutoresizingMaskIntoConstraints {
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else {
            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
            ])
        }
        rootViewController.addChild(viewController)
    } else {
        rootViewController = viewController
    }
    rootViewController.setOverrideTraitCollection(traits, forChild: viewController)
    viewController.didMove(toParent: rootViewController)

    window.rootViewController = rootViewController

    rootViewController.beginAppearanceTransition(true, animated: false)
    rootViewController.endAppearanceTransition()

    rootViewController.view.setNeedsLayout()
    rootViewController.view.layoutIfNeeded()

    viewController.view.setNeedsLayout()
    viewController.view.layoutIfNeeded()

    return {
        rootViewController.beginAppearanceTransition(false, animated: false)
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
        rootViewController.endAppearanceTransition()
        window.rootViewController = nil
    }*/
}


/*
private func add(traits: UITraitCollection, viewController: UIViewController, to window: UIWindow) -> () -> Void {
    let rootViewController = UIViewController()
//    if viewController != window.rootViewController {
//        rootViewController = UIViewController()
//        rootViewController.view.backgroundColor = .clear
        rootViewController.view.frame = window.frame
//        rootViewController.view.translatesAutoresizingMaskIntoConstraints =
//        viewController.view.translatesAutoresizingMaskIntoConstraints
        rootViewController.preferredContentSize = rootViewController.view.frame.size
        viewController.view.frame = rootViewController.view.frame
        rootViewController.view.addSubview(viewController.view)

//        if viewController.view.translatesAutoresizingMaskIntoConstraints {
//            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        } else {
//            NSLayoutConstraint.activate([
//                viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
//                viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
//                viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
//                viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
//            ])
//        }
        rootViewController.addChild(viewController)
//    } else {
//        rootViewController = viewController
//    }
//    rootViewController.setOverrideTraitCollection(traits, forChild: viewController)
    viewController.didMove(toParent: rootViewController)
    window.rootViewController = rootViewController
    rootViewController.beginAppearanceTransition(true, animated: false)
    rootViewController.endAppearanceTransition()
    rootViewController.view.setNeedsLayout()
    rootViewController.view.layoutIfNeeded()
    viewController.view.setNeedsLayout()
    viewController.view.layoutIfNeeded()

    return {
        rootViewController.beginAppearanceTransition(false, animated: false)
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
        rootViewController.endAppearanceTransition()
        window.rootViewController = nil
    }

//    let rootViewController = UIViewController()
//    rootViewController.view.addSubview(viewController.view)
//    rootViewController.addChild(viewController)
//    viewController.didMove(toParent: rootViewController)
//
//    window.rootViewController = rootViewController
//
//    rootViewController.beginAppearanceTransition(true, animated: false)
//    rootViewController.endAppearanceTransition()
//
//    rootViewController.view.setNeedsLayout()
//    rootViewController.view.layoutIfNeeded()
//    return {
//        rootViewController.beginAppearanceTransition(false, animated: false)
//        rootViewController.willMove(toParent: nil)
//        rootViewController.view.removeFromSuperview()
//        rootViewController.removeFromParent()
//        rootViewController.didMove(toParent: nil)
//        rootViewController.endAppearanceTransition()
//        window.rootViewController = nil
//    }
}
*/

private func getKeyWindow() -> UIWindow? {
    var window: UIWindow?
    if #available(iOS 13.0, *) {
        window = UIApplication.sharedIfAvailable?.windows.first { $0.isKeyWindow }
    } else {
        window = UIApplication.sharedIfAvailable?.keyWindow
    }
    return window
}

private final class Window: UIWindow {
    var config: ViewImageConfig

    init(config: ViewImageConfig, viewController: UIViewController, interfaceStyle: UIUserInterfaceStyle) {
        let size = config.size ?? viewController.view.bounds.size
        self.config = config
        super.init(frame: .init(origin: .zero, size: size))

//        // NB: Safe area renders inaccurately for UI{Navigation,TabBar}Controller.
//        // Fixes welcome!
//        if viewController is UINavigationController {
//            self.frame.size.height -= self.config.safeArea.top
//            self.config.safeArea.top = 0
//        } else if let viewController = viewController as? UITabBarController {
//            self.frame.size.height -= self.config.safeArea.bottom
//            self.config.safeArea.bottom = 0
//            if viewController.selectedViewController is UINavigationController {
//                self.frame.size.height -= self.config.safeArea.top
//                self.config.safeArea.top = 0
//            }
//        }
        self.isHidden = false
        self.overrideUserInterfaceStyle = interfaceStyle
    }

    override var traitCollection: UITraitCollection {
        let superTraits = super.traitCollection
        return config.traits
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS 11.0, *)
    override var safeAreaInsets: UIEdgeInsets {
//        #if os(iOS)
//        let removeTopInset = self.config.safeArea == .init(top: 20, left: 0, bottom: 0, right: 0)
//        && self.rootViewController?.prefersStatusBarHidden ?? false
//        if removeTopInset { return .zero }
//        #endif
        return self.config.safeArea
    }
}
#endif

#if os(macOS)
import Cocoa

private final class ScaledWindow: NSWindow {
    override var backingScaleFactor: CGFloat {
        return 2
    }
}
#endif
#endif

extension Array {
    func sequence<A>() -> Async<[A]> where Element == Async<A> {
        guard !self.isEmpty else { return Async(value: []) }
        return Async<[A]> { callback in
            var result = [A?](repeating: nil, count: self.count)
            result.reserveCapacity(self.count)
            var count = 0
            zip(self.indices, self).forEach { idx, async in
                async.run {
                    result[idx] = $0
                    count += 1
                    if count == self.count {
                        callback(result as! [A])
                    }
                }
            }
        }
    }
}


final class ZeroInsetsViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

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
