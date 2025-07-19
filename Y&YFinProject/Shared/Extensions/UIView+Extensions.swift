import UIKit

extension UIView {
    enum Corner {
        case top
        case bottom
        case all
    }
    
    func roundCorners(_ corners: Corner, radius: CGFloat) {
        var maskedCorners: CACornerMask = []
        
        switch corners {
        case .top:
            maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .bottom:
            maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .all:
            maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                           .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        layer.cornerRadius = radius
        layer.maskedCorners = maskedCorners
        clipsToBounds = true
    }
}
