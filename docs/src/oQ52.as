/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/oQ52
 */

// forked from cat2151's SiON MML OPM Tone
// forked from cat2151's SiON TheABCSong2
// simple example 

// textBox内に「cde」と書けばcdeが鳴ります
// 他のSiON用MML自動生成装置の出力をペーストすれば鳴ります

package {
    import flash.display.Sprite; 
    import org.si.sion.*; 
    import flash.text.TextField;     //文字列表示のため
    import flash.text.TextFormat;    //等幅font表示のため
    import flash.text.TextFieldType; //文字列入力のため
    import flash.events.Event;       //文字列入力のため
     
    public class TheABCSong2 extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 
        private var tf:TextField = new TextField;       //表示用領域
        private var tfmt:TextFormat = new TextFormat;   //表示用領域のtextFormat指定に使う領域

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
         
        //コンストラクタ
        function TheABCSong2() { 
            //イベントハンドラを登録する
            //    テキスト変更を登録
            tf.addEventListener( Event.CHANGE, function(e :Event) :void {
                //Textが編集された場合
                playMml("t120;" + tf.text);
                });
            
            dispText("\r//↑ここに「cde」などMMLを入力またはクリップボードからペースト");
        } 
    } 
} 
  

