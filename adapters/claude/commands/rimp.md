# /rimp - 実装レビューコマンド

実装コードに対し、3つのレビュー人格による並列レビューを実行せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「レビュー対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: RFC・差分の読み込み

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に以下を読み込め:
- `docs/rfcs/<slug>/rfc.md`（RFC本文。設計意図の参照用）
- 実装差分（以下のコマンドで取得。レビュー関連ファイルを除外する）

```bash
git diff main...HEAD -- . ':!docs/rfcs/*/review-*.md'
```

RFC ファイルが存在しない場合はエラーを報告して終了せよ。

**大規模差分への対応:** diff の出力が 3000 行を超える場合は、ファイル単位で分割してレビューを行うこと。変更ファイル一覧を `git diff main...HEAD --name-only -- . ':!docs/rfcs/*/review-*.md'` で取得し、関連ファイルをグルーピングして各 Task に分配せよ。

### Step 3: レビューテンプレート読み込み

`~/projects/vdev/templates/review/review-default.md` を読み込め。

### Step 4: 並列レビュー実行

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。各 Task は独立したサブエージェントとして起動し、親セッションのコンテキストを引き継がない。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

各 Task のプロンプトには以下を含めること:
- レビュー人格の定義（下記参照）
- 検証項目（`~/projects/vdev/prompts/criterias/impl-review.md` から該当人格のセクションを抽出）
- RFC本文の全文
- 実装差分の全文
- レビューテンプレート
- 出力先ファイルパス
- 「レビュー結果を指定のファイルパスに Write ツールで書き込め」という指示

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
あなたは以下の人格で実装コードをレビューする。

## 人格定義
{人格ファイルの内容}

## 検証項目
{impl-review.md から該当人格のセクションを抽出した内容}

## 設計仕様（RFC）
{RFC本文の全文}

## レビュー対象コード（差分）
{git diff の全出力}

## レビューテンプレート
{レビューテンプレートの内容}

## 指示
- 上記の人格定義と検証項目に従い、実装コードを厳格にレビューせよ。
- RFC との整合性を必ず確認すること。
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
