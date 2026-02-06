# /arfc - 自動RFCコマンド

RFC作成からレビュー承認までを自動で実行する。メインエージェントは薄いオーケストレータとして振る舞い、ファイル読み込み・分析・執筆・レビューはすべて Task サブエージェントで実行する。

## 元ネタ文章

$ARGUMENTS

## 実行手順

### Phase 1: RFC作成

#### Step 1-1: 元ネタ文章の取得

上記「元ネタ文章」が空の場合は、「RFCの元ネタを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

#### Step 1-2: RFC 作成 Task の実行

以下のプロンプトで Task を起動し、RFC を作成させよ。

```
あなたは RFC 作成エージェントである。以下の手順で RFC を作成せよ。

## 元ネタ文章
{元ネタ文章をここに埋め込む}

## 手順

### Step 1: slugstr 生成
元ネタ文章の内容を要約し、**最大30文字**の全小文字ケバブケース英数字（a-z, 0-9, ハイフンのみ）で slugstr を生成せよ。

### Step 2: 初期化
以下のコマンドを Bash ツールで実行せよ。出力される文字列が完全な slug（YYYYMMDD-slugstr）である。
rfc-init <slugstr>

### Step 3: コードベース調査
カレントリポジトリのルート（git rev-parse --show-toplevel）を基準に、以下のシステム概要ドキュメントが存在する場合は並列に読み込め（存在しないファイルはスキップ）:
- docs/architecture.md
- docs/domain-model.md
- docs/api-overview.md

その上で、元ネタ文章に関連するコードベースを調査し、現行アーキテクチャ・データモデル・依存関係を把握せよ。

### Step 4: RFC起草
1. ~/projects/vdev/prompts/roles/rfc-author.md を読み込み、その人格に切り替わる。
2. docs/rfcs/<slug>/rfc.md のテンプレート構造に従い、元ネタ文章とコードベース調査結果をもとにRFCを起草する。
3. ステータスは「Draft (起草中)」、作成日は今日のJST日付（YYYY-MM-DD形式）とする。
4. 起草した内容を docs/rfcs/<slug>/rfc.md に書き込む。

### Step 5: DoD自己チェック
以下の完了定義を満たしているか自己チェックし、不足があれば補完せよ。
- 背景・動機が記述されていること
- 目的・スコープ（Goals / Non-Goals）が明確であること
- 具体的な設計案が記述されていること
- 代替案とその比較（トレードオフ）が示されていること
- 実装・リリース計画に検証方法が含まれていること
- システム概要ドキュメントへの影響が判断されていること

### Step 6: パブリッシュ
以下のコマンドを Bash ツールで実行せよ。
rfc-publish <slug>

### Step 7: 結果報告
最後に、以下の形式で結果を出力せよ（この出力がメインエージェントに返される）:
slug: <slug>
rfc_path: <RFC ファイルの絶対パス>
branch: rfc/<slug>
```

Task の結果から `slug` と `rfc_path` を取得し、以降のステップで使用する。

### Phase 2: レビューループ

最大3イテレーションのレビューループを実行する。

#### Step 2-1: 並列レビュー実行（Loop-A）

以下の3つのレビューを **Task ツールを使って並列に** 実行せよ。

**必ず3つの Task を単一メッセージ内で同時に発行すること。**

##### Task 1: Approach Reviewer

```
あなたは Approach Reviewer として RFC（設計ドキュメント）をレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/approach-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/rfc-review.md （あなたの人格に該当するセクションのみ参照）
3. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md
4. レビュー対象RFC: {rfc_path}

## 指示
- 人格定義と検証項目に従い、RFCを厳格にレビューせよ。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Approach Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-approach.md に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

##### Task 2: Security & Risk Reviewer

```
あなたは Security & Risk Reviewer として RFC（設計ドキュメント）をレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/security-risk-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/rfc-review.md （あなたの人格に該当するセクションのみ参照）
3. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md
4. レビュー対象RFC: {rfc_path}

## 指示
- 人格定義と検証項目に従い、RFCを厳格にレビューせよ。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Security & Risk Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-security-risk.md に Write ツールで書き込め。

## 出力制約
- 指摘事項は P0 最大5件、P1 最大3件、P2 最大2件とし、重要度の高い順に記載せよ。
- 各指摘の「内容」「修正の期待値」はそれぞれ1〜3文で簡潔に記述せよ。
- 「良い点」は最大5件とし、各1文で簡潔に記述せよ。
- Write ツールでファイル書き込み後、テキスト出力は判定結果（Approve / Request Changes）の1行のみとせよ。
```

##### Task 3: Technical Quality Reviewer

```
あなたは Technical Quality Reviewer として RFC（設計ドキュメント）をレビューする。
まず以下のファイルを Read ツールで読み込め。

1. 人格定義: ~/projects/vdev/prompts/roles/technical-quality-reviewer.md
2. 検証項目: ~/projects/vdev/prompts/criterias/rfc-review.md （あなたの人格に該当するセクションのみ参照）
3. レビューテンプレート: ~/projects/vdev/templates/review/review-default.md
4. レビュー対象RFC: {rfc_path}

