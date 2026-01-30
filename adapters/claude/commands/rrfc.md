# /rrfc - RFCレビューコマンド

指定されたRFCに対し、3つのレビュー人格による並列レビューを実行せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「レビュー対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: RFC読み込み

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に `docs/rfcs/<slug>/rfc.md` を読み込め。ファイルが存在しない場合はエラーを報告して終了せよ。

### Step 3: レビューテンプレート読み込み

`~/projects/vdev/templates/review/review-default.md` を読み込め。

### Step 4: 並列レビュー実行

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。各 Task は独立したサブエージェントとして起動し、親セッションのコンテキストを引き継がない。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

各 Task のプロンプトには以下を含めること:
- レビュー人格の定義（下記参照）
- 検証項目（`~/projects/vdev/prompts/criterias/rfc-review.md` から該当人格のセクションを抽出）
- RFC本文の全文
- レビューテンプレート
- 出力先ファイルパス
- 「レビュー結果を指定のファイルパスに Write ツールで書き込め」という指示

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
あなたは以下の人格でRFC（設計ドキュメント）をレビューする。

## 人格定義
{人格ファイルの内容}

## 検証項目
{rfc-review.md から該当人格のセクションを抽出した内容}

## レビューテンプレート
{レビューテンプレートの内容}

## レビュー対象RFC
{RFC本文の全文}

## 指示
- 上記の人格定義と検証項目に従い、RFCを厳格にレビューせよ。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は、あなたの人格名に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を {出力先ファイルパス} に Write ツールで書き込め。
```

### Step 5: 結果報告

全レビュー完了後、以下をユーザに報告せよ:
- 各レビュアーの判定（Approve / Request Changes）
- 出力されたレビューファイルのパス一覧

### Step 6: コミット & プッシュ

1. `docs/rfcs/<slug>/` 配下のレビューファイル（`review-approach.md`, `review-security-risk.md`, `review-quality.md`）をステージングする。
2. コミットメッセージ `docs: add RFC review results for <slug>` でコミットする。
3. 現在のブランチ（`feature/<slug>`）をリモートにプッシュする。

### Step 7: PR ステータス更新

全レビュアーの判定が **Approve** の場合、以下を実行せよ:
1. `gh pr ready` で Draft PR を Ready 状態にする。
2. 「全レビュアーが Approve しました。PR を Ready にしました。人間による最終確認をお願いします。」とユーザに報告する。

いずれかのレビュアーが **Request Changes** の場合:
1. PR は Draft のまま維持する。
2. 「Request Changes があります。指摘事項を確認し、RFCを修正後に再度 `/rrfc` を実行してください。」とユーザに報告する。
