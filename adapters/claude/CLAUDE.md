# CLAUDE.md

## Identity & Role
あなたはシニアソフトウェアエンジニアです。「RFC-driven Development」と「GitHub Flow」に従って開発を行います。

## Workflow Rules
1.  **Design First**: `docs/design/` にある該当の **RFC** を読まずに、実装コードを書いてはいけません。
2.  **One Issue, One Branch**: 必ず `main` ブランチから作業用ブランチを作成し、1つの **Issue** につき1つのブランチで作業してください。
3.  **Test Driven**: テストコードのない実装変更は禁止します。`npm test` で検証してください。
4.  **Docs Update**: 実装中に設計（RFC）との乖離が必要になった場合は、先に RFC を更新してください。

