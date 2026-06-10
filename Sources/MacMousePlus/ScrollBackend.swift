import Foundation

protocol ScrollBackend: AnyObject {
    var name: String { get }
    var isListening: Bool { get }
    var lastDebugMessage: String { get }

    func start()
    func stop()
}
