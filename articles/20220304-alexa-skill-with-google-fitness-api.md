---
title: "Google Fit APIを使って声で体重を記録・管理できるAlexaスキルを開発してみた"
emoji: "🔊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["alexa", "googlefit"]
published: false
---


## はじめに
タイトルの通りなのですが、

Alexa を使って、声だけで体重を管理、記録できるようにしたい。

スキルは非公開です。

### 実現したいこと

構成図を載せる

## Alexa スキルについて

Alexa スキルとは Alexa 向けのアプリのことです。例えば天気やニュースを教えてくれたり、音楽を流すことができます。
基本的には、

> ユーザー「アレクサ、今日の天気は？」
アレクサ「東京の天気は晴れです。」

のように Alexa に話しかけることで、Alexa が質問内容に応じて返事をしてくれます。

Alexa スキルを自分で開発することができ、Alexa Skill Kit として様々なツールが用意されています。
https://developer.amazon.com/ja-JP/alexa/alexa-skills-kit

### Alexa スキル開発の流れ

Alexa がユーザーの問いかけに対して返事をするまでの基本的な流れは以下のようになっています。
![Alexa スキルのしくみ](https://storage.googleapis.com/zenn-user-upload/3034a9cd85d9-20220305.png)
（引用：https://developer.amazon.com/ja-JP/alexa/alexa-skills-kit/start）

1. ユーザーが問いかける（例：「アレクサ、今日の天気は？」）
2. ユーザーが話した内容を対話モデル (Skill Interaction Model) を元に音声を処理して、ユーザーがどのようなリクエストを出したのかを識別する
3. 対話モデルによって識別されたリクエストをアプリケーションロジック（サーバー）に送り、アプリケーションロジックはスキルに応じた処理を行い、Alexa が答える文言を返却します。（例：天気を調べ、「東京の天気は晴れです。」という文言を生成する）
4. Alexa がユーザーに返事します。（例：「東京の天気は晴れです。」）

対話モデル（❷）とアプリケーションロジック（❸）の部分を開発することになります。
対話モデルは Alexa の[開発者コンソール](https://developer.amazon.com/alexa/console/ask)から作成することができます。アプリケーションロジックは開発者コンソール内でコーディング＆デプロイする方法のほか、AWS の Lambda など自分で用意したサーバーのアプリケーションで構築することができます。

まずはこちらのチュートリアルで簡単に Alexa スキルを開発することできます！簡単に開発できるのでぜひ試してみてください。
https://developer.amazon.com/ja/blogs/alexa/post/31c9fd71-f34f-49fc-901f-d74f4f20e28d/alexatraining-firstskill

### 「たいレコ」のモデルを構築してみる

今回の「たいレコ」スキルの対話モデルを作成していきます。

開発者コンソール画面の「スキル」タブから「スキルの作成」を押し、新しくスキルを作成します。
https://developer.amazon.com/alexa/console/ask





## Google Fit API について
## Alexa スキルの開発手順
## （詰まったところ）
デプロイエラー

## 学んだこと

- Alexa スキルを自分の手で開発することができた。
- OAuth 2.0 の仕組みについて理解できた。
- Terraform でインフラリソースの構成管理をする方法を知った。
