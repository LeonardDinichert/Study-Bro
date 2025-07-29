import Foundation
import UIKit

final class FocusStatusCenter {
    static let shared = FocusStatusCenter()
    
    private init() {}
    
    enum FocusMode {
        case work
        // Future focus modes can be added here
    }
    
    /// Attempts to open the Focus settings page to activate the specified focus mode.
    /// Note: Due to iOS restrictions, direct programmatic activation of focus modes is not allowed.
    /// This function opens the Settings app's Focus page, where the user can manually activate the mode.
    /// - Throws: An error if the URL cannot be opened.
    func requestFocusModeActivation(_ mode: FocusMode) throws {
        guard let url = URL(string: "App-Prefs:root=Focus") else {
            throw NSError(domain: "FocusStatusCenter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for Focus settings"])
        }
        if !UIApplication.shared.canOpenURL(url) {
            // iOS might restrict opening this URL scheme
            throw NSError(domain: "FocusStatusCenter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot open Focus settings URL"])
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    /// Attempts to open the Focus settings page to deactivate the specified focus mode.
    /// Note: Due to iOS restrictions, direct programmatic deactivation of focus modes is not allowed.
    /// This function opens the Settings app's Focus page, where the user can manually deactivate the mode.
    /// - Throws: An error if the URL cannot be opened.
    func requestFocusModeDeactivation(_ mode: FocusMode) throws {
        guard let url = URL(string: "App-Prefs:root=Focus") else {
            throw NSError(domain: "FocusStatusCenter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for Focus settings"])
        }
        if !UIApplication.shared.canOpenURL(url) {
            // iOS might restrict opening this URL scheme
            throw NSError(domain: "FocusStatusCenter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot open Focus settings URL"])
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
