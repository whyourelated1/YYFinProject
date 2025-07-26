import UIKit

public class PieChartView: UIView {
  // MARK: – Константы цветов (6 штук)
  public static let segmentColors: [UIColor] = [
    UIColor(hex: "#2DD881")!, // зелёный
    UIColor(hex: "#FFEA29")!, // жёлтый
    UIColor(hex: "#FF6B6B")!, // красный
    UIColor(hex: "#4D8CFF")!, // синий
    UIColor(hex: "#A259FF")!, // фиолетовый
    UIColor(hex: "#BBBBBB")!  // серый для "Остальные"
  ]

  // Входные данные
  public var entities: [Entity] = [] {
    didSet {
      setNeedsDisplay()
      updateLegend()
    }
  }

  // Легенда
  private let legendStack = UIStackView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear

    legendStack.axis = .vertical
    legendStack.spacing = 4
    legendStack.alignment = .leading
    addSubview(legendStack)
    legendStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      legendStack.centerXAnchor.constraint(equalTo: centerXAnchor),
      legendStack.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  // Сводим более 5 элементов в "Остальные"
  private var displayEntities: [Entity] {
    guard entities.count > 5 else { return entities }
    let firstFive = entities.prefix(5)
    let othersValue = entities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
    return Array(firstFive) + [Entity(value: othersValue, label: "Остальные")]
  }

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let items  = displayEntities
        let total  = items.reduce(Decimal.zero) { $0 + $1.value }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.45

        var start = -CGFloat.pi / 2
        for (i, item) in items.enumerated() {
            let share = total == 0 ? 0 :
                CGFloat(NSDecimalNumber(decimal: item.value / total).doubleValue)

            let end = start + 2 * .pi * share
            ctx.setFillColor(PieChartView.segmentColors[i].cgColor)
            ctx.move(to: center)
            ctx.addArc(center: center, radius: radius,
                       startAngle: start, endAngle: end, clockwise: false)
            ctx.fillPath()
            start = end
        }

        ctx.setBlendMode(.clear)
        ctx.addArc(center: center,
                   radius: radius * 0.85,
                   startAngle: 0, endAngle: 2 * .pi,
                   clockwise: false)
        ctx.fillPath()
        ctx.setBlendMode(.normal)
    }


  private func updateLegend() {
    legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let items = displayEntities
    let total = items.reduce(Decimal(0)) { $0 + $1.value }

    for (i, item) in items.enumerated() {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 6
      row.alignment = .center

        let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = PieChartView.segmentColors[i]
            dot.layer.cornerRadius = 4
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8)
        ])

      let percent = total == 0
        ? 0.0
        : (item.value / total * 100) as NSDecimalNumber
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.text = String(
        format: "%.0f%% %@", percent.doubleValue, item.label
      )
      row.addArrangedSubview(dot)
      row.addArrangedSubview(label)

      legendStack.addArrangedSubview(row)
    }
  }
    private func drawEmptyState(in rect: CGRect, context ctx: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.4
        
        // Серый круг
        ctx.setFillColor(UIColor.systemGray5.cgColor)
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        ctx.fillPath()
        
        // Текст
        let text = "Нет данных"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.systemGray2
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: center.x - textSize.width / 2,
            y: center.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }
}
