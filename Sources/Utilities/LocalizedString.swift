import Foundation

func localized(_ key: String) -> String {
    // Try SwiftPM resource bundle (nested inside .app during development)
    if let path = Bundle.main.path(forResource: "ClaudeOverlay_ClaudeOverlay", ofType: "bundle"),
       let bundle = Bundle(path: path) {
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    // Try Bundle.module (for swift run)
    let value = NSLocalizedString(key, bundle: .module, comment: "")
    if value != key {
        return value
    }
    // Fallback to main bundle (for standalone .app with .lproj in Resources)
    return NSLocalizedString(key, bundle: .main, comment: "")
}
