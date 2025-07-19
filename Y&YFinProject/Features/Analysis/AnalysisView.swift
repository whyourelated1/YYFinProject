import SwiftUI
import SwiftData

struct AnalysisView: UIViewControllerRepresentable {
    var direction: Direction
    var modelContainer: ModelContainer
    
    func makeUIViewController(context: Context) -> AnalysisVC {
        return AnalysisVC(direction: direction, modelContainer: modelContainer)
    }
    
    func updateUIViewController(_ uiViewController: AnalysisVC, context: Context) {}
}
