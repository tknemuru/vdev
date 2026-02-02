# /rimp - 実装レビューコマンド

実装コードに対し、3つのレビュー人格による並列レビューを実行せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「レビュー対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ確認

現在のブランチが `feature/<slug>` であることを確認せよ。異なる場合は `feature/<slug>` にチェックアウトせよ。

### Step 3: 事前確認と差分取得

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に以下を実行せよ:

1. `docs/rfcs/<slug>/rfc.md` の存在を確認せよ。ファイルが存在しない場合はエラーを報告して終了せよ。RFC の絶対パスを控えておくこと。
2. 実装差分を一時ファイルに保存せよ:

```bash
git diff main...HEAD -- . ':!docs/rfcs/*/review-*.md' > /tmp/rimp-diff-<slug>.txt
```

**大規模差分への対応:** diff の出力が 3000 行を超える場合は、ファイル単位で分割してレビューを行うこと。変更ファイル一覧を `git diff main...HEAD --name-only -- . ':!docs/rfcs/*/review-*.md'` で取得し、関連ファイルをグルーピングして各 Task に分配せよ。

**注意:** RFC本文やテンプレートをここで読み込む必要はない。各 Task が自身で読み込む。

### Step 4: 並列レビュー実行

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。各 Task は独立したサブエージェントとして起動し、必要なファイルを自身で読み込む。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

**Task のプロンプトに RFC 本文・差分・テンプレートを埋め込むな。ファイルパスのみ渡し、Task 側で読み込ませること。**

#### Task 1: Approach Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/approach-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-imp-approach.md`

#### Task 2: Security & Risk Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/security-risk-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-imp-security-risk.md`

#### Task 3: Technical Quality Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/technical-quality-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-imp-quality.md`

#### 各 Task のプロンプト構成

```
あなたは {人格名} として実装コードをレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: {人格ファイルの絶対パス}
2. 検証項目: ~/projects/vdev/prompts/criterias/impl-review.md （あなたの人格に該当するセクションのみ参照）
3. 設計仕様（RFC）: {RFC ファイルの絶対パス}
4. レビュー対象コード（差分）: /tmp/rimp-diff-<slug>.txt
5. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md

## 指示
- 人格定義と検証項目に従い、実装コードを厳格にレビューせよ。
- RFC との整合性を必ず確認すること。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は、あなたの人格名に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を {出力先ファイルの絶対パス} に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大5件とし、重要度の高い順に記載せよ。上限を超える場合は優先度の低いものを省略し、省略した旨を末尾に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

### Step 5: 結果報告

全レビュー完了後、以下をユーザに報告せよ:
- 各レビュアーの判定（Approve / Request Changes）
- 出力されたレビューファイルのパス一覧

### Step 6: コミット & プッシュ

1. `docs/rfcs/<slug>/` 配下のレビューファイル（`review-imp-approach.md`, `review-imp-security-risk.md`, `review-imp-quality.md`）をステージングする。
2. コミットメッセージ `docs: add implementation review results for <slug>` でコミットする。
3. 現在のブランチ（`feature/<slug>`）をリモートにプッシュする。

### Step 7: PR ステータス更新

全レビュアーの判定が **Approve** の場合、以下を実行せよ:
1. `gh pr ready` で Draft PR を Ready 状態にする。
2. 「全レビュアーが Approve しました。PR を Ready にしました。人間による最終確認をお願いします。」とユーザに報告する。

いずれかのレビュアーが **Request Changes** の場合:
1. PR は Draft のまま維持する。
2. 「Request Changes があります。指摘事項を確認し、コードを修正後に再度 `/rimp` を実行してください。」とユーザに報告する。
