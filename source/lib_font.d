
// Phobos Runtime Library
import std.stdio;
import std.string;

// derelict SDL
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

// my source
import lib_sdl;
import def;


/*--------------------
   Font - フォント管理用
   --------------------*/
class Font
{

private:
    SDL_Renderer* renderer;
    TTF_Font* font;
    SDL_Color color = { 255 , 255 , 255 };

    SDL_Texture*  texture;
    int srcWidth;      // フォント1文字の幅    fontsize:16 / width 8        
    int srcHeight;     // フォント1文字の高さ  fontsize:16 / height 23
    int srcWidthJ;
    int srcHeightJ;

    SDL_Texture*    textureKana;  // ひらがな・カタカナ
    int kanaThreshold;
    SDL_Texture*[]  textureKanji; // 漢字・それ以外
    const int TEXTURE_START      = 500;
    const int TEXTURE_EXTENTIONS = 100;
    int kanjiCount;


    int[ string ]   fontMap;

public:
    this( string fontname , int fontsize , SDL_Renderer* r , SDL_Color cl )
    {

        renderer = r;
        color = cl;

        // フォント取得
        font = TTF_OpenFont( toStringz( fontname ) , fontsize ); 

        // 半角 テーブル作成
        string abc;
        char[128] c;
        for( int i ; i < 128 ; i++ )
            if( 32 <= i && i <= 126 )
                c[ i ] = cast(char)i;
        abc = cast( string ) c;

        // フォント作成→イメージ取得
        SDL_Surface* image 
            = TTF_RenderText_Blended( font , toStringz( abc ) , color );

        // フォント幅確認
        srcWidth   = image.w / 128;
        srcHeight  = image.h;
        srcWidthJ  = srcWidth * 2;
        srcHeightJ = srcHeight;

        // フォント幅確認
        /* writef("width  : %03d`n", width); */
        /* writef("height : %03d`n", height); */

        // フォント貼付用テクスチャーの作成
        texture = SDL_CreateTextureFromSurface( renderer , image );




        // 漢字用テクスチャ初期化
        textureKanji.length = TEXTURE_START;
        kanjiCount = 0;

        // かな テーブル作成
        string aiueo
                = "あいうえおかきくけこさしすせそ"
                ~ "たちつてとなにぬねのはひふへほ"
                ~ "まみむめもやゆよらりるれろわをん"
                ~ "っゃゅょぁぃぅぇぉ"
                ~ "がぎぐげござじずぜぞだぢづでど"
                ~ "ばびぶべぼぱぴぷぺぽ"
                ~ "アイウエオカキクケコサシスセソ"
                ~ "タチツテトナニヌネノハヒフヘホ"
                ~ "マミムメモヤユヨラリルレロワヲン"
                ~ "ッャュョァィゥェォ"
                ~ "ガギグゲゴザジズゼゾダヂヅデド"
                ~ "バビブベボパピプペポヴ"
                ~ "、。ー〜「」";
        string key;

        for( int i = 0 ; i < aiueo.length ;  )
        {
            key = "";
            key ~= aiueo[ i ];
            key ~= aiueo[ i + 1 ];
            key ~= aiueo[ i + 2 ];
            i += 3;

            makeKanjiTexture( key );
        }

        return ;

    }
    ~this()
    {
        TTF_CloseFont(font);
        return;
    }


    /*-------------------- 
       makeKanjiTexture - 漢字用テクスチャ作成
       kanji : 追加する文字
       --------------------*/
    SDL_Texture* makeKanjiTexture( string kanji )
    {

        if( kanjiCount == textureKanji.length )
            textureKanji.length += TEXTURE_EXTENTIONS;

        // 文字・テクスチャ作成
        SDL_Surface* image = TTF_RenderUTF8_Blended( font , toStringz( kanji ) , color );
        
        // テクスチャーの作成
        textureKanji[ kanjiCount ] = SDL_CreateTextureFromSurface( renderer , image );
        fontMap[ kanji ] = kanjiCount;

        return textureKanji[ kanjiCount ++ ];
    }

    /*-------------------- 
       getJWord - 全角テクスチャ取得`
       ch : 取得する文字
       --------------------*/
    SDL_Texture* getJWord( string ch )
    {
        int* p;
        p = ch in fontMap;
        if( p is null )
        {
            return makeKanjiTexture( ch );
        }
        else
        {
            return textureKanji[ *p ];
        }
    }
    


    /*-------------------- 
       print - フォント描画 ※ word は基本は1文字（1byte or 3byte）
       --------------------*/
    void print( int curx , int cury , string word )
    {
        SDL_Rect src , dest;

        if( word.length == 0 )
            word = " ";

        // 半角・全角判定
        // 1byte 0xxx-xxxx
        // 2byte 110x-xxxx 10xx-xxxx
        // 3byte 1110-xxxx 10xx-xxxx 10xx-xxxx
        if( ( word[ 0 ] & 0x80 ) == 0 )
        {
            // 半角表示の場合 - word.length = 1
            src.x = srcWidth * word[ 0 ];
            src.y = 0;
            src.w = srcWidth;
            src.h = srcHeight;

            dest.x = curx * (FONT_WIDTH + FONT_X_MARGINE) + WINDOW_LEFT_MARGINE;
            dest.y = cury * (FONT_HEIGHT + FONT_Y_MARGINE) + WINDOW_TOP_MARGINE;
            dest.w = FONT_WIDTH;
            dest.h = FONT_HEIGHT;

            SDL_RenderCopy( renderer , texture , &src , &dest );

        }
        else
        {
            // 全角文字は3バイト - word.length = 3
            src.x = 0;
            src.y = 0;
            src.w = srcWidthJ;
            src.h = srcHeightJ;

            dest.x = curx * (FONT_WIDTH + FONT_X_MARGINE) + WINDOW_LEFT_MARGINE;
            dest.y = cury * (FONT_HEIGHT + FONT_Y_MARGINE) + WINDOW_TOP_MARGINE;
            dest.w = FONT_J_WIDTH;
            dest.h = FONT_J_HEIGHT;

            SDL_RenderCopy( renderer , getJWord( word ) , &src , &dest );

        }
        return; 

    }

}


