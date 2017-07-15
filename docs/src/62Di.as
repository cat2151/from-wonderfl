/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/62Di
 */

// forked from cat2151's SiON MML edit and play
// forked from cat2151's SiON MML OPM Tone
// forked from cat2151's SiON TheABCSong2

//演奏開始位置を指定できます（画面下）

// textBox内に「cde」と書けばcdeが鳴ります
// 他のMML自動生成装置の出力をペーストすれば鳴ります

//開発中

// 課題：履歴をつける。最後の入力から一定時間経過したら履歴に入れる。
//     text編集と被らない特殊な操作(「履歴」txtBoxを表示させそれをclick等?)で、
//     履歴から鳴らす。その場合はclipboardに格納する
// 課題：数値の増減編集に特化(カーソルで編集対象数値を変更、ion)
        private var myTimer:Timer = new Timer(2000, 1); //一定時間ごとに動作させるタイマに使う領域

        //SiON用MMLを元にSiONで音を鳴らす
        private function playMml(mml:String) :void {
            data = driver.compile(mml); 
            driver.play(data); 
        }

        //文字列を表示する
        private function dispText(text:String) :void {
            //表示文字列を更新する
            tf.text = text;
            tf.width = 400;
            tf.height = 400;
            tf.wordWrap = true;
            tf.multiline = true;
            tf.type = TextFieldType.INPUT;    //文字列入力可能にする
            tfmt.font = "MS Gothic";
            tf.setTextFormat ( tfmt );
            addChild( tf );
     }
        //文字列を表示する
        private function dispTextPos(text:String) :void {
            //表示文字列を更新する
            tfpos.y = 400;
            tfpos.width = 400;
            tfpos.text = text;
            tfpos.multiline = true;
            tfpos.type = TextFieldType.INPUT;    //文字列入力可能にする
            addChild( tfpos );
        }

        //演奏, 指定演奏開始位置からの演奏
        private function playEtc() :void {
                playMml("t120;" + tf.text);

                //positionで指定した場所から鳴らす
//                //0除算はあとで修正予定
//                //bpm可変曲の場合不正確(msec単位でないposition指定方法わかり次第修正)
//                driver.position = int((tfpos.text.split("\r"))[0]) * 60 * 1000 / driver.bpm;
                driver.position = int((tfpos.text.split("\r"))[0]) * 1000;
                myTimer.start();    //タイマを開始させる
        }
        
        //コンストラクタ
        function TheABCSong2() { 
            //イベントハンドラを登録する
            //    テキスト変更を登録
            tf.addEventListener( Event.CHANGE, function(e :Event) :void {
                //Textが編集された場合
                playEtc();
                  });
            //    テキスト変更を登録
            tfpos.addEventListener( Event.CHANGE, function(e :Event) :void {
                //Textが編集された場合
                playEtc();
                  });
            //    一定時間ごとに発生するタイマイベントを登録
            myTimer.addEventListener(TimerEvent.TIMER, function(e :TimerEvent) :void {
                //タイマのスタートから一定時間が経過した場合
                myTimer.stop();    //タイマを停止させる
                //履歴に格納する
                //★開発中
                });
            
            dispText("\r//↑ここにMMLを入力またはクリップボードからペースト");
            dispTextPos("0\r//↑演奏開始位置(秒)");
                    } 
    } 
} 
  
