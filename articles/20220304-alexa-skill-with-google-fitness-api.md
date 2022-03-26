---
title: "Google Fit アプリに音声で体重を記録できる Alexa スキルを開発してみた"
emoji: "🔊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["alexa", "googlefit"]
published: false
---


## はじめに
タイトルの通りなのですが、Google Fit という健康管理アプリに音声で体重を記録できる Alexa スキル「たいレコ」を開発してみました。（※スキルは非公開）

動機としては、Alexa スキルを一度開発してみたかったのと、声だけで体重を記録できるようになったら面白いかなと思ったからです。


デモ動画はこちらです。

https://youtu.be/cnYnPNduE_M

こんな感じで Alexa （Echo Show 5）に体重を伝えると、Google Fit に体重が記録されます。

![Google Fit アプリ](https://storage.googleapis.com/zenn-user-upload/c4976d447765-20220326.png =300x)

### 構成

以下のような構成で実現しています。

![構成図](https://storage.googleapis.com/zenn-user-upload/ff8f6ee8344a-20220326.png)

ユーザーが「65 キロと記録して」とリクエストすると、Alexa の対話モデルが音声を認識し Lambda 関数にリクエストを送ります。そして、Google Fit API を呼ぶことで体重データを記録します。最後にユーザーに応答を音声で返して完了です。
アプリからは Google Fit API 経由で記録された体重データを参照することができます。 

ソースコードはこちら。
https://github.com/yuma-ito-bd/alexa-weight-record-skill

以下、Alexa スキルの開発方法に関して、今回開発した体重記録スキル「たいレコ」の例を交えながら簡単に説明します。
:::message
Alexa スキルの開発だけで量が多くなってしまった（~~気力、体力が尽きてしまった~~）ので、Google Fit API については説明しません。以下のスクラップを読んでいただくか、ソースコードをご覧ください。
https://zenn.dev/yuma_ito_bd/scraps/5360873211bcad
:::

## Alexa スキルについて

Alexa スキルとは Alexa 向けのアプリのことです。例えば天気やニュースを教えてくれたり、音楽を流すことができます。
基本的には、

> ユーザー「アレクサ、今日の天気は？」
アレクサ「東京の天気は晴れです。」

のように Alexa に話しかけることで、Alexa が質問内容に応じて返事をしてくれます。（厳密には Alexa が搭載されたデバイスやアプリとやり取りをしますが、簡略のため音声インターフェースも含めて Alexa と呼ぶことにします）

Alexa スキルは自分で開発することができ、Alexa Skill Kit として様々なツールが用意されています。
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

#### スキルの新規作成
今回の体重記録スキル「たいレコ」スキルの対話モデルを作成していきます。（チュートリアルと被る箇所は適宜省略します）

まず、[開発者コンソール](https://developer.amazon.com/alexa/console/ask)画面の「スキル」タブから「スキルの作成」を押し、新しくスキルを作成します。
![開発者コンソール](https://storage.googleapis.com/zenn-user-upload/45cf7b48f513-20220326.png)

スキル名を入力し、追加する対話モデルの種類とアプリケーションロジックにあたるバックエンドリソースをホスティングする方法を選択します。

![スキルの作成](https://storage.googleapis.com/zenn-user-upload/30388c4ca3d5-20220307.png)

バックエンドリソースのホスティング方法は以下の3種類から選択できます。

- Alexa-hosted (Node.js): Alexa が用意してくれる Node.js の Lambda です。自分でリソースを用意しなくて良いので、チュートリアルとして利用したり、手軽に作成したい場合はこちらを選択すると良いと思います。
- Alexa-hosted (Python): 同じく Alexa が用意してくれる Python の Lambda です。Python で構築したい方はこちらを選択。
- ユーザー定義のプロビジョニング: 自分でリソースを用意した上で、Alexa の対話モデルからリクエストを投げる方法です。バックエンドリソースは自分好みに選択できるので、Lambda に限らず、EC2 や ECS でも可能ですし、AWS のサービスではなく Azure や GCP でもオンプレでも利用することもできます。（Alexa スキルくらいの簡単なアプリケーションなら Lambda で十分なパターンが多いと思います。）

#### スキルの呼び出し名
次にスキルの呼び出し名を設定します。スキルの呼び出し名とは、スキルを呼び出す際に「Alexa、○○を開いて」と呼びかける際の○○のフレーズです。デフォルトではスキル名が設定されています。
![スキルの呼び出し名](https://storage.googleapis.com/zenn-user-upload/c41a2b788d5d-20220326.png)

#### 対話モデル
次に、対話モデルの構築を行います。
対話モデルは、ユーザーの声によるリクエストをアプリケーションロジック用のリクエストに変換する役割を担います。つまり、ユーザーとアプリケーションロジックを結ぶ音声インターフェースとなります。

https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/create-the-interaction-model-for-your-skill.html

ここで、重要な概念が2つあります。「インテント」と「スロット」です。

インテント (Intent) とは、ユーザーのリクエストを満たすアクションのことです。アプリケーションロジックはインテントに対応した処理を実行します。ユーザーの音声によるリクエストをインテントに変換することで、アプリケーションロジックが処理を行えるようになります。

Web アプリケーションでの MVC フレームワークの C (Controller) にあたる部分です。Android アプリにも同じような概念があるようです。

例えば、「たいレコ」では「60キロと記録して」という音声フレーズを RegisterIntent というインテントに変換するように定義できます。アプリケーションロジックでは、RegisterIntent に対応する処理（体重を記録する）を実行します。（詳しくは具体的なコードを含めて後述します。）

そして、スロットとは、ユーザーのリクエストに含まれる可変情報（日付、数量、種類など）を表したものです。スロットの設定は任意です。

例えば、「60キロと記録して」というフレーズでは「60」の部分が可変情報となります。

スロット名とスロットタイプを定義します。スロット名はインテントに含まれる変数名のことで、アプリケーションロジックではスロット名を参照することでスロットの値をすることができます。スロットタイプとは、スロットの種類のことで、数値や日付などを設定します。数値や日付などはあらかじめ標準タイプとして用意されており、またリストとして自分で定義することもできます。（[スロットタイプリファレンス \| Alexa Skills Kit](https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/slot-type-reference.html#list-types)）

前置きが長くなりましたが、それでは「たいレコ」の対話モデルの設定を行いましょう。

まず、たいレコでは「体重を記録する」というアクションが必要なので、RegisterIntent というインテントを定義しましょう。

サイドバーから「カスタム＞対話モデル＞インテント」をクリックします。次に「インテントを追加」をクリックします。
![インテントを追加](https://storage.googleapis.com/zenn-user-upload/ff212eca49a8-20220326.png)

「RegisterIntent」と入力し、「カスタムインテントを作成」をクリックします。
![カスタムインテントを作成](https://storage.googleapis.com/zenn-user-upload/9f34e10d6c62-20220326.png)

次に、「サンプル発話」にユーザーの音声リクエストのパターンを設定します。1つのインテントに対して、複数の音声パターンを割り当てることができます。（このパターンを多数用意することで、ユーザーが異なる表現をしても柔軟に応答することができ、UXの向上につながるかと思います。）

今回は以下のパターンを設定します。（数字は漢数字で入力します）

- 「六十キロと記録して」
- 「六十キロ」（数値だけ言うパターン）

![サンプル発話の追加1](https://storage.googleapis.com/zenn-user-upload/ca0caa48a08c-20220326.png)

これだけでは「六十キロ（60キロ）」しか記録することができないので、スロットを定義することで任意の体重を記録できるようにします。

「インテントスロット」にスロット名とスロットタイプを以下のように入力します。

- スロット名: `weight`
- スロットタイプ: `AMAZON.NUMBER` （数値を識別できる標準スロットタイプ）

![スロットの追加](https://storage.googleapis.com/zenn-user-upload/1def50b6f7ef-20220326.png)

スロットを定義したので、サンプル発話を以下のように修正します。

- `{weight}`キロと記録して
- `{weight}`キロ

![サンプル発話2](https://storage.googleapis.com/zenn-user-upload/88c68c70ac95-20220326.png)

そして、「モデルを保存」を押して設定を保存します。

この設定によって、ユーザーが「XXキロと記録して」または「XXキロ」とリクエストした場合、`RegisterIntent` が呼ばれ、スロット `weight` には XX という数値が入っています。

設定が完了したら「モデルをビルド」をクリックして、対話モデルをビルドしましょう。設定したフレーズによって対応するインテントが呼ばれるようになります。

モデルのビルドが完了したら、対話モデルの構築は完了です。

### アプリケーションロジックの開発

対話モデルの構築が完了したので、次はアプリケーションロジックの開発を行います。

アプリケーションロジックは先述の通り、アプリケーションをホスティングするバックエンドリソースや使用する言語は自由に選ぶことができます。

Lambda を利用する場合は以下を参照。
https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/host-a-custom-skill-as-an-aws-lambda-function.html

それ以外のリソース を利用する場合は以下を参照。
https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/host-a-custom-skill-as-a-web-service.html

スキルの作成時に Alexa-hosted (Node.js) または Alexa-hosted (Python) を選択した場合は、「コードエディタ」タブからアプリケーションコードの作成を行うことができます。（ローカル環境でコーディングし、zip ファイルでソースコードをアップロードすることも可能です）

アプリケーションロジックの開発では、以下の SDK が用意されているのでそれを活用すると効率よく開発できると思います。

- [alexa/alexa\-skills\-kit\-sdk\-for\-nodejs](https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs)
- [alexa/alexa\-skills\-kit\-sdk\-for\-python](https://github.com/alexa/alexa-skills-kit-sdk-for-python)

今回は Node.js 用の SDK を利用して TypeScript で開発しました。

この SDK に関してもチュートリアル「[初めてのスキル開発 — ASK SDK for Node\.js ドキュメント](https://ask-sdk-for-nodejs.readthedocs.io/ja/latest/Developing-Your-First-Skill.html)」が用意されています。

必要な NPM パッケージをインストールします。

```bash
npm install --save ask-sdk
```

Lambda で最初に呼び出される `handler` 関数を作成します。
```typescript: index.ts
import { SkillBuilders } from 'ask-sdk-core';
import {
    cancelAndStopIntentHandler,
    errorHandler,
    helpIntentHandler,
    launchRequestHandler,
    registerIntentHandler,
    sessionEndedRequestHandler,
} from './app/alexaHanders';

const handler = SkillBuilders.custom()
    .addRequestHandlers(
        launchRequestHandler,
        registerIntentHandler,
        helpIntentHandler,
        cancelAndStopIntentHandler,
        sessionEndedRequestHandler
    )
    .addErrorHandlers(errorHandler)
    .lambda();

export { handler };
```

`ask-sdk-core` に含まれる `SkillBuilders` クラスを利用することで、簡単に Lambda 用のハンドラ関数を作成することができます。

ここで、`addRequestHandlers` 関数で、いくつかのリクエストハンドラと呼ばれる関数が呼び出されています。
リクエストハンドラこそが Alexa スキルの要となっており、スキルによって大きく処理が変わってきます。

たいレコでは、`registerIntentHandler` リクエストハンドラで体重の記録を行っています。

```ts:alexaHanders.ts
export const registerIntentHandler: RequestHandler = {
    canHandle(handlerInput: HandlerInput): boolean {
        const { request } = handlerInput.requestEnvelope;
        return (
            request.type === 'IntentRequest' &&
            request.intent.name === 'RegisterIntent'
        );
    },
    async handle(handlerInput: HandlerInput): Promise<Response> {
        // 体重の数値を取り出して登録する
        const weight = (handlerInput.requestEnvelope.request as IntentRequest)
            .intent.slots?.weight?.value;

        if (weight == null) {
            const speakText =
                'すみません。体重を聞き取れませんでした。もう一度教えてください。';
            return handlerInput.responseBuilder
                .speak(speakText)
                .reprompt(speakText)
                .withSimpleCard('エラー', speakText)
                .getResponse();
        }

        const dataSourceId = process.env.DATA_SOURCE_ID;
        if (dataSourceId == null) throw new Error('DATA_SOURCE_ID is not set');

        const oauth2Client = getOAuth2ClientForLambda();
        const usecase = new RegisterBodyData(oauth2Client, dataSourceId);
        usecase.exec(Number(weight), new Date());

        const speechText = `体重を${weight}キロで記録しました。また明日も記録してくださいね！`;

        return handlerInput.responseBuilder
            .speak(speechText)
            .withSimpleCard('体重記録完了！', speechText)
            .getResponse();
    },
};

```

リクエストハンドラの型 `RequestHandler` は以下です。

```ts
export interface RequestHandler<Input, Output> {
    canHandle(input: Input): Promise<boolean> | boolean;
    handle(input: Input): Promise<Output> | Output;
}
```

- `canHandle`: リクエストが自身のインテントかどうかを判断します。`registerIntentHandler` ではインテントの名前が先程開発者コンソールで登録した `RegisterIntent` であるかどうかを判断しています。
- `handle`: `canHandle` が `true` の場合に実行する処理です。`registerIntentHandler` ではリクエストから値を取り出して、Google Fit に登録する処理を実行し、レスポンスを生成しています。

リクエストハンドラを複数用意することで、様々なユーザーの要求に応えることができるようになります。

### アプリケーションロジックのデプロイ

アプリケーションロジックとなるコードの作成が完了したら、アプリケーションとしてデプロイしましょう。

#### Alexa-hosted を選択した場合
スキルの作成時に Alexa-hosted (Node.js) または Alexa-hosted (Python) を選択した場合は、「コードエディタ」タブで直接コードを生成するか、「Import Code」から zip ファイルでソースコードをインポートすることができます。

![コードのインポート](https://storage.googleapis.com/zenn-user-upload/19539b1f0139-20220326.png)

そして、「デプロイ」ボタンを押すと Lambda 関数が自動的に作成されてアプリケーションをデプロイすることができます。（とても楽です）


#### 自前の Lambda を利用する場合

今回は諸事情があり、自分で用意した Lambda を利用しました。（その理由については「（おまけ）Google Fit API の NPM パッケージが含まれていると、Alexa-hosted Lambda のデプロイエラーになる」にて）

https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/host-a-custom-skill-as-an-aws-lambda-function.html

まずは AWS で Lambda 関数を作成し、アプリケーションをデプロイしてください。（私は Terraform を利用して Lambda 関数を作成しました。）
作成した Lambda の ARN をコピーしておきます。
![Lambdaの作成](https://storage.googleapis.com/zenn-user-upload/e22540fc560b-20220226.png)

:::message
私は東京リージョンで Lambda 関数を作成しましたが、日本の場合は米国西部（オレゴン）(`us-west-2`) が最適だそうです。東京リージョンでも利用は可能です。
（参考：[カスタムスキルをAWS Lambda関数としてホスティングする \| Alexa Skills Kit](https://developer.amazon.com/ja-JP/docs/alexa/custom-skills/host-a-custom-skill-as-an-aws-lambda-function.html#select-the-optimal-region-for-your-aws-lambda-function)）
:::

次に、開発者コンソールの「ビルド」タブ＞カスタム＞エンドポイントを開いて、作成したLambdaのARNを入力します。

![ARNの入力](https://storage.googleapis.com/zenn-user-upload/1e46ed2d700c-20220226.png)

この状態で「エンドポイントを保存」をクリックすると以下のエラーが発生してしまいます。

![エンドポイント保存エラー](https://storage.googleapis.com/zenn-user-upload/ec47327c35ef-20220226.png)

まだ Lambda 関数を呼び出すために必要な権限を Alexa スキルに与えていないためです。

Alexa の開発者コンソールにある「スキルID」をコピーし、もう一度AWSコンソールに戻り、Lambda 関数の「トリガーを追加」から Alexa スキル ID を設定してください。

![トリガーの追加](https://storage.googleapis.com/zenn-user-upload/236df5772ba0-20220226.png)

そして、開発者コンソールの「エンドポイントを保存」をクリックすると成功しました！

![エンドポイント保存成功](https://storage.googleapis.com/zenn-user-upload/742b6e058c13-20220226.png)

### スキルのテスト

これで Alexa スキルの準備が整ったのでスキルのテストをしましょう。

開発者コンソールの「テスト」タブからテストを行うことができます。
マイクボタンを押し続けて話すか話す言葉を入力します。

![Alexaスキルのテスト](https://storage.googleapis.com/zenn-user-upload/47de806ac781-20220226.png)
※数字は漢数字で入力する必要があります。

できましたー！🎉🎉🎉

また、Echo Show 5 などの Alexa 搭載デバイスを持っている場合は、公開していなくてもデバイスからテストを行うことができます。（開発者コンソールでログインしているアカウントとデバイスでログインしているアカウントが同じである必要があります）

#### Lambda 関数単体でのテスト（補足）

Lambda 関数単体でテストをしたい場合、テストイベントのテンプレートに `alexa-skills-kit-start-session`（ LaunchRequest を送るイベント）が用意されているので、それを利用できます。

![Lambdaテストイベント](https://storage.googleapis.com/zenn-user-upload/be1699929c67-20220226.png)

これを実行して、LaunchIntent の応答が返ってきたらOK！
![Lambdaテスト](https://storage.googleapis.com/zenn-user-upload/c0d5bcdd64cc-20220226.png)

## （おまけ）Google Fit API の NPM パッケージが含まれていると、Alexa-hosted Lambda のデプロイエラーになる
詳しい原因はわかっていないのですが、Google Fit API の NPM パッケージが `package.json` に含まれている状態、かつホスティング方法に Alexa-hosted (Node.js) を選択した状態ではデプロイエラーになりました。

`package.json` は以下でした。
```json:package.json
  "dependencies": {
    "ask-sdk": "^2.12.0",
    "ask-sdk-core": "^2.12.0",
    "ask-sdk-model": "^1.37.2",
    "googleapis": "^95.0.0",
    "open": "^8.4.0",
    "server-destroy": "^1.0.1"
  }
```

自分で Lambda 関数を用意することでこのエラーを回避しました。

## さいごに

作ってみた感想としては、

- Alexa スキルは意外と簡単に作ることができて面白かった。
- スキル開発を通して新しい技術について知ることができた。（OAuth 2.0 による認可, Terraform でのインフラ構成管理）
- Google Fit API の仕様を理解して、コーディングするのが意外と時間がかかった。。。
- 小数を含む体重も聞き取ってくれて、音声認識の精度の高さに驚いた
- 過去に記録した体重を Alexa から確認する方法は一工夫が必要と感じた（単に数値をつらつらと言われてもあまり嬉しくないなと）

以上です。Alexa スキルの開発は楽しかったので是非皆さんもやってみてください！

最後まで読んでいただいてありがとうございました🙇‍♂️