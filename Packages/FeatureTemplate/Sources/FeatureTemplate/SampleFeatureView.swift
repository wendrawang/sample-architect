import DesignSystem
import SwiftUI

public struct SampleFeatureView: View {
    @ObservedObject private var viewModel: SampleFeatureViewModel

    public init(viewModel: SampleFeatureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            onAction: viewModel.handlePresentationAction
        ) {
            VStack(spacing: SampleFeatureStyle.contentSpacing) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 48))
                    .foregroundColor(SampleFeatureStyle.heroColor)
                Text(viewModel.value)
                    .font(AppTypography.heading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

