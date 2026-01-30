# /imp - 実装開始コマンド

承認済みRFCに基づき、実装を開始せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「実装対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ作成

`feature/<slug>` ブランチが存在しない場合は `main` から作成せよ。既に存在する場合はチェックアウトせよ。

```bash
git checkout main
git pull --ff-only origin main 2>/dev/null || true
git checkout -b feature/<slug> 2>/dev/null || git checkout feature/<slug>
```

### Step 3: RFC読み込み・ステータス確認

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に `docs/rfcs/<slug>/rfc.md` を読み込め。ファイルが存在しない場合はエラーを報告して終了せよ。
RFC のステータスが「Accepted (承認済)」であることを確認せよ。承認済みでない場合は、ユーザに警告を表示し、続行するか確認せよ。

### Step 4: システム概要ドキュメント読み込み

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に、以下のシステム概要ドキュメントが存在する場合は読み込め（存在しないファイルはスキップ）:
- `docs/architecture.md`
- `docs/domain-model.md`
- `docs/api-overview.md`

### Step 5: 実装計画の策定

RFC の詳細設計・実装計画セクションを分析し、実装タスクを洗い出せ。以下を含めること:
- 変更・新規作成が必要なファイルの一覧
- 実装の依存順序
- 各タスクで作成するテストの概要

実装計画をユーザに提示し、承認を得てから着手せよ。

### Step 6: 実装

RFC の設計意図に忠実に実装せよ。以下のルールに従うこと:
- テストコードを必ず作成すること。
- RFC との乖離が必要になった場合は、先に RFC を更新すること。
- 実装中に設計上の問題を発見した場合は、ユーザに報告し判断を仰ぐこと。

### Step 7: テスト実行

プロジェクトのテストコマンドを実行し、全て通過することを確認せよ。失敗がある場合は修正してから次のステップに進むこと。

### Step 8: コミット & プッシュ & PR 作成

1. 変更ファイルをステージングする。
2. コミットメッセージは変更内容に応じた適切なプレフィックス（`feat:`, `fix:`, `test:` 等）を付けること。
3. `feature/<slug>` ブランチをリモートにプッシュする。
4. Draft PR が未作成の場合、以下の形式で作成する:

```bash
gh pr create --draft \
  --title "feat: <slug>" \
  --body "## Summary

RFC に基づく実装。

- **RFC**: \`docs/rfcs/<slug>/rfc.md\`
- **Branch**: \`feature/<slug>\`

---
このPRはAIレビュー完了後に Ready 状態になります。"
```

5. 実装した内容の要約をユーザに報告せよ。
