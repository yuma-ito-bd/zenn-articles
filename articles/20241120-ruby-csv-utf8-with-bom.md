---
title: "RubyでBOMつきUTF-8のCSVを正しく読み込む方法3選"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ruby"]
published: true
---

## 問題：`CSV.read`では列情報を正しく読み込むことができなかった

RubyでCSVファイルを読み込む際はDefault Gemsに含まれている[^1]`csv` gemを使うことが多いでしょう。

[^1]: Ruby3.4からはDefault GemsではなくBundled Gemに変更されます。 (https://www.ruby-lang.org/en/news/2023/12/25/ruby-3-3-0-released/)

BOMつきのUTF-8エンコードされたCSVファイルを読み込むと、列情報を正しく参照できない問題に直面しました。

例えば、以下のようなBOMつきUTF-8のCSVファイルがあるとします。

```csv:utf8_with_bom.csv
name,age
Tom,20
Jerry,22
Alice,25
```

このCSVファイルを以下のように`CSV.read`で読み込むと、`name`列の情報を取得することができませんでした。

```rb:faild_to_read_csv_with_bom.rb
# frozen_string_literal: true

require 'csv'

csv = CSV.read('utf8_with_bom.csv', headers: true)

puts "name:"
puts csv['name']
puts "age:"
puts csv['age']

# Outputs:
# name:
#
#
#
# age:
# 20
# 22
# 25
```

`CSV.read`メソッドに`headers: true`を追加すると、`CSV.Table`オブジェクトが返ってきます。
https://docs.ruby-lang.org/ja/latest/method/CSV/s/read.html

`CSV.Table`クラスでは`[]`メソッドにインデックス番号を渡すとインデックス番号に対応する行情報を参照し、ヘッダー名を指定するとそのヘッダーの列情報を参照します。
よって、`csv['name']`とすれば`name`列の情報を取得できるはずですが、すべて`nil`になってしまいました。

その原因はCSVファイルのエンコーディングが**BOMつき**UTF-8になっていたことでした。

## 正しく読み込む方法3選

BOMつきUTF-8を読み込む方法を3つ紹介します。
もちろん方法は3つだけではありませんが、実務で使えそうな方法をまとめてみました。

Ruby 3.3.4の環境で検証しました。
```
❯ ruby -v
ruby 3.3.4 (2024-07-09 revision be1089c8ec) [arm64-darwin23]
```

紹介するサンプルコードは以下でも参照できます。

https://github.com/yuma-ito-bd/zenn-articles/tree/997ccda4eab3b4b8c7183c5f53f3de874e64daaa/scripts/20241120-ruby-csv-utf8-with-bom

### 1. `CSV.read`で`encoding: 'bom|utf-8'`を使って読み込む

まずはじめは`CSV.read`メソッドの呼び出しに`encoding: 'bom|utf-8'`オプションを指定する方法です。

```rb:using_csv_read_with_encoding_option.rb
csv = CSV.read('utf8_with_bom.csv', encoding: 'bom|utf-8', headers: true)
puts "name:"
puts csv['name']

# Outputs:
# name:
# Tom
# Jerry
# Alice
```
`encoding`を指定することにより、`name`列を正しく参照することができました。

### 2. `CSV.read`で`header_converters: :symbol`を指定して読み込む

2つ目の方法は`CSV.read`メソッドの呼び出しに`header_converters: :symbol`オプションを指定する方法です。
このオプションを指定すると、ヘッダーを読み込む際にシンボルへ変換してくれます。
https://docs.ruby-lang.org/ja/latest/method/CSV/s/new.html

```rb:using_header_converters.rb
csv = CSV.read('utf8_with_bom.csv', headers: true, header_converters: :symbol)
puts "name:"
puts csv[:name]

# Outputs:
# name:
# Tom
# Jerry
# Alice
```

よって、列情報を参照する際はシンボルでヘッダー名を指定する必要があります。
この方法のメリットとしては、読み込むファイルがBOMのありorなしに関係なく適用できる点です。
ちなみに、日本語のヘッダー名でもシンボルで指定可能です。（例：`:名前`）


### 3. `CSV.table`を使って読み込む

最後の方法は、`CSV.table`メソッドを使ってCSVファイルを読み込む方法です。
https://docs.ruby-lang.org/ja/latest/method/CSV/s/table.html

このメソッドでは2つ目の方法と同様に、ヘッダーのキーがシンボルに変換されます。

```rb:using_csv_table_method.rb
csv = CSV.table('utf8_with_bom.csv')
puts "name:"
puts csv[:name]

# Outputs:
# name:
# Tom
# Jerry
# Alice
```

この方法が一番シンプルかと思います。

ただし、`CSV.table`メソッドの中身は`CSV.read`に以下のオプションを指定していることと同等です。
2つ目の方法に`converters: :numeric`が追加されているのでご注意ください。

```rb
CSV.read( path, { headers:           true,
                  converters:        :numeric,
                  header_converters: :symbol }.merge(options) )
```

## まとめ

BOMつきUTF-8のCSVファイルを正しく読み込む方法を3つご紹介しました。
個人的には一番シンプルに書ける`CSV.table`が良さそうに思います。

ExcelファイルからCSVに変換した際、BOMつきUTF-8になっていることに気づかずハマってしまいました。
みなさんもファイルのエンコーディングには十分ご注意くださいませ。
