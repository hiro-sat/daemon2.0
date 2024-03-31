
// Phobos Runtime Library
import std.stdio;
import std.array;
import std.conv;

// derelict SDL
import derelict.sdl2.sdl;

// my source
import lib_sdl;
import lib_screen;

class ReadLine
{

private:

    MySDL  sdl;
    Screen scr;

    string line;
    int[]  lineCharWidth;
    int    lineSize;
    string inputChar;       // ローマ字入力用

    enum MODE{ ABC , HIRA , KATA  }
    MODE mode = MODE.ABC;

    const string KEY_BS = "BS";

    string[ string ]    hira;   // ひらがな変換用
    string[ string ]    kata;   // カタカナ変換用

    // プロンプト位置（初期位置）
    int promptx;
    int prompty;

    // シフトキー、コントルールキー押下状態
    bool shiftkey = false;
    bool ctrlkey = false;


    // 特殊処理の登録
    struct SPECIAL
    {
        string key;
        bool ctrl;
        bool shift;
        void delegate() func;
    }
    SPECIAL[] hotkey;


    // バックスペース入力
    void backSpace()
    {

        if( lineCharWidth.length == 0 )
            return ;
        
        /* int w = lineCharWidth[ lineCharWidth.length - 1 ]; */
        int w = lineCharWidth.back;
        if( w == 1 )
        {
            lineSize--;     // 半角
            scr.backSpace;
        }
        else
        {
            lineSize -= 2;  // 全角
            scr.backSpace( 2 );
        }

        line.length -= w;
        
        if( inputChar.length > 0 )
            inputChar.length -= 1;
        lineCharWidth.length -= 1;

        if( line.length <= 0 )
            scr.locate( promptx , prompty );

        return;
    }

    // ひらがな変換
    string convertHira( string key )
    {
        if( key in hira )
            return hira[ key ];

        if( key.length < 3 )
            return "";

        if( key[ 0 ] != key[ 1 ] )
            return "";

        key = key[ 1 .. $ ];

        if( key in hira )
            return "っ" ~ hira[ key ];

        return "";

    }
    // カタカナ変換
    string convertKata( string key )
    {
        if( key in kata )
            return kata[ key ];

        if( key.length < 3 )
            return "";

        if( key[ 0 ] != key[ 1 ] )
            return "";

        key = key[ 1 .. $ ];

        if( key in kata )
            return "ッ" ~ kata[ key ];

        return "";

    }

