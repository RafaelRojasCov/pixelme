/// Onboarding window shown when required permissions are missing.

#if os(macOS)
import AppKit
import PixelMeCore

public final class PermissionsOnboardingWindowController: NSWindowController {

    private let missingPermissions: [PermissionType]
    private let provider: PermissionsProvider

    public init(missingPermissions: [PermissionType], provider: PermissionsProvider) {
        self.missingPermissions = missingPermissions
        self.provider = provider

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PixelMe – Permissions Required"
        window.center()
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("Use init(missingPermissions:provider:)") }

    // MARK: UI construction

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        let titleLabel = makeLabel(
            "Permissions Required",
            fontSize: 18, bold: true
        )
        stack.addArrangedSubview(titleLabel)

        let bodyText = missingPermissions.map { permission -> String in
            switch permission {
            case .screenRecording:
                return "• Screen Recording – needed to read pixel data from other apps."
            case .accessibility:
                return "• Accessibility – needed for global keyboard monitoring and zoom detection."
            }
        }.joined(separator: "\n")

        let bodyLabel = makeLabel(bodyText, fontSize: 13)
        bodyLabel.maximumNumberOfLines = 0
        stack.addArrangedSubview(bodyLabel)

        let grantButton = NSButton(title: "Grant Permissions", target: self,
                                   action: #selector(grantTapped))
        grantButton.bezelStyle = .rounded
        grantButton.keyEquivalent = "\r"
        stack.addArrangedSubview(grantButton)

        window?.contentView = stack
    }

    @objc private func grantTapped() {
        for permission in missingPermissions {
            provider.requestPermission(permission)
        }
        close()
    }

    // MARK: Helper

    private func makeLabel(_ text: String, fontSize: CGFloat, bold: Bool = false) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
        field.isEditable = false
        field.isBordered = false
        field.backgroundColor = .clear
        return field
    }
}
#endif
