import SwiftUI

extension Color {
  // MARK: - Background

  /// Main app background (#1B2024).
  static let appBackground = Color(
    red: 0x1B / 255.0,
    green: 0x20 / 255.0,
    blue: 0x24 / 255.0
  )

  // MARK: - Dot colors

  /// Anonymous-edit green (#30DA59).
  static let dotGreen = Color(
    red: 0x30 / 255.0,
    green: 0xDA / 255.0,
    blue: 0x59 / 255.0
  )

  /// Bot-edit purple (#CC67CB).
  static let dotPurple = Color(
    red: 0xCC / 255.0,
    green: 0x67 / 255.0,
    blue: 0xCB / 255.0
  )

  /// Registered-user off-white (80% white blended with app background).
  static let dotWhite = Color(
    red: 0.80 + 0.20 * (0x1B / 255.0),
    green: 0.80 + 0.20 * (0x20 / 255.0),
    blue: 0.80 + 0.20 * (0x24 / 255.0)
  )

  // Dark variants (brightness × 0.3), used as fill for deletion bubbles.

  static let dotGreenDark = Color(
    red: 0x0E / 255.0,
    green: 0x41 / 255.0,
    blue: 0x1B / 255.0
  )

  static let dotPurpleDark = Color(
    red: 0x3D / 255.0,
    green: 0x1F / 255.0,
    blue: 0x3D / 255.0
  )

  static let dotWhiteDark = Color(white: 0.30)

  // MARK: - Overlay surfaces

  /// Article toast background.
  static let toastBackground = Color(white: 0.15)

  /// New-user banner cornflower blue (Hatnote: rgb(100,149,237)).
  static let newUserBanner = Color(
    red: 100 / 255.0,
    green: 149 / 255.0,
    blue: 237 / 255.0
  )
}
