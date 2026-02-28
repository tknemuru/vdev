#!/usr/bin/env bash
# git-utils.sh の単体テスト
#
# get_pr_status() と run_claude_with_recovery() の動作を検証する。
# 外部コマンド（gh, claude）はモック関数で置き換える。
#
# 使用方法:
#   bash tests/test_git_utils.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VDEV_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"

# テスト結果カウンタ
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# テスト結果を記録するユーティリティ関数
#
# 引数:
#   $1: テスト名
#   $2: 期待値
#   $3: 実際の値
assert_equals() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "  PASS: ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  FAIL: ${test_name}"
    echo "    期待値: '${expected}'"
    echo "    実際値: '${actual}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# 終了コードを検証するユーティリティ関数
#
# 引数:
#   $1: テスト名
#   $2: 期待する終了コード
#   $3: 実際の終了コード
assert_exit_code() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "  PASS: ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  FAIL: ${test_name}"
    echo "    期待終了コード: ${expected}"
    echo "    実際終了コード: ${actual}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# 文字列が含まれることを検証するユーティリティ関数
#
# 引数:
#   $1: テスト名
#   $2: 期待される部分文字列
#   $3: 検索対象の文字列
assert_contains() {
  local test_name="$1"
  local needle="$2"
  local haystack="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  FAIL: ${test_name}"
    echo "    '${needle}' が以下に含まれていない:"
    echo "    '${haystack}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ====================================================================
# get_pr_status() のテスト
# ====================================================================
echo ""
echo "=== get_pr_status() テスト ==="

# テスト: マージ済みPRに対して MERGED を返すこと
test_get_pr_status_merged() {
  echo "[テスト] マージ済みPRに対して MERGED を返す"

  # ghコマンドのモック: merged状態のPRが存在する
  gh() {
    if [[ "$*" == *"--state merged"* ]]; then
      echo "123"
    else
      echo ""
    fi
  }
  export -f gh

  # git-utils.sh を読み込み（ghモックが有効な状態で）
  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local result
  result=$(get_pr_status "feature/test-branch")

  assert_equals "MERGED を返す" "MERGED" "$result"

  unset -f gh
}

# テスト: オープンPRに対して OPEN を返すこと
test_get_pr_status_open() {
  echo "[テスト] オープンPRに対して OPEN を返す"

  # ghコマンドのモック: merged無し、open有り
  gh() {
    if [[ "$*" == *"--state merged"* ]]; then
      echo ""
    elif [[ "$*" == *"--state open"* ]]; then
      echo "456"
    else
      echo ""
    fi
  }
  export -f gh

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local result
  result=$(get_pr_status "feature/test-branch")

  assert_equals "OPEN を返す" "OPEN" "$result"

  unset -f gh
}

# テスト: PRなしブランチに対して NONE を返すこと
test_get_pr_status_none() {
  echo "[テスト] PRなしブランチに対して NONE を返す"

  # ghコマンドのモック: merged無し、open無し
  gh() {
    echo ""
  }
  export -f gh

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local result
  result=$(get_pr_status "feature/test-branch")

  assert_equals "NONE を返す" "NONE" "$result"

  unset -f gh
}

test_get_pr_status_merged
test_get_pr_status_open
test_get_pr_status_none

# ====================================================================
# run_claude_with_recovery() のテスト
# ====================================================================
echo ""
echo "=== run_claude_with_recovery() テスト ==="

# テスト: 初回成功で即座に戻り値0を返すこと
test_recovery_first_success() {
  echo "[テスト] 初回成功で即座に戻り値0を返す"

  # claudeコマンドのモック: 常に成功
  claude() {
    cat > /dev/null  # stdinを消費
    echo "成功出力"
    return 0
  }
  export -f claude

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local exit_code=0
  echo "テストプロンプト" | run_claude_with_recovery --allowedTools "Bash" 2>/dev/null || exit_code=$?

  assert_exit_code "戻り値0を返す" "0" "$exit_code"

  unset -f claude
}

# テスト: 初回失敗・2回目成功で戻り値0を返すこと
test_recovery_second_success() {
  echo "[テスト] 初回失敗・2回目成功で戻り値0を返す"

  local attempt_file
  attempt_file=$(mktemp)
  echo "0" > "$attempt_file"

  # claudeコマンドのモック: 1回目失敗、2回目成功
  claude() {
    cat > /dev/null  # stdinを消費
    local count
    count=$(cat "$ATTEMPT_FILE")
    count=$((count + 1))
    echo "$count" > "$ATTEMPT_FILE"
    if [ "$count" -eq 1 ]; then
      echo "エラー発生" >&2
      return 1
    fi
    echo "成功出力"
    return 0
  }
  export -f claude
  export ATTEMPT_FILE="$attempt_file"

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local exit_code=0
  echo "テストプロンプト" | run_claude_with_recovery --allowedTools "Bash" 2>/dev/null || exit_code=$?

  assert_exit_code "戻り値0を返す" "0" "$exit_code"

  rm -f "$attempt_file"
  unset -f claude
  unset ATTEMPT_FILE
}

# テスト: 3回連続失敗で戻り値1を返すこと
test_recovery_all_fail() {
  echo "[テスト] 3回連続失敗で戻り値1を返す"

  # claudeコマンドのモック: 常に失敗
  claude() {
    cat > /dev/null  # stdinを消費
    echo "エラー発生" >&2
    return 1
  }
  export -f claude

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  local exit_code=0
  echo "テストプロンプト" | run_claude_with_recovery --allowedTools "Bash" 2>/dev/null || exit_code=$?

  assert_exit_code "戻り値1を返す" "1" "$exit_code"

  unset -f claude
}

# テスト: 修復プロンプトにエラー出力と元プロンプトが含まれること
test_recovery_prompt_contains_error_and_original() {
  echo "[テスト] 修復プロンプトにエラー出力と元プロンプトが含まれる"

  local capture_file
  capture_file=$(mktemp)
  local attempt_file
  attempt_file=$(mktemp)
  echo "0" > "$attempt_file"

  # claudeコマンドのモック: 1回目失敗、2回目で受信プロンプトをキャプチャして成功
  claude() {
    local count
    count=$(cat "$ATTEMPT_FILE")
    count=$((count + 1))
    echo "$count" > "$ATTEMPT_FILE"
    if [ "$count" -eq 1 ]; then
      cat > /dev/null  # stdinを消費
      echo "テストエラーメッセージ" >&2
      return 1
    fi
    # 2回目: 修復プロンプトをキャプチャ
    cat > "$CAPTURE_FILE"
    return 0
  }
  export -f claude
  export ATTEMPT_FILE="$attempt_file"
  export CAPTURE_FILE="$capture_file"

  source "$VDEV_HOME/bin/lib/git-utils.sh"
  echo "元のテストプロンプト" | run_claude_with_recovery --allowedTools "Bash" 2>/dev/null

  local captured
  captured=$(cat "$capture_file")

  assert_contains "エラー出力が含まれる" "テストエラーメッセージ" "$captured"
  assert_contains "元のプロンプトが含まれる" "元のテストプロンプト" "$captured"

  rm -f "$capture_file" "$attempt_file"
  unset -f claude
  unset ATTEMPT_FILE
  unset CAPTURE_FILE
}

test_recovery_first_success
test_recovery_second_success
test_recovery_all_fail
test_recovery_prompt_contains_error_and_original

# ====================================================================
# rfc-init ブランチ作成冪等化のテスト
# ====================================================================
echo ""
echo "=== rfc-init ブランチ作成冪等化テスト ==="

# テスト: ブランチ作成コマンドに冪等化パターンが適用されていること
test_rfc_init_idempotent_branch() {
  echo "[テスト] rfc-init に冪等化パターンが適用されている"

  local rfc_init_content
  rfc_init_content=$(cat "$VDEV_HOME/bin/rfc-init")

  assert_contains \
    "checkout -b に 2>/dev/null フォールバックがある" \
    '2>/dev/null || git checkout "rfc/${SLUG}"' \
    "$rfc_init_content"
}

test_rfc_init_idempotent_branch

# ====================================================================
# adev.sh 冪等性スキップのテスト
# ====================================================================
echo ""
echo "=== adev.sh 冪等性スキップテスト ==="

# テスト: 実装PRマージ済みでスキップ処理が存在すること
test_adev_skip_merged_feature() {
  echo "[テスト] 実装PRマージ済みスキップのコードが存在する"

  local adev_content
  adev_content=$(cat "$VDEV_HOME/bin/adev.sh")

  assert_contains \
    "get_pr_status feature/ の呼び出しがある" \
    'get_pr_status "feature/${slug}"' \
    "$adev_content"

  assert_contains \
    "MERGED でスキップする分岐がある" \
    '実装PR マージ済み。スキップします。' \
    "$adev_content"
}

# テスト: RFC PRマージ済みで実装工程から再開する処理が存在すること
test_adev_skip_merged_rfc() {
  echo "[テスト] RFC PRマージ済みで実装工程から再開するコードが存在する"

  local adev_content
  adev_content=$(cat "$VDEV_HOME/bin/adev.sh")

  assert_contains \
    "get_pr_status rfc/ の呼び出しがある" \
    'get_pr_status "rfc/${slug}"' \
    "$adev_content"

  assert_contains \
    "RFC マージ済みで実装から再開する分岐がある" \
    'RFC PR マージ済み。実装工程から再開します。' \
    "$adev_content"
}

# テスト: AI修復ループが適用されていること
test_adev_recovery_loop_applied() {
  echo "[テスト] run_claude_with_recovery が adev.sh に適用されている"

  local adev_content
  adev_content=$(cat "$VDEV_HOME/bin/adev.sh")

  # Step 3-1 と Step 3-3 の両方で使われていること
  local count
  count=$(grep -c "run_claude_with_recovery" "$VDEV_HOME/bin/adev.sh")

  assert_equals "run_claude_with_recovery が2箇所で使用されている" "2" "$count"
}

# テスト: stdinパイプ方式が適用されていること
test_adev_stdin_pipe() {
  echo "[テスト] Step 3-3 が stdin パイプ方式である"

  local adev_content
  adev_content=$(cat "$VDEV_HOME/bin/adev.sh")

  # 位置引数方式の claude -p "..." が残っていないこと
  local old_pattern_count
  old_pattern_count=$(grep -c 'claude -p \\' "$VDEV_HOME/bin/adev.sh" 2>/dev/null || echo "0")

  # stdin パイプ方式（cat <<PROMPT_EOF ... | ）が使われていること
  assert_contains \
    "PROMPT_EOF ヒアドキュメントが使われている" \
    "PROMPT_EOF" \
    "$adev_content"
}

test_adev_skip_merged_feature
test_adev_skip_merged_rfc
test_adev_recovery_loop_applied
test_adev_stdin_pipe

# ====================================================================
# テスト結果サマリー
# ====================================================================
echo ""
echo "=============================="
echo "テスト結果: ${TESTS_PASSED}/${TESTS_RUN} 通過"
if [ "$TESTS_FAILED" -gt 0 ]; then
  echo "失敗: ${TESTS_FAILED} 件"
  exit 1
else
  echo "全テスト通過"
  exit 0
fi
