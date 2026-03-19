import SwiftUI
import Charts

enum TabPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case total = "Total"
}

struct StatCard: View {
    let title: String
    let value: Int
    let avg: Int?
    let color: Color
    var isCount = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(isCount ? "\(value)" : fmt(value))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
            if let avg = avg {
                Text("avg \(fmt(avg))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(color.opacity(0.6))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.16))
        .cornerRadius(8)
    }

    func fmt(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

struct CacheRateCard: View {
    let rate: Double

    var rateColor: Color {
        if rate >= 60 { return .green }
        if rate >= 30 { return .orange }
        return .red
    }

    var rateLabel: String {
        if rate >= 60 { return "Good" }
        if rate >= 30 { return "Fair" }
        return "Low"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cache-Rate")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f%%", rate))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(rateColor)
                Text(rateLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(rateColor)
            }
            Text("higher = better")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.16))
        .cornerRadius(8)
    }
}

struct AvgTrendCard: View {
    let history: [TokenUsage]
    let watcher: ClaudeWatcher

    var trendLabel: String { watcher.sessionTrend(history) }

    var trendColor: Color {
        switch trendLabel {
        case "Improving": return .green
        case "Increasing": return .red
        default: return .orange
        }
    }

    var avgPerTurn: Int {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.totalTokens } / history.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Avg/Turn trend")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(avgPerTurn >= 1000 ? String(format: "%.1fk", Double(avgPerTurn) / 1000) : "\(avgPerTurn)")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(trendColor)
                Text(trendLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(trendColor)
            }
            Text("per session majority vote")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.16))
        .cornerRadius(8)
    }
}

struct ContentView: View {
    @StateObject private var watcher = ClaudeWatcher()
    @State private var selectedPeriod: TabPeriod = .total

    var h: [TokenUsage] { watcher.history(for: selectedPeriod) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CtxMonitor")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Claude Code token usage")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TabPeriod.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                Button(watcher.isWatching ? "Stop" : "Start") {
                    watcher.isWatching ? watcher.stop() : watcher.start()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(watcher.isWatching ? .green : .purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(watcher.isWatching ? Color.green : Color.purple, lineWidth: 1)
                )
            }
            .padding()
            .background(Color(white: 0.1))

            HStack(spacing: 10) {
                StatCard(title: "Total-Text-Send", value: watcher.totalInput(h), avg: watcher.avgInput(h), color: .purple)
                StatCard(title: "AI-Reply", value: watcher.totalOutput(h), avg: watcher.avgOutput(h), color: .teal)
                StatCard(title: "Cache-Read", value: watcher.totalCache(h), avg: watcher.avgCache(h), color: .orange)
                StatCard(title: "Turns", value: watcher.turns(h), avg: nil, color: .gray, isCount: true)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color(white: 0.12))

            HStack(spacing: 10) {
                CacheRateCard(rate: watcher.cacheRate(h))
                AvgTrendCard(history: h, watcher: watcher)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(Color(white: 0.12))

            if h.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                    Text(watcher.isWatching ? "No data" : "Press Start")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.08))
            } else {
                Chart(h) { item in
                    LineMark(
                        x: .value("Time", item.timestamp),
                        y: .value("Total", item.totalTokens)
                    )
                    .foregroundStyle(Color.purple)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Time", item.timestamp),
                        y: .value("Total", item.totalTokens)
                    )
                    .foregroundStyle(Color.purple.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.month().day().hour(), centered: false)
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.gray)
                    }
                }
                .padding()
                .background(Color(white: 0.08))

                HStack(spacing: 16) {
                    Label("Total tokens / turn", systemImage: "circle.fill").foregroundColor(.purple)
                }
                .font(.system(size: 11))
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(white: 0.08))
            }
        }
        .background(Color(white: 0.08))
        .preferredColorScheme(.dark)
    }
}
