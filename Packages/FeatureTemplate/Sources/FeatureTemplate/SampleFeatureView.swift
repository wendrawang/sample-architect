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

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColor.brand)
                } else if let content = viewModel.content {
                    VStack(spacing: AppSpacing.xs) {
                        Text(content.title)
                            .font(AppTypography.heading)
                        Text(content.message)
                            .font(AppTypography.body)
                            .foregroundColor(AppColor.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    SecondaryButton("Lihat Custom Action", action: viewModel.didTapInfo)
                        .frame(maxWidth: 280)
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
