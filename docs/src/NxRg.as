/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/NxRg
 */

// forked from cat2151's SiON MML edit and play
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
    import com.bit101.components.CheckBox;
    import flash.events.MouseEvent;  //checkBox入力のため
     
    public class TheABCSong2 extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 
        private var tf:TextField = new TextField;       //表示用領域
        private var tfmt:TextFormat = new TextFormat;   //表示用領域のtextFormat指定に使う領域
        private var autoPointPlayCheck:CheckBox; // checkbox
        private var oldtext:String = new String;    //text backup

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
                if (autoPointPlayCheck.selected){
                    compareText();
                }
                playMml("t120;" + tf.text);
                //history
                oldtext = tf.text;
                });

            //regist checkbox handler
            autoPointPlayCheck = new CheckBox(this, 10, stage.stageHeight - 20, "AutoPointPlay", checkClickHandler);
            autoPointPlayCheck.selected = true;
            
            dispText("\r//↑ここに「cde」などMMLを入力またはクリップボードからペースト");
        } 

        // check box clicked
        private function checkClickHandler(event:MouseEvent):void {
            if (autoPointPlayCheck.selected == true) {
                dispText("checkbox on");
            }else{
                dispText("checkbox off");
            }
        }

        // compare tf vs oldtf
        private function compareText():void {
            var i:int;
            var line:int = 0;
            var txt1:String = tf.text;
            var txt2:String = oldtext;
            var outTxt:String = "";
            for (i = 0; i < txt1.length && i < txt2.length; i++){
                var cat1:int = txt1.charCodeAt(i);
                var cat2:int = txt2.charCodeAt(i);
                if (cat1 == 13){
                    // CRLF
                    line++;
                }
                if (cat1 != cat2){
                    dispText(txt1 + "//diff "+i+"//line "+line);
                    return;
                }
            }
            if (txt1.length < txt2.length){
                dispText(txt1+"//"+i);
            }else if(txt2.length < txt1.length){
                dispText(txt2+"//"+i);
            }else{
                dispText(txt1+"//same");
            }
       }
    } 
} 
  

