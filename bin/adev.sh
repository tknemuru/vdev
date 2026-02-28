#!/usr/bin/env bash
# 自動開発オーケストレータ
#
# 仕様書の RFC 一覧を入力として、RFC 作成から実装完了・マージまでを
# 全自動で順次実行する。RFC 単位で独立した claude プロセスを起動し、
# OOM を防止する。
#
# 使用方法:
#   bin/adev.sh <仕様書パス> [セクション名]
#
# 引数:
#   仕様書パス: 必須。RFC 一覧テーブルを含む仕様書のファイルパス
#   セクション名: 省略時は "4.3"。RFC 一覧テーブルが記載されたセクション

set -euo pipefail

VDEV_HOME="$HOME/projects/vdev"

# shellcheck source=lib/git-utils.sh
source "$VDEV_HOME/bin/lib/git-utils.sh"

# --- 引数チェック ---
if [ $# -lt 1 ]; then
  echo "Usage: adev.sh <仕様書パス> [セクション名]" >&2
  exit 1
fi

SPEC_PATH="$1"
SECTION="${2:-4.3}"

if [ ! -f "$SPEC_PATH" ]; then
  echo "エラー: 仕様書が見つかりません: $SPEC_PATH" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_CONTENT="$(cat "$SPEC_PATH")"

# --- Phase 1: 前提条件ゲート ---
echo "=== Phase 1: 前提条件検証 ==="

GATE_RESULT=$(claude -p \
  --allowedTools "Bash(git:*) Read Glob Grep" \
  "以下の仕様書の §4.1（必要な環境情報）と §4.2（事前の人間タスク）を検証せよ。
全項目が充足されていれば OK とだけ出力せよ。
1件でも未充足があれば、未充足項目を一覧表示し最後に FAIL と出力せよ。

仕様書:
$SPEC_CONTENT")

echo "$GATE_RESULT"

if echo "$GATE_RESULT" | grep -q "FAIL"; then
  echo "前提条件が未充足のため停止します。" >&2
  exit 1
fi

# --- Phase 2: RFC slug 一覧の抽出 ---
echo "=== Phase 2: RFC slug 一覧抽出 ==="

SLUGS_JSON=$(claude -p \
  --allowedTools "Read" \
  "以下の仕様書のセクション ${SECTION} から
RFC 一覧テーブルをパースし、slug のリストを JSON 配列で出力せよ。
出力は JSON 配列のみとし、他のテキストは一切含めるな。
例: [\"slug-1\", \"slug-2\"]

仕様書:
$SPEC_CONTENT")

echo "抽出された slug 一覧: $SLUGS_JSON"

# JSON 配列から slug を取り出す
SLUGS=($(echo "$SLUGS_JSON" | jq -r '.[]'))

if [ ${#SLUGS[@]} -eq 0 ]; then
  echo "エラー: RFC slug が抽出できませんでした。" >&2
  exit 1
fi

TOTAL=${#SLUGS[@]}
COMPLETED=0

# --- Phase 3: RFC 単位の直列ループ ---
echo "=== Phase 3: RFC 直列実行 (全 ${TOTAL} 件) ==="

for slug in "${SLUGS[@]}"; do
  echo ""
  echo "--- [$((COMPLETED + 1))/${TOTAL}] slug: ${slug} ---"

  DECISION_LOG="$REPO_ROOT/docs/rfcs/${slug}/adev-decisions.md"
  TIMESTAMP=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M%z)

  # 決定ログ初期化
  mkdir -p "$(dirname "$DECISION_LOG")"
  if [ ! -f "$DECISION_LOG" ]; then
    cat > "$DECISION_LOG" <<LOGEOF
# 自動開発 決定ログ

| タイムスタンプ | フェーズ | アクション | 結果 | 備考 |
|---------------|---------|-----------|------|------|
LOGEOF
  fi

  # --- Step 3-1: 自動 RFC ---
  echo "[${slug}] 自動 RFC 実行中..."
  TIMESTAMP=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M%z)

  if claude -p \
    --allowedTools "Bash Edit Read Write Glob Grep WebFetch WebSearch" \
    "以下のコマンド定義を読み込み、その手順に従ってRFCの作成・レビューを自動実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/arfc.md

\$ARGUMENTS の値は以下の元ネタ文章として扱え:
${SPEC_CONTENT}

対象 RFC の slug: ${slug}"; then
    echo "| ${TIMESTAMP} | RFC作成 | /arfc 実行 | 成功 | - |" \
      >> "$DECISION_LOG"
  else
    echo "| ${TIMESTAMP} | RFC作成 | /arfc 実行 | 失敗 | - |" \
      >> "$DECISION_LOG"
    echo "エラー: [${slug}] 自動 RFC が失敗しました。停止します。" >&2
    exit 1
  fi

  # --- Step 3-2: RFC PR マージ ---
  echo "[${slug}] RFC PR マージ中..."
  TIMESTAMP=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M%z)

  DEFAULT_BRANCH=$(get_default_branch)
  git checkout "rfc/${slug}" 2>/dev/null || true

  if gh pr merge --squash --delete-branch; then
    echo "| ${TIMESTAMP} | RFCマージ | gh pr merge | 成功 | - |" \
      >> "$DECISION_LOG"
    git checkout "$DEFAULT_BRANCH"
    git pull --ff-only origin "$DEFAULT_BRANCH" 2>/dev/null || true
  else
    echo "| ${TIMESTAMP} | RFCマージ | gh pr merge | 失敗 | - |" \
      >> "$DECISION_LOG"
    echo "エラー: [${slug}] RFC PR マージが失敗しました。停止します。" >&2
    exit 1
  fi

  # --- Step 3-3: 自動実装 ---
  echo "[${slug}] 自動実装実行中..."
  TIMESTAMP=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M%z)

  if claude -p \
    --allowedTools "Bash Edit Read Write Glob Grep WebFetch WebSearch" \
    "以下のコマンド定義を読み込み、その手順に従って実装を自動実行せよ。
- コマンド定義: ~/projects/vdev/adapters/claude/commands/aimp.md

\$ARGUMENTS の値は「${slug}」として扱え。

注意: /vfy の副作用を伴う操作はユーザ承認済みとして扱え。"; then
    echo "| ${TIMESTAMP} | 実装 | /aimp 実行 | 成功 | - |" \
      >> "$DECISION_LOG"
  else
    echo "| ${TIMESTAMP} | 実装 | /aimp 実行 | 失敗 | - |" \
      >> "$DECISION_LOG"
    echo "エラー: [${slug}] 自動実装が失敗しました。停止します。" >&2
    exit 1
  fi

  # --- Step 3-4: 実装 PR マージ ---
  echo "[${slug}] 実装 PR マージ中..."
  TIMESTAMP=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M%z)

  git checkout "feature/${slug}" 2>/dev/null || true

  if gh pr merge --squash --delete-branch; then
    echo "| ${TIMESTAMP} | 実装マージ | gh pr merge | 成功 | - |" \
      >> "$DECISION_LOG"
    git checkout "$DEFAULT_BRANCH"
    git pull --ff-only origin "$DEFAULT_BRANCH" 2>/dev/null || true
  else
    echo "| ${TIMESTAMP} | 実装マージ | gh pr merge | 失敗 | - |" \
      >> "$DECISION_LOG"
    echo "エラー: [${slug}] 実装 PR マージが失敗しました。停止します。" >&2
    exit 1
  fi

  COMPLETED=$((COMPLETED + 1))

  # --- 進捗サマリー ---
  RFC_PR_URL=$(gh pr list --search "rfc/${slug}" \
    --state merged --json url --jq '.[0].url' 2>/dev/null || echo "N/A")
  IMP_PR_URL=$(gh pr list --search "feature/${slug}" \
    --state merged --json url --jq '.[0].url' 2>/dev/null || echo "N/A")

  echo ""
  echo "[進捗] ${COMPLETED}/${TOTAL} 完了"
  echo "- slug: ${slug}"
  echo "- RFC PR: ${RFC_PR_URL}"
  echo "- 実装PR: ${IMP_PR_URL}"
done

# --- Phase 4: 完了報告 ---
echo ""
echo "=== 自動開発が完了しました ==="
echo ""
echo "処理結果: ${COMPLETED}/${TOTAL} 件完了"
