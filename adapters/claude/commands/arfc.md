# /arfc - 自動RFCコマンド

RFC作成からレビュー承認までを自動で実行する。メインエージェントは薄いオーケストレータとして振る舞い、各フェーズは既存コマンド（`/rfc`, `/rrfc`, `/urfc`）を Task 経由で内部呼び出しする。

## 元ネタ文章

$ARGUMENTS

## 実行手順

### Phase 1: RFC作成

#### Step 1-1: 元ネタ文章の取得

上記「元ネタ文章」が空の場合は、「RFCの元ネタを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

#### Step 1-2: RFC 作成 Task の実行

以下のプロンプトで Task を起動し、RFC を作成させよ。

```
以下のコマンド定義を読み込み、その手順に従って RFC を作成せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/rfc.md

$ARGUMENTS の値は以下の元ネタ文章として扱え:
{元ネタ文章をここに埋め込む}
```

Task の結果から `slug` と RFC ファイルパスを取得し、以降のステップで使用する。

### Phase 2: レビューループ

2つの独立したカウンターでループを制御する:
- `validation_attempts`: バリデーション試行回数（上限5回）
- `review_iterations`: レビューイテレーション回数（上限3回）

#### Step 2-1: レビュー実行（/rrfc 呼び出し）

以下のプロンプトで Task を起動し、レビューを実行させよ。

```
以下のコマンド定義を読み込み、その手順に従って RFC レビューを実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/rrfc.md

$ARGUMENTS の値は「{slug}」として扱え。
```

#### Step 2-2: 判定

Task の結果からステータスを確認する。

- **Approve の場合**: レビューループ完了。Phase 3 へ進む。
- **VALIDATION_FAIL の場合**:
  - `validation_attempts` をインクリメントする
  - `validation_attempts` >= 5 の場合:
    「バリデーション試行が上限（5回）に達しました。
    修正指示を確認し、手動で対応してください。」と報告して終了
  - `validation_attempts` < 5 の場合: Step 2-3 へ進む
- **Request Changes の場合**:
  - `review_iterations` をインクリメントする
  - `review_iterations` >= 3 の場合:
    「レビューイテレーションが上限（3回）に達しました。
    アクションプランを確認し、手動で対応してください。」と報告して終了
  - `review_iterations` < 3 の場合: Step 2-3 へ進む

#### Step 2-3: RFC 修正（/urfc 呼び出し）

以下のプロンプトで Task を起動し、RFC を修正させよ。
（VALIDATION_FAIL の場合は修正指示ファイルもコンテキストとして渡す）

```
以下のコマンド定義を読み込み、その手順に従って RFC を修正せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/urfc.md

$ARGUMENTS の値は「{slug}」として扱え。
```

Task 完了後、Step 2-1 に戻り次のイテレーションを開始する。

### Phase 3: 完了報告

`gh pr view rfc/{slug} --json url --jq '.url'` で PR URL を取得し、以下をユーザに報告せよ:

```
RFC レビューループが完了しました。

- **Status**: Accepted
- **RFC**: docs/rfcs/{slug}/rfc.md
- **Branch**: rfc/{slug}
- **PR**: {PR URL}
- **レビューラウンド数**: {iteration}

PR を Ready にしました。人間による最終確認・マージをお願いします。
```
