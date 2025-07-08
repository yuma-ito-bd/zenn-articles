---
title: "RailsのActive Recordで名前空間付きカスタムバリデーターを利用する"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["rails", "activerecord"]
published: false
publication_name: "arm_techblog"
---

## はじめに
こんにちは！
フィッツプラスシステム開発部の伊藤です。

今回の記事では、Active Recordで名前空間付きのカスタムバリデーターを定義し、利用する方法について解説します。

中規模〜大規模のRailsアプリケーションでは、名前空間を使ってクラス名の衝突を避けることが多いかと思います。
例えば、`Admin::User`など`User`の中でも管理者を表したい際に`Admin`という名前空間を付けて他の`User`クラスと区別します。

フィッツプラスでも2017年からあるRailsアプリケーションを運用しているので、名前空間を用いたクラスの整理を行っております。
特定の名前空間に特化したカスタムバリデーターを定義したく、今回の内容を調べました。

それでは、名前空間つきのカスタムバリデーターを定義して利用するにはどうすればよいか紹介します。

## カスタムバリデーターの定義

カスタムバリデーターの定義は難しくありません。
例えば、利用したいカスタムバリデーターは`Hoge::CustomValidator`とします。

以下のように、`ActiveModel::EachValidator`を継承したバリデータークラスを定義します。

```ruby:app/validators/hoge/custom_validator.rb
module Hoge
  class CustomValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      # ...
    end
  end
end
```

詳しくはRailsガイドなどをご参照ください。

https://railsguides.jp/active_record_validations.html#%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%A0%E3%83%90%E3%83%AA%E3%83%87%E3%83%BC%E3%82%BF

## モデルでのバリデーター指定方法

ここが一番のポイントです。
モデルで名前空間つきのカスタムバリデーターを指定する際は、**名前空間をスラッシュ区切りで指定**します。

つまり、先ほどの例では`'hoge/custom'`と指定します。
ハッシュのキーに`/`が含まれるためクォートする必要があるので注意してください。

実際のコードでは以下のようになります。

```ruby:app/models/user.rb
class User < ApplicationRecord
  validates :hoge, 'hoge/custom': true # `'<namespace>/<validator名>'` と指定する
end
```

このように記述することで、`Hoge::CustomValidator` を利用できます。

## `validates`メソッドのソースコード

最後に`validates`メソッドでどのようにバリデーターを読み込んでいるのか紹介します。

`validates`メソッドは`ActiveModel::Validations::ClassMethods`に定義されています。

https://github.com/rails/rails/blob/1688ba0a32fa5ed1c56afb166639fc1a460a04fa/activemodel/lib/active_model/validations/validates.rb#L111-L133

引数から実際に呼び出すバリデータークラスを抽出しているのは以下の箇所です。

https://github.com/rails/rails/blob/1688ba0a32fa5ed1c56afb166639fc1a460a04fa/activemodel/lib/active_model/validations/validates.rb#L121

上記では`key.to_s.camelize`した文字列に`Validator`を追加したものが呼び出されるバリデータークラスです。

Active Model側に標準で搭載されているバリデーションを使う際も同じ仕組みです。

- `presence: true`の場合、`PresenceValidator`クラス
  - https://github.com/rails/rails/blob/1688ba0a32fa5ed1c56afb166639fc1a460a04fa/activemodel/lib/active_model/validations/presence.rb#L5-L9
- `format: { with: /\A[a-zA-Z]+\z/}`の場合、`FormatValidator`クラス
  - https://github.com/rails/rails/blob/1688ba0a32fa5ed1c56afb166639fc1a460a04fa/activemodel/lib/active_model/validations/format.rb#L7

よって、名前空間つきのバリデータークラスを呼び出したい際も同様です。

以下のように`:'hoge/custom'`を`camelize`すると、`Hoge::Custom`です。
そしてこれに`Validator`をつけることで`Hoge::CustomValidator`クラスになります。

```ruby
p :'hoge/custom'.to_s.camelize # => "Hoge::Custom" 
p "#{:'hoge/custom'.to_s.camelize}Validator" # => "Hoge::CustomValidator"
```

:::message
`validates`メソッドの引数で`'hoge/custom': true`としているのでハッシュのキーは`:'hoge/custom'`です。
:::

ちなみに、ソースコードを調べていたところ、名前空間つきのバリデータークラスを指定する方法が`validates`メソッドのコメントにちゃんと説明されていました。

https://github.com/rails/rails/blob/1688ba0a32fa5ed1c56afb166639fc1a460a04fa/activemodel/lib/active_model/validations/validates.rb#L58-L61

以上です。
最後までお読みくださりありがとうございました！
