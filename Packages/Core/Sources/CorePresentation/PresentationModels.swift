import Foundation

// Every model here holds only value types, but a public type never gets implicit
// `Sendable` inference — the conformance is API surface, so it has to be written out.

public enum PresentationActionRole: Equatable, Sendable {
    case primary
    case secondary
    case destructive
}

public struct PresentationAction: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let role: PresentationActionRole
    public let dismissesOnTap: Bool

    public init(
        id: String,
        title: String,
        role: PresentationActionRole = .primary,
        dismissesOnTap: Bool = true
    ) {
        self.id = id
        self.title = title
        self.role = role
        self.dismissesOnTap = dismissesOnTap
    }
}

public struct BottomSheetModel: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let iconSystemName: String?
    public let title: String
    public let message: String
    public let actions: [PresentationAction]
    public let isDismissible: Bool

    public init(
        id: UUID = UUID(),
        iconSystemName: String? = nil,
        title: String,
        message: String,
        actions: [PresentationAction],
        isDismissible: Bool = true
    ) {
        self.id = id
        self.iconSystemName = iconSystemName
        self.title = title
        self.message = message
        self.actions = actions
        self.isDismissible = isDismissible
    }
}

public struct ScreenBlockerModel: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let iconSystemName: String
    public let title: String
    public let message: String
    public let actions: [PresentationAction]

    public init(
        id: UUID = UUID(),
        iconSystemName: String = "exclamationmark.triangle.fill",
        title: String,
        message: String,
        actions: [PresentationAction]
    ) {
        self.id = id
        self.iconSystemName = iconSystemName
        self.title = title
        self.message = message
        self.actions = actions
    }
}

public struct SnackbarModel: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let message: String
    public let iconSystemName: String?
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        message: String,
        iconSystemName: String? = nil,
        duration: TimeInterval = 3
    ) {
        self.id = id
        self.message = message
        self.iconSystemName = iconSystemName
        self.duration = duration
    }
}

