import UIKit
public extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1) {
        let s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        guard s.count == 6 else { return nil }

        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)

        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >>  8) & 0xFF) / 255
        let b = CGFloat( int        & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