    // ローマ字初期設定
    void init_roma()
    {
        // utf8 ひらがな、かたかなの全角文字の1バイト目 は E3
        hira["a"] = "あ"      ; hira["i"] = "い"      ; hira["u"] = "う"      ; 
        hira["e"] = "え"      ; hira["o"] = "お"      ; hira["ka"] = "か"     ; 
        hira["ki"] = "き"     ; hira["ku"] = "く"     ; hira["ke"] = "け"     ; 
        hira["ko"] = "こ"     ; hira["sa"] = "さ"     ; hira["si"] = "し"     ; 
        hira["su"] = "す"     ; hira["se"] = "せ"     ; hira["so"] = "そ"     ; 
        hira["ta"] = "た"     ; hira["ti"] = "ち"     ; hira["tu"] = "つ"     ; 
        hira["te"] = "て"     ; hira["to"] = "と"     ; hira["na"] = "な"     ; 
        hira["ni"] = "に"     ; hira["nu"] = "ぬ"     ; hira["ne"] = "ね"     ; 
        hira["no"] = "の"     ; hira["ha"] = "は"     ; hira["hi"] = "ひ"     ; 
        hira["hu"] = "ふ"     ; hira["he"] = "へ"     ; hira["ho"] = "ほ"     ; 
        hira["ma"] = "ま"     ; hira["mi"] = "み"     ; hira["mu"] = "む"     ; 
        hira["me"] = "め"     ; hira["mo"] = "も"     ; hira["ya"] = "や"     ; 
        hira["yi"] = "い"     ; hira["yu"] = "ゆ"     ; hira["ye"] = "いぇ"    ; 
        hira["yo"] = "よ"     ; hira["ra"] = "ら"     ; hira["ri"] = "り"     ; 
        hira["ru"] = "る"     ; hira["re"] = "れ"     ; hira["ro"] = "ろ"     ; 
        hira["wa"] = "わ"     ; hira["wi"] = "ゐ"     ; hira["wu"] = "う"     ; 
        hira["we"] = "ゑ"     ; hira["wo"] = "を"     ; hira["ga"] = "が"     ; 
        hira["gi"] = "ぎ"     ; hira["gu"] = "ぐ"     ; hira["ge"] = "げ"     ; 
        hira["go"] = "ご"     ; hira["za"] = "ざ"     ; hira["zi"] = "じ"     ; 
        hira["zu"] = "ず"     ; hira["ze"] = "ぜ"     ; hira["zo"] = "ぞ"     ; 
        hira["da"] = "だ"     ; hira["di"] = "ぢ"     ; hira["du"] = "づ"     ; 
        hira["de"] = "で"     ; hira["do"] = "ど"     ; hira["ba"] = "ば"     ; 
        hira["bi"] = "び"     ; hira["bu"] = "ぶ"     ; hira["be"] = "べ"     ; 
        hira["bo"] = "ぼ"     ; hira["pa"] = "ぱ"     ; hira["pi"] = "ぴ"     ; 
        hira["pu"] = "ぷ"     ; hira["pe"] = "ぺ"     ; hira["po"] = "ぽ"     ; 
        hira["la"] = "ぁ"     ; hira["li"] = "ぃ"     ; hira["lu"] = "ぅ"     ; 
        hira["le"] = "ぇ"     ; hira["lo"] = "ぉ"     ; hira["lya"] = "ゃ"    ; 
        hira["lyi"] = "ぃ"    ; hira["lyu"] = "ゅ"    ; hira["lye"] = "ぇ"    ; 
        hira["lyo"] = "ょ"    ; hira["xa"] = "ぁ"     ; hira["xi"] = "ぃ"     ; 
        hira["xu"] = "ぅ"     ; hira["xe"] = "ぇ"     ; hira["xo"] = "ぉ"     ; 
        hira["xya"] = "ゃ"    ; hira["xyi"] = "ぃ"    ; hira["xyu"] = "ゅ"    ; 
        hira["xye"] = "ぇ"    ; hira["xyo"] = "ょ"    ; hira["kya"] = "きゃ"   ; 
        hira["kyi"] = "きぃ"   ; hira["kyu"] = "きゅ"   ; hira["kye"] = "きぇ"   ; 
        hira["kyo"] = "きょ"   ; hira["gwa"] = "ぐぁ"   ; hira["gwi"] = "ぐぃ"   ; 
        hira["gwu"] = "ぐぅ"   ; hira["gwe"] = "ぐぇ"   ; hira["gwo"] = "ぐぉ"   ; 
        hira["gya"] = "ぎゃ"   ; hira["gyi"] = "ぎぃ"   ; hira["gyu"] = "ぎゅ"   ; 
        hira["gye"] = "ぎぇ"   ; hira["gyo"] = "ぎょ"   ; hira["sha"] = "しゃ"   ; 
        hira["shi"] = "し"    ; hira["shu"] = "しゅ"   ; hira["she"] = "しぇ"   ; 
        hira["sho"] = "しょ"   ; hira["swa"] = "すぁ"   ; hira["swi"] = "すぃ"   ; 
        hira["swu"] = "すぅ"   ; hira["swe"] = "すぇ"   ; hira["swo"] = "すぉ"   ; 
        hira["sya"] = "しゃ"   ; hira["syi"] = "しぃ"   ; hira["syu"] = "しゅ"   ; 
        hira["sye"] = "しぇ"   ; hira["syo"] = "しょ"   ; hira["tha"] = "てゃ"   ; 
        hira["thi"] = "てぃ"   ; hira["thu"] = "てゅ"   ; hira["the"] = "てぇ"   ; 
        hira["tho"] = "てょ"   ; hira["tsa"] = "つぁ"   ; hira["tsi"] = "つぃ"   ; 
        hira["tsu"] = "つ"    ; hira["tse"] = "つぇ"   ; hira["tso"] = "つぉ"   ; 
        hira["twa"] = "とぁ"   ; hira["twi"] = "とぃ"   ; hira["twu"] = "とぅ"   ; 
        hira["twe"] = "とぇ"   ; hira["two"] = "とぉ"   ; hira["tya"] = "ちゃ"   ; 
        hira["tyi"] = "ちぃ"   ; hira["tyu"] = "ちゅ"   ; hira["tye"] = "ちぇ"   ; 
        hira["tyo"] = "ちょ"   ; hira["dha"] = "でゃ"   ; hira["dhi"] = "でぃ"   ; 
        hira["dhu"] = "でゅ"   ; hira["dhe"] = "でぇ"   ; hira["dho"] = "でょ"   ; 
        hira["nya"] = "にゃ"   ; hira["nyi"] = "にぃ"   ; hira["nyu"] = "にゅ"   ; 
        hira["nye"] = "にぇ"   ; hira["nyo"] = "にょ"   ; hira["hya"] = "ひゃ"   ; 
        hira["hyi"] = "ひぃ"   ; hira["hyu"] = "ひゅ"   ; hira["hye"] = "ひぇ"   ; 
        hira["hyo"] = "ひょ"   ; hira["bya"] = "びゃ"   ; hira["byi"] = "びぃ"   ; 
        hira["byu"] = "びゅ"   ; hira["bye"] = "びぇ"   ; hira["byo"] = "びょ"   ; 
        hira["pya"] = "ぴゃ"   ; hira["pyi"] = "ぴぃ"   ; hira["pyu"] = "ぴゅ"   ; 
        hira["pye"] = "ぴぇ"   ; hira["pyo"] = "ぴょ"   ; hira["mya"] = "みゃ"   ; 
        hira["myi"] = "みぃ"   ; hira["myu"] = "みゅ"   ; hira["mye"] = "みぇ"   ; 
        hira["myo"] = "みょ"   ; hira["rya"] = "りゃ"   ; hira["ryi"] = "りぃ"   ; 
        hira["ryu"] = "りゅ"   ; hira["rye"] = "りぇ"   ; hira["ryo"] = "りょ"   ; 
        hira["ca"] = "か"     ; hira["ci"] = "し"     ; hira["cu"] = "く"     ; 
        hira["ce"] = "せ"     ; hira["co"] = "こ"     ; hira["cha"] = "ちゃ"   ; 
        hira["chi"] = "ち"    ; hira["chu"] = "ちゅ"   ; hira["che"] = "ちぇ"   ; 
        hira["cho"] = "ちょ"   ; hira["fa"] = "ふぁ"    ; hira["fi"] = "ふぃ"    ; 
        hira["fu"] = "ふ"     ; hira["fe"] = "ふぇ"    ; hira["fo"] = "ふぉ"    ; 
        hira["fwa"] = "ふぁ"   ; hira["fwi"] = "ふぃ"   ; hira["fwu"] = "ふぅ"   ; 
        hira["fwe"] = "ふぇ"   ; hira["fwo"] = "ふぉ"   ; hira["fya"] = "ふゃ"   ; 
        hira["fyi"] = "ふぃ"   ; hira["fyu"] = "ふゅ"   ; hira["fye"] = "ふぇ"   ; 
        hira["fyo"] = "ふょ"   ; hira["ja"] = "じゃ"    ; hira["ji"] = "じ"     ; 
        hira["ju"] = "じゅ"    ; hira["je"] = "じぇ"    ; hira["jo"] = "じょ"    ; 
        hira["jya"] = "じゃ"   ; hira["jyi"] = "じぃ"   ; hira["jyu"] = "じゅ"   ; 
        hira["jye"] = "じぇ"   ; hira["jyo"] = "じょ"   ; hira["qa"] = "くぁ"    ; 
        hira["qi"] = "くぃ"    ; hira["qu"] = "く"     ; hira["qe"] = "くぇ"    ; 
        hira["qo"] = "くぉ"    ; hira["qwa"] = "くぁ"   ; hira["qwi"] = "くぃ"   ; 
        hira["qwu"] = "くぅ"   ; hira["qwe"] = "くぇ"   ; hira["qwo"] = "くぉ"   ; 
        hira["qya"] = "くゃ"   ; hira["qyi"] = "くぃ"   ; hira["qyu"] = "くゅ"   ; 
        hira["qye"] = "くぇ"   ; hira["qyo"] = "くょ"   ; hira["va"] = "ヴぁ"    ; 
        hira["vi"] = "ヴぃ"    ; hira["vu"] = "ヴ"     ; hira["ve"] = "ヴぇ"    ; 
        hira["vo"] = "ヴぉ"    ; hira["vya"] = "ヴゃ"   ; hira["vyi"] = "ヴぃ"   ; 
        hira["vyu"] = "ヴゅ"   ; hira["vye"] = "ヴぇ"   ; hira["vyo"] = "ヴょ"   ; 
        hira["nn"] = "ん"     ; hira["n'"] = "ん"     ; hira["xn"] = "ん"     ; 
        hira["ltu"] = "っ"    ; hira["xtu"] = "っ"    ; hira["lwa"] = "ゎ"    ; 
        hira["xwa"] = "ゎ"    ; hira["lka"] = "ヵ"    ; hira["xka"] = "ヵ"    ; 
        hira["lke"] = "ヶ"    ; hira["xke"] = "ヶ"    ; hira["kwa"] = "くぁ"   ; 
        hira["mba"] = "んば"   ; hira["mbi"] = "んび"   ; hira["mbu"] = "んぶ"   ; 
        hira["mbe"] = "んべ"   ; hira["mbo"] = "んぼ"   ; hira["mpa"] = "んぱ"   ; 
        hira["mpi"] = "んぴ"   ; hira["mpu"] = "んぷ"   ; hira["mpe"] = "んぺ"   ; 
        hira["mpo"] = "んぽ"   ; hira["mma"] = "んま"   ; hira["mmi"] = "んみ"   ; 
        hira["mmu"] = "んむ"   ; hira["mme"] = "んめ"   ; hira["mmo"] = "んも"   ; 
        hira["tcha"] = "っちゃ" ; hira["tchi"] = "っち"  ; hira["tchu"] = "っちゅ" ; 
        hira["tche"] = "っちぇ" ; hira["tcho"] = "っちょ" ; 

        hira["-"] = "ー"      ; hira["~"] = "〜"      ; hira[","] = "、"      ; 
        hira["."] = "。"      ; hira["["] = "「"      ; hira["]"] = "」"      ; 


        kata["a"] = "ア"      ; kata["i"] = "イ"      ; kata["u"] = "ウ"      ; 
        kata["e"] = "エ"      ; kata["o"] = "オ"      ; kata["ka"] = "カ"     ; 
        kata["ki"] = "キ"     ; kata["ku"] = "ク"     ; kata["ke"] = "ケ"     ; 
        kata["ko"] = "コ"     ; kata["sa"] = "サ"     ; kata["si"] = "シ"     ; 
        kata["su"] = "ス"     ; kata["se"] = "セ"     ; kata["so"] = "ソ"     ; 
        kata["ta"] = "タ"     ; kata["ti"] = "チ"     ; kata["tu"] = "ツ"     ; 
        kata["te"] = "テ"     ; kata["to"] = "ト"     ; kata["na"] = "ナ"     ; 
        kata["ni"] = "ニ"     ; kata["nu"] = "ヌ"     ; kata["ne"] = "ネ"     ; 
        kata["no"] = "ノ"     ; kata["ha"] = "ハ"     ; kata["hi"] = "ヒ"     ; 
        kata["hu"] = "フ"     ; kata["he"] = "ヘ"     ; kata["ho"] = "ホ"     ; 
        kata["ma"] = "マ"     ; kata["mi"] = "ミ"     ; kata["mu"] = "ム"     ; 
        kata["me"] = "メ"     ; kata["mo"] = "モ"     ; kata["ya"] = "ヤ"     ; 
        kata["yi"] = "イ"     ; kata["yu"] = "ユ"     ; kata["ye"] = "イェ"    ; 
        kata["yo"] = "ヨ"     ; kata["ra"] = "ラ"     ; kata["ri"] = "リ"     ; 
        kata["ru"] = "ル"     ; kata["re"] = "レ"     ; kata["ro"] = "ロ"     ; 
        kata["wa"] = "ワ"     ; kata["wi"] = "ヰ"     ; kata["wu"] = "ウ"     ; 
        kata["we"] = "ヱ"     ; kata["wo"] = "ヲ"     ; kata["ga"] = "ガ"     ; 
        kata["gi"] = "ギ"     ; kata["gu"] = "グ"     ; kata["ge"] = "ゲ"     ; 
        kata["go"] = "ゴ"     ; kata["za"] = "ザ"     ; kata["zi"] = "ジ"     ; 
        kata["zu"] = "ズ"     ; kata["ze"] = "ゼ"     ; kata["zo"] = "ゾ"     ; 
        kata["da"] = "ダ"     ; kata["di"] = "ヂ"     ; kata["du"] = "ヅ"     ; 
        kata["de"] = "デ"     ; kata["do"] = "ド"     ; kata["ba"] = "バ"     ; 
        kata["bi"] = "ビ"     ; kata["bu"] = "ブ"     ; kata["be"] = "ベ"     ; 
        kata["bo"] = "ボ"     ; kata["pa"] = "パ"     ; kata["pi"] = "ピ"     ; 
        kata["pu"] = "プ"     ; kata["pe"] = "ペ"     ; kata["po"] = "ポ"     ; 
        kata["la"] = "ァ"     ; kata["li"] = "ィ"     ; kata["lu"] = "ゥ"     ; 
        kata["le"] = "ェ"     ; kata["lo"] = "ォ"     ; kata["lya"] = "ャ"    ; 
        kata["lyi"] = "ィ"    ; kata["lyu"] = "ュ"    ; kata["lye"] = "ェ"    ; 
        kata["lyo"] = "ョ"    ; kata["xa"] = "ァ"     ; kata["xi"] = "ィ"     ; 
        kata["xu"] = "ゥ"     ; kata["xe"] = "ェ"     ; kata["xo"] = "ォ"     ; 
        kata["xya"] = "ャ"    ; kata["xyi"] = "ィ"    ; kata["xyu"] = "ュ"    ; 
        kata["xye"] = "ェ"    ; kata["xyo"] = "ョ"    ; kata["kya"] = "キャ"   ; 
        kata["kyi"] = "キィ"   ; kata["kyu"] = "キュ"   ; kata["kye"] = "キェ"   ; 
        kata["kyo"] = "キョ"   ; kata["gwa"] = "グァ"   ; kata["gwi"] = "グィ"   ; 
        kata["gwu"] = "グゥ"   ; kata["gwe"] = "グェ"   ; kata["gwo"] = "グォ"   ; 
        kata["gya"] = "ギャ"   ; kata["gyi"] = "ギィ"   ; kata["gyu"] = "ギュ"   ; 
        kata["gye"] = "ギェ"   ; kata["gyo"] = "ギョ"   ; kata["sha"] = "シャ"   ; 
        kata["shi"] = "シ"    ; kata["shu"] = "シュ"   ; kata["she"] = "シェ"   ; 
        kata["sho"] = "ショ"   ; kata["swa"] = "スァ"   ; kata["swi"] = "スィ"   ; 
        kata["swu"] = "スゥ"   ; kata["swe"] = "スェ"   ; kata["swo"] = "スォ"   ; 
        kata["sya"] = "シャ"   ; kata["syi"] = "シィ"   ; kata["syu"] = "シュ"   ; 
        kata["sye"] = "シェ"   ; kata["syo"] = "ショ"   ; kata["tha"] = "テャ"   ; 
        kata["thi"] = "ティ"   ; kata["thu"] = "テュ"   ; kata["the"] = "テェ"   ; 
        kata["tho"] = "テョ"   ; kata["tsa"] = "ツァ"   ; kata["tsi"] = "ツィ"   ; 
        kata["tsu"] = "ツ"    ; kata["tse"] = "ツェ"   ; kata["tso"] = "ツォ"   ; 
        kata["twa"] = "トァ"   ; kata["twi"] = "トィ"   ; kata["twu"] = "トゥ"   ; 
        kata["twe"] = "トェ"   ; kata["two"] = "トォ"   ; kata["tya"] = "チャ"   ; 
        kata["tyi"] = "チィ"   ; kata["tyu"] = "チュ"   ; kata["tye"] = "チェ"   ; 
        kata["tyo"] = "チョ"   ; kata["dha"] = "デャ"   ; kata["dhi"] = "ディ"   ; 
        kata["dhu"] = "デュ"   ; kata["dhe"] = "デェ"   ; kata["dho"] = "デョ"   ; 
        kata["nya"] = "ニャ"   ; kata["nyi"] = "ニィ"   ; kata["nyu"] = "ニュ"   ; 
        kata["nye"] = "ニェ"   ; kata["nyo"] = "ニョ"   ; kata["hya"] = "ヒャ"   ; 
        kata["hyi"] = "ヒィ"   ; kata["hyu"] = "ヒュ"   ; kata["hye"] = "ヒェ"   ; 
        kata["hyo"] = "ヒョ"   ; kata["bya"] = "ビャ"   ; kata["byi"] = "ビィ"   ; 
        kata["byu"] = "ビュ"   ; kata["bye"] = "ビェ"   ; kata["byo"] = "ビョ"   ; 
        kata["pya"] = "ピャ"   ; kata["pyi"] = "ピィ"   ; kata["pyu"] = "ピュ"   ; 
        kata["pye"] = "ピェ"   ; kata["pyo"] = "ピョ"   ; kata["mya"] = "ミャ"   ; 
        kata["myi"] = "ミィ"   ; kata["myu"] = "ミュ"   ; kata["mye"] = "ミェ"   ; 
        kata["myo"] = "ミョ"   ; kata["rya"] = "リャ"   ; kata["ryi"] = "リィ"   ; 
        kata["ryu"] = "リュ"   ; kata["rye"] = "リェ"   ; kata["ryo"] = "リョ"   ; 
        kata["ca"] = "カ"     ; kata["ci"] = "シ"     ; kata["cu"] = "ク"     ; 
        kata["ce"] = "セ"     ; kata["co"] = "コ"     ; kata["cha"] = "チャ"   ; 
        kata["chi"] = "チ"    ; kata["chu"] = "チュ"   ; kata["che"] = "チェ"   ; 
        kata["cho"] = "チョ"   ; kata["fa"] = "ファ"    ; kata["fi"] = "フィ"    ; 
        kata["fu"] = "フ"     ; kata["fe"] = "フェ"    ; kata["fo"] = "フォ"    ; 
        kata["fwa"] = "ファ"   ; kata["fwi"] = "フィ"   ; kata["fwu"] = "フゥ"   ; 
        kata["fwe"] = "フェ"   ; kata["fwo"] = "フォ"   ; kata["fya"] = "フャ"   ; 
        kata["fyi"] = "フィ"   ; kata["fyu"] = "フュ"   ; kata["fye"] = "フェ"   ; 
        kata["fyo"] = "フョ"   ; kata["ja"] = "ジャ"    ; kata["ji"] = "ジ"     ; 
        kata["ju"] = "ジュ"    ; kata["je"] = "ジェ"    ; kata["jo"] = "ジョ"    ; 
        kata["jya"] = "ジャ"   ; kata["jyi"] = "ジィ"   ; kata["jyu"] = "ジュ"   ; 
        kata["jye"] = "ジェ"   ; kata["jyo"] = "ジョ"   ; kata["qa"] = "クァ"    ; 
        kata["qi"] = "クィ"    ; kata["qu"] = "ク"     ; kata["qe"] = "クェ"    ; 
        kata["qo"] = "クォ"    ; kata["qwa"] = "クァ"   ; kata["qwi"] = "クィ"   ; 
        kata["qwu"] = "クゥ"   ; kata["qwe"] = "クェ"   ; kata["qwo"] = "クォ"   ; 
        kata["qya"] = "クャ"   ; kata["qyi"] = "クィ"   ; kata["qyu"] = "クュ"   ; 
        kata["qye"] = "クェ"   ; kata["qyo"] = "クョ"   ; kata["va"] = "ヴァ"    ; 
        kata["vi"] = "ヴィ"    ; kata["vu"] = "ヴ"     ; kata["ve"] = "ヴェ"    ; 
        kata["vo"] = "ヴォ"    ; kata["vya"] = "ヴャ"   ; kata["vyi"] = "ヴィ"   ; 
        kata["vyu"] = "ヴュ"   ; kata["vye"] = "ヴェ"   ; kata["vyo"] = "ヴョ"   ; 
        kata["nn"] = "ン"     ; kata["n'"] = "ン"     ; kata["xn"] = "ン"     ; 
        kata["ltu"] = "ッ"    ; kata["xtu"] = "ッ"    ; kata["lwa"] = "ヮ"    ; 
        kata["xwa"] = "ヮ"    ; kata["lka"] = "ヵ"    ; kata["xka"] = "ヵ"    ; 
        kata["lke"] = "ヶ"    ; kata["xke"] = "ヶ"    ; kata["kwa"] = "クァ"   ; 
        kata["mba"] = "ンバ"   ; kata["mbi"] = "ンビ"   ; kata["mbu"] = "ンブ"   ; 
        kata["mbe"] = "ンベ"   ; kata["mbo"] = "ンボ"   ; kata["mpa"] = "ンパ"   ; 
        kata["mpi"] = "ンピ"   ; kata["mpu"] = "ンプ"   ; kata["mpe"] = "ンペ"   ; 
        kata["mpo"] = "ンポ"   ; kata["mma"] = "ンマ"   ; kata["mmi"] = "ンミ"   ; 
        kata["mmu"] = "ンム"   ; kata["mme"] = "ンメ"   ; kata["mmo"] = "ンモ"   ; 
        kata["tcha"] = "ッチャ" ; kata["tchi"] = "ッチ"  ; kata["tchu"] = "ッチュ" ; 
        kata["tche"] = "ッチェ" ; kata["tcho"] = "ッチョ" ; 

        kata["-"] = "ー"      ; kata["~"] = "〜"      ; kata[","] = "、"      ; 
        kata["."] = "。"      ; kata["["] = "「"      ; kata["]"] = "」"      ; 

        return;
    }


