/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/jxkV
 */

//安定バージョン
package {
    import flash.display.Sprite; 
    import org.si.sion.*; 
    import flash.text.TextField;     //文字列表示のため
    import flash.text.TextFormat;    //等幅font表示のため
    import flash.text.TextFieldType; //文字列入力のため
    import flash.events.Event;       //文字列入力のため
    
    // MMLプリプロセッサ
    // 画面で入力した文字をプリプロセスし、プリプロセス結果を表示し、演奏する
    public class MmlPreproView extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 
        private var pre1:MmlPreprocessor1 = new MmlPreprocessor1();    //プリプロセッサ
        private var pre2:MmlPreprocessor2 = new MmlPreprocessor2();    //プリプロセッサ
        private var pre3:MmlPreprocessor3 = new MmlPreprocessor3();    //プリプロセッサ
        private var blk:MultiTrackBlock = new MultiTrackBlock();      //ブロック
        
        private var tf1:TextField = new TextField;       //表示用領域
        private var tf2:TextField = new TextField;       //表示用領域
        private var tfmt:TextFormat = new TextFormat;   //表示用領域のtextFormat指定に使う領域

        //SiON用MMLを元にSiONで音を鳴らす
        private function playMml(mml:String) :void {
            data = driver.compile(mml); 
            driver.play(data); 
        }

        //文字列表示エリアを設定する
        private function dispText1(text:String) :void {
            tf1.text = text;  //表示文字列の初期値
            tf1.width = 400;
            tf1.height = 300;
            tf1.wordWrap = true;
            tf1.multiline = true;
            tf1.type = TextFieldType.INPUT;    //文字列入力可能にする
            tfmt.font = "MS Gothic";
            tf1.setTextFormat ( tfmt );
            addChild( tf1 );
        }
        //文字列表示エリアを設定する
        private function dispText2(text:String) :void {
            tf2.text = text;  //表示文字列の初期値
            tf2.y = 300;
            tf2.width = 400;
            tf2.height = 100;
            tf2.wordWrap = true;
            tf2.multiline = true;
            tfmt.font = "MS Gothic";
            tf2.setTextFormat ( tfmt );
            addChild( tf2 );
        }
         
        //コンストラクタ
        function MmlPreproView() { 
            //イベントハンドラを登録する
            //    テキスト変更を登録
            tf1.addEventListener( Event.CHANGE, function(e :Event) :void {
                //Textが編集された場合
                // MMLプリプロセス開始
                pre1.debug = "";
                pre2.debug = "";
                pre3.debug = "";
                pre1.init(tf1.text);
                pre2.registerBlocks(pre1.lines, pre1.expandingAreaIndex);
                // MMLプリプロセス結果取得
                var mml:String = pre3.expandBlocks(pre1.lines, pre1.expandingAreaIndex, pre2.blocks, pre2.blockNames);
                // 演奏
                playMml("t120;" + mml);
                dispText2("展開結果:" + mml + "\rdebug情報:" + pre1.debug + pre2.debug + pre3.debug);
                });
            //文字列表示エリアを設定する
            dispText1("/*マルチトラックマクロ定義*/\r＿ＣＭ７＿c;e;g;b;＿Ｄｍ７＿d;f;a;<c>;＿Ｅｍ７＿e;g;b;<d>;＿ＦＭ７＿f;a;<c>;<e>;＿Ｇ６＿g;b;<d>;<e>;＿Ａｍ７＿a;<c>;<e>;<g>;\r１c;e;g;２d;f;a;３e;g;b;４f;a;<c>;５g;b;<d>;６a;<c>;<e>;\rしー>>c<<; でぃー>>d<<;いー>>e<<;えふ>>f<<;じー>>g<<;えー>>a<<;びー>>b<<;\r初期t150l2%6@0v9;\r転調kt3;\r音色#OPM@0 { 5, 0,\r//AR DR  SR  RR  SL  TL  KS MUL DT1 DT2 AMS\r 15,  6,  4,  5, 10, 19,  0,  0,  1,  0,  0,\r 15,  6,  4,  5, 12,  0,  0,  5,  1,  0,  0,\r 21,  8,  4,  6,  8,  0,  0,  5,  4,  0,  0,\r 21,  9,  6,  6, 11,  0,  0,  2,  1,  0,  0,\r};\r\r/*ここからマクロを使ったMMLを書く。全角「１」とか追記すると鳴る*/\r音色;\r初期１４５転調４５１;\r初期えーえーえー転調えーえーえー\r//エラーだと無音\r");
            //テストコードを書く場所
            //※privateメソッドのテストをする場合は一時的にpublicに書き換える
            /*
            pre1.init("あc;e;g;いd;f;a;うe;g;b;えa;あいう;え");
            pre2.registerBlocks(pre1.lines, pre1.expandingAreaIndex);
            dispText2("これが表示されたら、このあと無限ループしている可能性あり");
            var mml:String;
            mml = pre3.expandBlocks(pre1.lines, pre1.expandingAreaIndex, pre2.blocks, pre2.blockNames);
            dispText2(pre1.debug + pre2.debug + pre3.debug + mml);
            */
        } 
        
    } 
}

    //MMLプリプロセッサ   複数trkの塊を1ブロックとして定義し、ブロックを時間単位とtrk単位で連結して出力する

    //プリプロセッサ1
    //初期処理
    //使用方法：init()を呼び出してメンバ設定のち、メンバを参照する
    class MmlPreprocessor1 { 
      //コンストラクタ
      public function MmlPreprocessor1() { }
      
      //メンバ
      //※init()でだけこれを設定している
      public var lines:Array = new Array();   //「;」区切り配列
      public var expandingAreaIndex:int;      //展開エリア位置
      public var debug:String = "";
      
      //メソッド
      
      // 初期処理
      // 事前整形、「;」区切り、展開エリア決定、を行う
      // ※呼び出し元：「プリプロセス」の想定
      //入力：画面入力した文字列
      //出力：「;」区切り配列、展開エリア位置   ※クラスメンバに持たせる
      public function init(str:String) :void {
        //事前整形
        str = preFormat(str);
        //「;」区切り配列取得
        lines = getLineArray(str);
        //展開エリア決定
        expandingAreaIndex = getExpandingAreaIndex(lines);
        debug += ("\r展開エリア決定["+expandingAreaIndex+"]\r");
        //テストコード:pre1.init("あc;いe;うg;あ;い;う");
      }
      
      //事前整形
      //CRLFと半角スペースとコメントを取り除く
      //入力：  文字列
      //出力：  整形後の文字列
      private function preFormat(str:String) :String {
        str = str.replace(/\/\/.*[\r\n]/g, "");  // "//" コメント除去  ※CRLF除去の前に実行する
        str = str.replace(/[\r\n]/g, "");   //CRLF除去
        str = str.replace(/[ ]/g, "");      //半角スペース除去
        str = str.replace(/\/\*\/?([^\/]|[^*]\/)*\*\//g, "");  // "/**/" コメント除去
        //テストコード:dispText2(pre1.preFormat("あ あ \r\n い い /*こめ*/ //こめ"));  //test
        return str;
      }
      
      //「;」区切り配列取得
      //与えられたテキストデータを、「;」を区切り文字として分割し、配列に入れる
      //入力：  画面入力された文字列
      //出力：  文字列の配列。末尾に「;」は、ない
      private function getLineArray(str:String) :Array {
        var lines:Array = str.split("\;");  //;で分割
        return lines;
        //テストコード:dispText2(pre1.getLineArray("a;b;c")[0]);  //test
      }
      
      //展開エリア決定
      //「;」改行配列について、何個目からが、展開エリアか、を取得する
      //・入力：「;」改行配列
      //・出力：何個目(0ベース)  ※見つからない場合-1
      private function getExpandingAreaIndex(lines:Array) :int {
        var index:int = 0;
        for each (var str:String in lines) {
          if (str.search(/[\!-\~]/) == -1){
            //文字列にASCII文字がひとつも見つからない場合
            //つまり、文字列が全て非ASCII文字だった場合
            return index;
          }
          index++;
        }
        return -1;
        //テストコード:dispText2(pre1.getExpandingAreaIndex(pre1.getLineArray("あa;いb;うc;あ")).toString());  //test
      }
      
    }


    //プリプロセッサ2
    //ブロック登録エリア処理
    //使用方法：init()を呼び出してメンバ設定のち、メンバを参照する
    class MmlPreprocessor2 { 
      //コンストラクタ
      public function MmlPreprocessor2() { }
      
      //メンバ
      public var blocks:Array = new Array();      //ブロック配列
      public var blockNames:Array = new Array();  //ブロック名配列
      public var debug:String = "";
      
      //ブロック登録
      //「;」区切り行ごとに処理を行い、"ブロック先頭"から"ブロック終端"までの複数行を1ブロックとして登録する
      //入力：  行配列、ブロック展開エリア先頭
      //出力：  ブロック配列、ブロック名配列  ※クラスメンバに出力
      public function registerBlocks(lines:Array, expandingAreaIndex:int) :void {
        var lineIndex:int = 0;  //行カウンタ（現在処理中の行インデックス）
        var linesArrayLength:int = lines.length;  //配列サイズ
        var nowBlockIndex:int = 0; //ブロック配列インデックス
        
        while (lineIndex< expandingAreaIndex) {
          //行カウンタが展開エリアより前の間はループ
          //現ブロック終端取得
          var endIndexOfNowBlock:int = getEndIndexOfNowBlock(lines, lineIndex, linesArrayLength);
          
          //ブロック取得
          blocks[nowBlockIndex] = getBlock(lines, lineIndex, endIndexOfNowBlock);
          
          //ブロック名配列に、ブロック名を追加
          blockNames[nowBlockIndex] = blocks[nowBlockIndex].name;
          debug = debug + "blockname"+nowBlockIndex+"[" + blockNames[nowBlockIndex] + "]";
          
          nowBlockIndex++;
          
          //行カウンタを、現ブロック終端+1へ
          lineIndex = endIndexOfNowBlock + 1;
          //テストコード：  ※ほかの「debug」とある行を使ってprintfデバッグ
            //pre1.init("あc;e;g;いd;f;a;うe;g;b;あ;い;う");
            //pre2.registerBlocks(pre1.lines, pre1.expandingAreaIndex);
            //dispText2(pre2.debug);
        }
      }
      
      //現ブロック末尾取得
      //  ※終端index考慮あり
      //入力：現在位置、ブロック登録エリア終端+1の位置  ※配列添字0ベース
      //出力：末尾位置  ※配列添字0ベース
      private function getEndIndexOfNowBlock(lines:Array, lineIndex:int, linesArrayLength:int) :int {
        var nextBlockIndex:int = getNextBlockIndex(lines, lineIndex);
        if (nextBlockIndex == -1){
          //次が見つからない場合、終端indexをreturn
          return linesArrayLength - 1;
        }
        //見つかった場合、次ブロック位置-1をreturn
        return nextBlockIndex - 1;
      }
      
      //次ブロックindex取得
      //引数：  「;」改行配列、配列現在位置（0ベース）
      //戻り値：見つからないなら-1  ※末尾を想定
      private function getNextBlockIndex(lines:Array, lineIndex:int) :int {
        var lineCount:int = 0;
        
        for each (var str:String in lines) {
          if (lineCount < lineIndex + 1){
            //lineIndex + 1に到達するまではskip
            //※現ブロック先頭の次から処理対象とする
            lineCount++;
            continue;
          }
          if (str.search(/^[\!-\~]/) == -1){
            //行先頭が非ASCIIの場合
            //※ここが次ブロックindex
            return lineCount;
          }
          lineCount++;
        }
        return -1;
      }
      
      //ブロック取得
      //入力：行配列、ブロック先頭、ブロック終端
      //出力：ブロック
      private function getBlock(lines:Array, lineIndex:int, endIndexOfNowBlock:int) :MultiTrackBlock {
        var block:MultiTrackBlock = new MultiTrackBlock();
        var trk:int = 0;        //トラック番号
        var i:int;              //ループカウンタ
        
        //行配列のブロック先頭から末尾までを、ブロックのtrack[0]～track[n]に登録する
        for (i = lineIndex; i < endIndexOfNowBlock + 1; i++){
          if (trk == 0){
            //先頭トラックの場合
            var str:String = lines[i];
            //トラック名取得
            //前提：行が非ASCII文字で始まり、非ASCII文字がその後に存在する
            var trackNameEndNextIndex:int = str.search(/[\!-\~]/);    //トラック名終端の次の文字のindexを取得
            block.name = str.substring(0, trackNameEndNextIndex);                 //トラック名取得
            block.tracks[trk] = str.substring(trackNameEndNextIndex, str.length); //トラック内容取得
          debug = debug + "trk0[" + block.tracks[trk] + "]";
          } else {
            //上記以外の場合
            block.tracks[trk] = lines[i];
          debug = debug + "trk" + trk.toString() + "[" + block.tracks[trk] + "]";
          }
          trk++;
        }
        return block;
      }
    }

    //ブロック（MML複数trackが入ったデータ）
    class MultiTrackBlock { 
      //コンストラクタ
      public function MultiTrackBlock() { }
      //メンバ
      public var name:String;                 //ブロック名
      public var tracks:Array = new Array();  //トラックの配列
    }

    //プリプロセッサ3
    //ブロック展開
    //使用方法：expandBlocks()を呼び出す
    class MmlPreprocessor3 { 
      //コンストラクタ
      public function MmlPreprocessor3() { }
      
      //メンバ
      public var blocks:Array = new Array();      //ブロック配列
      public var blockNames:Array = new Array();  //ブロック名配列
      public var sortedBlockNames:Array;          //文字列長降順でソートされたブロック名配列
      public var debug:String = "";
      
      //メソッド
      
      //ブロック展開
      //入力：行配列、展開エリア先頭位置、ブロック配列、ブロック名配列
      //出力：展開済みMML
      public function expandBlocks(lines:Array, expandingAreaIndex:int, blocks:Array, blockNames:Array) :String {
        this.blocks = blocks;
        this.blockNames = blockNames;
        this.sortedBlockNames = getMaxMatchStrings(blockNames);
        var mmlTracks:Array = new Array();    //展開済みMMLを格納
        var nowTopTrack:int = 0;  //現在展開行の先頭trk番号 ※現在展開行の持つ最大トラック数ぶん増えていく
        
        //「;」区切り1行ごと処理
        var lineCount:int = 0;
        debug += "行数[" + lines.length.toString() + "]";
        for each (var line:String in lines) {
          if (lineCount < expandingAreaIndex){
            //expandingAreaIndexに到達するまではskip
            //※展開エリア先頭から処理対象とする
            lineCount++;
            continue;
          }
          debug += "\r展開エリアで展開[" + line + "]";
          //1行展開
          var maxTrackNumber:int; //現在展開行での最大トラック数
          maxTrackNumber = expandLine(line, mmlTracks, nowTopTrack);
          //例：展開行1行目が3トラックあった場合、次の行は4トラック目から
          nowTopTrack += maxTrackNumber;
        }
        
        var mml:String = "";
        for each (var mmlTrk:String in mmlTracks) {
          debug += ("\rmml構築[" + mmlTrk + "]");
          mml += mmlTrk;
          mml += ";";
        }
        return mml;
      }
      
      //1行展開
      //1行MMLを、複数trackのMMLに展開して追記する
      //入力：展開エリア1行、MMLtrk配列への参照、現在展開行の先頭trk番号
      //出力：MMLtrk配列(追記して出力)、
      //      現在展開行の最大トラック数
      private function expandLine(line:String, mmlTracks:Array, nowTopTrack:int) :int {
        var i:int = 0;  //文字カウンタ
        var maxTrackNumber:int = 0;  //現在行の最大トラック数
        
        while (i < line.length){
          //文字カウンタが末尾未満の間はループ
          
          var str:String = line.substring(i, line.length);  //現在展開対象の文字列
          debug += ("マッチ開始[" + str + "]");
          
          //現在展開対象の文字列を元に、マッチするブロック名取得
          var matchedString:String = getMaxMatched(str, sortedBlockNames);
          debug += ("マッチ結果[" + matchedString + "]");
          if (matchedString.length == 0){
            debug += "マッチするブロック名なし[]";
            return 0;
          }
          
          //見つけたブロック名を元に、1ブロック展開(MML出力)
          expandBlock(matchedString, this.blocks, mmlTracks, nowTopTrack, maxTrackNumber);
          
          //現在展開行の最大トラック数更新
          var block:MultiTrackBlock = getBlock(matchedString, blocks);
          maxTrackNumber = getMaxTrackNumber(block, maxTrackNumber);
          i += matchedString.length;
          debug += ("文字カウンタ[" + i.toString() + "]");
        }
        
        return maxTrackNumber;
      }
      
      //1ブロック展開
      //入力：展開元文字列（例：「えふ」）、
      //      ブロック配列、
      //      MMLtrk配列、
      //      現在展開行の先頭trk番号、
      //      現在展開行の最大トラック数
      //出力：MMLtrk配列  ※追記出力する
      private function expandBlock(str:String, blocks:Array, mmlTracks:Array, trackOffset:int, maxTrackNumber:int) :void {
        //ブロック検索
        var block:MultiTrackBlock = getBlock(str, blocks);
        debug += ("1ブロック展開:ブロック名[" + block.name + "]");
        
        if (isNonNote1trkBlock(block)){
          //ブロックが、a～gを含まず、ブロックtrk数=1の場合   ※例：l8 や k1  ※rはどちらでも構わないが判定シンプルなほうとする
          //ブロックを、現在展開行の最大トラック数ぶん増幅展開し、return
          expandNonNote1trkBlock(block, mmlTracks, trackOffset, maxTrackNumber);
          return;
        }
        
        if (0 < maxTrackNumber && maxTrackNumber < block.tracks.length){
          //現在展開行の最大トラック数 < ブロックtrk数 の場合、mmlTracksを休符で埋める
          //※イメージ：最大3和音のときに、4和音ブロック展開なら、ブロックを追記する前に、4和音目を追記できるよう休符で埋める
          //  コピー元trackは、現在展開行の先頭トラックとする ※mmlTracks先頭行だと、先頭行が音色定義で増幅したくない場合に、増幅されてしまう
          padMultiMmlTracks(maxTrackNumber, trackOffset, block.tracks.length, mmlTracks, mmlTracks[trackOffset]);
        }
        
        var nowTrk:int = 0; //現在ブロックのMML出力トラック番号（mmlTracksに書き込む際はoffsetの追加が必須）
        for each (var track:String in block.tracks) {
          //ブロックから取得したtrackを、MMLの各トラックに追記出力する
          if (mmlTracks[trackOffset + nowTrk] == undefined){
            //空(undefined)の場合は初期化する
            mmlTracks[trackOffset + nowTrk] = "";
          }
          //MMLの対象トラックに追記出力する
          mmlTracks[trackOffset + nowTrk] += track;
          debug += ("track追記結果[" + track + "]");
          nowTrk++;
        }
        
        if (nowTrk < maxTrackNumber){
          //nowTrk < 現在展開行の最大トラック数 の場合、mmlTracks休符埋めメソッドを呼び出す
          //※イメージ：最大5和音のときに、3和音なら、2track分、休符で埋める
          //  コピー元trackは、ブロックの先頭トラックとする
          //  引数に与えるnowTrkの値イメージ：呼び出す時点では、3和音だった場合3である
          padMultiMmlTracks(nowTrk, trackOffset, maxTrackNumber, mmlTracks, block.tracks[0]);
        }
      }
      
      //ブロックが「ノート以外、track数1」かを判定する
      //入力：ブロック
      //出力：ブロックが、a～gを含まず、ブロックtrk数=1 ならtrue
      //※例：l8 や kt1  ※rはどちらでも構わないが判定シンプルなほうとする
      private function isNonNote1trkBlock(block:MultiTrackBlock) :Boolean {
        if (block.tracks.length != 1){
          //ブロックtrk数 != 1の場合
          return false;
        }
        var track:String = block.tracks[0];  //blockの持つtrack(前提:ブロックtrk数 = 1)
        if (track.search(/[a-g]/) != -1){
          //trackがa～gを含む場合
          return false;
        }
        return true;
      }
      
      //ブロックを、現在展開行の最大トラック数ぶん増幅展開する
      //前提：ブロックが1track  ※備考：現在展開行はどのトラックもtick数が同じ状態になっている。呼び出し元でそのようにしている
      //入力：ブロック、
      //      MMLtrk配列、
      //      現在展開行の先頭trk番号、
      //      現在展開行の最大トラック数
      //出力：MMLtrk配列  ※追記出力する
      private function expandNonNote1trkBlock(block:MultiTrackBlock, mmlTracks:Array, trackOffset:int, maxTrackNumber:int) :void {
        var i:int;
        if (maxTrackNumber == 0){
          //現在展開行の最大トラック数が0の場合（現在展開行の先頭で、まだ最大トラック数0の状態の場合を想定）
          if (mmlTracks[trackOffset] == undefined){
            //空(undefined)の場合は初期化する
            mmlTracks[trackOffset] = "";
          }
          //ブロック(1track)を、現在展開行に1track書き込む
          mmlTracks[trackOffset] += block.tracks[0];
        }else{
          //上記以外の場合
          for (i = trackOffset; i < trackOffset + maxTrackNumber; i++){
            mmlTracks[i] += block.tracks[0];
          }
        }
      }
      
      //休符埋め処理_複数track分
      //概要：loopして、休符埋め処理1track分 を呼び出す
      //最大5和音のときに、3和音なら、2track分、loopしてメソッド呼び出す
      //入力：埋める開始trk、現在展開行の先頭trk番号、埋める最大trk数、MMLtrk配列、コピー元track
      //出力：MMLtrk配列（複数trackに、コピー元trackを、追記出力する）
      private function padMultiMmlTracks(nowTrk:int, trackOffset:int, maxTrackNumber:int, mmlTracks:Array, fromTrack:String) :void {
        var i:int;  //ループカウンタ
        
        for (i = nowTrk; i < maxTrackNumber; i++) {
          //最大和音数までループして空trackで埋める
          padMmlTracks(trackOffset + i, mmlTracks, fromTrack);
        }
      }
      
      //休符埋め処理_1track分
      //入力：追記対象track番号(0ベース)、MMLtrk配列、コピー元track
      //出力：MMLtrk配列（対象trackに、コピー元trackを、追記出力する）
      private function padMmlTracks(targetTrack:int, mmlTracks:Array, fromTrack:String) :void {
        var str:String = fromTrack.replace(/[a-g]/g, "r"); //音符を休符に置換する
        if (mmlTracks[targetTrack] == undefined){
          //空(undefined)の場合は初期化する
          mmlTracks[targetTrack] = "";
        }
        mmlTracks[targetTrack] += str;
      }
      
      //ブロック検索
      //展開元文字列でブロック配列を探し、ブロックを取得する
      //■TODO OOPとしてはblocksクラスを作って、そのメソッドとするのもいいかも
      private function getBlock(str:String, blocks:Array) :MultiTrackBlock {
        for each (var block:MultiTrackBlock in blocks) {
          if (block.name == str){
            debug += "ブロックマッチ[]";
            return block;
          }
        }
        //■TODO エラーチェック
        debug += "getBlockエラー\r";
        return null;
      }
      
      //最大マッチ
      //長い文字列を優先してマッチさせる
      //入力：調べたい文字列、最大マッチ配列
      //出力：入力文字列先頭から最大マッチした文字列
      private function getMaxMatched(str:String, matchStrings:Array) :String {
        for each (var matchString:String in matchStrings) {
          var pattern:RegExp = new RegExp("^" + matchString);
          if (str.search(pattern) != -1){
            //マッチした場合
            debug += ("strとpatternとマッチ結果[" + str + ","+pattern+","+matchString+"]");
            return matchString;
          }
        }
        //■TODO エラーハンドリング
        debug += "エラーgetMaxMatched\r";
        return "/*エラーgetMaxMatched*/";
      }
      
      //最大trk数更新
      //入力：ブロック、最大trk数
      //出力：そのブロックのtrk数が最大trk数より大きければ、
      //      そのブロックのtrk数を返却。
      //      そうでなければ、最大trk数を返却。
      private function getMaxTrackNumber(block:MultiTrackBlock, max:int) :int {
        if (block.tracks.length > max){
          //ブロックtrk数が最大超過した場合
          return block.tracks.length;
        }
        return max;
      }
      
      //ブロック名最大マッチ配列取得
      private function getMaxMatchStrings(blockNames:Array) :Array {
        var maxMatchStrings:Array = blockNames.concat(); //シャローコピー
        maxMatchStrings.sort(Array.DESCENDING); //文字列ソート（降順）
        debug += ("\rgetMaxMatchStrings");
        for each (var line1:String in blockNames) {
          debug += ("ブロック名["+line1+"]");
        }
        for each (var line2:String in maxMatchStrings) {
          debug += ("最大マッチ文字列["+line2+"]");
        }
        return maxMatchStrings;
      }
      
    }
