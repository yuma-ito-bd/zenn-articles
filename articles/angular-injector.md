---
title: "Angularの遅延モジュールとサービスクラスの関係"
emoji: "🐜"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["angular"]
published: false
---

## 依存性の注入（Dependency Injection, DI）とは

DIとはDependency Injectionの略で、日本語では「依存性の注入」と呼ばれています。

そもそも依存性 (dependency) とは、あるクラスが機能を実現するために必要な他のクラス（オブジェクト）のことです。
例えば、クラスAからクラスBのメソッドやプロパティを呼び出している場合、「クラスAはクラスBに依存している」といいます。

```javascript
class A {
    hoge() {
        const b = new B();
        b.fuga();
    }
}

class B {
    fuga(){ /* 省略 */}
}
```

そして、依存性の注入とは、クラスAが依存しているクラスBを直接生成するのではなく、外部ソースに要求する設計（デザインパターン）のこと。

Angularでは、依存性を解決するためのDIコンテナがすでに用意されています。