    /*-------------------- 
       keyInput - キーボード文字入力
       size_max;  入力文字列最大 全角2バイト換算
       --------------------*/
    int keyInput( SDL_Event e , int size_max )
    {
        string ch = "";

        if( e.type == SDL_KEYUP )
            switch( e.key.keysym.sym )
            {
                case SDLK_RSHIFT:
                case SDLK_LSHIFT:
                    shiftkey = false;
                    break;
                case SDLK_RCTRL:
                case SDLK_LCTRL:
                    ctrlkey = false;
                    break;
                default:
                    break;
            }
        else if( e.type == SDL_KEYDOWN )
        {

            // 特殊キーの確認
            foreach( SPECIAL h ; hotkey )
                if( checkHotKey( h , e ) )
                    return 0;

            if( ctrlkey )
            {
                switch( e.key.keysym.sym )
                {
                    case SDLK_h: 
                        ch = KEY_BS;
                        break;
                    case SDLK_j:
                        mode = MODE.HIRA;
                        inputChar = "";
                        break;
                    case SDLK_k:
                        mode = MODE.KATA;
                        inputChar = "";
                        break;
                    case SDLK_l:
                        mode = MODE.ABC;
                        inputChar = "";
                        break;
                    default:
                        break;
                }
            }
            else
            {
                switch( e.key.keysym.sym )
                {
                    case SDLK_RETURN:
                        return 1;           // 抜ける

                    case SDLK_RSHIFT:
                    case SDLK_LSHIFT:
                        shiftkey = true;
                        break;
                    case SDLK_RCTRL:
                    case SDLK_LCTRL:
                        ctrlkey = true;
                        break;
                    case SDLK_a: ch = shiftkey ? "A" : "a" ; break;
                    case SDLK_b: ch = shiftkey ? "B" : "b" ; break;
                    case SDLK_c: ch = shiftkey ? "C" : "c" ; break;
                    case SDLK_d: ch = shiftkey ? "D" : "d" ; break;
                    case SDLK_e: ch = shiftkey ? "E" : "e" ; break;
                    case SDLK_f: ch = shiftkey ? "F" : "f" ; break;
                    case SDLK_g: ch = shiftkey ? "G" : "g" ; break;
                    case SDLK_h: ch = shiftkey ? "H" : "h" ; break;
                    case SDLK_i: ch = shiftkey ? "I" : "i" ; break;
                    case SDLK_j: ch = shiftkey ? "J" : "j" ; break;
                    case SDLK_k: ch = shiftkey ? "K" : "k" ; break;
                    case SDLK_l: ch = shiftkey ? "L" : "l" ; break;
                    case SDLK_m: ch = shiftkey ? "M" : "m" ; break;
                    case SDLK_n: ch = shiftkey ? "N" : "n" ; break;
                    case SDLK_o: ch = shiftkey ? "O" : "o" ; break;
                    case SDLK_p: ch = shiftkey ? "P" : "p" ; break;
                    case SDLK_q: ch = shiftkey ? "Q" : "q" ; break;
                    case SDLK_r: ch = shiftkey ? "R" : "r" ; break;
                    case SDLK_s: ch = shiftkey ? "S" : "s" ; break;
                    case SDLK_t: ch = shiftkey ? "T" : "t" ; break;
                    case SDLK_u: ch = shiftkey ? "U" : "u" ; break;
                    case SDLK_v: ch = shiftkey ? "V" : "v" ; break;
                    case SDLK_w: ch = shiftkey ? "W" : "w" ; break;
                    case SDLK_x: ch = shiftkey ? "X" : "x" ; break;
                    case SDLK_y: ch = shiftkey ? "Y" : "y" ; break;
                    case SDLK_z: ch = shiftkey ? "Z" : "z" ; break;
                    case SDLK_1: ch = shiftkey ? "!" : "1" ; break;
                    case SDLK_2: ch = shiftkey ? "@" : "2" ; break;
                    case SDLK_3: ch = shiftkey ? "#" : "3" ; break;
                    case SDLK_4: ch = shiftkey ? "$" : "4" ; break;
                    case SDLK_5: ch = shiftkey ? "%" : "5" ; break;
                    case SDLK_6: ch = shiftkey ? "^" : "6" ; break;
                    case SDLK_7: ch = shiftkey ? "&" : "7" ; break;
                    case SDLK_8: ch = shiftkey ? "*" : "8" ; break;
                    case SDLK_9: ch = shiftkey ? "(" : "9" ; break;
                    case SDLK_0: ch = shiftkey ? ")" : "0" ; break;
                    case SDLK_MINUS:        ch = shiftkey ? "_" : "-" ; break;
                    case SDLK_EQUALS:       ch = shiftkey ? "+" : "=" ; break;
                    case SDLK_COMMA:        ch = shiftkey ? "<" : "," ; break;
                    case SDLK_PERIOD:       ch = shiftkey ? ">" : "." ; break;
                    case SDLK_SEMICOLON:    ch = shiftkey ? ":" : ";" ; break;
                    case SDLK_QUOTE:        ch = shiftkey ? "\"": "'" ; break;
                    case SDLK_SLASH:        ch = shiftkey ? "?" : "/" ; break;
                    case SDLK_LEFTBRACKET:  ch = shiftkey ? "{" : "[" ; break;
                    case SDLK_RIGHTBRACKET: ch = shiftkey ? "}" : "]" ; break;
                    case SDLK_BACKSLASH:    ch = shiftkey ? "|" : "\\" ; break;
                    case SDLK_BACKQUOTE:    ch = shiftkey ? "~" : "`" ; break;
                    case SDLK_BACKSPACE:    ch = KEY_BS; break;
                    case SDLK_SPACE:        ch = " "; break;

                    default:
                         break;
                }

            }
        }

        if( ch == "" )
            return 0;

        if( ch == KEY_BS )
        {
            backSpace;
            return 0;
        }

        // 英字モードはそのまま追加
        if( mode == MODE.ABC )
        {
            inputChar = "";
            if( lineSize + 1 <= size_max )
            {
                line ~= ch;
                lineCharWidth ~= 1;
                lineSize ++;
                scr.print( ch );
            }
            return 0;
        }


        // 以下、全角入力（ひらがな・カタカナモード）

        switch( ch )
        {
            case "-":
            case "~":
            case ".":
            case ",":
            case "[":
            case "]":
                break;  // 次処理を行う
            default:
                if(  ! ( "a" <= ch && ch <= "z" ) )
                {

                    if( lineSize + 1 <= size_max )
                    {
                        // 英字以外はそのまま追加
                        inputChar = "";
                        line ~= ch;
                        lineCharWidth ~= 1;
                        lineSize ++;
                    }
                    return 0;
                }
                break;  // 次処理を行う
        }


        string word;

        // ひらがな・カタカナ変換
        switch( mode )
        {
            case MODE.HIRA:
                word = convertHira( inputChar ~ ch );
                break;
            case MODE.KATA:
                word = convertKata( inputChar ~ ch );
                break;
            default:
                return 0;
        }
        
        if( word == "" )
        {
            if( lineSize + 1 <= size_max )
            {
                line ~= ch;
                lineCharWidth ~= 1;
                inputChar ~= ch;
                lineSize ++;

                scr.print( ch );
            }
        }
        else
        {
            if( ( lineSize - inputChar.length + ( word.length / 3 * 2 ) ) <= size_max )
            {
                foreach( i , c ; inputChar )
                    backSpace;
                inputChar = "";

                line ~= word;
                for( int i = 0 ; i < word.length ; i += 3 )
                {
                    lineCharWidth ~= 3;
                    lineSize += 2;
                }

                scr.print( word );
            }
        }

        return 0;
        
    }


