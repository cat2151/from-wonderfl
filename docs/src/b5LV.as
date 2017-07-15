/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/b5LV
 */

// forked from cat2151's SiON OPM Random FM Tone
// forked from cat2151's SiON OPM Tone MML
// forked from cat2151's SiON TheABCSong2

// ランダムFM音色生成装置
//   (SiONのFM音源音色エディタとしては「SiOPM音色エディタ」があります)

// fork元はDT2を使った音や過変調の音など生成される音色にバリエーションがありますが、
//      こちらは聴きやすさを優先した音色に限定しています
//      (1/100くらいの確率でDT2を使った音程感のない音色や過変調のノイズ系音色も生成します)
// 現状、音色については、稀に過変調に近いnoise音色が出現
//      (逆に一定値未満のTLはほとんど生成されないため、ある種の音色がほとんど出現しない可能性も)、
//      MUL0がありoctave低く聴こえる音色のarp,chordがbassと衝突、等の問題があります

package {
    import flash.net.IDynamicPropertyOutput;
    import flash.display.Stage;
    import flash.display.AVM1Movie; 
    import flash.display.Sprite; 
    import org.si.sion.*;            //OPM音色を鳴らすため
    import org.si.sion.events.*;     //演奏終了event取得のため
    import flash.text.TextField;     //文字列表示のため
    import flash.text.TextFormat;    //等幅font表示のため
    import flash.events.Event;       //TextFieldのScrollEvent取得のため
    import flash.events.MouseEvent;  //Mouse入力取得のため
    import flash.events.KeyboardEvent;  //キー入力取得のため
    import flash.utils.Timer;        //一定時間ごとのEvent取得のため
    import flash.events.TimerEvent;  //一定時間ごとのEvent取得のため
    import flash.system.System;      //MMLをclipboardに格納するため
    import com.bit101.components.*;  //ボタン入力とスクロールバー表示のため

    public class playRandomTone extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 

        private var myTimer:Timer = new Timer(1, 0);    //一定時間ごとに動作させるタイマに使う領域
        private var tf:TextField = new TextField;      //表示用領域 MML表示用
        private var tfStatus:TextField = new TextField;      //表示用領域 status表示用
        private var tfmt:TextFormat = new TextFormat;  //表示用領域のtextFormat指定に使う領域
        private var vScrollBar:VScrollBar;                //MML表示用領域のスクロールバー
        private var toneHis:history = new history(1000);    //音色履歴用領域
        private var mmlCurrent:Array = new Array(6);    //音色MML,演奏MML用領域
        private var autoNext:Boolean = true;    //演奏終了後に自動で次を生成・演奏するか
        private var autoToneChange:Boolean = true;    //演奏終了後の自動生成時に音色を自動更新するか
        private var addLoopf:Boolean = true;    //生成MMLに無限ループである$をつけるか
        private var oneMeasPlay:Boolean = true;    //生成MMLは1小節だけか, コード進行分(例:5小節)一度に生成するか
        private var matrixBuf:Array;     //フレーズ自動生成用データを格納
        private const maxPart:int = 3;       //パート数 Arp,Bass,Chordで3パート (領域確保用)
        private const maxChannel:int = 8;   //パート内最大発音数 (領域確保用)
        private const maxStep:int = 16;     //パート内最大step数 (領域確保用)
        private var currentKey:int = 0;    //KEY 0～11 0がC,11がB
        private var rootIndex:int = 0;      //コード進行index
        private var progressArpScale:Array = [    //arp用scale定義　コード進行の種類ごと
            [0,3,5,7,10],   //k進行用スケール　マイナーペンタ
            [0,3,5,7,10],
            [0,4,5,7,11],    //琉球
            [0,2,3,7,8],    //陰旋法
        ];
        private var progressBsScale:Array = [     //bass用scale定義　コード進行の種類ごと
            [0,2,3,5,7,8,10],    //k進行用スケール　マイナー
            [0,2,3,5,7,8,10],
            [0,4,5,7,11],    //琉球
            [0,2,3,5,7,8,10],    //陰旋法用　マイナー
        ];
        private var progressBass:Array = [    //bass用コード進行定義  : root : bass用scaleのトニックノートからのoffset(半音単位ではない)
            [0,2,3,5,6],    //k進行
            [0,6-7,5-7,6-7],  //※progressBassの要素数は、progress～系全体の要素数とみなされるので注意。ほかもここの要素数に合わせること
            [0,3-5,2-5,3-5],    //琉球
            [0,3-7,4-7,5-7,6-7],    //陰旋法用　マイナー
        ];
        private var progressChordRoot:Array = [ //chord用コード進行定義 : root : トニックノートを0として半音単位
            [0,3,5,8,10],        //k進行
            [0,10,8,10],
            [0,7,5,7],    //琉球
            [0,5,7,8,10],    //陰旋法用　マイナー
        ];
        private var progressChordTone:Array = [ //chord用コード進行定義 ランダムでocataveや倍音が変化しぶつかりを制御しきれないため、ぶつかりやすい音は外すのが無難
            [   [0,3,7,10],      //k進行    先頭の要素数をMML生成時の和音数としても利用しているので注意
                [0,4,7,11],    //※無音はnull
                [0,7,10,14],
                [0,4,7,11],
                [0,7,10,14]    ],
            [   [0,3,7,10],      
                [0,4,7,9], 
                [0,4,7,9],
                [0,4,7,10]    ],
            [   [0,4,7,11],      //琉球
                [0,4,7,2],
                [0,4,7,9],
                [0,4,7,10]    ],
            [   [0,3,7,10],      //陰旋法用　マイナー
                [0,3,7,10], 
                [0,3,7,10],
                [0,4,7,11],
                [0,4,7,10]    ],
        ];
        private var progressUnitLength:Array = [ //コード進行用 コード進行indexごとの演奏長さ(16分音符の個数)
            [16,16,16,8,8],      //k進行
            [16,16,16,16],
            [16,16,16,16],
            [16,16,16,8,8],
        ];

        private var arpScale:Array;      //コード進行のcurrent用配列 progressArpScale　に対応、以下同様
        private var bassScale:Array;     //コード進行のcurrent用配列
        private var rootBassArray:Array; //コード進行のcurrent用配列
        private var rootOfsArray:Array;  //コード進行のcurrent用配列
        private var chordArray:Array;    //コード進行のcurrent用配列
        private var writeLengthArray:Array;    //コード進行のcurrent用配列

        private var progressSeriesArr:Array;        //コード進行用の数列を格納する領域
        private var generatedArpScale:Array;      //生成されたコード進行用配列 progressArpScale　に対応、以下同様
        private var generatedBassScale:Array;     //生成されたコード進行用配列
        private var generatedRootBassArray:Array; //生成されたコード進行用配列
        private var generatedRootOfsArray:Array;  //生成されたコード進行用配列
        private var generatedChordArray:Array;    //生成されたコード進行用配列
        private var generatedWriteLengthArray:Array;    //生成されたコード進行用配列

        private var writeLengthArrMul:int=4;    //writeLengthArrayの要素に乗算する値
        private var writeLengthArrDiv:int=4;    //writeLengthArrayの要素に除算する値
        private var progressNumof:int = progressBass.length;    //進行の種類の個数
        private var progressTypeIndex:int = 0;    //コード進行の種類 現在値index
        private var playCount:int = 0;    //複数回演奏終了後KEY変更用カウンタ
        private var tempo:int = 130;
        private var debugmml:String = "";
        private var processChordNotenum:processChordNotenum = new processChordNotenum();    //chordのnotenum加工用
        private var chordNotenumForArpArray:Array;  //arp用 chordのNoteNumをchannel,measごとに格納
        private var isChordSyncArp:Boolean = false; //chord音程にあわせてarpフレーズを生成するか
        

        //関数定義

        //数値を整数にし文字列3文字になるよう左space埋め(padding)
        private function lpad3(inum:int) :String { return ("  " + int(inum)).substr(-3,3);          }
        
        //文字列を表示する
        private function dispText(text:String) :void {
            tf.y = 20;
            tf.text = text;            //表示文字列を更新する
            tf.width = 400;
            tf.height = 400-20;
            tf.wordWrap = true;
            tf.multiline = true;
            tfmt.font = "MS Gothic";
            tf.setTextFormat ( tfmt );
            addChild( tf );
        }
        //文字列を表示する ステータス表示用
        private function dispTextStatus(text:String) :void {
            tfStatus.y = tf.y + tf.height;
            tfStatus.width = tf.width;
            tfStatus.height = 50;
            tfStatus.text = text;            //表示文字列を更新する
            tfStatus.multiline = true;
            tfStatus.border = true;
            addChild( tfStatus );
        }
        /** TextFieldに合わせてスクロールバーを設定 */
        private function adjustScrollBar():void {
          var visibleLines:int = tf.numLines - tf.maxScrollV + 1;
          var percent:Number = visibleLines / tf.numLines;
          vScrollBar.setSliderParams(1, tf.maxScrollV, tf.scrollV);
          vScrollBar.setThumbPercent(percent);
          vScrollBar.value = tf.scrollV;
          //textfieldの横にスクロールバーを表示する
          vScrollBar.x = tf.x + tf.width;
          vScrollBar.y = tf.y;
          vScrollBar.height = tf.height;
        }

        //MMLを表示する
        private function dispMml(mml:String, am:String) :void {
            dispText(mml);
            dispTextStatus(debugmml + am);
        }

        //FM音色データ配列を元に、SiON用音色定義MMLを生成する
        //td:FM音色データ配列
        //part:音色定義番号（例："0"）
        private function makeToneMml(td:Array,part:String) :String {
            var mml:String = "";
            mml += "#OPM@";
            mml += part;
            mml += " { " + td[0] + ", " + td[1] + ",\n";
            for (var op:int=0;op<4;op++) {
                if (0==op) {
                    mml += "//AR DR  SR  RR  SL  TL  KS MUL DT1 DT2 AMS\n"
                }
                for (var counter:int=0;counter<11;counter++) {
                    mml = mml + lpad3(td[2 + 11*op + counter]) + ","
                }
                mml += "\n";
            }
            mml += "};\n";
            return mml;
        }
        //ランダムに音色MMLを生成する
        // Arp用音色を生成する
        private function makeToneMmlArp() :String {
            var td:Array = new Array(2+11*4); //ランダム音色データを格納する領域
            td = createRandomFMtone(td); //ランダムにFM音色データを生成する
            //エンベロープをArp用に再度ランダム生成
            for (var op:int=0;op<4;op++){
                td[2+11*op+ 0] = Math.random() *  5+25;   //AR
                td[2+11*op+ 3] = Math.random() *  15+15;   //RR
            }
            if (Math.random() * 100 < 99){
                adjustFMtoneTLbyALG_FB(td);//TLを加工する(ノイズ音色防止)
            }
            return makeToneMml(td,"0");
        }
        // Bass用音色を生成する
        private function makeToneMmlBass() :String {
            var td:Array = new Array(2+11*4); //ランダム音色データを格納する領域
            td = createRandomFMtone(td); //ランダムにFM音色データを生成する
            //エンベロープをBass用に再度ランダム生成
            for (var op:int=0;op<4;op++){
                td[2+11*op+ 0] = Math.random() *  8+22;   //AR
                td[2+11*op+ 3] = Math.random() *  7+24;   //RR
            }
            if (Math.random() * 100 < 99){
                adjustFMtoneTLbyALG_FB(td);//TLを加工する(ノイズ音色防止)
            }
            return makeToneMml(td,"1");
        }
        // Chord用音色を生成する
        private function makeToneMmlChord() :String {
            var td:Array = new Array(2+11*4); //ランダム音色データを格納する領域
            td = createRandomFMtone(td); //ランダムにFM音色データを生成する
            //エンベロープをChord用に再度ランダム生成
            for (var op:int=0;op<4;op++){
                if (!isModulator[td[0]][op]) {    //キャリアは減衰遅く
                    td[2+11*op+ 1] = Math.random() *   8+4;   //DR
                    td[2+11*op+ 2] = Math.random() *   8+4;   //SR
                }
            }
            if (Math.random() * 100 < 99){
                adjustFMtoneTLbyALG_FB(td);//TLを加工する(ノイズ音色防止)
            }
            return makeToneMml(td,"2");
        }

        //フレーズ自動生成用データを初期化
        private function initNoteMatrix () :void { 
            matrixBuf = new Array(maxPart);
            for (var part:int=0;part<maxPart;part++) {
                matrixBuf[part] = new Array(maxChannel);
                for (var channel:int=0;channel<maxChannel;channel++) {
                    matrixBuf[part][channel] = new Array(maxStep);
                    for (var step:int=0;step<maxStep;step++) {
                        matrixBuf[part][channel][step] = {
                            note:   0 as int,
                            q:      8 as int
                        };
                    }
                }
            }
        }
        //あるステップのデータを別ステップへ上書きコピー
        private function copyNoteMatrixStep (matrixBuf:Array,part:int,channel:int,fromStep:int,toStep:int) :void { 
            matrixBuf[part][channel][toStep].note = 
            matrixBuf[part][channel][fromStep].note;
            matrixBuf[part][channel][toStep].q = 
            matrixBuf[part][channel][fromStep].q;
        }
        
        //scaleとnoteを元にnoteNumberを算出する
        private function calcNoteNumber(scale:Array,note:int,notenumOfTonicNote:int) :int {
            //noteは0,1,2...でAマイナペンタなら69,69+3,69+5...
            var notenumOfs:int = 0;
            var newNote:int = 0;
            while (note<0){    //マイナスの場合の補正
                note += scale.length;
                notenumOfs -= 12;
            }
            notenumOfs += scale[note % scale.length];
            notenumOfs += int(note / scale.length) * 12;
            newNote = notenumOfTonicNote + notenumOfs;
            return newNote;
        }
        //NoteNumberの属するoctaveを得る
        private function calcOctave(noteNumber:int) :int {
            return int(noteNumber / 12);
        }
        //oldNoteNumberのoctaveとnewNumber2のoctaveを調べ,
        //octaveが相違していれば<>を得る
        private function getOctMML(oldNoteNumber:int,newNoteNumber:int) :String {
            var oldo:int = calcOctave(oldNoteNumber);
            var newo:int = calcOctave(newNoteNumber);
            var o:int = oldo;
            var mml:String = "";
            while (o!=newo){
                if (o>newo){
                    mml += ">";
                    o--;
                }else if (o<newo){
                    mml += "<";
                    o++;
                }
            }
            return mml;
        }
        //NoteNumber,oldNoteNumberを元に音程MMLを得る
        private function getNoteMML(noteNumber:int,oldNoteNumber:int) :String {
            var mml:String = "";
            var noteArray:Array = ["c","c+","d","d+","e","f","f+","g","g+","a","a+","b"];
            mml += getOctMML(oldNoteNumber,noteNumber);
            mml += noteArray[noteNumber % 12];
            return mml;
        }
        //matrixを元にMMLを生成する
        private function matrixToMML (matrixBuf:Array,part:int,channel:int,scale:Array,tonicNoteNum:int,defaultNoteNum:int,writeLength:int,isNoteNumMatrix:Boolean) :String {
            var mml:String = "";
            var nowNoteNumber:int = 0;
            var oldNoteNumber:int = defaultNoteNum;
            var step:int = 0;   //カウンタ
            var j:int = 0;    //カウンタ
            var sameStep:int = 0;
            var bufsize:int = writeLength;
            for (step=0;step<bufsize;step++) {
                //note
                if (isNoteNumMatrix) {
                    //matrixのデータをノートナンバー0～127とみなして取得する
                    nowNoteNumber = matrixBuf[part][channel][step].note;
                        //前提：scaleおよびtonicNum(keyから算出)による加工を事前に行っていること
                }else{
                    //matrix,scale,tonicNum(keyから算出)を元にノートナンバー0～127を算出する
                    nowNoteNumber = calcNoteNumber(scale,matrixBuf[part][channel][step].note,tonicNoteNum);
                }
                //q, 休符, tie
                if (-2 == matrixBuf[part][channel][step].q) {
                    //-2だけは休符に
                    mml += getOctMML(oldNoteNumber,nowNoteNumber);    //休符でもoctは上下させる,でないと小節最初が休符などの場合oct整合がとれない
                    mml += "r";
                    //休符が続く個数を数える
                    sameStep = 1;
                    for (j=step+1;j<bufsize;j++){
                        if(matrixBuf[part][channel][j].q!=-2){
                            break;
                        }
                        sameStep++;
                    }
                    //音長MMLを生成
                    if (16==sameStep){
                        mml += "1";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(12==sameStep){
                        mml += "2.";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(8==sameStep){
                        mml += "2";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(6==sameStep){
                        mml += "4.";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(4==sameStep){
                        mml += "4";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(3==sameStep){
                        mml += "8.";
                        step += sameStep-1;    //loop変数制御注意
                    }else if(2==sameStep){
                        mml += "8";
                        step += sameStep-1;    //loop変数制御注意
                    }
                }else{
                    //タイや普通のqはノートを生成
                    mml += getNoteMML(nowNoteNumber,oldNoteNumber);

                    //noteの後
                    if (-1 == matrixBuf[part][channel][step].q) {
                        //tieの場合
                        //同じnoteが続く個数を数える
                        sameStep = 1;
                        for (j=step+1;j<bufsize;j++){
                            if(matrixBuf[part][channel][j].note!=matrixBuf[part][channel][step].note){
                                //違うnoteならloop脱出
                                break;
                            }else if(matrixBuf[part][channel][j].q==-2){
                                //休符ならloop脱出
                                break;
                            }else if(matrixBuf[part][channel][j].q!=-1){
                                //tieでない場合
                                sameStep++; //個数には加えるがloop脱出(注意)
                                break;
                            }
                            sameStep++;
                        }
                        //音長MMLまたはtieを生成
                        if (16==sameStep){
                            mml += "1";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (12==sameStep){
                            mml += "2.";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (8==sameStep){
                            mml += "2";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (6==sameStep){
                            mml += "4.";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (4==sameStep){
                            mml += "4";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (3==sameStep){
                            mml += "8.";
                            step += sameStep -1;    //loop変数制御注意
                        }else if (2==sameStep){
                            mml += "8";
                            step += sameStep -1;    //loop変数制御注意
                        }else{
                            mml += "&";
                        }
                    }
                }
                oldNoteNumber = nowNoteNumber;
            }
            return mml;
        }

        //tonicNoteNumberを、defaultNoteNumberのoctaveにあるように調整する
        // tonicNoteNumberは半音単位の数値
        private function adjustTonicNoteNumber(tonicNoteNumber:int,defaultNoteNumber:int) :int {
            while (tonicNoteNumber<defaultNoteNumber){ //tonicNoteNumberがdefaultを下回らないようにする
                tonicNoteNumber += 12;
            }
            while (tonicNoteNumber>defaultNoteNumber+12){ //tonicNoteNumberがdefault+12を上回らないようにする
                tonicNoteNumber -= 12;
            }
            return tonicNoteNumber;
        }

        //ランダムフレーズ生成：Arp用
        //    scaleを元にフレーズを1小節分生成、matrixに書き込み、MMLを出力する
        private function makeRndArp(matrixBuf:Array,scale:Array,portamento:Boolean,oofs:int,writeLength:int) :String {
            const part:int = 0;
            const channel:int = 0;
            var mml:String = "";    //出力バッファ
            var bufsize:int = writeLength;
            var note:int = 0;    //loop内で値を維持したまま使われる
            var oldnote:int = 0;
            var q:int = 0;        //loopごとに初期化される
            var r:int = 0;    //次のnoteを決める際の乱数格納

            for (var step:int=0;step<bufsize;step++) {
                q = 4;    //初期化
                if (0==step){    //note初期化
                    note = int(Math.random() * scale.length);    //bassがtonicNoteなので、arpはtonicNote開始でなくてもいい
                    oldnote = note;
                }else{
                    //noteの決定
                    r = Math.random() * 100;
                    if ( r < 90 ) {       //上に向かう
                       note += 1 + int(Math.random() * (scale.length -1));
                    }else if ( r < 95 ) { //noteは前stepと同じままにし、前stepとtieで結ぶ
                        matrixBuf[part][channel][step-1].q = -1;
                    }else{                //下がる
                       note --;
                    }
                    //上は2octラップアラウンド、下は1octラップアラウンド
                    // 2oct上のtonicNoteを最高音として、それを超えた瞬間2oct下げる
                    if (note>scale.length * 2){ note -= scale.length*2; }
                    if (note<0){ note += scale.length; }
                }
                //q,tieの決定
                if ( !portamento ) {    //ポルタメントかけない場合のtie
                    if ( Math.random() * 100 < 10 ) {
                        q = -1;    //tie
                    }
                }else{    //ポルタメントかける場合のtie
                    if ( step>0 ){    //前のnoteからの推移が1なら前のnoteにportamentoをかける
                        if (Math.abs(note - oldnote) < 2){
                            matrixBuf[part][channel][step-1].q = -1;    //tie
                        }
                    }
                }
                //決定したnoteを元にmatrixに書き込み
                matrixBuf[part][channel][step].note = note + (oofs * scale.length);
                matrixBuf[part][channel][step].q = q;
                oldnote = note;
            }
            matrixBuf[part][channel][bufsize-1].q = 4;    //最後はtieにしない
            mml += "o5";
            const defaultNoteNumber:int = 12*5; //直前のo5にあわせる
            var tonicNoteNumber:int = currentKey;
            tonicNoteNumber = adjustTonicNoteNumber(tonicNoteNumber,defaultNoteNumber);
            if (portamento){
                mml += "po3";
            }
            mml += matrixToMML(matrixBuf,part,channel,scale,tonicNoteNumber,defaultNoteNumber,bufsize,false);
            return mml;
        }
        //ランダムにarpの音符MMLを生成する
        // 上昇, ランダム   フレーズ生成関数を呼び出す
        private function makeOnpuMmlArpUpRnd() :String {
            const part:int = 0;
            var mml:String = "";    //出力バッファ
            var scale:Array = arpScale; //note生成のためのスケールを指定
            var portamento:Boolean = false;
            var writeLength:int;
            var oofs:int = 0;    //octave offset
            var r:int = 0;  //乱数ワーク

            r = Math.random() * 100;
            if (r<50){ portamento = true; } //ポルタメント
            r = Math.random() * 100;
            if (r<10){ oofs --; }   //稀にoctave下げる：ローインターバルリミットに抵触しがちなので多用できない
            //設定値を元にmatrixに書き込み、matrixToMML
            if (oneMeasPlay){    //1小節だけ生成
                writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                mml += makeRndArp(matrixBuf,scale,portamento,oofs,writeLength);
            }else{    //コード進行ぶん（例：5小節）生成
                rootIndex = 0;
                for (var i:int=0;i<rootBassArray.length;i++){
                    writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                    mml += makeRndArp(matrixBuf,scale,portamento,oofs,writeLength);
                    mml += "\n";
                    progressChord();
                }
            }
            mml += ";";
            if (oneMeasPlay){    //1小節だけ生成の場合
                mml += "\n";
            }
            return mml;
        }
        //arpの音符MMLを生成する
        // chord音程に合わせたアルペジオを生成する
        //  chordNotenumForArpArrayを元に、
        //   1小節分生成、matrixに書き込み、MML生成
        private function makeArpFromChord(writeLength:int, chordMeas:int) :String {
            const part:int = 0;
            const channel:int = 0;
            var mml:String = "";    //出力バッファ
            var chordChannelSize:int = chordNotenumForArpArray.length;   //和音数
            var chordChannel:int = 0;   //カウンタ
            var scale:Array = arpScale; //note生成のためのスケールを指定    ダミー
            var oofs:int = 0;
            var isUp:Boolean = true;
            
            //matrixBufへ、chordNotenumForArpArrayから、
            // notenumモードで書き込み
            // アルペジエータ(和音からアルペジオを生成)
            //    arp type : 2oct updown
            for (var step:int=0;step<writeLength;step++){
                //chordChannel, isUp決定
                if (0 == step){
                    chordChannel = 0;
                    isUp = true;
                } else {
                    if (isUp){  //up
                        chordChannel++;
                        if (chordChannel >= chordChannelSize){  //type : 2oct up
                            chordChannel = 0;
                            oofs += 12;
                            if (oofs>=24){
                                isUp = false;   //downへ
                            }
                        }
                    } else {    //down
                        chordChannel --;
                        if (chordChannel < 0){
                            chordChannel = chordChannelSize -1;
                            oofs -= 12;
                        } else if (chordChannel <= 1 && oofs <= 0){
                                isUp = true;    //upへ
                        }
                    }
                }
                //chordChannelを元に、notenum決定
                var notenum:int = chordNotenumForArpArray[chordChannel][chordMeas] + oofs;
                //noteを元に、matrixBufへ書き込み
                matrixBuf[part][channel][step].note = notenum;
                matrixBuf[part][channel][step].q = 4;
            }
            
            mml += "o5";
            const defaultNoteNumber:int = 12*5; //直前のo5にあわせる
            var tonicNoteNumber:int = currentKey;
            tonicNoteNumber = adjustTonicNoteNumber(tonicNoteNumber,defaultNoteNumber);
            mml += matrixToMML(matrixBuf,part,channel,scale,tonicNoteNumber,defaultNoteNumber,writeLength,true);
            return mml;
        }
        //arpの音符MMLを生成する
        // アルペジオ生成関数を呼び出す
        private function makeOnpuMmlArpFromChord() :String {
            var mml:String = "";    //出力バッファ
            var writeLength:int;

            if (null == chordNotenumForArpArray){
                makeOnpuMmlChord(); //配列が確保されていない場合は、初期化する
                    //makeOnpuMmlChordからarpを呼び出さないよう注意(無限再起呼び出しになってしまう)
            }

            //設定値を元にmatrixに書き込み、matrixToMML
            if (oneMeasPlay){    //1小節だけ生成
                writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                mml += makeArpFromChord(writeLength,rootIndex);
            }else{    //コード進行ぶん（例：5小節）生成
                rootIndex = 0;
                for (var i:int=0;i<rootBassArray.length;i++){
                    //writeLength算出のためコード進行処理を行う
                    writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                    mml += makeArpFromChord(writeLength,i);
                    mml += "\n";
                    progressChord();
                }
            }
            mml += ";";
            if (oneMeasPlay){    //1小節だけ生成の場合
                mml += "\n";
            }
            return mml;
        }
        //arpの音符MMLを生成する
        private function makeOnpuMmlArp() :String {
            var mml:String = "";    //出力バッファ
            mml += "%6@0 ";
            mml += "@v0,32,64";
            if (addLoopf) { mml += "$"; }    //無限ループ演奏
            mml += "v5l16q4";

            if (isChordSyncArp){    //chord音程に合わせたアルペジオ
                mml += makeOnpuMmlArpFromChord();
            } else {                //上昇, ランダム
                mml += makeOnpuMmlArpUpRnd();
            }
            return mml;
        }

        //ランダムフレーズ生成：Bass用    matrixBufに書き込み
        //    現在生成されるフレーズはrootと導音がメイン
        private function makeRndBass(matrixBuf:Array,writeLength:int) :String {
            const part:int = 1;
            const channel:int = 0;
            var mml:String = "";    //出力バッファ
            var bufsize:int = writeLength;
            var rep:int = Math.random() * 100;    //繰り返しでフレーズを作るか
            var scale:Array = bassScale; //note生成のためのスケールを指定する
            var oofs:int=0, oldoofs:int=0, noteofs:int=0;   //octave offset, note offset
            var STf:Boolean=false, oldSTf:Boolean=false;    //noteを導音にするかのフラグ
            var note:int=0, q:int=0;    //書き込み用

            for (var step:int=0;step<bufsize;step++) {
                //初期化
                note = rootBassArray[rootIndex];    //root
                noteofs = 0;    //root
                oofs = 0;
                STf = false;
                q = 6;
                //note offset決定
                if ( Math.random() * 100 < 10 ) {
                    //導音
                    if (step>1 && step<bufsize-1){    //1つめ2つめはrootにするので、それ以降で
                        STf = true;
                        noteofs --;
                    }
                }
                //octave offset決定
                if ( Math.random() * 100 < 10 ) {
                    if (step>1){    //1つめ2つめはrootにするので、それ以降で
                        oofs = 1;
                    }
                }
                if ( rep > 80 ) {
                    //繰り返しでフレーズ生成する場合さらにoctave増やす
                    if ( Math.random() * 100 < 50 ) {
                        if (step>1){    //1つめ2つめはrootにするので、それ以降で
                            oofs = 1;
                        }
                    }
                }
                //前の音がoctave高い導音で、現在がoctave低いrootなら、現在をoctave高いrootにする
                if (oldSTf==true && oldoofs==1 && STf==false && oofs==0){
                    oofs = 1;
                    if (matrixBuf[part][channel][step-1].q!=-2){
                        matrixBuf[part][channel][step-1].q = -1;    //前の音を加工：休符でないならtieにする
                    }
                }
                //offsetを元にnote設定
                note += noteofs;    //root or 導音
                note += oofs * scale.length;    //octave

                //q,休符,tie
                if ( Math.random() * 100 < 10 ) {
                    q = 4;
                }
                if ( Math.random() * 100 < 10 ) {
                    if (step>0) {    //小節最初は0にしないので、それ以外で
                        q = -2;
                    }
                }
                if ( Math.random() * 100 < 50 ) {
                    q = -1;    //tie
                }

                //note,qをmatrixに書き込み
                matrixBuf[part][channel][step].note = note;
                matrixBuf[part][channel][step].q = q;
                oldSTf = STf;
                oldoofs = oofs;
            }

            if ( rep > 90 ) {
                //符点八分ぶんをコピー
                matrixBuf[part][channel][5].q = 6;    //tieにしない
                copyNoteMatrixStep(matrixBuf,part,channel, 0,6+0);
                copyNoteMatrixStep(matrixBuf,part,channel, 1,6+1);
                copyNoteMatrixStep(matrixBuf,part,channel, 2,6+2);
                copyNoteMatrixStep(matrixBuf,part,channel, 3,6+3);
                copyNoteMatrixStep(matrixBuf,part,channel, 4,6+4);
                copyNoteMatrixStep(matrixBuf,part,channel, 5,6+5);
            }else if ( rep > 80 ) {
                //1拍目を残り3拍にもコピー
                matrixBuf[part][channel][3].q = 6;    //tieにしない
                for (step=4;step<bufsize;step+=4) {
                    copyNoteMatrixStep(matrixBuf,part,channel, 0,step+0);
                    copyNoteMatrixStep(matrixBuf,part,channel, 1,step+1);
                    copyNoteMatrixStep(matrixBuf,part,channel, 2,step+2);
                    copyNoteMatrixStep(matrixBuf,part,channel, 3,step+3);
                }
            }
            matrixBuf[part][channel][bufsize-1].q = 6;    //最後はtieにしない(基本的に小節頭は強迫にしたい)
            //matrixToMML
            mml += "o3";
            const defaultNoteNumber:int = 12*3; //直前のo3にあわせる
            var tonicNoteNumber:int = currentKey;
            tonicNoteNumber = adjustTonicNoteNumber(tonicNoteNumber,defaultNoteNumber);
            mml += matrixToMML(matrixBuf,part,channel,scale,tonicNoteNumber,defaultNoteNumber,bufsize,false);
            return mml;
        }
        //ランダムにbassの音符MMLを生成する 生成関数を呼び出す
        private function makeOnpuMmlBass() :String {
            const part:int = 1;
            var mmlChannelInit:String = "%6@1 ";
            var writeLength:int;
            var mml:String = "";    //生成したフレーズを格納
            if (addLoopf) { mmlChannelInit += "$"; }    //無限ループ演奏
            mml += mmlChannelInit;
            mml += "v6l16q6";
            if (oneMeasPlay){ //1小節だけ生成
                writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                mml += makeRndBass(matrixBuf,writeLength);
            }else{ //コード進行ぶん（例：5小節）生成
                rootIndex = 0;
                for (var i:int=0;i<rootBassArray.length;i++){
                    writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                    mml += makeRndBass(matrixBuf,writeLength);
                    mml += "\n";
                    progressChord();
                }
            }
            mml += ";";
            if (oneMeasPlay){    //1小節だけ生成の場合
                mml += "\n";
            }
            return mml;
        }

        //ランダムフレーズ生成：Chord用    matrixBufに書き込み　MML出力
        //    指定note及びrhythmを元に、1channel分、1小節分を生成
        private function makeRndChord(channel:int,scale:Array,note:int,rhythmArray:Array,writeLength:int) : String {
            const part:int = 2;
            var mml:String = "";    //出力バッファ
            var bufsize:int = writeLength;
            var step:int = 0;    //書き込みstepカウンタ
            var isNullNote:Boolean = false;
            if (-1==note){  //nullの場合
                isNullNote = true;
            }
            if (!isNullNote){   //nullでない場合
                for (step=0;step<bufsize;step++) {
                    //生成済みNoteNumberを直接書き込む
                    matrixBuf[part][channel][step].note = note;
                    matrixBuf[part][channel][step].q = rhythmArray[step];
                }
                matrixBuf[part][channel][bufsize-1].q = 6;    //最後はtieにしない
            }else{  //nullの場合
                for (step=0;step<bufsize;step++) {
                    matrixBuf[part][channel][step].q = -2;//休符
                }
            }
            mml += "o3";
            const defaultNoteNumber:int = 12*3; //直前のo3にあわせる
            var tonicNoteNumber:int = currentKey;
            tonicNoteNumber = adjustTonicNoteNumber(tonicNoteNumber,defaultNoteNumber);
            mml += matrixToMML(matrixBuf,part,channel,scale,tonicNoteNumber,defaultNoteNumber,bufsize,true);
            return mml;
        }
        //chord用 ノートナンバーを全channel1小節ぶんだけ生成して配列chordNotenumArrの所定の位置に書き込む
        // currentKey,rootIndex, rootOfsArray,chordArrayを元に生成
        private function makeChordNotenumber1meas(chordNotenumArr:Array,part:int,chordSize:int,rootIndex:int,meas:int) :void {
            var channel:int = 0;    //カウンタ
            var note:int = 0;
            //和音数ぶん、配列要素に書き込み
            //まだnotenumberではなくoffset
            //chordArrayをもとに和音の元を生成、0～11の値に丸める
            for (channel=0;channel<chordSize;channel++){
                if (null==chordArray[rootIndex][channel]){  //コード進行設定から取得
                    //nullの場合
                    note = -1;  //数値系変数はnullとの比較ができない(配列要素は可)ため、-1を設定する
                }else{
                    //nullでない場合
                    note = chordArray[rootIndex][channel] % 12;
                        //前提：scaleの添字がマイナスにならないよう、chord配列の要素数=最大和音数を注意して設定済みであること
                }
                chordNotenumArr[channel][meas] = note;
            }
            //keyを元にrootNoteNumberを決める   ※tonicNoteNumberではなくコードの根音のnoteNumberを決める
            const defaultNoteNumber:int = 12*3; //o3にあわせる
            var rootNoteNumber:int = currentKey + rootOfsArray[rootIndex];  //keyに、コードの根音を示す値(scaleのtonicからのoffset)を加算する
            rootNoteNumber = adjustTonicNoteNumber(rootNoteNumber,defaultNoteNumber);    //tonicNote用関数流用
            //rootNoteNumberを和音の元に加算し、notenumber形式にする
            for (channel=0;channel<chordSize;channel++){
                if (chordNotenumArr[channel][meas]!=-1){    //nullでない場合
                    chordNotenumArr[channel][meas] += rootNoteNumber;
                }
            }
            //備考：この段階ではo3c付近のコード
        }
        // chordArray及びコード進行用設定を元に、
        // chordNotenum配列を生成する
        private function makeChordNoteNum(part:int,chordSize:int) : Array {
            var chordNotenumArr:Array;   //出力バッファ
            //出力領域確保
            chordNotenumArr = new Array(chordSize); 
            for (var channel:int=0;channel<chordSize;channel++){
                chordNotenumArr[channel] = new Array;
            }
            //全小節全channel分のchordNotenumを生成する
            var rootIndexTaihi:int = rootIndex;
            rootIndex = 0;
            for (var meas:int=0;meas<rootBassArray.length;meas++){
                //chord生成のため、chord構成音だけのscaleを指定
                makeChordNotenumber1meas(chordNotenumArr,part,chordSize,rootIndex,meas);
                progressChord();    //rootIndex変化
            }
            rootIndex = rootIndexTaihi;
            return chordNotenumArr;
        }
        //指定サイズのリズムを生成 chord用
        private function makeChordRhythm(bufsize:int) :Array {
            var rhythmArray:Array = new Array(bufsize); //出力バッファ bufsize求めたあとで確保
            //chordのrhythmを乱数で設定
            if (Math.random()*100 < 50) {
                for (var step:int=0;step<bufsize;step++) {
                    var r:int = Math.random()*100;
                    if (r<40){
                        rhythmArray[step] = -1;
                    }else if(r<50){
                        rhythmArray[step] = 6;
                    }else{
                        rhythmArray[step] = -2;
                    }
                }
            }else{    //全音符
                for (step=0;step<bufsize;step++) {
                    rhythmArray[step] = -1;
                }
            }
            return rhythmArray;
        }
        //ランダムにchordの音符MMLを生成する
        private function makeOnpuMmlChord() :String {
            const part:int = 2;
            var mml:String = "";    //出力バッファ
            var mmlChannelInit:String = "%6@2 ";
            if (addLoopf) { mmlChannelInit += "$"; }    //無限ループ演奏
            var scale:Array;    //note生成のためのスケール
            var note:int = 0;      //音程
            var writeLength:int;
            var chordNotenumArray:Array;    //channel,measごとのコード構成音
            var rhythmArray:Array;          //コードのリズム
            var chordSize:int = chordArray[0].length;    //最大和音数

            rhythmArray = makeChordRhythm(matrixBuf[part][0].length);

            //予め全小節全channel分のchordNotenumを生成する
            chordNotenumArray = makeChordNoteNum(part,chordSize);
            //生成したnotenumを加工する
            // o3くらいのchordをo5くらいにシフトする
            processChordNotenum.shift(chordNotenumArray,2*12);  //o5くらい
            // コード転回処理　notenumを加工する
            processChordNotenum.inversion(chordNotenumArray);
            // arp用にコピーする　(転回後、drop前のもの)
            chordNotenumForArpArray = processChordNotenum.copy(chordNotenumArray);
            // dropする
            var d:int = Math.random() * 100;
            if (d<20){
                processChordNotenum.drop(chordNotenumArray,1);  //drop2
            }else if (d<40){
                processChordNotenum.drop(chordNotenumArray,2);  //drop3
            }else if (d<60){
                processChordNotenum.drop(chordNotenumArray,1);  //drop2&4
                processChordNotenum.drop(chordNotenumArray,3);
            }   //dの残りはclosed
            processChordNotenum.sort(chordNotenumArray);    //drop後にsortしてMMLを読みやすくする

            //channelごとにMML出力   生成したnotenumを元に関数呼び出し
            var notenum:int = 0;
            var meas:int = 0;
            for (var channel:int=0;channel<chordSize;channel++){
                mml += mmlChannelInit;
                mml += "v4l16";
                if (oneMeasPlay){ //1小節だけ生成
                    //全小節全channel分のchordNotenumを元に、
                    //matrixを生成、MMLを出力
                    meas = rootIndex;
                    notenum = chordNotenumArray[channel][meas];
                    scale = chordArray[rootIndex]; //現在未使用。使う場合がきたときのため算出はしておく
                    writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                    mml += makeRndChord(channel,scale,notenum,rhythmArray,writeLength);
                }else{ //コード進行ぶん（例：5小節）生成
                    rootIndex = 0;
                    //1小節ごとに
                    for (meas=0;meas<rootBassArray.length;meas++){
                        //全小節全channel分のchordNotenumを元に、
                        //matrixを生成、MMLを出力
                        // writeLength生成のためコード進行処理を行う
                        notenum = chordNotenumArray[channel][meas];
                        scale = chordArray[rootIndex]; //現在未使用。使う場合がきたときのため算出はしておく
                        writeLength = writeLengthArray[rootIndex] * writeLengthArrMul / writeLengthArrDiv;
                        mml += makeRndChord(channel,scale,notenum,rhythmArray,writeLength);
                        progressChord();
                    }
                }
                mml += ";\n";
            }
            return mml;
        }

        //コード進行用数列を文字列化したものの末尾n文字を得る
        private function getProgressStringLast(progressSeriesArr:Array, n:int) : String {
            return progressSeriesArr.join("").substr(-n,n);
        }

        // ランダムにコード進行用数列を作成する
        private function makeProgressSeries() : Array {
            var progressSeriesArr:Array;   //出力バッファ
            var n:int = 0;
            var r:int = 0;  //乱数一時格納用
            var n0:int = 0; //最初の1個
            //出力領域確保
            progressSeriesArr = new Array;
            //最初の音
            if ( Math.random()*100 < 70 ){
                n = 6;
            } else {
                n = 1;
            }
            progressSeriesArr.push(n);
            n0 = n;
            //コード進行生成
            while (true){
                r = Math.random()*100;
                switch (n){
                case 1: //Iから次のコードへ進行
                    if (getProgressStringLast(progressSeriesArr,2)=="61" && r<50){
                        n = 2;  //k進行
                    }else if (getProgressStringLast(progressSeriesArr,6)=="156341" && r<50){    //forカノン進行
                        r = Math.random()*100;
                        if ( r < 50 ){
                            n = 4;
                        } else {
                            n = 2;
                        }
                    }else{
                        r = Math.random()*100;
                        if ( r < 10 ){
                            n = 4;
                        } else if ( r < 50 ){
                            n = 5;
                        } else {
                            n = 2;
                        }
                    }
                    break;
                case 2:
                    if (getProgressStringLast(progressSeriesArr,3)=="612" && r<50){
                        n = 4;  //k進行
                    }else if (getProgressStringLast(progressSeriesArr,7)=="1563412" && r<50){    //forカノン進行
                        n = 5;
                    }else if(getProgressStringLast(progressSeriesArr,3)=="362" && r<50){
                        n = 5;
                    }else if(getProgressStringLast(progressSeriesArr,2)=="62"){   //forカノン進行(minor)    626にはしない
                        r = Math.random()*100;
                        if ( r < 50 ){
                            n = 3;
                        } else if ( r < 75 ){
                            n = 4;
                        } else {
                            n = 5;
                        }
                    }else if (getProgressStringLast(progressSeriesArr,5)=="63412" && r<50){    //forカノン進行(minor)
                        n = 6;
                    }else if(getProgressStringLast(progressSeriesArr,2)=="12"){//12からは6には行かない
                        r = Math.random()*100;
                        if ( r < 50 ){  //ツーファイブ
                            n = 5;
                        } else {
                            n = 4;
                        }
                    }else{
                        r = Math.random()*100;
                        if ( r < 30 ){  //ツーファイブ
                            n = 5;
                        } else if ( r < 60 ){
                            n = 6;
                        } else {
                            n = 4;
                        }
                    }
                    break;
                case 3:
                    if (getProgressStringLast(progressSeriesArr,4)=="1563" && r<50){    //forカノン進行
                        n = 4;
                    }else if (getProgressStringLast(progressSeriesArr,2)=="63"){    //forカノン進行(minor)  636にはしない
                        n = 4;
                    }else{
                        r = Math.random()*100;
                        if ( r < 50 ){
                            n = 4;
                        } else {
                            n = 6;
                        }
                    }
                    break;
                case 4:
                    if (getProgressStringLast(progressSeriesArr,5)=="15634" && r<50){    //forカノン進行
                        r = Math.random()*100;
                        if ( r < 30 ){
                            n = 1;
                        } else if ( r < 70 ){//45のある派生を多めに
                            n = 5;
                        } else {
                            n = 6;
                        }
                    }else if (getProgressStringLast(progressSeriesArr,3)=="634" && r<50){    //forカノン進行(minor)
                        r = Math.random()*100;
                        if ( r < 50 ){
                            n = 1;
                        } else {
                            n = 5;
                        }
                    }else{
                        n = 5;
                    }
                    break;
                case 5:
                    if (getProgressStringLast(progressSeriesArr,2)=="65" && r<50){
                        n = 4;
                    }else if (getProgressStringLast(progressSeriesArr,2)=="15" && r<50){    //forカノン進行
                        n = 6;
                    }else{
                        r = Math.random()*100;
                        if ( r < 25 ){
                            n = 4;
                        } else if ( r < 50 ){
                            n = 1;
                        } else if ( r < 75 ){
                            n = 6;
                        } else {
                            n = 3;
                        }
                    }
                    break;
                case 6:
                    if (getProgressStringLast(progressSeriesArr,3)=="156" && r<50){    //forカノン進行
                        n = 3;
                    }else{
                        r = Math.random()*100;
                        if ( r < 20 ){
                            n = 4;
                        } else if ( r < 40 ){
                            n = 5;
                        } else if ( r < 60 ){
                            n = 2;
                        } else if ( r < 80 ){
                            n = 3;
                        } else {
                            n = 1;
                        }
                    }
                    break;
                }
                //配列に挿入する
                progressSeriesArr.push(n);
                r = Math.random()*100;
                if (6<=progressSeriesArr.length){ r = 0; }//長いなら早めにloop脱出
                //5かつコード進行数列のサイズが2より大きいなら一定確率でloop脱出
                if (5==n && progressSeriesArr.length > 2 && r<50){ break; }
                //最初が6かつ、現在3かつ、コード進行数列のサイズが2より大きいなら一定確率でloop脱出
                if (6==n0 && 3==n && progressSeriesArr.length > 2 && r<50){ break; }
                //k進行になったらloop脱出
                if (getProgressStringLast(progressSeriesArr,5)=="61245"){ break; }
            }
            return progressSeriesArr;
        }
        // コード進行用数列を元に、コード進行のcurrent用配列を生成する
        //  方針：調性感の考慮は省略し、根音を元に、ダイアトニックコードのうちMaj7,min7,7を単純に当てはめる
        private function makeProgressCurrentArray(progressSeriesArr:Array) : void {
            var n1:int = 0, n2:int = 0; //bass用のofs, chordのroot用のofs
            var oldn2:int = 0;
            var n2_0:int = 0;   //n2の1つ目の値を格納
            generatedArpScale = [0,3,5,7,10];   //mPENTA
            generatedBassScale = [0,2,3,5,7,8,10];    //マイナースケール(ただし以降のコードネームは平行調のメジャースケールに対するもの)
            //progressSeriesArrを元に、各種Array生成
            generatedRootBassArray = new Array;
            generatedRootOfsArray = new Array;
            generatedChordArray = new Array;
            generatedWriteLengthArray = new Array;
            for (var i:int=0;i<progressSeriesArr.length;i++){
                //コード進行数列を元にn1,n2を決定しコードを挿入
                switch (progressSeriesArr[i]){
                    case 1: //I△7
                        n1 = 2;
                        n2 = 3;
                        generatedChordArray.push([0,4,7,11]);
                        break;
                    case 2: //IIm7
                        n1 = 3;
                        n2 = 5;
                        generatedChordArray.push([0,3,7,10]);
                        break;
                    case 3: //IIIm7
                        n1 = 4;
                        n2 = 7;
                        generatedChordArray.push([0,3,7,10]);
                        break;
                    case 4: //IV△7
                        n1 = 5;
                        n2 = 8;
                        generatedChordArray.push([0,4,7,11]);
                        break;
                    case 5: //V7
                        n1 = 6;
                        n2 = 10;
                        generatedChordArray.push([0,4,7,10]);
                        break;
                    case 6: //VIm7
                        n1 = 0;
                        n2 = 0;
                        generatedChordArray.push([0,3,7,10]);
                        break;
                }
                //n1,n2を、前の音からの移動が大きくなりすぎないよう修正
                if (n2 - oldn2 >= 8){   //8半音以上上に動く場合
                    n1 -= generatedBassScale.length;
                    n2 -= 12;
                } else if (n2 - n2_0 >= 12 && n2 - oldn2 >= 5){ //5半音以上上に動き、かつ元のoctaveより高くなる場合
                    n1 -= generatedBassScale.length;
                    n2 -= 12;
                }
                generatedRootBassArray.push(n1);
                generatedRootOfsArray.push(n2);
                //1小節のstep数
                generatedWriteLengthArray.push(16);
                oldn2 = n2;
                if (0==i){ n2_0 = n2; } //最初の1回のみ保存
            }
            //1小節のstep数を加工し、2・4・8小節等にできるだけ収める
            switch (generatedWriteLengthArray.length){
            case 3: for (i=1;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 5: for (i=3;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 6: for (i=2;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 7: for (i=1;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 9: for (i=7;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 10: for (i=6;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 11: for (i=5;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 12: for (i=4;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 13: for (i=3;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 14: for (i=2;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            case 15: for (i=1;i<generatedWriteLengthArray.length;i++){ generatedWriteLengthArray[i] /= 2; }; break;
            }
        }


        //SiON用MMLを生成する
        // 前提：mmlCurrentが生成済みであること
        private function makeMml(mmlCurrent:Array) :String {
            var mml:String = "";    //MML全体を格納する領域
            mml += mmlCurrent[0];    //音色MML arp
            mml += mmlCurrent[1];    //音色MML bass
            mml += mmlCurrent[2];    //音色MML chord
            mml += "#EFFECT1{delay300,32,1};";
            mml += "#EFFECT2{autopan2.6};";
            mml += "t"+tempo+";"
            mml += "\n";
            mml += mmlCurrent[3];    //演奏MML arp
            mml += mmlCurrent[4];    //演奏MML bass
            mml += mmlCurrent[5];    //演奏MML chord
            return mml;
        }

        //SiON用MMLを元にSiONで音を鳴らす
        private function playMml(mml:String) :void {
            data = driver.compile(mml); 
            driver.play(data);
        }

        //ランダムにFM音色データを生成し、FM音色データ配列に出力する
        private var isModulator:Array = [  //アルゴリズムごとにオペレータのどれがモジュレータかを格納
                [ true, true, true, false ],    //ALG0
                [ true, true, true, false ],    //ALG1
                [ true, true, true, false ],    //ALG2
                [ true, true, true, false ],    //ALG3
                [ true, false, true, false ],   //ALG3
                [ true, false, false, false ],  //ALG5
                [ true, false, false, false ],  //ALG6
                [ false, false, false, false ]  //ALG7
                ];
        private function createRandomFMtone(td:Array) :Array {
            var freedom:int = Math.random() * 100;    //音色のフリーダム度を格納
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
                if (freedom>98){    //エンベロープを早すぎず遅すぎず、などの制約を外す場合
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
        //FM音色配列のTL(TotalLevel)調整　　引数を元に調整後の値を取得する
        private function adjustFMtoneTL1op(td:Array, op:int, minTL:int) :void {
            var _TL:int = td[2+11*op+5];
            if (_TL < minTL ) { _TL += minTL; }    //TLがminTL未満の場合、minTL～minTL*2の値をとるようにする
//            if (_TL < minTL ) { _TL = minTL; }    //TLがminTL未満の場合、minTLにする
            td[2+11*op+5] = _TL;
        }
        //FM音色配列のTL(TotalLevel)調整　　td配列の値を加工する　　ALGとFBを元にモジュレータTLの下限値を決める
        //  過変調によるノイズや金属音の出る割合を下げる
        //  制約：簡易的な調査で決めた便宜上の値であり、加工後の音色の妥当性の検証はあまりされていない
        private function adjustFMtoneTLbyALG_FB(td:Array) :void {
            var _op:int = 0;
            var _FB:int = td[1];
            switch (td[0]) {
            case 0:
                    adjustFMtoneTL1op(td, _op++, 20+_FB);
                    adjustFMtoneTL1op(td, _op++, 20);
                    adjustFMtoneTL1op(td, _op++, 20);
                    break;
            case 1:
                    adjustFMtoneTL1op(td, _op++, 10+_FB);
                    adjustFMtoneTL1op(td, _op++, 10);
                    adjustFMtoneTL1op(td, _op++, 20);
                    break;
            case 2:
                    adjustFMtoneTL1op(td, _op++, 15+_FB);
                    adjustFMtoneTL1op(td, _op++, 20);
                    adjustFMtoneTL1op(td, _op++, 20);
                    break;
            case 3:
                    adjustFMtoneTL1op(td, _op++, 10+_FB);
                    adjustFMtoneTL1op(td, _op++, 15);
                    adjustFMtoneTL1op(td, _op++, 15);
                    break;
            case 4:
                    adjustFMtoneTL1op(td, _op++, 10+_FB);
                    break;
            case 5:
                    adjustFMtoneTL1op(td, _op++, 15+_FB);
                    break;
            case 6:
                    adjustFMtoneTL1op(td, _op++, 10+_FB);
                    break;
            case 7:
                    adjustFMtoneTL1op(td, _op++, 0+_FB);
                    break;
            }
        }

        
        //音色履歴から演奏、クリップボードにMML格納
        private function playHistory(add:int) :void {
            //MMLを履歴から取得
            var mmlArray:Array = toneHis.get(add);    //MML領域に、履歴から取得した値をセット
            var mml:String = mmlArray[0];         //MMLを格納する領域
            mmlCurrent[0] = mmlArray[1+0];
            mmlCurrent[1] = mmlArray[1+1];
            mmlCurrent[2] = mmlArray[1+2];
            mmlCurrent[3] = mmlArray[1+3];
            mmlCurrent[4] = mmlArray[1+4];
            mmlCurrent[5] = mmlArray[1+5];
            currentKey = mmlArray[1+6+0];
            progressTypeIndex = mmlArray[1+6+1];
            if (-1 == progressTypeIndex ){
                progressSeriesArr = mmlArray[1+6+5];
                makeProgressCurrentArray(progressSeriesArr);//progressSeriesArrを元に設定
            }
            setChordProgressParameter(progressTypeIndex);//progressTypeIndexを元に設定
            writeLengthArrMul = mmlArray[1+6+2];
            writeLengthArrDiv = mmlArray[1+6+3];
            tempo = mmlArray[1+6+4];

            playMml(mml);             //SiON用MMLを元にSiONで音を鳴らす
            System.setClipboard(mml); //clipboardにMMLを格納する
            var am:String = "";       //追加表示文字列領域
            am += "(履歴"+toneHis.readIndex+"番の音色データを鳴らしました)\n";
            am += "(クリップボードにSiON用MMLをコピーしました)\n";
            dispMml(mml,am);   //MMLとstatusを表示する
            autoNext=false;    //演奏終了後に次の生成を行わないようにする
        }
        //コードを進行させる
        private function progressChord() : void {
            rootIndex++;
            rootIndex %= rootOfsArray.length;
        }
        //ランダムにコード進行typeを設定する
        private function setRndChordProgressParameter() :void {
            if (Math.random()*100 < 70){
                progressSeriesArr = makeProgressSeries();
                makeProgressCurrentArray(progressSeriesArr);
                progressTypeIndex = -1;
            } else {
                progressTypeIndex = int(Math.random()* progressNumof);
            }
            setChordProgressParameter( progressTypeIndex );
        }
        //コード進行用パラメータを、進行の種類を元に設定する
        private function setChordProgressParameter(index:int) :void {
            if (-1 != index){
                arpScale = progressArpScale[index];
                bassScale = progressBsScale[index];
                rootBassArray = progressBass[index];
                rootOfsArray = progressChordRoot[index];
                chordArray = progressChordTone[index];
                writeLengthArray = progressUnitLength[index];
            } else {
                if (null==generatedArpScale){
                    progressSeriesArr = makeProgressSeries();
                    makeProgressCurrentArray(progressSeriesArr);
                }
                arpScale = generatedArpScale;
                bassScale = generatedBassScale;
                rootBassArray = generatedRootBassArray;
                rootOfsArray = generatedRootOfsArray;
                chordArray = generatedChordArray;
                writeLengthArray = generatedWriteLengthArray;
            }
        }

        //音色生成、演奏、表示、クリップボードに格納
        //clipFlag：クリップボードに格納するか
        //makePart：-1なら6つとも更新、0～5なら指定した1つだけ更新
        private function playAndDisp(clipFlag:Boolean,makePart:int) :void {
            var mml:String;       //MMLを格納する領域
            var am:String = "";   //追加表示文字列領域
            am += "(カーソル左右：履歴内の音色データを鳴らす)\n";

            if (-1 == makePart) {    //6つ全て更新
                if (0<playCount/* && (0==playCount%2)*/){
                    progressChord();    //2回目からはroot進行
                }
                var loopf:Boolean=false; //規定ループに達したか
                if (oneMeasPlay && rootBassArray.length*2==playCount){ loopf = true; }//コード進行が2周したら
                if (!oneMeasPlay && playCount > 1){ loopf = true; }//1周
                if (loopf){
                    //キーをランダムに変更
                    currentKey = int(Math.random()*12);
                    //コードの種類をランダムに変更
                    setRndChordProgressParameter();
                    //拍子の種類をランダムに変更
                    rndBeat();
                    playCount = 0;
                    //ArpTypeをランダムに変更
                    rndArpType();
                }
                playCount++;
                if (autoToneChange){
                    //ランダムに音色MML生成
                    mmlCurrent[0] = makeToneMmlArp();
                    mmlCurrent[1] = makeToneMmlBass();
                    mmlCurrent[2] = makeToneMmlChord();
                }
                //ランダムに演奏MML生成
                mmlCurrent[3] = makeOnpuMmlArp();
                mmlCurrent[4] = makeOnpuMmlBass();
                mmlCurrent[5] = makeOnpuMmlChord();
                if (isChordSyncArp){ mmlCurrent[3] = makeOnpuMmlArp(); }    //chordにあわせて再度生成する
            } else {    //1つだけ更新
                if (!addLoopf){ play456(); }//無限loopつけないモードで音色やフレーズの変更を行った場合、一旦無限loopフレーズを生成する
                //演奏終了後の「6つ全て自動更新」をやめる(消えないように)。また、コード進行つきで生成
                autoNext=false; addLoopf=true; oneMeasPlay=false;
                switch (makePart) {
                case 0: mmlCurrent[0] = makeToneMmlArp(); am+="(Arpの音色を更新しました)"; break;
                case 1: mmlCurrent[1] = makeToneMmlBass(); am+="(Bassの音色を更新しました)"; break;
                case 2: mmlCurrent[2] = makeToneMmlChord(); am+="(Chordの音色を更新しました)"; break;
                case 3:
                        if (isChordSyncArp){
                            var oldArpMml:String = mmlCurrent[3];
                            for (var i:int=0;i<100;i++){ //違うarpが生成されるまで繰り返し生成する
                                mmlCurrent[5] = makeOnpuMmlChord();  //arp生成にchordが必要なため
                                mmlCurrent[3] = makeOnpuMmlArp();    //chordにあわせてarpを再度生成する
                                if (oldArpMml != mmlCurrent[3]){ break; }   //違うarpになったらloop脱出
                            }
                            am+="(ChordとArpのフレーズを更新しました)";
                        } else {
                            mmlCurrent[3] = makeOnpuMmlArp(); 
                            am+="(Arpのフレーズを更新しました)";
                        }
                        break;
                case 4: mmlCurrent[4] = makeOnpuMmlBass(); am+="(Bassのフレーズを更新しました)"; break;
                case 5: mmlCurrent[5] = makeOnpuMmlChord();
                        if (isChordSyncArp){
                            mmlCurrent[3] = makeOnpuMmlArp();    //chordにあわせて再度生成する
                            am+="(ChordとArpのフレーズを更新しました)";
                        } else {
                            am+="(Chordのフレーズを更新しました)";
                        }
                        break;
                }
            }
            mml = makeMml(mmlCurrent);   //SiON用MMLを生成する
            var mmlArray:Array = new Array(1+6+6);    //履歴用
            mmlArray[0] = mml;
            mmlArray[1+0] = mmlCurrent[0];
            mmlArray[1+1] = mmlCurrent[1];
            mmlArray[1+2] = mmlCurrent[2];
            mmlArray[1+3] = mmlCurrent[3];
            mmlArray[1+4] = mmlCurrent[4];
            mmlArray[1+5] = mmlCurrent[5];
            mmlArray[1+6+0] = currentKey;
            mmlArray[1+6+1] = progressTypeIndex;
            mmlArray[1+6+2] = writeLengthArrMul;
            mmlArray[1+6+3] = writeLengthArrDiv;
            mmlArray[1+6+4] = tempo;
            mmlArray[1+6+5] = progressSeriesArr;
            toneHis.add(mmlArray);    //MMLを履歴に保存する
            playMml(mml);             //SiON用MMLを元にSiONで音を鳴らす
            if (clipFlag){ System.setClipboard(mml); } //clipboardにMMLを格納する
            if (clipFlag){ am += "(クリップボードにSiON用MMLをコピーしました)\n"; }
            dispMml(mml,am);          //MMLとstatusを表示する
        }
        //後述のキー4,5,6を押したのとほぼ同じ処理を行う
        private function play456() :void {
            autoNext=false; addLoopf=true; oneMeasPlay=false;
            mmlCurrent[3] = makeOnpuMmlArp();
            mmlCurrent[4] = makeOnpuMmlBass();
            playAndDisp(true,5);
        }
        //ランダムで拍子変更　これから生成するデータに影響
        private function rndBeat() :void {
            if (Math.random() * 100 < 70){
                beat4per4();
            }else{
                beat6per8();
            }
        }
        //6/8拍子に これから生成するデータに影響
        private function beat6per8() :void {
            writeLengthArrMul = 3;
            writeLengthArrDiv = 4;
            tempo = 112;
        }
        //4/4拍子に　これから生成するデータに影響
        private function beat4per4() :void {
            writeLengthArrMul = 4;
            writeLengthArrDiv = 4;
            tempo = 130;
        }
        //ランダムでArpType変更　これから生成するデータに影響
        private function rndArpType() :void {
            if (Math.random() * 100 < 30){
                isChordSyncArp = true;
            }else{
                isChordSyncArp = false;
            }
        }


        //キー入力判定
        private function keyinput(keycode:int) :void {
            switch (keycode) {
            case 37: playHistory(-1); break;    //カーソルキー左
            case 39: playHistory( 1); break;
            case 49:                                //フルキー1
            case 97:                                //テンキー1
                     playAndDisp(true,0); break;
            case 50: 
            case 98:
                     playAndDisp(true,1); break;
            case 51:
            case 99:
                     playAndDisp(true,2); break;
            case 52: 
            case 100:
                     rndArpType();    //ボタンやキー入力で明示的にフレーズ生成を行う場合はrnd
                     playAndDisp(true,3); break;
            case 53:
            case 101:
                     playAndDisp(true,4); break;
            case 54:
            case 102:
                     playAndDisp(true,5); break;
            case 55:
            case 103:
                     currentKey+=11;//キー変更
                     currentKey%=12;
                     play456();
                     dispTextStatus("(KEYを変更しました)");
                     break;
            case 56:
            case 104:
                     currentKey++;//キー変更
                     currentKey%=12;
                     play456();
                     dispTextStatus("(KEYを変更しました)");
                     break;
            case 57:
            case 105:
                     //音色は維持したまま自動生成・演奏するモードにし、生成する
                     autoToneChange = false;
                     autoNext=true; addLoopf=false; oneMeasPlay=false;
                     playAndDisp(false,-1);
                     dispTextStatus("(音色を維持したまま自動演奏します)");
                     break;
            case 90:    //Z
                    beat6per8();  //1小節の長さを3/4に変更
                    play456();
                    dispTextStatus("(6/8拍子にしました)");
                    break;
            case 88:    //X
                    beat4per4();  //1小節の長さを4/4に変更
                    play456();
                    dispTextStatus("(4/4拍子にしました)");
                    break;
            case 67:    //C
                    //コード進行タイプを変更
                    progressTypeIndex = (progressTypeIndex + progressNumof -1)% progressNumof;
                    setChordProgressParameter( progressTypeIndex );
                    play456();
                    dispTextStatus("(コード進行を変更しました)");
                    break;
            case 86:    //V
                    //コード進行タイプを変更
                    progressTypeIndex = (progressTypeIndex + 1)% progressNumof;
                    setChordProgressParameter( progressTypeIndex );
                    play456();
                    dispTextStatus("(コード進行を変更しました)");
                    break;
            case 66:    //B
                    //arp生成タイプを変更
                    if (isChordSyncArp){
                        isChordSyncArp = false;
                    } else {
                        isChordSyncArp = true;
                    }
                    playAndDisp(true,5);
                    playAndDisp(true,3);
                    break;
            case 78:    //N
                    //ランダムなコード進行
                    progressSeriesArr = makeProgressSeries();
                    makeProgressCurrentArray(progressSeriesArr);
                    progressTypeIndex = -1;
                    setChordProgressParameter( progressTypeIndex );
                    play456();
                    dispTextStatus("(コード進行をランダムに生成しました)");
                    break;
            }
        }
        //ボタン押下時に呼び出される
        private function _buttonL(e :MouseEvent) :void { keyinput(37); }
        private function _buttonR(e :MouseEvent) :void { keyinput(39); }
        private function _button1(e :MouseEvent) :void { keyinput(48+1); }
        private function _button2(e :MouseEvent) :void { keyinput(48+2); }
        private function _button3(e :MouseEvent) :void { keyinput(48+3); }
        private function _button4(e :MouseEvent) :void { keyinput(48+4); }
        private function _button5(e :MouseEvent) :void { keyinput(48+5); }
        private function _button6(e :MouseEvent) :void { keyinput(48+6); }
        private function _button7(e :MouseEvent) :void { keyinput(48+7); }
        private function _button8(e :MouseEvent) :void { keyinput(48+8); }
        private function _buttonStepM(e :MouseEvent) :void { keyinput(90); }
        private function _buttonStepP(e :MouseEvent) :void { keyinput(88); }
        private function _buttonProgressM(e :MouseEvent) :void { keyinput(67); }
        private function _buttonProgressP(e :MouseEvent) :void { keyinput(86); }
        private function _buttonAuto(e :MouseEvent) :void { keyinput(48+9); }
        private function _buttonArpType(e :MouseEvent) :void { keyinput(66); }
        private function _buttonRndProgress(e :MouseEvent) :void { keyinput(78); }



        //コンストラクタ(初期設定)
        function playRandomTone() {
            //ボタンの見た目を設定する　ボタン登録より前に行う必要がある
            Style.embedFonts = false; 
            Style.fontName = "MS Gothic";
            Style.fontSize = 12;
            Style.BACKGROUND = 0x010801;    //背景(ボタン輪郭に使用)
            Style.BUTTON_FACE = 0xE0D0D0;    //ボタン背景
            Style.LABEL_TEXT = 0x010101;    //ボタン文字
            //ボタンを登録する
            var _btn1:PushButton = new PushButton(this,   0, 0, "ToneA", _button1 );
            var _btn2:PushButton = new PushButton(this,  50, 0, "ToneB", _button2 );
            var _btn3:PushButton = new PushButton(this, 100, 0, "ToneC", _button3 );
            var _btn4:PushButton = new PushButton(this, 150, 0, "PhraseA", _button4 );
            var _btn5:PushButton = new PushButton(this, 200, 0, "PhraseB", _button5 );
            var _btn6:PushButton = new PushButton(this, 250, 0, "PhraseC", _button6 );
            var _btn7:PushButton = new PushButton(this, 300, 0, "Key -", _button7 );
            var _btn8:PushButton = new PushButton(this, 350, 0, "Key +", _button8 );
            var _btnStepM:PushButton = new PushButton(this, 410, 20, "6/8", _buttonStepM );
            var _btnStepP:PushButton = new PushButton(this, 410, 40, "4/4", _buttonStepP );
            var _btnProgressM:PushButton = new PushButton(this, 410, 60, "Chord-", _buttonProgressM );
            var _btnProgressP:PushButton = new PushButton(this, 410, 80, "Chord+", _buttonProgressP );
            var _btnArpType:PushButton = new PushButton(this, 410, 100, "ArpType", _buttonArpType );
            var _btnRndProgress:PushButton = new PushButton(this, 410, 120, "RndProgress", _buttonRndProgress );
            var _btnL:PushButton = new PushButton(this, 410, 300, "Hist-", _buttonL );
            var _btnR:PushButton = new PushButton(this, 410, 320, "Hist+", _buttonR );
            var _btnAuto:PushButton = new PushButton(this, 410, 380, "Auto", _buttonAuto );
            
            _btn1.width = _btn2.width = _btn3.width = 50;
            _btn4.width = _btn5.width = _btn6.width = 50;
            _btn7.width = _btn8.width = 50;
            _btnAuto.width = _btnL.width = _btnR.width = 
            _btnStepM.width = _btnStepP.width =
            _btnProgressM.width = _btnProgressP.width = _btnArpType.width = _btnRndProgress.width = 45;
            //MML表示領域にスクロールバーをつける
            vScrollBar = new VScrollBar(this, 400, 0, function(e:Event):void {
              // スクロールバーのスクロール時にTextFieldの位置を合わせる
              tf.scrollV = vScrollBar.value;
            });
            
            //イベントハンドラを登録する
            //    MOUSE_DOWN(マウス左ボタンプッシュ)を登録
            stage.addEventListener( MouseEvent.MOUSE_DOWN, function(e :MouseEvent) :void {
                //クリックした場合
//                playAndDisp(true,-1);     //生成と演奏と表示とクリップボード格納
                });
            //    キーボードのキー押下を登録
            stage.addEventListener( KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) :void {
                //キーボードのキーが押された場合
                keyinput(e.keyCode);
                });
            //    SiON演奏終了を登録
            driver.addEventListener( SiONEvent.FINISH_SEQUENCE, function(e :SiONEvent) :void {
                //演奏が終了した場合
                myTimer.start();   //タイマをスタートさせる
                });
            //    一定時間ごとに発生するタイマイベントを登録
            myTimer.addEventListener(TimerEvent.TIMER, function(e :TimerEvent) :void {
                //タイマのスタートから一定時間が経過した場合
                myTimer.stop();     //タイマを停止させる
                if (autoNext) {
                    playAndDisp(false,-1); //生成と演奏と表示
                }});
            //    MML表示領域のスクロールイベントを登録
            tf.addEventListener(Event.SCROLL, function(e:Event):void {
              //MML表示領域がスクロールした場合にスクロールバーの位置を合わせる
              adjustScrollBar();
            });

            //フレーズ自動生成用バッファを初期化
            initNoteMatrix();

            //予めMMLを生成して履歴に格納しておく
            addLoopf = true; oneMeasPlay = false;     //履歴にコード進行版を格納するため
            setChordProgressParameter(0);    //コード進行用パラメタ初期設定
            for (var i:int=0;i<100;i++){
                var mml:String = "";    //生成したMML格納のためのテンポラリ領域
                var mmlArray:Array = new Array(1+6+6);    //履歴格納領域を確保
                //2回目以降のパラメタ変更
                if (i>0){
                    //コード進行用パラメタ設定
                    setRndChordProgressParameter();
                    //MML生成用　拍子パラメータ設定
                    rndBeat();
                    //キーをランダムに変更
                    currentKey = int(Math.random()*12);
                    //ArpTypeをランダムに変更
                    rndArpType();
                }
                //パラメタを元に生成
                mmlCurrent[0] = makeToneMmlArp();    //音色MML生成
                mmlCurrent[1] = makeToneMmlBass();
                mmlCurrent[2] = makeToneMmlChord();
                mmlCurrent[3] = makeOnpuMmlArp();    //演奏MML生成
                mmlCurrent[4] = makeOnpuMmlBass();
                mmlCurrent[5] = makeOnpuMmlChord();
                if (isChordSyncArp){ mmlCurrent[3] = makeOnpuMmlArp(); }    //chordにあわせて再度生成する
                mml = makeMml(mmlCurrent);           //SiON演奏用MMLを生成する
                mmlArray[0] = mml;    //履歴保存のためarrayに格納
                mmlArray[1+0] = mmlCurrent[0];
                mmlArray[1+1] = mmlCurrent[1];
                mmlArray[1+2] = mmlCurrent[2];
                mmlArray[1+3] = mmlCurrent[3];
                mmlArray[1+4] = mmlCurrent[4];
                mmlArray[1+5] = mmlCurrent[5];
                mmlArray[1+6+0] = currentKey;
                mmlArray[1+6+1] = progressTypeIndex;
                mmlArray[1+6+2] = writeLengthArrMul;
                mmlArray[1+6+3] = writeLengthArrDiv;
                mmlArray[1+6+4] = tempo;
                mmlArray[1+6+5] = progressSeriesArr;
                toneHis.add(mmlArray);              //音色データを履歴に保存する
            }
            setChordProgressParameter(0); beat4per4(); isChordSyncArp=false;    //初回演奏用
            addLoopf = false; oneMeasPlay = true;    //初回演奏後自動演奏するため

            //初回演奏
            playAndDisp(false,-1);     //生成と演奏と表示
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

    //chordNotenum領域(channelごと小節ごとの二次元配列にnoteNumberが格納されているもの)に対する加工を行う
    // 音程シフト、コード転回、など
    class processChordNotenum { 
        //メソッド
        //コンストラクタ
        public function processChordNotenum(){
            
        }

        //数値を整数にし文字列3文字になるよう左space埋め(padding)
        private function lpad3(inum:int) :String { return ("  " + int(inum)).substr(-3,3);          }

        //chordNoteNumのnotenumberを指定したshiftValue分だけシフトする
        public function shift(chordNotenumArray:Array,shiftValue:int) :void {
            var chordSize:int = chordNotenumArray.length;   //和音数 入力配列のlengthを元に算出する
            var numofMeas:int = chordNotenumArray[0].length;    //小節数 入力配列の先頭を元に算出する
            var channel:int = 0;    //カウンタ
            var meas:int = 0;   //小節番号
            for (channel=0;channel<chordSize;channel++){
                for (meas=0;meas<numofMeas;meas++){
                    if (chordNotenumArray[channel][meas]!=-1){  //無音でない場合
                        chordNotenumArray[channel][meas] += shiftValue;
                    }
                }
            }
        }

        //コード転回
        public function inversion(chordNotenumArray:Array) :void {
            var chordSize:int = chordNotenumArray.length;   //和音数 入力配列のlengthを元に算出する
            var numofMeas:int = chordNotenumArray[0].length;    //小節数 入力配列の先頭を元に算出する
            var channel:int = 0;    //カウンタ
            var meas:int = 0;   //小節番号
            //転回
            var chordToneArr:Array = new Array(chordSize); //1小節ごとのsort用 1小節全channel分 chordSize算出後に確保すること
            var inversionArr:Array = new Array(chordSize);  //1小節ごとの転回用ワーク chordSize算出後に確保すること
            var inversionCount:int = 0; //転回処理用カウンタ
            var selectedInversion:int = 0;  //どの転回を選んだか
            var oldTopNoteNum:int = 0;
            var inversionSize:int = 0;
            //転回用ワーク領域確保
            // 基本形、第一転回形、...、ごと　：和音数ぶん(基本形+)転回形がある
            for (inversionCount=0;inversionCount<chordSize;inversionCount++){
                //[転回形の数][和音数]
                inversionArr[inversionCount] = new Array(chordSize);
            }
            
            //1小節ごと、全channelをセットにして処理
            for (meas=0;meas<numofMeas;meas++){
                inversionSize = chordSize;  //転回の種類の数　使わない転回がある場合減少する
                //転回の前処理としてソートする
                // コード構成音配列に入れる
                for (channel=0;channel<chordSize;channel++){
                    chordToneArr[channel] = chordNotenumArray[channel][meas];
                }
                // コード構成音配列をnotenumでソート　数値昇順ソート
                chordToneArr.sort(Array.NUMERIC);
                    //備考：以降の転回後にもソートを行ない、
                        //配列の末尾がtopnoteであることを前提とした処理を行う
                //転回：ソート済み配列を元に、それを転回したものを生成する
                for (inversionCount=0;inversionCount<chordSize;inversionCount++){
                    //コピー
                    for (channel=0;channel<chordSize;channel++){
                        inversionArr[inversionCount][channel] = chordToneArr[channel];
                    }
                    if (inversionCount!=0){
                        //転回の回数ぶん繰り返し
                       for (var k:int=0;k<inversionCount;k++){
                            var n:int = inversionArr[inversionCount].pop(); //末尾を抜き出しnにセット
                            if (n>12){ n -= 12; }//nをoctave下げる
                            inversionArr[inversionCount].unshift(n);    //配列先頭にnを挿入
                            inversionArr[inversionCount].sort(Array.NUMERIC);   //-1が配列先頭にくるよう数値昇順ソート
                        }
                    }
                }
                // topNoteと2ndNoteが半音でぶつかる転回を探し、配列から削除する(lengthが変化する)
                for (inversionCount=0;inversionCount<inversionArr.length;inversionCount++){
                    if (inversionArr[inversionCount].length>1){
                        //2和音以上の場合
                        if (1 == inversionArr[inversionCount][chordSize-1] - inversionArr[inversionCount][chordSize-2]){
                            //半音でぶつかる場合
                            for (channel=0;channel<chordSize;channel++){
                                inversionArr[inversionCount][channel] = -1;
                                inversionSize--;
                            }          //-1で埋め、優先度検索で一番下にくるようにする
                                //備考：　inversionArr.splice(inversionCount,1);　はフリーズ。ただし1次元配列のときはspliceも成功した
                                //      sliceで1つ目と2つ目を抜き取り、1つ目に2つ目をconcatして、それをinversionArrに上書きしてもフリーズ
                            break;
                        }
                    }
                }
                //選択：どの転回がよいかの優先度を算出する
                if (0==meas){   // 1小節目の場合、ランダムでoldTopNoteNumを設定
                    oldTopNoteNum = 12*5 +6 + (int(Math.random() * 12));   //o5あたり, 少し高めもあり
                }
                // 前の小節からのtopNoteの移動の少ないものを選択
                var topNoteDiff1:int = 0;   //topNoteの移動の値、調査直後
                var topNoteDiffAbs:int = 0; //絶対値
                var topNoteDiffAbsArray:Array = new Array(inversionArr.length);
                for (inversionCount=0;inversionCount<inversionArr.length;inversionCount++){
                    if (-1==inversionArr[inversionCount][chordSize-1]){
                        topNoteDiff1 = 999; //topnoteが-1の場合
                    }else{
                        topNoteDiff1 = inversionArr[inversionCount][chordSize-1] - oldTopNoteNum;
                        //前のtopnoteにあわせて転回を加工する
                        if (topNoteDiff1>6){
                            //高すぎるならoctave落とす
                            for (channel=0;channel<chordSize;channel++){
                                inversionArr[inversionCount][channel] -= 12;
                                topNoteDiff1 -= 12;
                            }
                        }else if (topNoteDiff1<-6){
                            //低すぎるならoctave上げる
                            for (channel=0;channel<chordSize;channel++){
                                inversionArr[inversionCount][channel] += 12;
                                topNoteDiff1 += 12;
                            }
                        }
                    }
                    topNoteDiffAbs = Math.abs(topNoteDiff1);
                    var rndStr:String = lpad3(int(Math.random() * 1000));   //移動で-1と+1がある場合乱数で決める
                    topNoteDiffAbsArray[inversionCount] = lpad3(topNoteDiffAbs) + rndStr + lpad3(inversionCount);
                        //"005137002"のような文字列を生成　topNoteとの差の絶対値が5,乱数137,添字2の転回
                }
                // ソート
                topNoteDiffAbsArray.sort();
                // ソート結果を設定　例："001137002"から"002"を取得して設定
                selectedInversion = topNoteDiffAbsArray[0].substr(6,3);
                
                //書き戻す　：1小節分全channel
                for (channel=0;channel<chordSize;channel++){
                    chordNotenumArray[channel][meas] = inversionArr[selectedInversion][channel];
                }
                oldTopNoteNum = chordNotenumArray[chordSize-1][meas];
            }
        }

        //chordNoteNumの、topNoteから指定した分のnotenumberを、drop(octave下げ)する
        // 制約：ローインターバルリミットの考慮(音色,arp,bassとの兼ね合い, octave up,omit, etc.)がない
        public function drop(chordNotenumArray:Array,ofsFromTopNote:int) :void {
            var chordSize:int = chordNotenumArray.length;   //和音数 入力配列のlengthを元に算出する
            var numofMeas:int = chordNotenumArray[0].length;    //小節数 入力配列の先頭を元に算出する
            var meas:int = 0;   //小節番号カウンタ
            if (ofsFromTopNote>=chordSize){ //和音数が少ない場合はdropしない
                return;
            }
            for (meas=0;meas<numofMeas;meas++){
                if (chordNotenumArray[ofsFromTopNote][meas]!=-1){  //無音でない場合
                    chordNotenumArray[ofsFromTopNote][meas] -= 12;  //octave下げる
                }
            }
        }
        //chordNoteNumの全channelのnoteを、measごとに、notenumでソートする
        public function sort(chordNotenumArray:Array) :void {
            var chordSize:int = chordNotenumArray.length;       //和音数 入力配列のlengthを元に算出する
            var numofMeas:int = chordNotenumArray[0].length;    //小節数 入力配列の先頭を元に算出する
            var chordToneArr:Array = new Array(chordSize);      //1小節ごとのsort用 1小節全channel分 chordSize算出後に確保すること
            var meas:int = 0;   //小節番号カウンタ
            //小節ごと
            for (meas=0;meas<numofMeas;meas++){
                var channel:int = 0;    //カウンタ
                // コード構成音配列に入れる
                for (channel=0;channel<chordSize;channel++){
                    chordToneArr[channel] = chordNotenumArray[channel][meas];
                }
                // コード構成音配列をnotenumでソート　数値昇順ソート
                chordToneArr.sort(Array.NUMERIC);
                //書き戻す　：1小節分全channel
                for (channel=0;channel<chordSize;channel++){
                    chordNotenumArray[channel][meas] = chordToneArr[channel];
                }
            }
        }
        //コピー
        public function copy(fromChordNotenumArray:Array) :Array {
            var chordSize:int = fromChordNotenumArray.length;       //和音数 入力配列のlengthを元に算出する
            var numofMeas:int = fromChordNotenumArray[0].length;    //小節数 入力配列の先頭を元に算出する
            var chordNotenumArr:Array = new Array(chordSize);       //出力バッファ
            for (var channel:int=0;channel<chordSize;channel++){
                chordNotenumArr[channel] = new Array(numofMeas);
                for (var meas:int=0;meas<numofMeas;meas++){
                    chordNotenumArr[channel][meas] = fromChordNotenumArray[channel][meas];
                }
            }
            return chordNotenumArr;
        }
    }
