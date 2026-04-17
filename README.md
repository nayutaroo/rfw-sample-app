# flutter-experimental-app

[rfw (Remote Flutter Widgets)](https://pub.dev/packages/rfw) を使ったサーバードリブン UI の検証リポジトリ。

## ディレクトリ構成

```
.
├── app/              # Flutter アプリ (iOS / Android)
├── server/           # Go HTTP サーバー
│   ├── main.go
│   ├── rfw/          # RFW ウィジェット定義ソース (.rfwtxt)
│   └── static/       # 生成済みバイナリ (.rfw) ※gitignore
├── tools/
│   └── generate_rfw/ # .rfwtxt → .rfw 変換スクリプト (Dart)
├── mise.toml         # ツールバージョン管理 & タスク定義
└── .vscode/
    └── launch.json   # VS Code 実行設定
```

## セットアップ

```bash
mise install           # Flutter 3.41.5-stable / Go 1.25.8 をインストール
mise run install       # Flutter 依存パッケージを取得
mise run generate:rfw  # .rfwtxt → .rfw バイナリを生成
```

## 起動

```bash
# ターミナル 1: Go サーバーを起動
mise run server:run

# ターミナル 2: Flutter アプリを起動
mise run run
```

VS Code からは `⇧⌘D` → Debug / Profile / Release を選択して `F5`。

> **Android エミュレーター使用時の注意**
> `app/lib/config/server_config.dart` がエミュレーター向けに自動で `10.0.2.2:8080` に切り替えます。

## サーバー API

| メソッド | パス | 説明 |
|--------|------|------|
| GET | `/widgets/{name}` | バイナリ RFW を返す (`application/octet-stream`) |
| GET | `/data/products` | 商品一覧 JSON を返す |

## RFW ウィジェットの更新手順

1. `server/rfw/*.rfwtxt` を編集
2. `mise run generate:rfw` でバイナリを再生成
3. サーバーを再起動してアプリを hot reload

## mise タスク一覧

| タスク | 説明 |
|--------|------|
| `install` | Flutter 依存パッケージを取得 |
| `run` | アプリを起動 |
| `analyze` | 静的解析 |
| `test` | テスト実行 |
| `format` | コードフォーマット |
| `build-ios` | iOS リリースビルド |
| `build-android` | Android リリースビルド |
| `generate:rfw` | .rfwtxt → .rfw 変換 |
| `server:run` | Go サーバーを起動 |
| `server:build` | Go サーバーをビルド |
