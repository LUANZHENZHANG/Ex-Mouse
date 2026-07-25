import Foundation

struct CodexQuotaWindow: Codable, Equatable, Sendable {
    let usedPercent: Double
    let windowDurationMins: Int
    let resetsAt: TimeInterval

    var remainingPercent: Int {
        max(0, min(100, Int((100 - usedPercent).rounded())))
    }

    var windowName: String {
        switch windowDurationMins {
        case 0..<360:
            return "\(windowDurationMins) 分钟"
        case 360..<1_440:
            return "\(windowDurationMins / 60) 小时"
        case 1_440..<10_080:
            return "\(windowDurationMins / 1_440) 天"
        case 10_080:
            return "周"
        default:
            return "\(windowDurationMins / 1_440) 天"
        }
    }

    func menuTitle(now: Date = Date(), calendar: Calendar = .current) -> String {
        let resetDate = Date(timeIntervalSince1970: resetsAt)
        let resetText: String
        if calendar.isDate(resetDate, inSameDayAs: now) {
            resetText = resetDate.formatted(date: .omitted, time: .shortened)
        } else {
            resetText = resetDate.formatted(
                .dateTime.month(.defaultDigits).day().hour().minute()
            )
        }
        return "\(windowName)额度：剩余 \(remainingPercent)% · \(resetText) 重置"
    }
}

struct CodexQuotaSnapshot: Equatable, Sendable {
    let primary: CodexQuotaWindow
    let secondary: CodexQuotaWindow?
}

enum CodexQuotaError: LocalizedError {
    case executableNotFound
    case launchFailed(String)
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "未找到 Codex"
        case let .launchFailed(message):
            return "Codex 启动失败：\(message)"
        case let .server(message):
            return "Codex 返回错误：\(message)"
        case .invalidResponse:
            return "Codex 返回了无法识别的数据"
        }
    }
}

enum CodexQuotaClient {
    private struct Header: Decodable {
        let id: Int?
    }

    private struct Envelope: Decodable {
        struct Result: Decodable {
            struct RateLimits: Decodable {
                let primary: CodexQuotaWindow?
                let secondary: CodexQuotaWindow?
            }

            let rateLimits: RateLimits
        }

        struct ServerError: Decodable {
            let message: String
        }

        let id: Int?
        let result: Result?
        let error: ServerError?
    }

    static func decodeResponse(_ data: Data) throws -> CodexQuotaSnapshot? {
        let decoder = JSONDecoder()
        let header = try decoder.decode(Header.self, from: data)
        guard header.id == 2 else {
            return nil
        }
        let envelope = try decoder.decode(Envelope.self, from: data)
        if let error = envelope.error {
            throw CodexQuotaError.server(error.message)
        }
        guard let primary = envelope.result?.rateLimits.primary else {
            throw CodexQuotaError.invalidResponse
        }
        return CodexQuotaSnapshot(
            primary: primary,
            secondary: envelope.result?.rateLimits.secondary
        )
    }

    static func fetch() async throws -> CodexQuotaSnapshot {
        guard let executableURL = findExecutable() else {
            throw CodexQuotaError.executableNotFound
        }

        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw CodexQuotaError.launchFailed(error.localizedDescription)
        }

        defer {
            try? inputPipe.fileHandleForWriting.close()
            if process.isRunning {
                process.terminate()
            }
        }

        let requests = [
            #"{"method":"initialize","id":1,"params":{"clientInfo":{"name":"shunshu","title":"顺鼠","version":"1.0.0"}}}"#,
            #"{"method":"initialized","params":{}}"#,
            #"{"method":"account/rateLimits/read","id":2}"#,
        ].joined(separator: "\n") + "\n"
        inputPipe.fileHandleForWriting.write(Data(requests.utf8))

        do {
            for try await line in outputPipe.fileHandleForReading.bytes.lines {
                if let snapshot = try decodeResponse(Data(line.utf8)) {
                    return snapshot
                }
            }
        } catch let error as CodexQuotaError {
            throw error
        } catch {
            throw CodexQuotaError.invalidResponse
        }
        throw CodexQuotaError.invalidResponse
    }

    private static func findExecutable() -> URL? {
        var candidates: [String] = []
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            candidates.append(contentsOf: path.split(separator: ":").map { "\($0)/codex" })
        }
        candidates.append(contentsOf: [
            "/Applications/AI工具/ChatGPT.app/Contents/Resources/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ])

        return candidates.first(where: {
            FileManager.default.isExecutableFile(atPath: $0)
        }).map(URL.init(fileURLWithPath:))
    }
}
