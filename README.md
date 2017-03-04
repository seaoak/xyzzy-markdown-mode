# markdown-mode for xyzzy

本ソフトウェアは、
[Yousuke Ushiki 氏](https://github.com/youz) (@youz) が Gist 上で公開されている
[「改変 markdown-mode for \#xyzzy (色付け & メジャーモード化) 」](https://gist.github.com/youz/1339252)
の
[Revision 4 (2011/Nov/07 15:22 JST)](https://gist.github.com/youz/1339252/79962dee5a3386ab06ac6ebbaafec985c1146d63)
を Fork したものです。    
https://gist.github.com/youz/1339252

オリジナルは、[kia](http://www.geocities.jp/kiaswebsite/) 氏が
Web サイト
[kia's website](http://www.geocities.jp/kiaswebsite/)
にて公開されている
[markdown.l](http://www.geocities.jp/kiaswebsite/xyzzy/markdown.html)
の `Rev: 227` (2006/Aug/08) です。    
http://www.geocities.jp/kiaswebsite/xyzzy/markdown.html


## Overview

xyzzy は Windows 上で動作するテキストエディタです。    
https://xyzzy-022.github.io

markdown-mode は、xyzzy 上で Markdown 記法をサポートするメジャーモードです。

シンタックスハイライトと入力補完ができます。


## Installation

[`markdown-mode.l`](https://github.com/seaoak/xyzzy-markdown-mode/blob/master/markdown-mode.l)
をダウンロードして、
xyzzy インストール先フォルダ配下の
`site-lisp\markdown-mode` フォルダに置きます
（初回はこのフォルダが無いはずなので新規作成してください）。

Git が使える環境ならば、このリポジトリを直接 git clone できます：

```
C:\xyzzy>cd site-lisp
C:\xyzzy\site-lisp>git clone https://github.com/seaoak/xyzzy-markdown-mode.git markdown-mode
```

`markdown-mode.l` を置いたら、xyzzy でバイトコンパイルします。
xyzzy 上で `M-x byte-compile-file` を実行し、
`markdown-mode.l` を指定してください。
バイトコンパイル済みファイル `markdown-mode.lc` が生成されます。

次に、xyzzy の初期設定ファイル（デフォルトでは `site-lisp\siteinit.l`）に
次の２行を追加してください：

```lisp
(load-library "markdown-mode/markdown-mode")
(push '("\\.md$" . markdown-mode) *auto-mode-alist*)
```

初期設定ファイルを編集したら、いつもの xyzzy のお作法のとおり変更を反映させます：

 1. `M-x byte-recompile-directory` でバイトコンパイル
 2. xyzzy のダンプファイルを削除
 3. xyzzy を再起動

手順 2, 3 の代わりに、
Ctrl キーと Shift キーを押しながら xyzzy を起動しても同じです。

以上で markdown-mode のインストールは完了です。

拡張子が `.md` のファイルを xyzzy で開くと、自動的に markdown-mode になります。
必要に応じて拡張子の関連付けなどを Windows に設定してください。


## License

オリジナルおよび改変版のソースファイル先頭に書かれたライセンス条項が
MIT License のものだったので、本ソフトウェアも MIT License とします。
