import Combine
import CoreKit
import CorePresentation
import Foundation

public struct FinancialProduct: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let value: String
    public let change: String

    public init(id: String, name: String, value: String, change: String) {
        self.id = id
        self.name = name
        self.value = value
        self.change = change
    }
}

@MainActor
public final class FinancialViewModel: ObservableObject {
    public let presentation = ScreenPresentationStore()
    public let products: [FinancialProduct] = [
        FinancialProduct(id: "deposit", name: "Deposito", value: "Rp15.000.000", change: "+4,25% p.a."),
        FinancialProduct(id: "fund", name: "Reksa Dana", value: "Rp8.240.000", change: "+2,18%"),
        FinancialProduct(id: "bond", name: "Obligasi", value: "Rp5.000.000", change: "+6,10% p.a.")
    ]

    private let lifecycleProbe = LifecycleProbe("FinancialViewModel")

    public init() {}

    public func didTapRiskInfo() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "chart.line.uptrend.xyaxis.circle.fill",
                title: "Nilai portofolio",
                message: "Nilai investasi dapat naik atau turun mengikuti kondisi pasar.",
                actions: [PresentationAction(id: "understood", title: "Mengerti")]
            )
        )
    }
}