    /*-------------------- 
       checkHotKey - 特殊キーの確認
        ret: true : 処理抜ける 
       --------------------*/
    bool checkHotKey( SPECIAL hotkey , SDL_Event e )
    {

        int x;
        int y;
        string ch;

        switch( e.key.keysym.sym )
        {
            case SDLK_a: ch = "a" ; break;
            case SDLK_b: ch = "b" ; break;
            case SDLK_c: ch = "c" ; break;
            case SDLK_d: ch = "d" ; break;
            case SDLK_e: ch = "e" ; break;
            case SDLK_f: ch = "f" ; break;
            case SDLK_g: ch = "g" ; break;
            case SDLK_h: ch = "h" ; break;
            case SDLK_i: ch = "i" ; break;
            case SDLK_j: ch = "j" ; break;
            case SDLK_k: ch = "k" ; break;
            case SDLK_l: ch = "l" ; break;
            case SDLK_m: ch = "m" ; break;
            case SDLK_n: ch = "n" ; break;
            case SDLK_o: ch = "o" ; break;
            case SDLK_p: ch = "p" ; break;
            case SDLK_q: ch = "q" ; break;
            case SDLK_r: ch = "r" ; break;
            case SDLK_s: ch = "s" ; break;
            case SDLK_t: ch = "t" ; break;
            case SDLK_u: ch = "u" ; break;
            case SDLK_v: ch = "v" ; break;
            case SDLK_w: ch = "w" ; break;
            case SDLK_x: ch = "x" ; break;
            case SDLK_y: ch = "y" ; break;
            case SDLK_z: ch = "z" ; break;
            case SDLK_1: ch = "1" ; break;
            case SDLK_2: ch = "2" ; break;
            case SDLK_3: ch = "3" ; break;
            case SDLK_4: ch = "4" ; break;
            case SDLK_5: ch = "5" ; break;
            case SDLK_6: ch = "6" ; break;
            case SDLK_7: ch = "7" ; break;
            case SDLK_8: ch = "8" ; break;
            case SDLK_9: ch = "9" ; break;
            case SDLK_0: ch = "0" ; break;
            case SDLK_MINUS:        ch = "-" ; break;
            case SDLK_EQUALS:       ch = "=" ; break;
            case SDLK_COMMA:        ch = "," ; break;
            case SDLK_PERIOD:       ch = "." ; break;
            case SDLK_SEMICOLON:    ch = ";" ; break;
            case SDLK_QUOTE:        ch = "'" ; break;
            case SDLK_SLASH:        ch = "/" ; break;
            case SDLK_LEFTBRACKET:  ch = "[" ; break;
            case SDLK_RIGHTBRACKET: ch = "]" ; break;
            case SDLK_BACKSLASH:    ch = "\\" ; break;
            case SDLK_BACKQUOTE:    ch = "`" ; break;
            case SDLK_BACKSPACE:    ch = KEY_BS; break;
            case SDLK_SPACE:        ch = " "; break;
            default:
                 break;
        }

        if( hotkey.ctrl == ctrlkey 
                && hotkey.shift == shiftkey 
                &&  hotkey.key == ch )
        {
            if( hotkey.func !is null )
            {
                x = scr.getCurX;
                y = scr.getCurY;
                hotkey.func();
                scr.locate( x , y );
                ctrlkey = false;
                shiftkey = false;
            }
            return true;
        }
        return false;
    }



public:
    this( MySDL sd , Screen sc )
    {
    
        sdl = sd;
        scr = sc;

        init_roma;

        return;
    }


