import UIKit
import Lottie

final class SplashViewController: UIViewController {

    private let animationView = LottieAnimationView(name: "PigIllustration")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        animationView.contentMode = .scaleAspectFit
        animationView.loopMode   = .playOnce
        animationView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animationView.play { [weak self] finished in
            guard finished else { return }
            self?.showMainInterface()
        }
    }

    private func showMainInterface() {
        let mainVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()!
        mainVC.modalTransitionStyle = .crossDissolve
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true)
    }
}
