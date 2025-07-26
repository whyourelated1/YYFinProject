import SwiftUI
import SwiftData

struct AnalysisViewControllerWrapper: UIViewControllerRepresentable {
    let client: NetworkClient
    let accountId: Int
    let direction: Direction
    let modelContainer: ModelContainer

    func makeUIViewController(context: Context) -> UIViewController {
        return AnalysisViewController(
            client: client,
            accountId: accountId,
            direction: direction,
            modelContainer: modelContainer
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
