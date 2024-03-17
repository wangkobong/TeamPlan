// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Gen {
  internal enum Colors {
    internal static let blackColor = ColorAsset(name: "BlackColor")
    internal static let darkGreyColor = ColorAsset(name: "DarkGreyColor")
    internal static let greyColor = ColorAsset(name: "GreyColor")
    internal static let mainBlueColor = ColorAsset(name: "MainBlueColor")
    internal static let mainPurpleColor = ColorAsset(name: "MainPurpleColor")
    internal static let warningRedColor = ColorAsset(name: "WarningRedColor")
    internal static let whiteColor = ColorAsset(name: "WhiteColor")
    internal static let whiteGreyColor = ColorAsset(name: "WhiteGreyColor")
  }
  internal enum Images {
    internal static let alertDidChallengeRectangleBlue = ImageAsset(name: "alert_didChallenge_rectangle_blue")
    internal static let alertDidChallengeRectangleGrey = ImageAsset(name: "alert_didChallenge_rectangle_grey")
    internal static let alertDidChallengeRectanglePlus = ImageAsset(name: "alert_didChallenge_rectangle_plus")
    internal static let alertDidChallengeRed = ImageAsset(name: "alert_didChallenge_red")
    internal static let alertDidChallengeX = ImageAsset(name: "alert_didChallenge_x")
    internal static let alertDidChallengeYellow1 = ImageAsset(name: "alert_didChallenge_yellow1")
    internal static let alertDidChallengeYellow2 = ImageAsset(name: "alert_didChallenge_yellow2")
    internal static let guideImage1 = ImageAsset(name: "guide_image1")
    internal static let guideImage2 = ImageAsset(name: "guide_image2")
    internal static let guideImage3 = ImageAsset(name: "guide_image3")
    internal static let guideImage4 = ImageAsset(name: "guide_image4")
    internal static let guideImage5 = ImageAsset(name: "guide_image5")
    internal static let bookCircleBlue = ImageAsset(name: "book_circle_blue")
    internal static let bookCircleGrey = ImageAsset(name: "book_circle_grey")
    internal static let calendarCircleBlue = ImageAsset(name: "calendar_circle_blue")
    internal static let calendarCircleGrey = ImageAsset(name: "calendar_circle_grey")
    internal static let dropCircleBlue = ImageAsset(name: "drop_circle_blue")
    internal static let dropCircleGrey = ImageAsset(name: "drop_circle_grey")
    internal static let folderCircleCheckBlue = ImageAsset(name: "folder_circle_check_blue")
    internal static let folderCircleCheckGrey = ImageAsset(name: "folder_circle_check_grey")
    internal static let folderCirclePlusBlue = ImageAsset(name: "folder_circle_plus_blue")
    internal static let folderCirclePlusGrey = ImageAsset(name: "folder_circle_plus_grey")
    internal static let lockIcon = ImageAsset(name: "lock_icon")
    internal static let pencilCircleBlue = ImageAsset(name: "pencil_circle_blue")
    internal static let pencilCircleGrey = ImageAsset(name: "pencil_circle_grey")
    internal static let plusCircle = ImageAsset(name: "plus_circle")
    internal static let bombNoti = ImageAsset(name: "bomb_noti")
    internal static let checkNoti = ImageAsset(name: "check_noti")
    internal static let paperNoti = ImageAsset(name: "paper_noti")
    internal static let penNoti = ImageAsset(name: "pen_noti")
    internal static let powerNoti = ImageAsset(name: "power_noti")
    internal static let account = ImageAsset(name: "account")
    internal static let addChallengeText = ImageAsset(name: "add_challenge_text")
    internal static let bomb = ImageAsset(name: "bomb")
    internal static let bombSmile = ImageAsset(name: "bomb_smile")
    internal static let chevronRight = ImageAsset(name: "chevron_right")
    internal static let document = ImageAsset(name: "document")
    internal static let house = ImageAsset(name: "house")
    internal static let leftArrowHome = ImageAsset(name: "left_arrow_home")
    internal static let rightArrowHome = ImageAsset(name: "right_arrow_home")
    internal static let titleHome = ImageAsset(name: "title_home")
    internal static let warningCircle = ImageAsset(name: "warning_circle")
    internal static let waterdrop = ImageAsset(name: "waterdrop")
    internal static let waterdropReverse = ImageAsset(name: "waterdrop_reverse")
    internal static let waterdropSide = ImageAsset(name: "waterdrop_side")
    internal static let image = ImageAsset(name: "Image")
    internal static let teamplan = ImageAsset(name: "TEAMPLAN")
    internal static let launchImage = ImageAsset(name: "launchImage")
    internal static let appleLogo = ImageAsset(name: "appleLogo")
    internal static let loginView = ImageAsset(name: "loginView")
    internal static let pencil = ImageAsset(name: "Pencil")
    internal static let time = ImageAsset(name: "Time")
    internal static let onboarding1 = ImageAsset(name: "onboarding_1")
    internal static let onboarding2 = ImageAsset(name: "onboarding_2")
    internal static let onboarding3 = ImageAsset(name: "onboarding_3")
    internal static let onboarding4 = ImageAsset(name: "onboarding_4")
    internal static let checkBoxDone = ImageAsset(name: "checkBox_done")
    internal static let checkBoxNone = ImageAsset(name: "checkBox_none")
    internal static let projectBombSmile = ImageAsset(name: "project_bomb_smile")
    internal static let projectEmpty = ImageAsset(name: "project_empty")
    internal static let projectMenuBtn = ImageAsset(name: "project_menu_btn")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
