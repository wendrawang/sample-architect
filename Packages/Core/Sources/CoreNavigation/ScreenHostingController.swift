import CoreKit
import SwiftUI
import UIKit

@MainActor
public final class ScreenHostingController<Content: View>: UIHostingController<Content> {
    public var onPopped: (() -> Void)?
    private let hidesNavigationBar: Bool
    private let lifecycleProbe: LifecycleProbe

    public init(
        rootView: Content,
        title: String? = nil,
        hidesNavigationBar: Bool = false
    ) {
        self.hidesNavigationBar = hidesNavigationBar
        lifecycleProbe = LifecycleProbe("ScreenHostingController<\(Content.self)>")
        super.init(rootView: rootView)
        self.title = title
        view.backgroundColor = .systemBackground
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(hidesNavigationBar, animated: animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard isMovingFromParent || navigationController?.isBeingDismissed == true else { return }
        let callback = onPopped
        onPopped = nil
        callback?()
    }
}

public enum NavigationAppearance {
    @MainActor
    public static func applyGlobalStyle() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.91, green: 0.03, blue: 0.08, alpha: 1)
    }
}
