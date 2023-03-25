---
title: "[AWS CodePipeline] デプロイ時にCodeBuildを用いてDBマイグレーションを行う方法"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["AWS", "CodePipeline", "CodeBuild"]
published: true
---

## この記事で説明すること
CodePipelineを用いたCICDパイプラインにCodeBuildを使ったDBマイグレーションを組み込む方法を紹介します。

背景としては、手動で行っていたDBマイグレーションに手間や時間がかかっていたため、自動化する方法を探しました。
もともとCodePipelineを用いてデプロイの自動化はできていたので、そこにDBマイグレーションを行うフェーズを追加することでDBマイグレーションの自動化を実現しました。

## 前提
この記事でのDBマイグレーションとは、テーブルの追加やテーブル定義の変更などを示します。また、アプリケーションのデプロイよりもDBマイグレーションを先に行ってもエラーが発生しないことを前提としています。

また、新しいリソースやIAMロールを作ることができるユーザーを用意してください。

## インフラ構成図
本記事で紹介する構成図は以下です。中央のMigrationフェーズの部分がメイントピックです。マルチAZ構成などは省略しています。
![インフラ構成図](https://storage.googleapis.com/zenn-user-upload/24e61c027fff2249e6e5a8a4.png)

DBマイグレーションの部分の拡大図は以下です。
![](https://storage.googleapis.com/zenn-user-upload/9c96ec4192e83056544fcd82.png)

## 主に利用するAWSリソース
- CodeBuild（DBマイグレーションを実行するため）
- CodePipelineとソースアーティファクト用のS3バケット
- RDS（マイグレーション対象のDB）
- VPC, サブネット、セキュリティーグループなど

## 手順とポイント
1. CodeBuildを設置するためのprivateサブネットを用意します。依存パッケージ（npmパッケージなど）をインターネットからインストールするため、NATゲートウェイを設置します。privateサブネットからインターネットに出られればOKです。さらに、CodePipelineを作成しておきます。今回の構成ではソースとしてCodeCommit、ビルド・テスト用のCodeBuild、CodeDeployでECSへデプロイします。
2. DBマイグレーション用のCodeBuildのセキュリティーグループを作成します。インバウンドルールは設定不要です。
![](https://storage.googleapis.com/zenn-user-upload/0288ed00f31eef05a9fd51db.png)
3. RDSのセキュリティーグループのインバウンドルールにCodeBuildのセキュリティーグループを追加します。プロトコルやポートは適宜設定してください。インバウンドルールを設定することで、CodebuildからDBにアクセスできるようになります。
![](https://storage.googleapis.com/zenn-user-upload/0fb08008d3618ae6010fca6e.png)
1. CodePipelineにMigrationステージを作成、CodeBuildを新しく作成します。（デプロイステージよりも先）
    - 「環境」＞「追加設定」でVPCとprivateサブネットを指定します。サブネットは上記で用意したprivateサブネットです。
    ![](https://storage.googleapis.com/zenn-user-upload/c961647330a83cffe1ea6bd7.png)
    - `buildspec.yml`を作成します。`buildspec.yml`はCodeBuild内で実行するコマンドや設定を記載したファイルです。CodeCommitのリポジトリに含める場合は、「buildspecファイルを使用する」を選択します。私はビルド用の`buildspec.yml`と区別するため、ファイル名を`buildspec-migration.yml`としました。コマンドには、マイグレーションに必要な依存パッケージのインストールとマイグレーション実行コマンドを記述します。
        ```yml:buildspec-migration.yml
        version: 0.2

        phases:
        install:
            on-failure: ABORT
            runtime-versions:
            nodejs: 12
        pre_build:
            on-failure: ABORT
            commands:
            - npm ci
        build:
            on-failure: ABORT
            commands:
            - npm run db:migrate
        ```
    - CodeBuildの環境変数にDBへ接続するために必要な情報を設定します。
    
    :::message
    セキュリティーのため、認証情報の管理はAmazon Secrets Managerを利用することをおすすめします。
    :::

    - プロキシサーバーを用いている場合は環境変数または`buildspec-migration.yml`内のコマンドでプロキシの設定をします。
2. CodeBuildのポリシーを確認します。
    - CodePipelineのアーティファクトストアに設定したS3バケットに対して、`GetObject`できることを確認します。
    ![](https://storage.googleapis.com/zenn-user-upload/165d0b7ab22792f87a778649.png)
    ![](https://storage.googleapis.com/zenn-user-upload/263859cce1c394f923cf5c28.png)
3. S3のVPCエンドポイントを作成します。
    - VPC内に設置されたCodeBuildからVPC外にあるS3にアクセスするために必要です。VPCエンドポイントがない場合、作成します。
4. 設定が完了したら、Pipelineを実行します。CodeBuildのログでDBへのマイグレーションができていたら成功です。

## 構築時に詰まったこと
### Source Downloadで403エラーになる
CodeBuildのポリシー、S3バケットのバケットポリシー、S3のVPCエンドポイントを確認しましょう。私はCodeBuildのポリシーでS3のリソースの指定で間違えていました。具体的には`*`がなかったので、S3バケット内のオブジェクトを取得できていませんでした、

### DBに接続できない
DBの接続情報を確認しましょう。また、RDSのセキュリティーグループのインバウンドルールにCodeBuildのセキュリティーグループが許可されているか確認しましょう。

### 依存パッケージのインストールが進まない
CodeBuildがあるprivateサブネットからインターネットにアクセスできるか確認しましょう。プロキシサーバーを用いる場合、例えば環境変数に`HTTP_PROXY`, `HTTPS_PROXY`というキーを追加し、プロキシサーバーのURLを値にセットすることで、プロキシサーバーを経由してインストールすることができます。

## まとめ
紹介は以上です。デプロイ作業を適切に自動化することで、作業時間の削減や人為的なミスを減らすことができます。これからも今回のような改善を続けていきたいです。

読んでいただき、ありがとうございました。

### 参考にしたサイト
https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/vpc-support.html#best-practices-for-vpcs
https://qiita.com/Mister_K/items/428e6bb61d9299bff83c
https://zenn.dev/faycute/articles/4735ce7b4342c7