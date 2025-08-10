import SwiftUI
import Combine


struct AppTheme {
    /// Main brand color
    static let primaryColor = Color(hex: "#FFB660")
    /// 10% lighter tint of the primary color
    static let primaryTint = Color(hex: "#FFC86A")
    /// 10% darker shade of the primary color
    static let primaryShade = Color(hex: "#E6A456")

    /// Neutral backgrounds
    static let background = Color(light: .white, dark: .black)
    static let cardBackground = Color(light: Color(hex: "#F8F8F8"),
                                      dark: Color(hex: "#1C1C1E"))

    static let cornerRadius: CGFloat = 12

    struct CardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .glassEffect()
                //.clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(AppTheme.CardModifier())
    }

}

extension Color {
    /// Create a color from a hex string like "#FFAA00"
    init(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Convenience initializer for dynamic light/dark colors
    init(light: Color, dark: Color) {
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
