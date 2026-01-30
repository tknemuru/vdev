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
- `git diff main...HEAD` の出力（実装差分の全体）

RFC ファイルが存在しない場合はエラーを報告して終了せよ。

### Step 3: レビューテンプレート読み込み

`~/projects/vdev/templates/review/review-default.md` を読み込め。

### Step 4: 並列レビュー実行

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。各 Task は独立したサブエージェントとして起動し、親セッションのコンテキストを引き継がない。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

各 Task のプロンプトには以下を含めること:
- レビュー人格の定義（下記参照）
- コード固有の検証項目（下記参照）
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

## コード固有の検証項目

### Approach Reviewer の場合:
- 実装はRFCの設計意図に忠実か。乖離がある場合、その理由は妥当か。
- 不要なコードや過剰な実装はないか。RFCのスコープを超えていないか。
- より単純な実装方法はないか。

### Security & Risk Reviewer の場合:
- セキュリティ脆弱性（インジェクション、XSS、認証不備等）はないか。
- 機密情報（シークレット、個人情報）の取り扱いは適切か。
- エラーハンドリングは適切か。障害時に安全に失敗するか。
- 依存ライブラリに既知の脆弱性はないか。

### Technical Quality Reviewer の場合:
- コードは読みやすく保守しやすいか。命名・構造は適切か。
- テストは十分か。正常系・異常系・境界値がカバーされているか。
- ログ・メトリクス等の可観測性は実装されているか。
- パフォーマンス上の問題はないか（N+1クエリ、不要なループ等）。
- 既存コードベースのスタイル・パターンと一貫しているか。

## 設計仕様（RFC）
{RFC本文の全文}

## レビュー対象コード（差分）
{git diff main...HEAD の全出力}

## レビューテンプレート
{レビューテンプレートの内容}

## 指示
- 上記の人格定義とコード固有の検証項目に従い、実装コードを厳格にレビューせよ。
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
