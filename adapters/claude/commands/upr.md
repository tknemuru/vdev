# /upr - PRコメント対応コマンド

人間による PR レビューコメントに基づき、RFC・コードを修正せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ確認

現在のブランチが `feature/<slug>` であることを確認せよ。異なる場合は `feature/<slug>` にチェックアウトせよ。

### Step 3: PR コメント取得

`gh` CLI を使用して、`feature/<slug>` ブランチの PR コメントを取得せよ。

```bash
gh pr view feature/<slug> --comments --json comments,reviews
```

コメントが存在しない場合は「対応すべき PR コメントはありません。」と報告して終了せよ。

### Step 4: RFC・コードの読み込み

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に以下を読み込め:
- `docs/rfcs/<slug>/rfc.md`（RFC本文）
- 実装差分（以下のコマンドで取得。レビュー関連ファイルを除外する）

```bash
git diff main...HEAD -- . ':!docs/rfcs/*/review-*.md'
```

### Step 5: コメント分析

PR コメントを分析し、修正対象を分類せよ:
- RFC に対する指摘 → `docs/rfcs/<slug>/rfc.md` を修正
- コードに対する指摘 → 該当ソースコードを修正
- 質問・確認事項 → ユーザに報告し判断を仰ぐ

### Step 6: 修正

1. `~/projects/vdev/prompts/roles/rfc-author.md` を読み込み、RFC 修正時はその人格に従う。
2. RFC の修正が必要な場合は、設計意図を維持しつつ指摘を反映する。
3. コードの修正が必要な場合は、RFC の設計意図に忠実に対応する。
4. テストコードの修正・追加が必要な場合は対応する。

### Step 7: テスト実行

コードを修正した場合は、プロジェクトのテストコマンドを実行し全て通過することを確認せよ。

### Step 8: コミット & プッシュ

1. 変更ファイルをステージングする。
2. コミットメッセージは変更内容に応じた適切なプレフィックス（`fix:`, `refactor:`, `docs:` 等）を付けること。
3. `feature/<slug>` ブランチをリモートにプッシュする。
4. 修正内容の要約をユーザに報告せよ。
