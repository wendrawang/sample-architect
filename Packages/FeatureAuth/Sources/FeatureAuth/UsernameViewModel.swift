import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class UsernameViewModel: ObservableObject {
    @Published public var username = ""
    public let presentation = ScreenPresentationStore()

    public var canContinue: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    private let validateUsername: any ValidateUsernameUseCaseProtocol
    private let onContinue: (String) -> Void
    private let lifecycleProbe = LifecycleProbe("UsernameViewModel")

    public init(
        validateUsername: any ValidateUsernameUseCaseProtocol,
        onContinue: @escaping (String) -> Void
    ) {
        self.validateUsername = validateUsername
        self.onContinue = onContinue
    }

    public func didTapContinue() {
        do {
            onContinue(try validateUsername.execute(username))
        } catch {
            presentation.show(
                snackbar: SnackbarModel(
                    message: error.localizedDescription,
                    iconSystemName: "exclamationmark.circle.fill"
                )
            )
        }
    }

    public func didTapHelp() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "questionmark.circle.fill",
                title: AuthStrings.usernameHelp,
                message: AuthStrings.usernameHelpMessage,
                actions: [
                    PresentationAction(id: "contact-support", title: AuthStrings.usernameHelpContact),
                    PresentationAction(id: "close", title: AuthStrings.usernameHelpClose, role: .secondary)
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        guard id == "contact-support" else { return }
        presentation.show(
            snackbar: SnackbarModel(
                message: AuthStrings.usernameHelpInvoked,
                iconSystemName: "checkmark.circle.fill"
            )
        )
    }
}
