# CtxMonitor

**Claude Code のトークン使用量を可視化する macOS アプリ**  
A macOS app that visualizes token usage from Claude Code sessions.

---

## スクリーンショット / Screenshot

> Day / Week / Total の期間切り替えとセッション別トレンド分析

---

## 概要 / Overview

**日本語**  
CtxMonitor は、Claude Code が `~/.claude/projects/` に記録する JSONL ログを読み込み、トークン消費量をリアルタイムでグラフ表示する macOS アプリです。セッションをまたいだ傾向分析により、プロンプトの効率改善に役立てることができます。

**English**  
CtxMonitor reads the JSONL logs that Claude Code writes to `~/.claude/projects/` and displays token usage as a real-time graph. Session-aware trend analysis helps you improve prompt efficiency over time.

---

## 機能 / Features

| 機能 | 説明 |
|------|------|
| Total-Text-Send | 入力トークン数の集計 / Input token count |
| AI-Reply | 出力トークン数の集計 / Output token count |
| Cache-Read | キャッシュ読み込みトークン数 / Cache read tokens |
| Turns | セッション内のターン数 / Number of turns |
| Cache-Rate | キャッシュ活用率（高いほど効率的）/ Cache utilization rate |
| Avg/Turn trend | セッション単位の消費傾向（多数決判定）/ Per-session trend (majority vote) |
| Day / Week / Total | 期間別フィルタリング / Period filtering |

---

## 必要環境 / Requirements

- macOS 13 (Ventura) 以上 / macOS 13 or later
- [Claude Code](https://claude.ai/code) がインストール済みであること / Claude Code installed
- Xcode 15 以上（ビルドする場合）/ Xcode 15+ (for building from source)

---

## インストール / Installation

### ソースからビルド / Build from source
```bash
git clone https://github.com/YOUR_USERNAME/CtxMonitor.git
cd CtxMonitor
open CtxMonitor.xcodeproj
```

Xcode で `Product → Run`（⌘R）を実行してください。  
In Xcode, run `Product → Run` (⌘R).

**注意 / Note:**  
App Sandbox を無効にしてください（`~/.claude/` へのアクセスに必要）。  
Disable App Sandbox in `CtxMonitor.entitlements` (required for `~/.claude/` access).

---

## 仕組み / How it works

Claude Code は各セッションのやり取りを `~/.claude/projects/<project>/**.jsonl` に記録します。  
CtxMonitor はこのファイルを3秒ごとに監視し、`type: "assistant"` のレコードから `usage` フィールドを抽出してグラフ化します。

Claude Code records each session to `~/.claude/projects/<project>/**.jsonl`.  
CtxMonitor watches these files every 3 seconds and extracts `usage` fields from `type: "assistant"` records.

---

## 指標の注意事項 / Metric notes

- **Cache-Rate の閾値（Good/Fair/Low）は参考値です。** 公式ベンチマークは存在しません。  
  Cache-Rate thresholds (Good/Fair/Low) are approximate — no official benchmark exists.
- **Total-Text-Send はキャッシュ差分のため実際より少なく表示される場合があります。**  
  Total-Text-Send may be understated due to cache differential reporting by the API.
- **Avg/Turn trend はセッション単位の多数決で判定します。**  
  Avg/Turn trend uses per-session majority vote, not raw total comparison.

---

## ライセンス / License

MIT

---

## 作者 / Author

[@ninnin8672](https://note.com/ninnin8672)
