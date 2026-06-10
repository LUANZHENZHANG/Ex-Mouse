import Foundation

final class ScrollController {
    private let backend: ScrollBackend

    init(onStateChanged: @escaping () -> Void) {
        self.backend = NextScrollBackend(onStateChanged: onStateChanged)
    }

    var backendName: String { backend.name }
    var isListening: Bool { backend.isListening }
    var lastDebugMessage: String { backend.lastDebugMessage }

    func start() { backend.start() }
    func stop() { backend.stop() }
}
