import SwiftUI
import UIKit

final class ShakeDetector: UIView {

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype,
                              with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

struct ShakeDetectorView: UIViewRepresentable {

    func makeUIView(context: Context) -> ShakeDetector {
        ShakeDetector()
    }

    func updateUIView(_ uiView: ShakeDetector, context: Context) {
        if uiView.window != nil && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
}