    /*-------------------- 
       setHotKey - 特殊キーの設定。同じキーなら上書き
       --------------------*/
    void setHotKey( string k , bool ctrl , bool shift , void delegate() func )
    {

        int i = 0;
        foreach( SPECIAL h ; hotkey )
        {
            if( h.ctrl == ctrl 
                    && h.shift == shift 
                    &&  h.key == k )
            {
                hotkey[ i ].func = func;
                return;
            }
            i++;
        }

        hotkey.length ++;
        i = to!int( hotkey.length - 1 );
        hotkey[ i ].key = k;
        hotkey[ i ].ctrl = ctrl;
        hotkey[ i ].shift = shift;
        hotkey[ i ].func = func;

        return;
    }

    void clearHotkey()
    {
        hotkey.length = 0;
        return;
    }

    /*-------------------- 
       tline_input - 文字列入力
       size_max;  入力文字列最大 全角2バイト換算
       --------------------*/
    string input( int size_max, int y, int x , ref bool quit )
    {
        scr.locate( x , y );
        return input( size_max , quit );
    }
    string input( int size_max, ref bool quit )
    {

        line     = "";
        lineCharWidth.length = 0;
        lineSize = 0;

        mode     = MODE.ABC;
        shiftkey = false;
        ctrlkey  = false;

        promptx = scr.getCurX;
        prompty = scr.getCurY;

        while( true )
        {
            // キューに溜まったイベントを処理
            for( SDL_Event e; SDL_PollEvent( &e ); ) 
            {
                switch( e.type ) 
                {
                    // 終了イベント
                    case SDL_QUIT:
                        quit = true;
                        return "";         // 抜ける
                    case SDL_KEYUP:
                    case SDL_KEYDOWN:
                        if( keyInput( e , size_max ) != 0 )
                            return line;   // 抜ける
                        break;
                    default:
                        break;
                }
            }
            scr.disp;
        }
    }

}

