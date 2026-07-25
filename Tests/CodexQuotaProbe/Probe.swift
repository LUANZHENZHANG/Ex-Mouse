import Foundation

@main
struct CodexQuotaProbe {
    static func main() async {
        do {
            let snapshot = try await CodexQuotaClient.fetch()
            print("remaining=\(snapshot.primary.remainingPercent)")
            print("window=\(snapshot.primary.windowDurationMins)")
            print("reset=\(Int(snapshot.primary.resetsAt))")
        } catch {
            FileHandle.standardError.write(Data("error=\(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
