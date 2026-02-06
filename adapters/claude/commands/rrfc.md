# /rrfc - RFCレビューコマンド

指定されたRFCに対し、3つのレビュー人格による並列レビューとシンセサイザーによる統合を実行せよ。

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

### Step 4: ラウンド判定

`docs/rfcs/<slug>/` 配下の `action-plan-r*.md` ファイル数を確認し、ラウンド番号を自動判定する。

- `action-plan-r*.md` が 0件 → ラウンド1（初回フルレビュー）
- `action-plan-r*.md` が N件 → ラウンド N+1（差分レビュー・段階的収束）

### Step 5: 並列レビュー実行

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

#### 各 Task のプロンプト構成（ラウンド1）

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
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を {出力先ファイルの絶対パス} に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。上限を超える場合は優先度の低いものを省略し、省略した旨を末尾に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

#### 各 Task のプロンプト構成（ラウンド2）

ラウンド1のプロンプトに以下を追加する。

```
## 追加コンテキスト（ラウンド 2）
- これはレビュー第2ラウンドである。
- 前回のアクションプラン: {action-plan-r1.md の絶対パス}
- 前回レビュー以降の変更差分のみをレビュー対象とせよ。
- P0 および P1 を報告せよ。P2 は報告不要。

## 変更差分の取得方法
以下の git diff コマンドを Bash ツールで実行し、差分を取得せよ:
git diff HEAD~1 -- {RFC ファイルの絶対パス}
```

#### 各 Task のプロンプト構成（ラウンド3）

ラウンド1のプロンプトに以下を追加する。

```
## 追加コンテキスト（ラウンド 3）
- これはレビュー第3ラウンドである。
- 前回のアクションプラン: {action-plan-r2.md の絶対パス}
- 前回レビュー以降の変更差分のみをレビュー対象とせよ。
- P0 のみ報告せよ。P1 / P2 は報告不要。

## 変更差分の取得方法
以下の git diff コマンドを Bash ツールで実行し、差分を取得せよ:
git diff HEAD~1 -- {RFC ファイルの絶対パス}
```

### Step 6: シンセサイザー実行

3つのレビュー Task 完了後、以下のプロンプトでシンセサイザー Task を起動せよ。

```
あなたはシンセサイザーとして、複数のレビュー結果を統合する。
まず以下のファイルを Read ツールで読み込め。

1. シンセサイザー定義: ~/projects/vdev/prompts/roles/synthesizer.md
2. アクションプランテンプレート: ~/projects/vdev/templates/review/action-plan-default.md
3. レビュー結果1: docs/rfcs/<slug>/review-approach.md
4. レビュー結果2: docs/rfcs/<slug>/review-security-risk.md
5. レビュー結果3: docs/rfcs/<slug>/review-quality.md

## 指示
- シンセサイザー定義の処理手順に従い、3つのレビュー結果を統合せよ。
- アクションプランテンプレートの構造に従い、統合結果を作成せよ。
- テンプレート内の {N} はラウンド番号 {round} に置き換えよ。
- 「である」調で記述せよ。
- 統合結果を docs/rfcs/<slug>/action-plan-r{round}.md に Write ツールで書き込め。

## 出力
Write ツールでファイル書き込み後、以下の形式で結果を出力せよ:
status: [Approve / Request Changes]
p0_count: {P0件数}
p1_count: {P1件数}
p2_count: {P2件数}
```

**ラウンド2の追加指示:**

```
## 追加コンテキスト（ラウンド 2）
- これはラウンド 2 のシンセサイズである。
- P0 および P1 を処理対象とする。P1 は上位3件をアクション対象とせよ。
- P2 セクションは「該当なし（ラウンド2では P0 + P1 限定）」と記載せよ。
```

**ラウンド3の追加指示:**

```
## 追加コンテキスト（ラウンド 3）
- これはラウンド 3 のシンセサイズである。
- P0 のみを処理対象とする。
- P1/P2 セクションは「該当なし（ラウンド3では P0 限定）」と記載せよ。
```

### Step 7: 結果報告

シンセサイザーの結果とレビュー結果を以下の形式で報告せよ:
- シンセサイザーの判定（Approve / Request Changes）
- P0 / P1 / P2 の件数
- 出力されたレビューファイルとアクションプランのパス一覧

### Step 8: コミット & プッシュ

1. `docs/rfcs/<slug>/` 配下のレビューファイル（`review-approach.md`, `review-security-risk.md`, `review-quality.md`）およびアクションプラン（`action-plan-r{round}.md`）をステージングする。
2. コミットメッセージ `docs: add RFC review results (round {round}) for <slug>` でコミットする。
3. 現在のブランチ（`rfc/<slug>`）をリモートにプッシュする。

### Step 9: PR ステータス更新

シンセサイザーの判定が **Approve** の場合、以下を実行せよ:
1. `docs/rfcs/<slug>/rfc.md` のステータスを「Accepted (承認済)」に更新する。
2. ステータス変更をコミットする（メッセージ: `docs: mark RFC as accepted for <slug>`）。
3. リモートにプッシュする。
4. `gh pr ready` で Draft PR を Ready 状態にする。
5. 「レビューが Approve されました。RFC を Accepted に更新し、PR を Ready にしました。人間による最終確認・マージをお願いします。」とユーザに報告する。

シンセサイザーの判定が **Request Changes** の場合:
1. PR は Draft のまま維持する。
2. 「Request Changes があります。アクションプラン `docs/rfcs/<slug>/action-plan-r{round}.md` を確認し、`/urfc <slug>` でRFCを修正後に再度 `/rrfc` を実行してください。」とユーザに報告する。
