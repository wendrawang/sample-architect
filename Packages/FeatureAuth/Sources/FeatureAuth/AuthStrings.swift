import Foundation

/// Pengganti `R.string` dari R.swift, tanpa code generator dan tanpa build plugin.
///
/// Dua hal yang dijaga di sini:
///
/// 1. **Key tidak pernah ditulis di call site.** View memanggil `AuthStrings.usernameTitle`,
///    bukan mengetik ulang string key. Salah ketik jadi error compile, sama seperti dulu.
/// 2. **`bundle: .module`.** Ini yang paling sering terlewat di project modular: tanpa itu
///    Foundation mencari di `Bundle.main`, tidak menemukan apa-apa, lalu diam-diam
///    mengembalikan key mentahnya sebagai teks. Setiap package punya bundle sendiri.
enum AuthStrings {
    static var usernameTitle: String { local("auth.username.title") }
    static var usernameSubtitle: String { local("auth.username.subtitle") }
    static var usernameFieldTitle: String { local("auth.username.field.title") }
    static var usernameFieldPlaceholder: String { local("auth.username.field.placeholder") }
    static var usernameContinue: String { local("auth.username.continue") }
    static var usernameHelp: String { local("auth.username.help") }
    static var usernameHelpMessage: String { local("auth.username.help.message") }
    static var usernameHelpContact: String { local("auth.username.help.contact") }
    static var usernameHelpClose: String { local("auth.username.help.close") }
    static var usernameHelpInvoked: String { local("auth.username.help.invoked") }

    static var usernameHeroTitle: String { local("auth.username.hero.title") }
    static var usernameHeroSubtitle: String { local("auth.username.hero.subtitle") }
    static var usernameHeroAction: String { local("auth.username.hero.action") }
    static var usernameLocale: String { local("auth.username.locale") }
    static var usernameQuickTransfer: String { local("auth.username.quick.transfer") }
    static var usernameQuickCash: String { local("auth.username.quick.cash") }
    static var usernameQuickToken: String { local("auth.username.quick.token") }
    static var usernameQuickEMoney: String { local("auth.username.quick.emoney") }
    static var usernameQuickScan: String { local("auth.username.quick.scan") }
    static var usernameQuickPromo: String { local("auth.username.quick.promo") }

    static var passwordNavigationTitle: String { local("auth.password.navigationTitle") }
    static var passwordTitle: String { local("auth.password.title") }

    static var errorUsernameTooShort: String { local("auth.error.usernameTooShort") }
    static var errorPasswordTooShort: String { local("auth.error.passwordTooShort") }
    static var passwordFieldTitle: String { local("auth.password.field.title") }
    static var passwordFieldPlaceholder: String { local("auth.password.field.placeholder") }
    static var passwordForgot: String { local("auth.password.forgot") }
    static var passwordContinue: String { local("auth.password.continue") }
    static var passwordBiometricHint: String { local("auth.password.biometric.hint") }
    static var passwordHelpTitle: String { local("auth.password.help.title") }
    static var passwordHelpMessage: String { local("auth.password.help.message") }
    static var passwordHelpReset: String { local("auth.password.help.reset") }
    static var passwordHelpLater: String { local("auth.password.help.later") }
    static var passwordErrorTitle: String { local("auth.password.error.title") }
    static var passwordErrorRetry: String { local("auth.password.error.retry") }
    static var passwordErrorDismiss: String { local("auth.password.error.dismiss") }

    private static func local(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
