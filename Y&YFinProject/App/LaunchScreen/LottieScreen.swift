import SwiftUI

struct SplashScreen: View {
    let onFinish: () -> Void

    var body: some View {
        LottieView(name: "PigIllustration", onFinished: onFinish)
            .ignoresSafeArea()          // растягиваем на весь экран
            .background(Color.white)     // тот же цвет, что у LaunchScreen
    }
}
