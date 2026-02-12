# /aimp - 自動実装コマンド

承認済みRFCに基づく実装からレビュー承認までを自動で実行する。メインエージェントは薄いオーケストレータとして振る舞い、各フェーズは既存コマンド（`/imp`, `/vfy`, `/rimp`, `/uimp`）を Task 経由で内部呼び出しする。

## 対象slug

$ARGUMENTS

## 実行手順

### Phase 1: 実装

#### Step 1-1: slug の取得

上記「対象slug」が空の場合は、「実装対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

#### Step 1-2: 実装 Task の実行

以下のプロンプトで Task を起動し、実装を実行させよ。

```
以下のコマンド定義を読み込み、その手順に従って実装を行え。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/imp.md

$ARGUMENTS の値は「{slug}」として扱え。
```

### Phase 1.5: Verification

#### Step 1.5-1: Verification 実行（/vfy 呼び出し）

以下のプロンプトで Task を起動し、Verification を実行させよ。

```
以下のコマンド定義を読み込み、その手順に従って Verification を実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/vfy.md

$ARGUMENTS の値は「{slug}」として扱え。
```

#### Step 1.5-2: 判定

Task の結果から Verification の判定を確認する。

- **全 PASS の場合**: Phase 2 へ進む。
- **FAIL がある場合**: FAIL 項目をユーザに報告して終了する。

### Phase 2: レビューループ

最大3イテレーションのレビューループを実行する。

#### Step 2-1: レビュー実行（/rimp 呼び出し）

以下のプロンプトで Task を起動し、実装レビューを実行させよ。

```
以下のコマンド定義を読み込み、その手順に従って実装レビューを実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/rimp.md

$ARGUMENTS の値は「{slug}」として扱え。
```

#### Step 2-2: 判定

Task の結果からシンセサイザーの判定を確認する。

- **Approve の場合**: レビューループ完了。`/rimp` 内でコミット・プッシュ・`gh pr ready` が実行済みのため、Phase 3 へ進む。
- **Request Changes かつ iteration < 3 の場合**: Step 2-3 へ進む。
- **Request Changes かつ iteration >= 3 の場合**: 「最大イテレーション回数（3回）に達しました。アクションプラン `docs/rfcs/{slug}/action-plan-imp-r{round}.md` を確認し、手動で対応してください。」とユーザに報告して終了。

#### Step 2-3: コード修正（/uimp 呼び出し）

以下のプロンプトで Task を起動し、コードを修正させよ。

```
以下のコマンド定義を読み込み、その手順に従ってコードを修正せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/uimp.md

$ARGUMENTS の値は「{slug}」として扱え。
```

#### Step 2-4: 再検証（/vfy 呼び出し）

コード修正後、以下のプロンプトで Task を起動し、Verification を再実行させよ。

```
以下のコマンド定義を読み込み、その手順に従って Verification を実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/vfy.md

$ARGUMENTS の値は「{slug}」として扱え。
```

- **全 PASS の場合**: Step 2-1 に戻り次のイテレーションを開始する（iteration をインクリメント）。
- **FAIL がある場合**: FAIL 項目をユーザに報告して終了する。

### Phase 3: 完了報告

`gh pr view feature/{slug} --json url --jq '.url'` で PR URL を取得し、以下をユーザに報告せよ:

```
実装レビューループが完了しました。

- **Status**: Approved
- **Branch**: feature/{slug}
- **PR**: {PR URL}
- **レビューラウンド数**: {iteration}

PR を Ready にしました。人間による最終確認・マージをお願いします。
```
