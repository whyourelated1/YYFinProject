import Foundation
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype,
                                   with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default
                .post(name: UIDevice.deviceDidShakeNotification,
                      object: nil)
        }
    }
}
