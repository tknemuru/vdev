# /aimp - 自動実装コマンド

承認済みRFCに基づく実装からレビュー承認までを自動で実行する。メインエージェントは薄いオーケストレータとして振る舞い、ファイル読み込み・分析・実装・レビューはすべて Task サブエージェントで実行する。

## 対象slug

$ARGUMENTS

## 実行手順

### Phase 1: 実装

#### Step 1-1: slug の取得

上記「対象slug」が空の場合は、「実装対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

#### Step 1-2: ブランチ作成

`feature/{slug}` ブランチが存在しない場合はデフォルトブランチから作成せよ。既に存在する場合はチェックアウトせよ。

```bash
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d: -f2 | tr -d ' ')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH" 2>/dev/null || true
git checkout -b feature/{slug} 2>/dev/null || git checkout feature/{slug}
```

#### Step 1-3: RFC 存在確認

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に `docs/rfcs/{slug}/rfc.md` の存在を確認せよ。ファイルが存在しない場合はエラーを報告して終了せよ。RFC の絶対パスを控えておくこと。

RFC のステータスが「Accepted (承認済)」であることを確認せよ。承認済みでない場合は、ユーザに警告を表示し、続行するか確認せよ。

#### Step 1-4: 実装 Task の実行

以下のプロンプトで Task を起動し、実装を実行させよ。タスク計画承認のチェックポイントは設けない（RFC 承認時点で設計合意は完了しているため）。

```
あなたは実装エージェントである。RFC に基づいて実装を行う。

## 対象
- slug: {slug}
- RFC: {rfc_path}
- ブランチ: feature/{slug}

## 手順

### Step 1: RFC・システム概要ドキュメントの読み込み
以下を並列に読み込め（存在しないファイルはスキップ）:
- {rfc_path}
- docs/architecture.md
- docs/domain-model.md
- docs/api-overview.md

### Step 2: 実装タスク策定
RFC の詳細設計（セクション5）から、変更・新規作成が必要なファイルを特定し、実装タスクを策定せよ。

### Step 3: 実装
RFC の設計意図に忠実に実装せよ。以下のルールに従うこと:
- テスト方針（~/projects/vdev/adapters/claude/rules/testing-policy.md）を読み込み、それに基づきテストを作成すること。
- Docコメント規約（~/projects/vdev/adapters/claude/rules/doc-comments.md）を読み込み、それに従うこと。
- 実装中に設計上の問題を発見した場合は、テキスト出力で報告すること。

### Step 4: テスト実行
プロジェクトのテストコマンドを実行し、全て通過することを確認せよ。失敗がある場合は修正すること。

### Step 5: コミット & プッシュ & PR 作成
1. 変更ファイルをステージングする。
2. コミットメッセージは変更内容に応じた適切なプレフィックス（feat:, fix:, test: 等）を付けること。
3. feature/{slug} ブランチをリモートにプッシュする。
4. Draft PR が未作成の場合、以下のコマンドで作成する:

gh pr create --draft --title "feat: {slug}" --body "## Summary

RFC に基づく実装。

- **RFC**: docs/rfcs/{slug}/rfc.md
- **Branch**: feature/{slug}

---
このPRはAIレビュー完了後に Ready 状態になります。"

### Step 6: 結果報告
最後に、以下の形式で結果を出力せよ:
status: completed
files_changed: {変更ファイル数}
tests_passed: {テスト通過状況}
```

### Phase 2: レビューループ

最大3イテレーションのレビューループを実行する。

#### Step 2-1: 差分取得

デフォルトブランチを取得し、実装差分を一時ファイルに保存せよ:

```bash
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d: -f2 | tr -d ' ')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git diff "$DEFAULT_BRANCH"...HEAD -- . ':!docs/rfcs/*/review-*.md' ':!docs/rfcs/*/action-plan-*.md' > /tmp/aimp-diff-{slug}.txt
```

#### Step 2-2: 並列レビュー実行（Loop-A）

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

##### Task 1: Approach Reviewer

```
あなたは Approach Reviewer として実装コードをレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/approach-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/impl-review.md （あなたの人格に該当するセクションのみ参照）
3. 設計仕様（RFC）: {rfc_path}
4. レビュー対象コード（差分）: /tmp/aimp-diff-{slug}.txt
5. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md

## 指示
- 人格定義と検証項目に従い、実装コードを厳格にレビューせよ。
- RFC との整合性を必ず確認すること。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Approach Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-imp-approach.md に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

##### Task 2: Security & Risk Reviewer

```
あなたは Security & Risk Reviewer として実装コードをレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/security-risk-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/impl-review.md （あなたの人格に該当するセクションのみ参照）
3. 設計仕様（RFC）: {rfc_path}
4. レビュー対象コード（差分）: /tmp/aimp-diff-{slug}.txt
5. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md

## 指示
- 人格定義と検証項目に従い、実装コードを厳格にレビューせよ。
- RFC との整合性を必ず確認すること。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Security & Risk Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-imp-security-risk.md に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

##### Task 3: Technical Quality Reviewer

