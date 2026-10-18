# Zenn Contents

* [📘 How to use](https://zenn.dev/zenn/articles/zenn-cli-guide)
* [📘 Markdown guide](https://zenn.dev/zenn/articles/markdown-guide)

## 開発環境

Node.jsとnpmは[mise](https://mise.jdx.dev/)で管理します。
リポジトリのルートで以下を実行してください。

```sh
mise install
mise exec -- npm ci
mise exec -- npm run help
```

記事のプレビューと文章のチェックは以下で実行できます。

```sh
mise exec -- npm run preview
mise exec -- npm run lint
```
