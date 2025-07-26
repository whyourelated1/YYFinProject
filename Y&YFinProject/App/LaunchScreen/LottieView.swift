import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var onFinished: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if uiView.isAnimationPlaying == false {
            uiView.play { finished in
                if finished {
                    onFinished?()
                }
            }
        }
    }
}

