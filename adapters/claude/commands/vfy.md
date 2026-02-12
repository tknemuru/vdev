# /vfy - Verification 実行コマンド

実装済みコードに対し、RFC の Goals 達成確認（Verification）を独立して実行する。実装エージェントとは異なるセッションで検証を行うことで、確証バイアスを排除する。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「検証対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ確認

現在のブランチが `feature/<slug>` であることを確認せよ。異なる場合は `feature/<slug>` にチェックアウトせよ。

### Step 3: RFC 読み込みと Verification 抽出

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に、`docs/rfcs/<slug>/rfc.md` を読み込め。

RFC ファイルが存在しない場合はエラーを報告して終了せよ。

以下を抽出せよ:
- Goals テーブルから全 Goal の `#`、`Goal`、`達成確認方法 (Verification)` を抽出する。
- テスト戦略セクション（セクション5）から全テスト項目を抽出する。

### Step 4: テスト充足確認

テスト戦略に記載された全テストが実装されているか確認せよ。

1. テスト戦略の各テスト項目について、対応するテストコードが存在するか確認する。
2. プロジェクトのテストコマンドを実行し、全テストが通過することを確認する。
3. テスト不足・失敗がある場合は FAIL として記録し、Step 5 の Verification 実行には進まない。FAIL 項目を報告して終了せよ。

### Step 5: Verification 実行

各 Goal の Verification を順に実行し、結果を PASS/FAIL + エビデンスとして記録する。

実行ルール:
- Verification に記載されたコマンド・手順を**そのまま実行**せよ。
- 「目視確認」「記載があること」等の確認は、対象ファイルの該当箇所を Read で読み込み、期待する内容が存在することを引用で示せ。
- **「〜を追記済み」「〜を実装済み」はエビデンスとして認めない。** 実装したことは diff から自明であり、Verification の目的は「実装した結果として目的が達成されたか」の確認である。
- 副作用を伴う操作は実行前にユーザに承認を求め、承認を得た上で実行せよ。
- **Verification の実行をスキップし、後続の人間作業として残すことは禁止する。** すべての Verification はこの Step で完了させること。

### Step 6: 結果ファイル書き出し

結果を以下の形式で `docs/rfcs/<slug>/verification-results.md` に書き出せ:

```markdown
# Verification Results

| # | Goal | Verification | 結果 | エビデンス |
|---|------|-------------|------|-----------|
| G1 | {Goal内容} | {確認方法} | PASS / FAIL | {実行コマンドの出力、ファイル該当箇所の引用等} |
```

### Step 7: PR body 更新

`gh pr edit` で PR body に Verification 結果テーブルを追記せよ。既存の「## Verification Results」セクションがある場合は置換せよ。

```bash
# 現在の PR body を取得
CURRENT_BODY=$(gh pr view --json body --jq '.body')

# Verification 結果セクションを追記または置換
gh pr edit --body "{更新後の body}"
```

### Step 8: コミット & プッシュ

1. `docs/rfcs/<slug>/verification-results.md` をステージングする。
2. コミットメッセージ: `docs: add verification results for <slug>`
3. `feature/<slug>` ブランチをリモートにプッシュする。

### Step 9: 結果報告

- 全 PASS の場合: 「全 Verification が PASS しました。`/rimp <slug>` でレビューを実行してください。」と報告する。
- FAIL がある場合: FAIL 項目を一覧表示し、「FAIL の項目を修正後、`/vfy <slug>` を再実行してください。」と報告する。
