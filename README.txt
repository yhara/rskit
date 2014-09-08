Ruby/SDLスターターキット - メモ帳一本でゲームが作れる開発環境

! 動作環境

Windows

! サンプルを動かしてみよう

game.exeをダブルクリックするとサンプルゲーム「the apple catcher」が
起動します。矢印キーでキャラクターを左右に動かし、りんごを集めてください。

debug.exeをダブルクリックするとウィンドウモードで起動します。

! サンプルを改造してみよう

main.rbにゲームのスクリプトが書いてあります。
main.rbをテキストエディタで開き、編集してみましょう。
例えば、真ん中あたりにこんな行があります。

      #item.x += item.v-8    #←隠しモード

この行の先頭の「#」を消して、ファイルを保存しましょう。

もう一度game.exeを実行すると……どうなるかは、自分の目で確かめてみてください。:-)

! 自分のゲームを作ろう

main.rbを編集すれば、自分のオリジナルのゲームを作ることができます。

スクリプトはRubyの文法に従って書きます。
Rubyの文法については以下のサイトを参照してください。
* Rubyリファレンスマニュアル : http://www.ruby-lang.org/ja/man/

また、Ruby/SDLの使い方については以下のサイトを参照してください。
* Ruby/SDL Reference Manual : http://www.kmc.gr.jp/~ohai/rubysdl_ref.html

画像データにはbmp(フルカラー推奨), png, gif, jpg が使用できます。
音声データにはwav, ogg, midi, mod(it, s3m, mod等)が使用できます。
※RSKitではmp3は使用できません。oggを使用してください。

また、以下のURLでゲーム製作に役立つ情報が公開されている…かも知れません。
* http://mono.kmc.gr.jp/~yhara/w/?RubySDLStarterKit

! 謝辞

RSKitは以下のソフトウェアを利用しています。
* Ruby : http://www.ruby-lang.org/
* SDL(Simple DirectMedia Layer) : http://www.libsdl.org/
* Ruby/SDL : http://www.kmc.gr.jp/~ohai/rubysdl.html
* Exerb : http://exerb.sourceforge.jp/

また、sound/bom08.wavは以下のサイトのものを利用しています。
* ザ・マッチメイカァズ : http://osabisi.sakura.ne.jp/m2/

作者の方々に感謝します。ありがとうございます。

! History

1.2.0b(2007/1/4)   - *.soが読み込めなかったのを修正
1.2.0a(2006/12/25) - 最初のリリース 

! 連絡先

 yhara / 京大マイコンクラブ
  
 yhara(at)kmc.gr.jp
 http://mono.kmc.gr.jp/~yhara/

