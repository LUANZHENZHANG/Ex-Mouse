import Foundation

@main
enum SystemShortcutScriptCheck {
    static func main() {
        let expectedScripts: [(SystemShortcutScript.Action, String)] = [
            (.previousDesktop, "tell application \"System Events\"\n    key code 123 using control down\nend tell"),
            (.nextDesktop, "tell application \"System Events\"\n    key code 124 using control down\nend tell"),
            (.zoomIn, "tell application \"System Events\"\n    key code 24 using {command down, shift down}\nend tell"),
            (.zoomOut, "tell application \"System Events\"\n    key code 27 using command down\nend tell"),
        ]

        for (action, expectedScript) in expectedScripts {
            guard SystemShortcutScript.source(for: action) == expectedScript else {
                fputs("System shortcut script check failed\\n", stderr)
                exit(EXIT_FAILURE)
            }
        }
        print("System shortcut script check passed")
    }
}