```
あなたは Technical Quality Reviewer として実装コードをレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/technical-quality-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/impl-review.md （あなたの人格に該当するセクションのみ参照）
3. 設計仕様（RFC）: {rfc_path}
4. レビュー対象コード（差分）: /tmp/aimp-diff-{slug}.txt
5. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md

## 指示
- 人格定義と検証項目に従い、実装コードを厳格にレビューせよ。
- RFC との整合性を必ず確認すること。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Technical Quality Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-imp-quality.md に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

**2ラウンド目以降の追加指示（上記プロンプトに追加）:**

```
## 追加コンテキスト（ラウンド {N}）
- これはレビュー第{N}ラウンドである。
- 前回のアクションプラン: docs/rfcs/{slug}/action-plan-imp-r{N-1}.md
- 前回レビュー以降の変更差分のみをレビュー対象とせよ。
- P0 のみ報告せよ。P1 / P2 は報告不要。

## 変更差分の取得方法
以下の git diff コマンドを Bash ツールで実行し、差分を取得せよ:
git diff HEAD~1 -- . ':!docs/rfcs/*/review-*.md' ':!docs/rfcs/*/action-plan-*.md'
```

#### Step 2-3: シンセサイザー実行（Loop-B）

3つのレビュー Task 完了後、以下のプロンプトでシンセサイザー Task を起動せよ。

```
あなたはシンセサイザーとして、複数のレビュー結果を統合する。
まず以下のファイルを Read ツールで読み込め。

1. シンセサイザー定義: ~/projects/vdev/prompts/roles/synthesizer.md
2. アクションプランテンプレート: ~/projects/vdev/templates/review/action-plan-default.md
3. レビュー結果1: docs/rfcs/{slug}/review-imp-approach.md
4. レビュー結果2: docs/rfcs/{slug}/review-imp-security-risk.md
5. レビュー結果3: docs/rfcs/{slug}/review-imp-quality.md

## 指示
- シンセサイザー定義の処理手順に従い、3つのレビュー結果を統合せよ。
- アクションプランテンプレートの構造に従い、統合結果を作成せよ。
- テンプレート内の {N} はラウンド番号 {round} に置き換えよ。
- 「である」調で記述せよ。
- 統合結果を docs/rfcs/{slug}/action-plan-imp-r{round}.md に Write ツールで書き込め。

## 出力
Write ツールでファイル書き込み後、以下の形式で結果を出力せよ:
status: [Approve / Request Changes]
p0_count: {P0件数}
p1_count: {P1件数}
p2_count: {P2件数}
```

**2ラウンド目以降の追加指示:**

```
## 追加コンテキスト（ラウンド {N}）
- これはラウンド {N} のシンセサイズである。
- 2ラウンド目以降は P0 のみを処理対象とする。
- P1/P2 セクションは「該当なし（2ラウンド目以降は P0 限定）」と記載せよ。
```

#### Step 2-4: 判定（Loop-C）

シンセサイザー Task の結果から `status` を確認する。

- **status が Approve の場合**: Phase 3 へ進む
- **status が Request Changes かつ iteration < 3 の場合**: Step 2-5 へ進む
- **status が Request Changes かつ iteration >= 3 の場合**: 「最大イテレーション回数（3回）に達しました。アクションプラン docs/rfcs/{slug}/action-plan-imp-r{round}.md を確認し、手動で対応してください。」とユーザに報告して終了

#### Step 2-5: コード修正（Loop-D）

以下のプロンプトで Implementer Task を起動し、コードを修正させよ。

```
あなたは Implementer として、レビュー指摘に基づきコードを修正する。
まず以下のファイルを Read ツールで読み込め。

1. アクションプラン: docs/rfcs/{slug}/action-plan-imp-r{round}.md
2. 設計仕様（RFC）: {rfc_path}

## 指示
- アクションプランの P0（必須対応）は必ず対応すること。
- アクションプランの P1（推奨対応）は原則対応すること。
- アクションプランの P2（記録のみ）は対応不要。
- 「要判断」セクションがある場合は、その箇所の修正を保留し、他の指摘のみ対応せよ。
- RFC の設計意図から逸脱しないよう注意すること。
- 修正後、プロジェクトのテストコマンドを実行し、全て通過することを確認せよ。

## 出力
テスト通過後、「コードを修正しました。」とだけ出力せよ。
```

コード修正 Task 完了後、以下を実行:

1. 変更ファイルをステージングする
2. コミットメッセージ `fix: address review feedback for {slug} (round {round})` でコミットする
3. `feature/{slug}` ブランチをリモートにプッシュする
4. 差分ファイルを再取得する（Step 2-1 と同様）

Step 2-2 に戻り、次のイテレーションを開始する（iteration をインクリメント）。

### Phase 3: 承認完了処理

全レビュアーが Approve した場合、以下を実行せよ。

#### Step 3-1: レビュー結果コミット

1. `docs/rfcs/{slug}/` 配下のレビューファイルをステージングする
2. コミットメッセージ `docs: add implementation review results for {slug}` でコミットする
3. `feature/{slug}` ブランチをリモートにプッシュする

#### Step 3-2: PR Ready 化

`gh pr ready` で Draft PR を Ready 状態にする。

#### Step 3-3: 完了報告

以下をユーザに報告せよ:

```
実装レビューループが完了しました。

- **Status**: Approved
- **Branch**: feature/{slug}
- **レビューラウンド数**: {iteration}

PR を Ready にしました。人間による最終確認・マージをお願いします。
```
