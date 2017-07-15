/**
 * Copyright cat2151 ( http://wonderfl.net/user/cat2151 )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/zOlG
 */

// forked from cat2151's SiON TheABCSong2
// simple example 
package { 
    import flash.display.Sprite; 
    import org.si.sion.*; 
     
    public class TheABCSong2 extends Sprite { 
        public var driver:SiONDriver = new SiONDriver(); 
        public var data:SiONData; 
         
        function TheABCSong2() { 
        
            data = driver.compile(
                "t100;"    //tempo必須っぽ
//OPM音色設定                
//alg[0-7], fb[0-7], 
+"#OPM@0{ 4,0,"
//A,D,S[0-31],R[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], dt2[0-3], ams[0-3])
//A  D  S  R   sl tl ks ml  d1d2ams
+"31,12, 5, 6,  5,10, 0,2,  1,0,0,"
+"31,12, 5, 6,  1, 0, 0,1,  1,0,0,"
+" 8,10,15, 4, 10,30, 0,6,  0,0,0,"
+" 8, 2,15, 4, 10, 0, 0,6,  0,0,0,"
+"};"
//演奏
                +"%6 @0 $ c1 r1;"
               ); 
            driver.play(data); 
        } 
    } 
} 
  

