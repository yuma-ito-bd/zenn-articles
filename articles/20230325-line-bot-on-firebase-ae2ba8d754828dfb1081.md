---
title: "LINE Messaging APIを使ってオウム返しbotを作成する (Cloud Functions for Firebase 環境)"
emoji: "🦜"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["line", "firebase"]
published: true
---

## はじめに
LINE Messaging APIを使ってオウム返しをするLINE botをCloud Functions for Firebaseを使って作成してみようと思います。

まず、LINE Messaging APIとはLINEユーザーとの双方向コミュニケーションを行えるようにするための機能です。
ユーザーが送ったメッセージに対して返信をしたり、任意のタイミングでユーザーやグループにメッセージを送ることができます。
詳しくは以下のドキュメントをご覧ください。
https://developers.line.biz/ja/services/messaging-api/

完成イメージは以下です。
![](https://storage.googleapis.com/zenn-user-upload/23ad3adfb9fa-20230318.png)

GitHubリポジトリ
https://github.com/yuma-ito-bd/line-messaging-api-bot

### 環境

主なツールのバージョンは以下。

- Node.js: v18.15.0
- firebase-tools (Firebase CLI): v11.24.1
- @line/bot-sdk (LINE Messaging APIのSDK): v7.5.2
- TypeScript: v4.9.5

## LINE Messaging APIの初期設定

まず、LINE Messaging APIを利用するための設定を行います。

### LINE bot用のチャネルを作成
[Messaging APIのページ](https://developers.line.biz/ja/services/messaging-api/)から「今すぐ始めよう」をクリックします。

![](https://storage.googleapis.com/zenn-user-upload/f2ccac61c286-20230312.png)

初めての場合はログインページが挟まるので、個人のLINEアカウントかビジネスアカウントでログインしてください。
![](https://storage.googleapis.com/zenn-user-upload/2adfd3e57a3c-20230325.png)

新しいチャネル（今回ではLINE botのこと）用の設定を行います。
チャネルの種類は「Messaging API」を選択してください。
![](https://storage.googleapis.com/zenn-user-upload/0ae5b80f3be4-20230312.png)


プロバイダー、チャネルなどの用語は以下のページで説明されています。

https://developers.line.biz/ja/docs/line-developers-console/overview/


## チャネルアクセストークンの取得

Messaging APIを利用するためには、チャネルアクセストークンという認証用トークンが必要です。
チャネルアクセストークンの説明は以下に載っています。
https://developers.line.biz/ja/docs/messaging-api/channel-access-tokens/

### チャネルアクセストークン v2.1 を作成する流れ

3種類のチャネルアクセストークンがありますが、v2.1というチャネルアクセストークンが推奨されています。
チャネルアクセストークンv2.1はJWTを使って任意の有効期間を指定できるトークンです。

チャネルアクセストークンの作成方法は以下です。
https://developers.line.biz/ja/docs/messaging-api/generate-json-web-token/

詳しくは上記ページに記載されているので、ここでは簡単な手順を説明します。

  1. アサーション署名キーのキーペアを生成する
      - Go, Python, ブラウザで生成する例が載っています。私はブラウザで生成しました。
  2. 「チャネル基本設定」＞「アサーション署名キー」から生成した公開鍵を設定する
  3. JWTを生成する
      - Node.jsのライブラリ`node-jose`を利用しました。
  4. チャネルアクセストークンv2.1を発行する
      - アクセストークン発行用のエンドポイントに生成したJWTを使ってリクエストします。
      - [チャネルアクセストークンv2.1を発行する Messaging APIリファレンス \| LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#issue-channel-access-token-v2-1)

### アサーション署名キーのキーペアを作成

私はブラウザのコンソールを使って署名キーを作成しました。
公開鍵はLINE Developersコンソールのチャネル基本設定タブにある「公開鍵を登録する」ボタンをクリックして登録してください。
秘密鍵は後で使うので`assertion-private.key.json`というファイルに保存しておきます。

### JWTを生成する

認証用のJWTを生成をするためには以下の情報が必要です。

- `kid`：アサーション署名キーの公開鍵を登録したことによって発行されたもの。「チャネル基本設定＞アサーション署名キー」から取得できます
- チャネルID：「チャネル基本設定＞チャネルID」
- アサーション署名キーの秘密鍵：前節で`assertion-private.key.json`に保存したもの

まず、環境変数として利用するべくプロジェクト配下に`.env`ファイルを作成し、チャネルIDと`kid`を登録します。
```:.env
CHANNEL_ID=<自分のチャネルID>
KID=<自分のkid>
```

次にJWTを生成するための`node-jose`というパッケージと環境変数を利用するための`dotenv`をインストールします。

```bash
npm i node-jose
npm i -D dotenv
```

そして、以下のような`make_token.js`ファイルを作成します。

```js:make_token.js
const jose = require("node-jose");
const fs = require("fs");
const path = require("path");

require("dotenv").config();

const makeJWT = async () => {
  const privateKey = JSON.parse(
    fs.readFileSync(path.join(__dirname, "assertion-private.key.json"))
  );

  const header = {
    alg: "RS256",
    typ: "JWT",
    kid: process.env.KID, // チャネル基本設定＞アサーション署名キー
  };

  const payload = {
    iss: process.env.CHANNEL_ID, // チャネルID
    sub: process.env.CHANNEL_ID, // チャネルID
    aud: "https://api.line.me/",
    exp: Math.floor(new Date().getTime() / 1000) + 60 * 25, // JWTの有効期間（UNIX時間）
    token_exp: 60 * 60 * 24 * 30, // チャネルアクセストークンの有効期間
  };

  const jwt = await jose.JWS.createSign(
    { format: "compact", fields: header },
    privateKey
  )
    .update(JSON.stringify(payload))
    .final();

  return jwt;
};

const createToken = async (jwt) => {
  const accessTokenUrl = "https://api.line.me/oauth2/v2.1/token";
  const response = await fetch(accessTokenUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_assertion_type:
        "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      client_assertion: jwt,
    }).toString(),
  });

  return response;
};

(async () => {
  const jwt = await makeJWT();
  const accessTokenResponse = await createToken(jwt);
  console.log(await accessTokenResponse.json());
})();
```

このスクリプトを実行すると、新しく作成したチャネルアクセストークンがコンソールに出力されます。

```
$ node make_token.js
{
  access_token: 'xxxxxx.yyyyyyyyy.zzzzzz',
  token_type: 'Bearer',
  expires_in: 2592000,
  key_id: 'aaaaaaaaaaa'
}
```
出力されたJSONの`access_token`がチャネルアクセストークンです。
チャネルアクセストークンはAPIを呼び出す際に利用するので、メモしておきましょう。

### （メモ）チャネルアクセストークンの発行時にエラーが発生
チャネルアクセストークンの発行を行った際に以下のようなエラーレスポンスが返ってきました。

```bash
$ node make_token.js 
{ error: 'invalid_client', error_description: 'Invalid exp' }
```
JWTの有効時間`payload.exp`が正しくないようです。有効時間を30分から25分に縮めたところ、正常にチャネルアクセストークンを取得することができました。

## Cloud Functions for Firebaseの利用準備

次はLINE Messaging APIからWebhookで呼ばれるバックエンドサーバーの準備をします。
今回はCloud Functions for Firebaseを利用します。（他のサービスでも利用可能ですが、Google Apps Scriptはおすすめしません。その理由はこの記事の最後をご覧ください）

Cloud Functions for Firebaseはサーバレスコンピューティングのサービスで、JavaScriptやTypeScriptの実行環境を簡単に用意してくれます。似たようなサービスではAWSのLambdaがあります。

https://firebase.google.com/docs/functions?hl=ja

[スタートガイド](https://firebase.google.com/docs/functions/get-started?hl=ja)などを参考にプロジェクトの初期化を行います。

まず、[Firebaseコンソール](https://console.firebase.google.com/?hl=ja)で[プロジェクトを追加]をクリックします。

次に、Firebase CLIをインストールします。

```bash
npm install -D firebase-tools
```

Firebase CLIにてGoogleアカウントにログインします。

```bash
npx firebase login
```

Cloud Functionsを利用するための初期化を行います。言語はTypeScriptを選択しました。
```bash
npx firebase functions
```
実行すると、`functions`というフォルダが作成されます。

フォルダ構成は以下です。（`package.json`が2つあるので注意）

```
.
├── assertion-private.key.json
├── firebase.json
├── functions
│   ├── node_modules
│   ├── package-lock.json
│   ├── package.json # Cloud Functionsで実行するコードのためのpackage.json
│   ├── src
│   ├── tsconfig.dev.json
│   └── tsconfig.json
├── make_token.js
├── node_modules
├── package-lock.json
└── package.json # firebase-toolsなどローカル環境で実行するコードのためのpackage.json
```

以降は`functions`フォルダ内で実装するので、`functions`フォルダ内に移動してください。

```bash
cd functions
```

動作確認用のサンプルコードの実装を行います。
`src/index.ts`ファイルを作成し、単純に文字列を返すようにします。

```ts:index.ts
import {https} from "firebase-functions";

export const webhook = https.onRequest((req, res) => {
  res.send("HTTP POST request sent to the webhook URL!");
});
```

`webhook`という変数を`export`することで、`webhook`という名前のCloud Functionsの関数が作成されるようになります。

次にデプロイをします。

```bash
npx firebase deploy --only functions
```

以下のようにデプロイのコマンドが実行されます。

```
=== Deploying to 'xxxxxxxxxxxxx'...

i  deploying functions
Running command: npm --prefix "$RESOURCE_DIR" run lint

> lint
> eslint --ext .js,.ts .

Running command: npm --prefix "$RESOURCE_DIR" run build

> build
> tsc

✔  functions: Finished running predeploy script.
i  functions: preparing codebase default for deployment
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
i  artifactregistry: ensuring required API artifactregistry.googleapis.com is enabled...
✔  artifactregistry: required API artifactregistry.googleapis.com is enabled
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged /home/xxxxxxxxxxxxxxx/functions (165.74 KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 16 function webhook(us-central1)...
✔  functions[webhook(us-central1)] Successful create operation.
Function URL (webhook(us-central1)): https://xxxxxxxxxxxxxxx.cloudfunctions.net/webhook
i  functions: cleaning up build files...

✔  Deploy complete!
```

Firebaseのコンソール画面から以下のように`webhook`という関数が表示されていればデプロイ完了です。
![](https://storage.googleapis.com/zenn-user-upload/477f1889999f-20230318.png)

関数のエンドポイント（デプロイコマンドのログの中にURLがあります）にブラウザからアクセスし、レスポンスが返ってくればOKです！
![](https://storage.googleapis.com/zenn-user-upload/ef6abfd338e6-20230318.png)


## LINE Messaging APIのWebhook URLを設定する

LINE Developersコンソールに戻り、「Messaging API設定」タブからWebhook設定を行います。
Webhook URLという項目に先程作成した関数のURLを設定して「検証」ボタンを押します。「成功」が表示されればOKです。

![](https://storage.googleapis.com/zenn-user-upload/6df12567f12f-20230318.png)

また、「Webhookの利用」をONにしてください。

![](https://storage.googleapis.com/zenn-user-upload/779434149992-20230318.png)

これにより、ユーザーがメッセージを登録したり、友達登録をした際にCloud Functionsでイベントを受け取れるようになりました。

## オウム返し機能を実装する

さて、本命のオウム返し機能を実装します。
今回はユーザーがテキストメッセージを送ってきた場合のみ考慮し、画像やスタンプ送信はスコープ外とします。

ユーザーにメッセージを送るためにはLINE Messaging APIの利用が必要です。
「LINE Messaging API SDK for nodejs」というSDKが用意されているのでインストールしましょう。
https://line.github.io/line-bot-sdk-nodejs/

```bash
npm install @line/bot-sdk
```
※Node.js以外のSDKも用意されています (参照：https://developers.line.biz/ja/docs/messaging-api/line-bot-sdk/)

そして、`index.ts`に以下のようなコードを書きます。

```ts:index.ts
import {https, logger} from "firebase-functions";
import {defineString} from "firebase-functions/params";
import {WebhookRequestBody, Client} from "@line/bot-sdk";

// 実行時に必要なパラメータを定義
const config = {
  channelSecret: defineString("CHANNEL_SECRET"),
  channelAccessToken: defineString("CHANNEL_ACCESS_TOKEN"),
};

export const webhook = https.onRequest((req, res) => {
  res.send("HTTP POST request sent to the webhook URL!");

  // LINE Messaging API Clientの初期化
  const lineClient = new Client({
    channelSecret: config.channelSecret.value(),
    channelAccessToken: config.channelAccessToken.value(),
  });

  // ユーザーがbotに送ったメッセージをそのまま返す
  const {events} = req.body as WebhookRequestBody;
  events.forEach((event) => {
    switch (event.type) {
    case "message": {
      const {replyToken, message} = event;
      if (message.type === "text") {
        lineClient.replyMessage(replyToken, {type: "text", text: message.text});
      }

      break;
    }
    default:
      break;
    }
  });
});
```
（コードの解説は後ほど）

デプロイコマンドを実行します。
途中で以下のような質問が来るので、チャネルシークレットとチャネルアクセストークンを入力します。（初回のみ）
```
? Enter a string value for CHANNEL_SECRET: xxxx
? Enter a string value for CHANNEL_ACCESS_TOKEN: xxxxxx
```

- `CHANNEL_SECRET`：LINE Developer Consoleの「チャネル基本設定」内にある「チャネルシークレット」
- `CHANNEL_ACCESS_TOKEN`：先程取得したチャネルアクセストークン

入力が完了すると、`.env.<project_ID>`という`.env`ファイルが作成されます。
ここではCloud Functions実行時のパラメータ（環境構成）を設定しています。パラメータを変更したい場合は`.env`ファイルを更新してください。
詳しくは、[環境を構成する  \|  Cloud Functions for Firebase](https://firebase.google.com/docs/functions/config-env?hl=ja#parameter_types) を参照してください。

:::message
チャネルアクセストークンは有効期間（最大30日間）があるので、期限が切れる前に入れ替える必要があります。
ローテーションに関しては今回の記事では省略します。
:::


さて、コードの解説をします。

```ts
// 実行時に必要なパラメータを定義
const config = {
  channelSecret: defineString("CHANNEL_SECRET"),
  channelAccessToken: defineString("CHANNEL_ACCESS_TOKEN"),
};
```
ここでは実行時に必要なパラメータの設定をしています。関数のデプロイ時にこれらの値が`.env`ファイルから読み込まれます。

:::message

きちんとサービスを運用する際には`defineString`ではなく`defineSecret`を指定して、Cloud Secret Managerでトークンなどの機密情報を管理した方が良いでしょう。
:::

```ts
// LINE Messaging API Clientの初期化
const lineClient = new Client({
  channelSecret: config.channelSecret.value(),
  channelAccessToken: config.channelAccessToken.value(),
});
```
LINE Messaging APIにリクエストを送るためのクライアントの初期化を行います。
`.value()`によってパラメータの読み込みをしています。


```ts
  // ユーザーがbotに送ったメッセージをそのまま返す
  const {events} = req.body as WebhookRequestBody;
```
Webhookによるリクエストの`body`のパラメータは以下のドキュメントに記載されています。

https://developers.line.biz/ja/reference/messaging-api/#webhook-event-objects

例としては、
```json
{
  "destination": "xxxxxxxxxx",
  "events": [
    {
      "type": "message",
      "message": {
        "type": "text",
        "id": "14353798921116",
        "text": "Hello, world"
      },
      "timestamp": 1625665242211,
      "source": {
        "type": "user",
        "userId": "U80696558e1aa831..."
      },
      "replyToken": "757913772c4646b784d4b7ce46d12671",
      "mode": "active",
      "webhookEventId": "01FZ74A0TDDPYRVKNK77XKC3ZR",
      "deliveryContext": {
        "isRedelivery": false
      }
    },
    {
      "type": "follow",
      "timestamp": 1625665242214,
      "source": {
        "type": "user",
        "userId": "Ufc729a925b3abef..."
      },
      "replyToken": "bb173f4d9cf64aed9d408ab4e36339ad",
      "mode": "active",
      "webhookEventId": "01FZ74ASS536FW97EX38NKCZQK",
      "deliveryContext": {
        "isRedelivery": false
      }
    },
    {
      "type": "unfollow",
      "timestamp": 1625665242215,
      "source": {
        "type": "user",
        "userId": "Ubbd4f124aee5113..."
      },
      "mode": "active",
      "webhookEventId": "01FZ74B5Y0F4TNKA5SCAVKPEDM",
      "deliveryContext": {
        "isRedelivery": false
      }
    }
  ]
}
```
です。複数のイベントがほぼ同時に起きた際、Webhookのリクエストはまとめて送られることがあるようです。

```ts
events.forEach((event) => {
  switch (event.type) {
  case "message": {
    const {replyToken, message} = event;
    if (message.type === "text") {
      lineClient.replyMessage(replyToken, {type: "text", text: message.text});
    }

   break;
  }
  ...
})
```
今回はユーザーが投稿したテキストメッセージをオウム返ししたいので、`events`配列の要素`event`に対して

- メッセージ送信のイベント：`event.type`が`message` 
- メッセージがテキストメッセージ：`event.message.typeが"text"`

の場合にレスポンスを返すようにします。（詳しいパラメータはドキュメントにすべて載っています）

最後に、メッセージを返信します。

```ts
lineClient.replyMessage(replyToken, {type: "text", text: message.text});
```
返信するために必要なパラメータはドキュメントを参照してください。

[応答メッセージを送る \| LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#send-reply-message)

## LINE botを友達登録してメッセージを送ってみる

やっとここまで来ました。
LINE Developersコンソールの「Messaging API設定＞QRコード」をLINEアプリで読み込んでください。

友達登録をしてテキストメッセージを送ってみると・・・？

![](https://storage.googleapis.com/zenn-user-upload/23ad3adfb9fa-20230318.png)

オウム返ししてくれました🎉


## 署名の検証を行う（本番環境では必須）

まだまだ終わりではありません。
本番環境にて運用する場合にはセキュリティー対策を行う必要があります。
LINEプラットフォーム以外からの不正なリクエストを防ぐために署名の検証を行います。

詳しくは、[署名を検証する \| LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#signature-validation) をご確認ください。

署名を検証するには3つの方法があります。

- SDKの[`middlewere`](https://line.github.io/line-bot-sdk-nodejs/api-reference/middleware.html)を利用する
  - Express.jsなどのWebフレームワークを利用している場合
- SDKの[`validateSignature`関数](https://line.github.io/line-bot-sdk-nodejs/api-reference/validate-signature.html)
  - 署名の検証の前に`body-parser`でリクエストのパースを行う環境（Firebase Cloud Functionsなど）や任意のタイミングで検証したい場合
- 自作の関数で検証する

今回の場合は、Cloud Functionsを使っているので、`validateSignature`関数を利用することにします。

```diff ts:index.ts
- import {WebhookRequestBody, Client} from "@line/bot-sdk";
+ import {WebhookRequestBody, Client, SignatureValidationFailed, validateSignature} from "@line/bot-sdk";

...

export const webhook = https.onRequest((req, res) => {
  res.send("HTTP POST request sent to the webhook URL!");

+  // 署名の検証
+  const channelSecret = config.channelSecret.value();
+  const signature = req.header("x-line-signature") ?? "";
+  if (!validateSignature(req.rawBody, channelSecret, signature)) {
+    throw new SignatureValidationFailed("invalid signature");
+  }

  // LINE Messaging API Clientの初期化
  ...
});
```

### 検証
ヘッダーに無効な署名を記載を載せてPOSTリクエストを送ります

```bash
curl \
  'https://<自分の環境のURL>/webhook' \
  -H 'X-Line-Signature: invalid signature' \
  -H 'Content-Type: application/json' \
  -d '{"destination": "xxxxxxxxxx","events": [{"type": "message","message": {"type": "text","id": "14353798921116","text": "Hello, world"},"timestamp": 1625665242211,"source": {"type": "user","userId": "U80696558e1aa831..."},"replyToken": "757913772c4646b784d4b7ce46d12671","mode": "active","webhookEventId": "01FZ74A0TDDPYRVKNK77XKC3ZR","deliveryContext": {"isRedelivery": false}}]}'
```

Cloud Functionsのログを確認するとエラーが吐かれ、不正なリクエストを弾くことができました。
![](https://storage.googleapis.com/zenn-user-upload/387f5be0d0f3-20230318.png)

## まとめ

LINE Messaging APIを使ってオウム返しbotを作成する手順を説明しました。
LINE Messaging APIのドキュメントがとても分かりやすかったので、基本的にはそちらを確認すれば大丈夫です。
LINE Messaging APIのSDKも揃っていますし、Firebase CLIも便利だったので今回の経験を生かして、次は独自のbotを作成したいです。

### 参考ページ

- [Messaging APIの概要 \| LINE Developers](https://developers.line.biz/ja/docs/messaging-api/overview/)
- [LINE Messaging API SDK for nodejs \| line\-bot\-sdk\-nodejs](https://line.github.io/line-bot-sdk-nodejs/#getting-started)
- [LINE の Messging API を試してみる](https://zenn.dev/tatsuyasusukida/scraps/bf35b2746f549e)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions?hl=ja)


## （おまけ）バックエンドサーバーの実行環境にGASを利用しようとしたが断念した

最初、サーバーの実行環境としてGAS (Google Apps Script) を利用しようとしていたのですが、以下の観点から利用しないことにしました。

- ES Modules (`import/export`) に対応していない。
  - 代替案はあるがnpmパッケージを利用する規模の開発には向いていなさそう。
  - トークンの検証はSDKを利用したかった。
  - https://github.com/google/clasp/blob/master/docs/esmodules.md
- LINE Messaging APIの仕様として、Webhookのエンドポイントからは200コードが返却されなくてはならない。しかし、GASではセキュリティ上302コードが返却されてしまうため。
  - https://developers.google.com/apps-script/reference/content/text-output?hl=ja