## 指示
- 人格定義と検証項目に従い、RFCを厳格にレビューせよ。
- レビューテンプレートの構造に従い、レビュー結果を作成せよ。
- テンプレート内の {人格名} は「Technical Quality Reviewer」に置き換えよ。
- 判定は Approve または Request Changes のいずれかとせよ。
- P0 / P1 / P2 の該当がない場合は「該当なし」と記載せよ。
- 「である」調で記述せよ。
- レビュー結果を docs/rfcs/{slug}/review-quality.md に Write ツールで書き込め。

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
- 前回のアクションプラン: docs/rfcs/{slug}/action-plan-r{N-1}.md
- 前回レビュー以降の変更差分のみをレビュー対象とせよ。
- P0 のみ報告せよ。P1 / P2 は報告不要。

## 変更差分の取得方法
以下の git diff コマンドを Bash ツールで実行し、差分を取得せよ:
git diff HEAD~1 -- {rfc_path}
```

#### Step 2-2: シンセサイザー実行（Loop-B）

3つのレビュー Task 完了後、以下のプロンプトでシンセサイザー Task を起動せよ。

```
あなたはシンセサイザーとして、複数のレビュー結果を統合する。
まず以下のファイルを Read ツールで読み込め。

1. シンセサイザー定義: ~/projects/vdev/prompts/roles/synthesizer.md
2. アクションプランテンプレート: ~/projects/vdev/templates/review/action-plan-default.md
3. レビュー結果1: docs/rfcs/{slug}/review-approach.md
4. レビュー結果2: docs/rfcs/{slug}/review-security-risk.md
5. レビュー結果3: docs/rfcs/{slug}/review-quality.md

## 指示
- シンセサイザー定義の処理手順に従い、3つのレビュー結果を統合せよ。
- アクションプランテンプレートの構造に従い、統合結果を作成せよ。
- テンプレート内の {N} はラウンド番号 {round} に置き換えよ。
- 「である」調で記述せよ。
- 統合結果を docs/rfcs/{slug}/action-plan-r{round}.md に Write ツールで書き込め。

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

#### Step 2-3: 判定（Loop-C）

シンセサイザー Task の結果から `status` を確認する。

- **status が Approve の場合**: Phase 3 へ進む
- **status が Request Changes かつ iteration < 3 の場合**: Step 2-4 へ進む
- **status が Request Changes かつ iteration >= 3 の場合**: 「最大イテレーション回数（3回）に達しました。アクションプラン docs/rfcs/{slug}/action-plan-r{round}.md を確認し、手動で対応してください。」とユーザに報告して終了

#### Step 2-4: RFC 修正（Loop-D）

以下のプロンプトで RFC Author Task を起動し、RFC を修正させよ。

```
あなたは RFC Author として、レビュー指摘に基づき RFC を修正する。
まず以下のファイルを Read ツールで読み込め。

1. RFC Author 定義: ~/projects/vdev/prompts/roles/rfc-author.md
2. アクションプラン: docs/rfcs/{slug}/action-plan-r{round}.md
3. 現在のRFC: {rfc_path}

## 指示
- アクションプランの P0（必須対応）は必ず対応すること。
- アクションプランの P1（推奨対応）は原則対応すること。
- アクションプランの P2（記録のみ）は対応不要。
- 「要判断」セクションがある場合は、その箇所の修正を保留し、他の指摘のみ対応せよ。
- 修正した RFC を {rfc_path} に Write ツールで書き込め。
- 「である」調で記述せよ。

## 出力
Write ツールでファイル書き込み後、「RFC を修正しました。」とだけ出力せよ。
```

RFC 修正 Task 完了後、以下を実行:

1. `docs/rfcs/{slug}/` 配下の変更ファイルをステージングする
2. コミットメッセージ `docs: revise RFC for {slug} (round {round} fixes)` でコミットする
3. `rfc/{slug}` ブランチをリモートにプッシュする

Step 2-1 に戻り、次のイテレーションを開始する（iteration をインクリメント）。

### Phase 3: 承認完了処理

全レビュアーが Approve した場合、以下を実行せよ。

#### Step 3-1: ステータス更新

`docs/rfcs/{slug}/rfc.md` のステータスを「Accepted (承認済)」に更新する。

#### Step 3-2: コミット & プッシュ

1. `docs/rfcs/{slug}/` 配下の全ファイルをステージングする
2. コミットメッセージ `docs: mark RFC as accepted for {slug}` でコミットする
3. `rfc/{slug}` ブランチをリモートにプッシュする

#### Step 3-3: PR Ready 化

`gh pr ready` で Draft PR を Ready 状態にする。

#### Step 3-4: 完了報告

以下をユーザに報告せよ:

```
RFC レビューループが完了しました。

- **Status**: Accepted
- **RFC**: docs/rfcs/{slug}/rfc.md
- **Branch**: rfc/{slug}
- **レビューラウンド数**: {iteration}

PR を Ready にしました。人間による最終確認・マージをお願いします。
```
