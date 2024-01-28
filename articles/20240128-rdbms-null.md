---
title: "MySQL, PostgreSQLのnullに関する比較"
emoji: "🥹"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['mysql', 'postgresql']
published: false
---

## 概要

MySQLとPostgreSQLのnullの扱いについて解説します。
算術比較演算子の結果など共通する部分もありますが、`ORDER BY`による結果の順番が異なるなど仕様が異なる点もあります。

比較する内容は以下の通りです。

- 算術比較演算子の結果
- NULLか調べる演算子
- ORDER BYでの扱い

なお、比較したMySQL, PostgreSQLのバージョンは以下です。

- MySQL: 8.0
- PostgreSQL: 15.4

## 比較表

ざっくりまとめると以下です。

観点 | MySQL | PostgreSQL
---|---|---
算術比較演算子(`=`など)の結果 | `NULL` | `NULL`
NULLを調べる演算子 | `IS NULL`, `IS NOT NULL` | `IS NULL`, `IS NOT NULL`, `ISNULL`, `NOTNULL`
ORDER BYでの扱い（`ASC`の場合） | **最初**（値があるカラムよりも前）に出力される。最後にするためには`column_name IS NULL ASC`を追加する | **最後**（値があるカラムよりも後）に出力される。最初にするためには`NULLS FIRST`を追加する


## MySQL

以下のPlayGroundにて検証が可能です。
https://www.db-fiddle.com/f/4jyoMCicNSZpjMt4jFYoz5/11711

### 算術演算子の結果

