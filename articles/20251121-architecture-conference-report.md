---
title: "アーキテクチャカンファレンス参加レポート"
emoji: "🏗️"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["architecture", "conference"]
published: true
---

<!-- textlint-disable japanese/no-doubled-joshi -->

## はじめに

2025/11/20~2025/11/21の2日間で行われた「アーキテクチャConference2025」に参加してきました。

https://architecture-con.findy-tools.io/2025

システムの設計は興味がある分野の一つでして、今回新しく学んだことや気になったことをまとめてみようと思います。

https://x.com/yuma_ito_bd/status/1991810508148875668?s=20

## 基調講演
- [モダナイズの現実と選択：マイクロサービスが最適解か？](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/76yLXDva)
- [アーキテクト思考 ― チームでより良い技術的意思決定を導くリーダーシップ](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/jCaMrybb)
- [DDDが導く戦略的トレードオフのアート](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/jACGoGTg)
- [そもそも「レジリエンス」とは何か？](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/BFVX-Rfb&m=2025/session/mdl/BFVX-Rfb)

基調講演はどれも聴き応えのある内容でした。
マイクロサービスはあくまで手段でありビジネスでの成果を第一に考えること、どの方法もメリット・デメリットはありトレードオフが存在すること。そして、小さな変更を積み重ねること（デプロイとリリースを分けること）、一次元で捉えず軸を足して俯瞰的に捉えること、など心に残った言葉が沢山ありました。

業務でシステムのリアーキテクチャを進めているところなのですが、デプロイとリリースを分けて小さく進めていたのでこの方法で良いのだと勇気をもらえました。

また、会場ではグラレコ（グラフィックレコーディング）をしていて、講演内容がとてもとても分かりやすくまとめられていました！

![Sam Newmanさんの講演のグラレコ](https://storage.googleapis.com/zenn-user-upload/621b219d9f88-20251121.jpg)
*Sam Newmanさんの講演のグラレコ*

![Gregor Hohpeさんの講演のグラレコ](https://storage.googleapis.com/zenn-user-upload/a36a89e4a916-20251121.jpg)
*Gregor Hohpeさんの講演のグラレコ*

![Vlad Khononovさんの講演のグラレコ](https://storage.googleapis.com/zenn-user-upload/78f1bdd371fa-20251121.jpg)
*Vlad Khononovさんの講演のグラレコ*

あのハイレベルな内容をリアルタイムで1枚の絵にまとめられるなんてすごいですね。この絵を眺めると「あんなこと言っていたな」と思い出すことができますね。自分もこんな風に要点だけ分かりやすくまとめられるようになりたいです。

あと、会場では同時通訳もしてくれていて、これには本当に助けていただきました。英語での講演かつ話している内容もかなりハイレベルで濃密だったので、同時通訳していただけなければ話についていけなかったと思います。本当にありがとうございました！

## DDD/モジュラーモノリス/マイクロサービス
- [グローバルなコンパウンド戦略を支えるモジュラーモノリスとドメイン駆動設計](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/54kPzMNF)
- [ドメイン駆動設計とマイクロサービスアーキテクチャ](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/dKYSKAs8)
- [SaaS拡大期の成長痛　〜モジュラーモノリスへのリアーキと生成AIの活用〜](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/G1FCC7TZ)
- [AIで加速する次世代のBill Oneアーキテクチャ ― 成長の先にある軌道修正](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/Dq5ZMwaq)

DDDやモジュラーモノリス/マイクロサービスをどのように導入、推進しているのかというお話を聞くことができました。

モノリスの限界が見えてきたときに移行先はモジュラーモノリスなのかマイクロサービスなのか、どの部分をどの順序で切り出すのかという課題があります。
他の企業さんがどのような意思決定をされていたのか知ることができ、勉強になりました。
さらに、AIエージェントを使ってリアーキテクチャの速度を加速させた話もあり、以前よりもスピーディーに変化することができる時代になったのだなと感じました。

## AIエージェント
- [進化する AI エージェント： 未来を見据えた設計と運用戦略](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/NvabHK4D)
- [【ワークショップ】AI エージェントの開発からデプロイまで体験してみよう！](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/AOOuSWL1)
- [AIエージェントSaaSを安全に提供する技術：自社サンドボックス基盤設計からの学び](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/mnKMunB1)
- [【AWS特別企画】実践的アーキテクチャレビュー会 〜KDDIアジャイル開発センター・gumi・ソラコム 〜](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/NS3XlYYL)
- [7,000店舗で実稼働：大規模業務システムとヒューマンインタラクションが融合するAIの全貌](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/vDOM0r7M)

AIエージェントはもっぱら使う側だったので、AIエージェントを作る側の話を伺えたのはとても面白かったです！今回のイベントで一番始めて知ることが多かったトピックでした。

特に、Googleさんが提供してくださったAIエージェントの開発ワークショップでは、簡単にAIエージェントを作成することができて驚きました。

ワークショップの内容は以下にあるチュートリアルでした。

https://github.com/google-cloud-japan/next-tokyo-assets/blob/b566d65a4d31bb12ec6e2f3adba3fa6d8ed7fee9/2025/generative-ai-agent-dev-deploy-handson/tutorial.md

「今日の東京の気温は？」と問いかけると気温を教えてくれる簡単なAIエージェントを実装して、さらにWeb上にデプロイまでできました。

![](https://storage.googleapis.com/zenn-user-upload/3f3dd09e3fca-20251121.png)
*実装したAIエージェントの動作検証*

Googleさんの提供するエージェント開発キット（ADK）を使うことでAIエージェントに必要なコード量が少なくなり、AIエージェントのコア機能の実装に集中することができます。さらに、ADKは動作検証用のチャット機能やAIエージェントの評価を行うための機能も提供してくれているので、AIエージェントの開発にかかる手間が大きく削減できます。

さらに、GeminiのアシストによってAIエージェントを自然言語で実装できる機能がリリースされたとのことでした！
最後時間が少ししかなかったのですが、自分は「しりとりエージェント」をGeminiに作ってもらいました。

https://x.com/yuma_ito_bd/status/1991743142442500171?s=20

## 組織・文化
- [マルチドライブアーキテクチャ：複数の駆動力でプロダクトを前進させる](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/unznQkBA)
- [「グローバルワン全員経営」の実践を通じて進化し続けるファーストリテイリングのアーキテクチャ](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/_6nC92S-)
- [制度的トラストを支えるアーキテクチャ - デジタル時代の公共性とその実務](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/lTp4WEwa)
- [Figma, Inc. CPO登壇： アイデアを爆速でプロダクトに落とし込むには](https://architecture-con.findy-tools.io/2025?m=2025/session/mdl/nP1mxgp7)

「アーキテクチャ」が指し示すものはソフトウェアだけではなく、開発組織や開発プロセスのアーキテクチャも設計する必要があるということも大きな学びでした。

ビジネスのコアドメインを大きく成長させつつ、技術的負債を解消したりAIを使って開発スピードを上げたりするためには開発組織やチーム間のコミュニケーション、開発プロセスも柔軟に変えていく必要があります。
これからの時代はアーキテクトが意思決定する対象はソフトウェアだけでなく、コミュニケーションや開発プロセスといった技術ではないものも含まれるということを知り、面白さを感じつつ大変な道のりだと思いました。


## さいごに

アーキテクチャConferenceは初参加でしたが、とても充実した2日間でした！
スポンサーブースもたくさん回って各企業のサービスやアーキテクチャに関して話すことができ楽しかったです。

講演者の皆さん、スポンサーの皆さん、カンファレンスを主催してくださったFindyの皆さん、ありがとうございました！

