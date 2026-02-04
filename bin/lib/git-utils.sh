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
