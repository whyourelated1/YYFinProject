import SwiftUICore
import UIKit

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIDevice.deviceDidShakeNotification)
            ) { _ in action() }
    }
}

extension View {
    //выполнить при встряске
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
}
