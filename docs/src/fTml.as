/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/fTml
 */

// forked from cat2151's SiON OPM Random FM Tone
// forked from cat2151's SiON OPM Tone MML
// forked from cat2151's SiON TheABCSong2

// ランダムFM音色生成装置
//   (SiONのFM音源音色エディタとしては「SiOPM音色エディタ」があります)

package { 
    import flash.display.Sprite; 
    import org.si.sion.*;            //OPM音色を鳴らすため
    import org.si.sion.events.*;     //演奏終了event取得のため
    import flash.text.TextField;     //文字列表示のため
    import flash.text.TextFormat;    //等幅font表示のため
    import flash.events.MouseEvent;  //Mouse入力取得のため
    import flash.events.KeyboardEvent;  //キー入力取得のため
    import flash.utils.Timer;        //一定時間ごとのEvent取得のため
    import flash.events.TimerEvent;  //一定時間ごとのEvent取得のため
    import flash.system.System;      //MMLをclipboardに格納するため
     
    public class playRandomTone extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 

        private var myTimer:Timer = new Timer(100, 0);    //一定時間ごとに動作させるタイマに使う領域
        private var tf:TextField = new TextField;      //表示用領域
        private var tfmt:TextFormat = new TextFormat;  //表示用領域のtextFormat指定に使う領域
        private var toneHis:history = new history(10000);    //音色履歴用領域

        //関数定義

        //数値を整数にし文字列3文字になるよう左space埋め(padding)
        private function lpad3(inum:int) :String { return ("  " + int(inum)).substr(-3,3);          }

        //MMLを元にした文字列に、アルゴリズム解説文字列を追加する
        private function addAlgText(mml:String, td:Array) :String {
            var mmlText:String;
            var connection:Array = new Array(
                "[#0]\n  |\n[#1]\n  |\n[#2]\n  |\n[#3]\n",
                "[#1][#0]\n ＼  /\n  [#2] \n  [#3]\n",
                "[#1]\n  |\n[#2][#0]\n  ＼ /\n  [#3]\n",
                "    [#0]\n      |\n[#2][#1]\n  ＼ /\n  [#3]\n",
                "[#2][#0]\n  |   |\n[#3][#1]\n",
                "    [#0]\n   /  | ＼\n[#3][#2][#1]\n",
                "        [#0]\n          |\n[#3][#2][#1]\n",
                "[#3][#2][#1][#0]\n" );

            mmlText = mml + "\nアルゴリズム" + td[0] + "番\n" + connection[td[0]];
            return mmlText
        }
        
        //文字列を表示する
        private function dispText(text:String) :void {
            //表示文字列を更新する
            tf.text = text;
            tf.width = 400;
            tf.height = 400;
            tf.wordWrap = true;
            tf.multiline = true;
            tfmt.font = "MS Gothic";
            tf.setTextFormat ( tfmt );
            addChild( tf );
        }

        //MMLを表示する
        private function dispMml(mml:String, td:Array, am:String) :void {
            var text:String = "";
            text += addAlgText(mml, td); //アルゴリズム文字列を追加
            text += am;                  //引数で与えられた文字列を追加
            dispText(text);
        }

        //FM音色データ配列を元に、SiON用MMLを生成する
        private function makeMml(td:Array) :String {
            var mml:String = "//     ALG FB\n";
            mml += "#OPM@0 { " + td[0] + ", " + td[1] + ",\n";
            for (var op:int=0;op<4;op++) {
                mml += "//AR DR  SR  RR  SL  TL  KS MUL DT1 DT2 AMS\n"
                for (var counter:int=0;counter<11;counter++) {
                    mml = mml + lpad3(td[2 + 11*op + counter]) + ","
                }
                mml += "\n";
            }
            mml += "};\n";
            mml += "t120 %6 @0 v6 a1r2 v6 a1 r2;\n"
            mml += "%6 @0 v6 r1r2r16 <c+1 r2;\n"
            mml += "%6 @0 v6 r1r2r8 <e1 r2;\n"
            mml += "%6 @0 v6 r1r2r8. <g+1 r2;\n"
            return mml;
        }

        //SiON用MMLを元にSiONで音を鳴らす
        private function playMml(mml:String) :void {
            data = driver.compile(mml); 
            driver.play(data); 
        }

        //ランダムにFM音色データを生成する
        private function createRandomFMtone(td:Array) :Array {
            var freedom:int = Math.random() * 100;    //音色のフリーダム度を格納
            var isModulator:Array = [  //アルゴリズムごとにオペレータのどれがモジュレータかを格納
                [ true, true, true, false ],    //ALG0
                [ true, true, true, false ],    //ALG1
                [ true, true, true, false ],    //ALG2
                [ true, true, true, false ],    //ALG3
                [ true, false, true, false ],   //ALG3
                [ true, false, false, false ],  //ALG5
                [ true, false, false, false ],  //ALG6
                [ false, false, false, false ]  //ALG7
                ];
            td[0] = int(Math.random() * 8);    //ALG
            td[1] = int(Math.random() * 8);    //FB
            for (var op:int=0;op<4;op++) {
                td[2+11*op+ 0] = Math.random() *  20+6;   //AR
                td[2+11*op+ 1] = Math.random() *   4+8;   //DR
                td[2+11*op+ 2] = Math.random() *   4+8;   //SR
                td[2+11*op+ 3] = Math.random() *   4+2;   //RR
                td[2+11*op+ 4] = Math.random() *   8+8;   //SL
                if (isModulator[td[0]][op]) {
                    td[2+11*op+ 5] = Math.random() * 50;  //TL (Modulator)
                } else {
                    td[2+11*op+ 5] = 0;                   //TL (Carrier)
                }
                td[2+11*op+ 6] = 0;                     //KS
                td[2+11*op+ 7] = Math.random() *   6;   //MUL
                td[2+11*op+ 8] = Math.random() *   8;   //DT1
                td[2+11*op+ 9] = 0;                     //DT2
                td[2+11*op+10] = 0;                     //AMS
                if (freedom>70){    //エンベロープを早すぎず遅すぎず、などの制約を外す場合
                    if (Math.random()*4<1){ td[2+11*op+ 7] = Math.random() *  16; }   //MUL
                    if (freedom>85){
                        td[2+11*op+ 0] = Math.random() *  32;   //AR
                        td[2+11*op+ 1] = Math.random() *  32;   //DR
                        td[2+11*op+ 2] = Math.random() *  32;   //SR
                        td[2+11*op+ 3] = Math.random() *  16;   //RR
                        td[2+11*op+ 4] = Math.random() *  16;   //SL
                        if (Math.random()*4<1){ td[2+11*op+ 5] = Math.random() *   4; }   //TL
                        if (Math.random()*4<1){ td[2+11*op+ 6] = Math.random() *   4; }   //KS
                        if (Math.random()*4<1){ td[2+11*op+ 9] = Math.random() *   4; }   //DT2
                        if (Math.random()*4<1){ td[2+11*op+10] = Math.random() *   4; }   //AMS
                        if (freedom>95 && Math.random()*4<1){ td[2+11*op+ 5] = Math.random() * 16; }   //TL (17～128は省略)
                    }
                }
            }
            return td;
        }
        
        //音色履歴から演奏、クリップボードにMML格納
        private function playHistory(add:int) :void {
            //音色データを履歴から取得
            var td:Array = toneHis.get(add);    //音色データ領域
            var mml:String;         //MMLを格納する領域
            var am:String = "";     //追加表示文字列領域
            am += "\n(履歴"+toneHis.readIndex+"番の音色データを鳴らしました)\n";
            am += "\n(クリップボードにSiON用MMLをコピーしました)\n";

            mml = makeMml(td);        //FM音色データ配列を元に、SiON演奏用MMLを生成する
            playMml(mml);             //SiON用MMLを元にSiONで音を鳴らす
            dispMml(mml,td,am);       //MMLを表示する
            System.setClipboard(mml); //clipboardにMMLを格納する
        }

        //音色生成、演奏、表示、クリップボードに格納
        private function playAndDisp(clipFlag:Boolean) :void {
            var td:Array = new Array(2+11*4);      //ランダム音色データを格納する領域
            var mml:String;       //MMLを格納する領域
            var am:String = "";   //追加表示文字列領域
            am += "\n(カーソル左右：履歴内の音色データを鳴らす)\n";
            if (clipFlag){ am += "\n(クリップボードにSiON用MMLをコピーしました)\n"; }

            td = createRandomFMtone(td); //ランダムにFM音色データを生成する
            toneHis.add(td);             //音色データを履歴に保存する
            mml = makeMml(td);           //FM音色データ配列を元に、SiON演奏用MMLを生成する
            playMml(mml);                //SiON用MMLを元にSiONで音を鳴らす
            dispMml(mml,td,am);          //MMLを表示する
            if (clipFlag){ System.setClipboard(mml); } //clipboardにMMLを格納する
        }

        //コンストラクタ(初期設定)
        function playRandomTone() {
            //イベントハンドラを登録する
            //    MOUSE_DOWN(マウス左ボタンプッシュ)を登録
            stage.addEventListener( MouseEvent.MOUSE_DOWN, function(e :MouseEvent) :void {
                //クリックした場合
                playAndDisp(true);     //演奏と表示とクリップボード格納
                });
            //    キーボードのキー押下を登録
            stage.addEventListener( KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) :void {
                //キーボードのキーが押された場合
                switch (e.keyCode) {
                case 37: playHistory(-1); break;
                case 39: playHistory( 1); break;
                }
                });
            //    演奏終了を登録
            driver.addEventListener( SiONEvent.FINISH_SEQUENCE, function(e :SiONEvent) :void {
                //演奏が終了した場合
                myTimer.start();   //タイマをスタートさせる
                });
            //    一定時間ごとに発生するタイマイベントを登録
            myTimer.addEventListener(TimerEvent.TIMER, function(e :TimerEvent) :void {
                //タイマのスタートから一定時間が経過した場合
                myTimer.stop();     //タイマを停止させる
                playAndDisp(false); //演奏と表示
                });

            //予め音色を生成して履歴に格納しておく
            for (var i:int=0;i<10000;i++){
                var td:Array = new Array(2+11*4); //ランダム音色データを格納する領域
                td = createRandomFMtone(td);  //ランダムにFM音色データを生成する
                toneHis.add(td);              //音色データを履歴に保存する
            }

            //初回演奏
            playAndDisp(false);     //演奏と表示
        }


    }
}
    
    //履歴バッファ
    //FIFO(lengthはコンストラクタで指定)に対して読み書き
    //制約：履歴バッファにaddする値の型はArray限定
    class history { 
        //公開プロパティ
        public var readIndex:int;      //履歴index(読み込み用)
        //非公開プロパティ
        private var writeIndex:int;    //履歴index(書き込み用)
        private var writeIndexMax:int; //何段目まで履歴が入っているか
        private var fifoBuf:Array;     //履歴を格納
        private var bufLength:int;     //履歴段数を格納

        //メソッド

        //コンストラクタ
        public function history(length:int) {
            fifoBuf = new Array(length);
            bufLength = length;
        }

        //値を履歴に書き込み、readIndexも同期させる
        public function add(data:Array) :void {
            //履歴にデータ書き込み
            fifoBuf[writeIndex] = data;
            //readIndexを同期させる
            readIndex = writeIndex;
            //max更新
            if (writeIndexMax < bufLength - 1){ writeIndexMax = writeIndex; }
            //writeIndexをラップアラウンド
            writeIndex = (writeIndex + 1) % bufLength;
        }

        //指定された分、履歴を遡り、値を取得する(readIndexを変更し、それを元に取得)
        public function get(add:int) :Array {
                                      //備考：ArrayではなくObjectと記述した場合、呼び出し側記述時にコンパイルエラー
            //readIndex更新
            readIndex += add;
            //readIndexを前後ともラップアラウンド
            if (readIndex < 0){ readIndex = writeIndexMax; }
            else if (readIndex>writeIndexMax){ readIndex = 0; }
            //履歴からデータ取得
            return fifoBuf[readIndex];
        }
    }
