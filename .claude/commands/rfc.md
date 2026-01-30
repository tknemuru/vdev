# /rfc - RFC作成コマンド

以下の手順に従い、RFCドキュメントを作成せよ。

## 元ネタ文章

$ARGUMENTS

## 実行手順

### Step 1: 元ネタ文章の取得

上記「元ネタ文章」が空の場合は、「RFCの元ネタを入力してください。」とだけ表示し、ユーザの次のメッセージを待て。入力がある場合はそれを元ネタ文章として使用する。

### Step 2: slug生成

元ネタ文章を要約し、以下の仕様でslugを生成せよ。

- 形式: `YYYYMMDD-slugstr`
- `YYYYMMDD`: JST（日本標準時間, UTC+9）の今日の日付
- `slugstr`: 元ネタ文章の内容を要約した、**最大30文字**の全小文字ケバブケース英数字（a-z, 0-9, ハイフンのみ）

### Step 3: ディレクトリ作成

カレントリポジトリのルート（`git rev-parse --show-toplevel`）を基準に `docs/rfcs/<slug>/` ディレクトリを作成せよ。同名のディレクトリが既に存在する場合は、slugstr の末尾に連番（`-2`, `-3`, ...）を付与して重複を回避せよ。

### Step 4: RFC起草

1. `~/projects/vdev/prompts/roles/rfc-author.md` を読み込み、その人格に切り替わる。
2. `~/projects/vdev/templates/rfc/rfc-default.md` のテンプレート構造に従い、元ネタ文章をもとにRFCを起草する。
3. ステータスは「Draft (起草中)」、作成日は今日のJST日付（YYYY-MM-DD形式）とする。
4. 起草した内容を `docs/rfcs/<slug>/rfc.md` に書き込む。
