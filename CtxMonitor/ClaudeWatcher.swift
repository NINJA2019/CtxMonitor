import Foundation
import Combine

struct TokenUsage: Identifiable {
    let id = UUID()
    let sessionId: String
    let timestamp: Date
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int

    var cacheRate: Double {
        totalTokens > 0 ? Double(cacheReadTokens) / Double(totalTokens) * 100 : 0
    }
}

class ClaudeWatcher: ObservableObject {
    @Published var usageHistory: [TokenUsage] = []
    @Published var isWatching = false

    private var timer: Timer?
    private var lastReadPosition: [String: Int] = [:]

    func start() {
        isWatching = true
        loadExistingData()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.checkForNewData()
        }
    }

    func stop() {
        isWatching = false
        timer?.invalidate()
        timer = nil
    }

    var todayHistory: [TokenUsage] {
        let start = Calendar.current.startOfDay(for: Date())
        return usageHistory.filter { $0.timestamp >= start }
    }

    var weekHistory: [TokenUsage] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return usageHistory.filter { $0.timestamp >= start }
    }

    func history(for period: TabPeriod) -> [TokenUsage] {
        switch period {
        case .day:   return todayHistory
        case .week:  return weekHistory
        case .total: return usageHistory
        }
    }

    func totalInput(_ h: [TokenUsage]) -> Int { h.reduce(0) { $0 + $1.inputTokens } }
    func totalOutput(_ h: [TokenUsage]) -> Int { h.reduce(0) { $0 + $1.outputTokens } }
    func totalCache(_ h: [TokenUsage]) -> Int { h.reduce(0) { $0 + $1.cacheReadTokens } }
    func turns(_ h: [TokenUsage]) -> Int { h.count }

    func avgInput(_ h: [TokenUsage]) -> Int { h.isEmpty ? 0 : totalInput(h) / h.count }
    func avgOutput(_ h: [TokenUsage]) -> Int { h.isEmpty ? 0 : totalOutput(h) / h.count }
    func avgCache(_ h: [TokenUsage]) -> Int { h.isEmpty ? 0 : totalCache(h) / h.count }

    func cacheRate(_ h: [TokenUsage]) -> Double {
        let total = h.reduce(0) { $0 + $1.totalTokens }
        let cache = h.reduce(0) { $0 + $1.cacheReadTokens }
        return total > 0 ? Double(cache) / Double(total) * 100 : 0
    }

    func sessionTrend(_ h: [TokenUsage]) -> String {
        let sids = Dictionary(grouping: h) { $0.sessionId }
        var improving = 0; var stable = 0; var increasing = 0
        for (_, turns) in sids {
            guard turns.count >= 4 else { stable += 1; continue }
            let half = turns.count / 2
            let first = Double(turns.prefix(half).reduce(0) { $0 + $1.totalTokens }) / Double(half)
            let second = Double(turns.suffix(turns.count - half).reduce(0) { $0 + $1.totalTokens }) / Double(turns.count - half)
            let diff = (second - first) / first * 100
            if diff < -10 { improving += 1 }
            else if diff > 10 { increasing += 1 }
            else { stable += 1 }
        }
        if improving > stable && improving > increasing { return "Improving" }
        if increasing > stable && increasing > improving { return "Increasing" }
        return "Stable"
    }

    private func projectsDir() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }

    private func allJsonlFiles() -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: projectsDir(),
            includingPropertiesForKeys: nil
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "jsonl" }
    }

    private func loadExistingData() {
        usageHistory = []
        lastReadPosition = [:]
        for file in allJsonlFiles() {
            parseFile(file, fromStart: true)
        }
        DispatchQueue.main.async {
            self.usageHistory.sort { $0.timestamp < $1.timestamp }
        }
    }

    private func checkForNewData() {
        for file in allJsonlFiles() {
            parseFile(file, fromStart: false)
        }
    }

    private func parseFile(_ url: URL, fromStart: Bool) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n")
        let key = url.path
        let startLine = fromStart ? 0 : (lastReadPosition[key] ?? 0)
        var newItems: [TokenUsage] = []

        for (i, line) in lines.enumerated() {
            guard i >= startLine, !line.isEmpty else { continue }
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String, type == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any],
                  let tsString = json["timestamp"] as? String
            else { continue }

            let input = usage["input_tokens"] as? Int ?? 0
            let output = usage["output_tokens"] as? Int ?? 0
            let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
            let cacheCreate = usage["cache_creation_input_tokens"] as? Int ?? 0
            let total = input + output + cacheRead + cacheCreate

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: tsString) else { continue }

            let sessionId = json["sessionId"] as? String ?? "unknown"
            newItems.append(TokenUsage(
                sessionId: sessionId,
                timestamp: date,
                inputTokens: input,
                outputTokens: output,
                cacheReadTokens: cacheRead + cacheCreate,
                totalTokens: total
            ))
        }

        lastReadPosition[key] = lines.count

        if !newItems.isEmpty {
            DispatchQueue.main.async {
                self.usageHistory.append(contentsOf: newItems)
                self.usageHistory.sort { $0.timestamp < $1.timestamp }
            }
        }
    }
}
