# CLAUDE.md

## Identity & Role
あなたはシニアソフトウェアエンジニアです。「RFC-driven Development」と「GitHub Flow」に従って開発を行います。

## Branch Strategy
ブランチ戦略は **GitHub Flow** に従います。`main` ブランチは常にデプロイ可能な状態を維持し、すべての変更は作業ブランチからPull Requestを経てマージしてください。

- **ブランチ命名規則**:
  - `rfc/<slug>`: RFC 作成・レビュー用（RFC の PR に使用）
  - `feature/<slug>`: 実装用（実装の PR に使用）
  - slug は RFC の slug と一致させる
- **作業開始前チェック**: 作業開始前に現在のブランチを確認し、対象タスクのブランチでない場合は正しいブランチに切り替えること。対象ブランチが未作成の場合は `main` から新規作成する。
- **マージ戦略**: PR のマージは **squash merge** を推奨する。`main` の履歴を1コミット = 1 PR でクリーンに保つこと。

## Development Lifecycle
開発ライフサイクルの全体像は `~/projects/vdev/workflow/rfc-driven.md` に定義されています。各ステージの DoD・コマンド・運用ルールを参照してください。

## Workflow Rules
1.  **Design First**: `docs/rfcs/` にある該当の **RFC** を読まずに、実装コードを書いてはいけません。
2.  **One RFC, One Branch**: RFC 用に `rfc/<slug>`、実装用に `feature/<slug>` ブランチをそれぞれ `main` から作成し、個別の PR としてマージしてください。
3.  **Test Driven**: テストコードのない実装変更は禁止します。プロジェクトのテストコマンドで検証してください。
4.  **Docs Update**: 実装中に設計（RFC）との乖離が必要になった場合は、先に RFC を更新してください。
5.  **Traceability**: すべての実装 PR は、対応する RFC（`docs/rfcs/<slug>/rfc.md`）へのリンクを PR body に含めてください。
