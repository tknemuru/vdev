# /imp - 実装開始コマンド

承認済みRFCに基づき、実装を開始せよ。

## 対象slug

$ARGUMENTS

## 実行手順

### Step 1: slug の取得

上記「対象slug」が空の場合は、「実装対象のslugを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。

### Step 2: ブランチ作成

`feature/<slug>` ブランチが存在しない場合はデフォルトブランチから作成せよ。既に存在する場合はチェックアウトせよ。

```bash
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d: -f2 | tr -d ' ')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH" 2>/dev/null || true
git checkout -b feature/<slug> 2>/dev/null || git checkout feature/<slug>
```

### Step 3: RFC・システム概要ドキュメントの読み込み

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に、以下を**並列に（単一メッセージ内で同時に）**読み込め（存在しないファイルはスキップ）:
- `docs/rfcs/<slug>/rfc.md`
- `docs/architecture.md`
- `docs/domain-model.md`
- `docs/api-overview.md`

RFC ファイルが存在しない場合はエラーを報告して終了せよ。
RFC のステータスが「Accepted (承認済)」であることを確認せよ。承認済みでない場合は、ユーザに警告を表示し、続行するか確認せよ。

### Step 4: 実装タスク策定

Step 3 で読み込んだ RFC・システム概要ドキュメントに基づき、実装タスクを策定せよ。コードベースの追加調査は行わないこと。

- RFC の詳細設計（セクション5）から、変更・新規作成が必要なファイルを特定する
- 1タスク = 1コミット程度の粒度に分割する
- タスク間の依存関係を整理し、実施順序を決定する
- 各タスクで必要なテストの概要を含める

RFC 承認時点で設計合意は完了しているため、タスク計画の承認は不要である。策定後、そのまま実装に着手せよ。

### Step 5: 実装

RFC の設計意図に忠実に実装せよ。以下のルールに従うこと:
- テスト方針（`rules/testing-policy.md`）に基づきテストを作成すること。
- RFC との乖離が必要になった場合は、先に RFC を更新すること。
- 実装中に設計上の問題を発見した場合は、ユーザに報告し判断を仰ぐこと。

### Step 6: テスト実行

プロジェクトのテストコマンドを実行し、全て通過することを確認せよ。失敗がある場合は修正してから次のステップに進むこと。

### Step 7: コミット & プッシュ & PR 作成

1. 変更ファイルをステージングする。
2. コミットメッセージは変更内容に応じた適切なプレフィックス（`feat:`, `fix:`, `test:` 等）を付けること。
3. `feature/<slug>` ブランチをリモートにプッシュする。
4. Draft PR が未作成の場合、以下の形式で作成する:

```bash
gh pr create --draft \
  --title "feat: <slug>" \
  --body "## Summary

RFC に基づく実装。

- **RFC**: \`docs/rfcs/<slug>/rfc.md\`
- **Branch**: \`feature/<slug>\`

---
このPRはAIレビュー完了後に Ready 状態になります。"
```

5. 実装した内容の要約と PR URL をユーザに報告せよ。
