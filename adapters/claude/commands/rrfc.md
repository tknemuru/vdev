# /rrfc - RFCレビューコマンド

指定されたRFCに対し、3つのレビュー人格による並列レビューを実行せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「レビュー対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ確認

現在のブランチが `rfc/<slug>` であることを確認せよ。異なる場合は `rfc/<slug>` にチェックアウトせよ。

### Step 3: RFC ファイル存在確認

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に `docs/rfcs/<slug>/rfc.md` の存在を確認せよ。ファイルが存在しない場合はエラーを報告して終了せよ。RFC の絶対パスを控えておくこと（Task に渡すため）。

**注意:** RFC本文やテンプレートをここで読み込む必要はない。各 Task が自身で読み込む。

### Step 4: 並列レビュー実行

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。各 Task は独立したサブエージェントとして起動し、必要なファイルを自身で読み込む。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

**Task のプロンプトに RFC 本文やテンプレートを埋め込むな。ファイルパスのみ渡し、Task 側で読み込ませること。**

#### Task 1: Approach Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/approach-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-approach.md`

#### Task 2: Security & Risk Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/security-risk-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-security-risk.md`

#### Task 3: Technical Quality Reviewer

- 人格ファイル: `~/projects/vdev/prompts/roles/technical-quality-reviewer.md`
- 出力先: `docs/rfcs/<slug>/review-quality.md`

#### 各 Task のプロンプト構成

```
あなたは {人格名} として RFC（設計ドキュメント）をレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: {人格ファイルの絶対パス}
2. 検証項目: ~/projects/vdev/prompts/criterias/rfc-review.md （あなたの人格に該当するセクションのみ参照）
3. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md
4. レビュー対象RFC: {RFC ファイルの絶対パス}

## 指示
- 人格定義と検証項目に従い、RFCを厳格にレビューせよ。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は、あなたの人格名に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を {出力先ファイルの絶対パス} に Write ツールで書き込め。
```

### Step 5: 結果報告

全レビュー完了後、以下をユーザに報告せよ:
- 各レビュアーの判定（Approve / Request Changes）
- 出力されたレビューファイルのパス一覧

### Step 6: コミット & プッシュ

1. `docs/rfcs/<slug>/` 配下のレビューファイル（`review-approach.md`, `review-security-risk.md`, `review-quality.md`）をステージングする。
2. コミットメッセージ `docs: add RFC review results for <slug>` でコミットする。
3. 現在のブランチ（`rfc/<slug>`）をリモートにプッシュする。

### Step 7: PR ステータス更新

全レビュアーの判定が **Approve** の場合、以下を実行せよ:
1. `docs/rfcs/<slug>/rfc.md` のステータスを「Accepted (承認済)」に更新する。
2. ステータス変更をコミットする（メッセージ: `docs: mark RFC as accepted for <slug>`）。
3. リモートにプッシュする。
4. `gh pr ready` で Draft PR を Ready 状態にする。
5. 「全レビュアーが Approve しました。RFC を Accepted に更新し、PR を Ready にしました。人間による最終確認・マージをお願いします。」とユーザに報告する。

いずれかのレビュアーが **Request Changes** の場合:
1. PR は Draft のまま維持する。
2. 「Request Changes があります。指摘事項を確認し、`/urfc <slug>` でRFCを修正後に再度 `/rrfc` を実行してください。」とユーザに報告する。
