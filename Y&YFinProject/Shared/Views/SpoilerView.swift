import SwiftUI

final class EmitterView: UIView {

    override class var layerClass: AnyClass { CAEmitterLayer.self }
    override var layer: CAEmitterLayer { super.layer as! CAEmitterLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let cell = CAEmitterCell()
        cell.contents      = UIImage(named: "textSpeckle_Normal")?.cgImage
        cell.color         = UIColor.label.cgColor
        cell.alphaRange    = 0.30
        cell.alphaSpeed    = -1
        cell.emissionRange = .pi * 2
        cell.lifetime      = 1.1
        cell.scale         = 0.55
        cell.velocityRange = 25
        cell.birthRate     = 600

        layer.emitterShape = .rectangle
        layer.emitterCells = [cell]
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.emitterPosition = .init(x: bounds.midX, y: bounds.midY)
        layer.emitterSize     = bounds.size
    }
}

private struct InvisibleInk: UIViewRepresentable {
    let active: Bool
    func makeUIView(context: Context) -> EmitterView { EmitterView() }
    func updateUIView(_ v: EmitterView, context: Context) {
        if active { v.layer.beginTime = CACurrentMediaTime() }
        v.layer.birthRate = active ? 1 : 0
    }
}

private struct SpoilerModifier: ViewModifier {
    @Binding var active: Bool
    func body(content: Content) -> some View {
        content
            .opacity(active ? 0 : 1)
            .overlay(InvisibleInk(active: active))
            .animation(.default, value: active)
    }
}

extension View {
    func spoiler(isOn: Binding<Bool>) -> some View {
        modifier(SpoilerModifier(active: isOn))
    }
}
