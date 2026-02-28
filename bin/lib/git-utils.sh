#!/usr/bin/env bash
# Git関連のユーティリティ関数

# デフォルトブランチ名を取得する
# リモートから取得できない場合は main → master の順でフォールバック
#
# 戻り値:
#   標準出力にデフォルトブランチ名を出力
get_default_branch() {
  local branch

  # 1. リモートのHEADから取得を試行
  branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d: -f2 | tr -d ' ')

  if [ -n "$branch" ]; then
    echo "$branch"
    return 0
  fi

  # 2. ローカルブランチの存在確認でフォールバック
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    echo "main" # デフォルト
  fi
}

# 指定ブランチのPR状態を取得する
#
# 引数:
#   $1: ブランチ名（例: rfc/20260301-xxx, feature/20260301-xxx）
#
# 戻り値:
#   標準出力に "MERGED", "OPEN", "NONE" のいずれかを出力
get_pr_status() {
  local branch="$1"

  if [ -n "$(gh pr list --head "$branch" --state merged \
    --json number --jq '.[0].number' 2>/dev/null)" ]; then
    echo "MERGED"
    return 0
  fi

  if [ -n "$(gh pr list --head "$branch" --state open \
    --json number --jq '.[0].number' 2>/dev/null)" ]; then
    echo "OPEN"
    return 0
  fi

  echo "NONE"
}

# claude -p をエラー修復ループ付きで実行する
#
# stdinからプロンプトを受け取り、claude -p に渡す。
# 失敗時はエラー出力を含む修復プロンプトで最大2回再実行する。
#
# 引数:
#   $@: claude -p に渡す追加オプション（--allowedTools 等）
#
# stdin:
#   claude -p に渡すプロンプト本文
#
# 戻り値:
#   成功時 0、最大試行到達時 1
run_claude_with_recovery() {
  local max_attempts=3
  local attempt=1
  local tmpfile
  tmpfile=$(mktemp)
  local errfile
  errfile=$(mktemp)
  trap 'rm -f "$tmpfile" "$errfile"' RETURN

  # stdinを一時ファイルに保存
  cat > "$tmpfile"

  while [ "$attempt" -le "$max_attempts" ]; do
    echo "[claude] 試行 ${attempt}/${max_attempts}" >&2

    if [ "$attempt" -eq 1 ]; then
      # 初回: 元のプロンプトをそのまま実行
      if cat "$tmpfile" | claude -p "$@" 2>"$errfile"; then
        return 0
      fi
    else
      # 修復: エラー情報を含むプロンプトで再実行
      # errfile の内容を事前に変数に保存する
      # （パイプ右辺の 2>"$errfile" によるトランケートとのレースを回避）
      local prev_error
      prev_error=$(cat "$errfile")
      local orig_prompt
      orig_prompt=$(cat "$tmpfile")
      if {
        cat <<RECOVERY_EOF
前回の実行が以下のエラーで失敗した。
エラー内容を分析し、問題を調査・修復した上で、
元のタスクを完遂せよ。

--- エラー出力 ---
${prev_error}

--- 元のプロンプト ---
${orig_prompt}
RECOVERY_EOF
      } | claude -p "$@" 2>"$errfile"; then
        return 0
      fi
    fi

    echo "[claude] 試行 ${attempt} 失敗" >&2
    attempt=$((attempt + 1))
  done

  echo "[claude] 最大試行回数(${max_attempts})に到達" >&2
  return 1
}
