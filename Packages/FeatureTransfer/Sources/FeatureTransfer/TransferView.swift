import Combine
import DesignSystem
import SwiftUI

public struct TransferView: View {
    private struct FavoriteRecipient: Identifiable {
        let id: String
        let initials: String
        let name: String
        let bank: String
        let account: String
    }

    @ObservedObject private var viewModel: TransferViewModel
    @State private var searchText = ""

    private let recipients = [
        FavoriteRecipient(id: "1", initials: "AW", name: "ANDI WIJAYA", bank: "BANK DEMO A", account: "2710-••••-68"),
        FavoriteRecipient(id: "2", initials: "BS", name: "BUDI SANTOSO", bank: "BANK DEMO B", account: "5520-••••-7807"),
        FavoriteRecipient(id: "3", initials: "CL", name: "CITRA LESTARI", bank: "BANK DEMO C", account: "5859-••••-2809"),
        FavoriteRecipient(id: "4", initials: "DS", name: "DANIEL SETIAWAN", bank: "BANK DEMO D", account: "9010-••••-1168"),
        FavoriteRecipient(id: "5", initials: "EK", name: "EKA KURNIA", bank: "BANK DEMO E", account: "9002-••••-180")
    ]

    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            style: ScreenStyle(background: .white),
            onAction: viewModel.handlePresentationAction
        ) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    transferTypePicker

                    Text("INFORMASI PENERIMA")
                        .font(AppTypography.label)
                        .foregroundColor(AppColor.secondaryText.opacity(0.65))

                    searchField
                    newRecipientRow

                    Text("Favorit")
                        .font(AppTypography.heading)

                    LazyVStack(spacing: 0) {
                        ForEach(filteredRecipients) { recipient in
                            recipientRow(recipient)
                        }
                    }

                    if !viewModel.destinationAccount.isEmpty {
                        amountCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, AppSpacing.lg)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.destinationAccount)
        }
    }

    private var transferTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                transferChip("IDR", isSelected: true)
                transferChip("Rekening Saya", isSelected: false)
                transferChip("Valas", isSelected: false)
                transferChip("Proxy BI-FAST", isSelected: false)
            }
        }
    }

    private func transferChip(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(AppTypography.label)
            .foregroundColor(isSelected ? .white : AppColor.primaryText)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 44)
            .background(isSelected ? AppColor.brand : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isSelected ? AppColor.brand : AppColor.divider, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 21, weight: .medium))
                .foregroundColor(AppColor.brand)
            TextField("Cari nama penerima", text: $searchText)
                .font(AppTypography.body)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 58)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private var newRecipientRow: some View {
        Button(action: viewModel.didTapNewRecipient) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(
                        width: TransferStyle.accountIconSize,
                        height: TransferStyle.accountIconSize
                    )
                    .background(AppColor.charcoal.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Penerima Baru")
                        .font(AppTypography.heading)
                    Text("Tambah informasi rekening tujuan")
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.primaryText)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func recipientRow(_ recipient: FavoriteRecipient) -> some View {
        Button {
            viewModel.selectDestinationAccount(recipient.account)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text(recipient.initials)
                    .font(AppTypography.heading)
                    .foregroundColor(.white)
                    .frame(
                        width: TransferStyle.accountIconSize,
                        height: TransferStyle.accountIconSize
                    )
                    .background(AppColor.brand)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipient.name)
                        .font(AppTypography.heading)
                        .foregroundColor(AppColor.primaryText)
                    Text(recipient.bank)
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                    Text(recipient.account)
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                }

                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.yellow)
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Lanjutkan transfer")
                .font(AppTypography.heading)

            AppTextField(
                title: "Rekening tujuan",
                placeholder: "Masukkan nomor rekening",
                text: $viewModel.destinationAccount,
                keyboardType: .numberPad
            )

            AppTextField(
                title: "Nominal",
                placeholder: "Contoh: 100000",
                text: $viewModel.amount,
                keyboardType: .numberPad
            )

            PrimaryButton(
                "Lanjut",
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.destinationAccount.isEmpty && !viewModel.amount.isEmpty,
                action: viewModel.didTapReview
            )
        }
        .padding(AppSpacing.md)
        .background(TransferStyle.infoBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var filteredRecipients: [FavoriteRecipient] {
        guard !searchText.isEmpty else { return recipients }
        return recipients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.bank.localizedCaseInsensitiveContains(searchText)
        }
    }
}

/// Ownership boundary for the transfer screen. Popping the route releases this view, which
/// releases the ViewModel, whose `deinit` cancels the in-flight submit and completion tasks.
public struct TransferScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TransferViewModel

    public init(dependencies: any TransferDependencies) {
        _viewModel = StateObject(
            wrappedValue: TransferViewModel(
                submitTransfer: SubmitTransferUseCase(
                    repository: dependencies.makeTransferRepository()
                )
            )
        )
    }

    public var body: some View {
        TransferView(viewModel: viewModel)
            .onReceive(viewModel.$didFinish) { didFinish in
                guard didFinish else { return }
                dismiss()
            }
    }
}