[MySQL :: MySQL 8.0 リファレンスマニュアル :: 3.3.4.6 NULL 値の操作](https://dev.mysql.com/doc/refman/8.0/ja/working-with-null.html)

`=`, `<`, `<>`などの算術比較演算子の結果は常に`NULL`となる。

```sql
$ SELECT 1 = NULL, 1 <> NULL, 1 < NULL, 1 > NULL;

| 1 = NULL | 1 <> NULL | 1 < NULL | 1 > NULL |
| -------- | --------- | -------- | -------- |
| null     | null      | null     | null     |
```

そのため、WHERE句において比較しても結果に出力されない。

```sql
$ SELECT * FROM users;

| id  | name |
| --- | ---- |
| 1   | Taro |
| 2   | Jiro |
| 3   |      |

$ SELECT * FROM users WHERE name <> 'Taro';

| id  | name |
| --- | ---- |
| 2   | Jiro |
```

### NULLを調べる演算子

MySQLでは`IS NULL`演算子によって、値がNULLであるかどうかを調べることができる。
また、`IS NOT NULL`演算子によって、値がNULLではないかを調べることができる。

```sql
$ SELECT * FROM users WHERE name IS NULL;

| id  | name |
| --- | ---- |
| 3   |      |
```

### ORDER BYでの扱い

NULLは非NULLの値よりも**小さい**と評価される。
そのため、`ORDER BY`でソートすると以下の位置に出力される。

- 昇順（`ASC`）の場合：**最初**（値があるカラムよりも前）
- 降順（`DESC`）の場合：**最後**（値があるカラムよりも後）

```sql
$ SELECT * FROM users ORDER BY name ASC;

| id  | name |
| --- | ---- |
| 3   |      |
| 2   | Jiro |
| 1   | Taro |
```
`name`カラムがNULLとなっているレコード(id: 3)が先になり、3, 2, 1という順番で出力された。

`DESC`の場合は、1, 2, 3という順番となる。
```sql
$ SELECT * FROM users ORDER BY name DESC;

| id  | name |
| --- | ---- |
| 1   | Taro |
| 2   | Jiro |
| 3   |      |
```

もしNULLの出力順序を入れ替えたい場合、`ORDER BY`の条件に`<column_name> IS NULL ASC` (または`<column_name> IS NULL DESC`)を追加する。

```sql
$ SELECT * FROM users ORDER BY name IS NULL ASC, name ASC;

| id  | name |
| --- | ---- |
| 2   | Jiro |
| 1   | Taro |
| 3   |      |
```
こうすると、`name`カラムがNULLであるレコードが最後になり、2, 1, 3という順番で出力される。

`DESC`の場合は3, 1, 2という順番になる。
```sql
$ SELECT * FROM users ORDER BY name IS NULL DESC, name DESC;

| id  | name |
| --- | ---- |
| 3   |      |
| 1   | Taro |
| 2   | Jiro |
```

`<column_name> IS NULL ASC`で順番が入れ替わる理由は、`<column_name> IS NULL`の結果でソートしているから。
NULLのカラムは`IS NULL`の結果が`true`(1)となるため、昇順でソートすると後方になる。

```sql
$ SELECT *, name IS NULL FROM users ORDER BY name IS NULL ASC, name ASC;

| id  | name | name IS NULL  |
| --- | ---- | ------------- |
| 2   | Jiro | 0             |
| 1   | Taro | 0             |
| 3   |      | 1             |
```

## PostgreSQL

以下のPlayGroundで検証可能です。
https://www.db-fiddle.com/f/beWHsSQs8Gfct2poFe8RmH/1

### 算術演算子の結果
参考： [9.2. 比較関数および演算子](https://www.postgresql.jp/document/15/html/functions-comparison.html)

MySQLと同様に `=`, `<`, `<>`などの算術比較演算子の結果は常に`NULL`となる。
```sql
$ SELECT 1 = NULL as "1 = NULL", 1 <> NULL as "1 <> NULL", 1 < NULL as "1 < NULL", 1 > NULL as "1 > NULL";

| 1 = NULL | 1 <> NULL | 1 < NULL | 1 > NULL |
| -------- | --------- | -------- | -------- |
|          |           |          |          |
```

また、WHERE句で比較しても結果に出力されない。

```sql
$ SELECT * FROM users;

| id  | name |
| --- | ---- |
| 1   | Taro |
| 2   | Jiro |
| 3   |      |

$ SELECT * FROM users WHERE name <> 'Taro';

| id  | name |
| --- | ---- |
| 2   | Jiro |
```

ここで、 PostgreSQLではNULLを比較して評価できる演算子が用意されている。

- `IS DISTINCT FROM`: NULLを比較可能な値とした上で、等しくない。
- `IS NOT DISTINCT FROM`: NULLを比較可能な値とした上で、等しい。

先程の例(`<> 'Taro'`)では、nameが`Taro`ではないレコードの結果は`Jiro`(id: 2)のレコードのみ出力されていた。
しかし、`IS DISTINCT FROM`演算子を用いるとNULLのレコード(id: 3)も結果に出力することができる。

```sql
$ SELECT * FROM users WHERE name IS DISTINCT FROM 'Taro';

| id  | name |
| --- | ---- |
| 2   | Jiro |
| 3   |      |
```

これは以下の条件と同義となる。
```sql
$ SELECT * FROM users WHERE name <> 'Taro' or name IS NULL;

| id  | name |
| --- | ---- |
| 2   | Jiro |
| 3   |      |
```

### NULLを調べる演算子

PostgreSQLでは、`IS NULL`, `IS NOT NULL`演算子によって、値がNULLであるかどうかを調べることができる。
さらに、非標準構文であるが、`ISNULL`, `NOTNULL`演算子でも調べられる。

```sql
$ SELECT * FROM users WHERE name IS NULL;

| id  | name |
| --- | ---- |
| 3   |      |
```

```sql
$ SELECT * FROM users WHERE name ISNULL;

| id  | name |
| --- | ---- |
| 3   |      |
```

### ORDER BYでの扱い
参考：[7.5. 行の並べ替え(ORDER BY)](https://www.postgresql.jp/document/15/html/queries-order.html)

MySQLと異なり、PostgreSQLでのNULLは非NULL値よりも**大きい**と評価される。
そのため、`ORDER BY`でソートすると以下の位置に出力される。

- 昇順（`ASC`）の場合：**最後**（値があるカラムよりも後）
- 降順（`DESC`）の場合：**最初**（値があるカラムよりも前）

つまり、以下のような結果となる。

```sql
$ SELECT * FROM users ORDER BY name ASC;

| id  | name |
| --- | ---- |
| 2   | Jiro |
| 1   | Taro |
| 3   |      |

$ SELECT * FROM users ORDER BY name DESC;

| id  | name |
| --- | ---- |
| 3   |      |
| 1   | Taro |
| 2   | Jiro |
```

NULLの順番を指定したい場合は、`NULLS FIRST`, `NULLS LAST`を以下のように追加する。

```sql
$ SELECT * FROM users ORDER BY name ASC NULLS FIRST;

| id  | name |
| --- | ---- |
| 3   |      |
| 2   | Jiro |
| 1   | Taro |

$ SELECT * FROM users ORDER BY name DESC NULLS LAST;

| id  | name |
| --- | ---- |
| 1   | Taro |
| 2   | Jiro |
| 3   |      |
```


## （番外編） Oracle
MySQLやPostgreSQLと異なり、空文字`''`とNULLは区別されない。

> Oracleでは文字列型のNULLを長さが0(ゼロ)の文字列と区別できないという例外があります。

https://docs.oracle.com/cd/F19136_01/sqlrf/Oracle-Compliance-To-Core-SQL2011.html#GUID-D372D906-805B-49B8-824A-D4697B05B7F8


## 最後に

MySQLとPostgreSQLのNULLの扱いに関して比較して解説しました。
業務でMySQLのNULLについて調べた際、ふと「他のRDBMSだとどうなのだろうか」を思い調べてみたら、
予想外に異なる点があったのでとても良い機会になりました。
