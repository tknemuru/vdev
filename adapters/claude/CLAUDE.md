# CLAUDE.md

## Development Lifecycle
開発ライフサイクルの全体像は `~/projects/vdev/workflow/rfc-driven.md` に定義されています。各ステージの DoD・コマンド・運用ルールを参照してください。

## System Overview Documents（システム概要ドキュメント）

リポジトリごとに以下の3ドキュメントを `docs/` 配下に配置する規約とする。IEEE 1016 Software Design Description の3ビューポイント（Structure / Data / Interface）に対応し、システムの全体像を簡潔に記述する。

| ドキュメント | 目的 | 記載内容 |
|---|---|---|
| `docs/architecture.md` | システム構造の把握 | ディレクトリ構成、レイヤー構造、依存関係、技術選定、デプロイ構成 |
| `docs/domain-model.md` | ドメイン概念・データの把握 | ドメイン概念と関係、業務ルール・制約、状態遷移、データ永続化（DB設計） |
| `docs/api-overview.md` | インターフェース設計の把握 | エンドポイント一覧、認証方式、共通パターン、エラーハンドリング規約 |

既存リポジトリやリポジトリの特性上不要な場合は省略可とする。各コマンドは存在するドキュメントのみ参照する。
