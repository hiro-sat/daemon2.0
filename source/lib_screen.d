// Phobos Runtime Library
import std.stdio;
import std.conv;

// derelict SDL
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

// my source
import lib_sdl;
import lib_font;
import def;

/*--------------------
   Screen - スクリーン管理用
   --------------------*/
class Screen
{

private:

    MySDL sdl;

    int curx , cury;
    int color;

    struct Buffer
    {
        string text; 
        int color;
    }
    Buffer[ TEXT_HEIGHT ][ TEXT_WIDTH ]  buffer;
    Buffer[ TEXT_HEIGHT ][ TEXT_WIDTH ]  _buffer;

    Font[ 100 ] font;   // color pallette 0-99
    SDL_Renderer* renderer;

    // フォントを作成
    Font createFont( ubyte r, ubyte g, ubyte b )
    {

        SDL_Color cl = { r , g , b };

        return new Font( FONTNAME , FONTSIZE , renderer , cl );

    }

    /*-------------------- 
       addCurXY - 文字表示時のカーソルXY移動
       --------------------*/
    void addCurXY( ref int cx , ref int cy , int x , int y )
    {
        cx += x; 
        cy += cx / TEXT_WIDTH; // TEXT WIDTH を超えたら y + 1
        cx =  cx % TEXT_WIDTH;

        cy += y;

        // 画面範囲は超えないことにする。
        // ※ スクロールはしない
        if( cx < 0 ) cx = 0;
        if( cx >= TEXT_WIDTH ) cx = TEXT_WIDTH - 1;
        if( cy < 0 ) cy = 0;
        if( cy >= TEXT_HEIGHT ) cy = TEXT_HEIGHT - 1;

        return ;
    }

    /*-------------------- 
       bufferPrint - バッファに文字追加
       --------------------*/
    void bufferPrint( ref int x, ref int y , int cl , string word )
    {

        assert( x >= 0 && x < TEXT_WIDTH );
        assert( y >= 0 && y < TEXT_HEIGHT );

        for( int i ; i < word.length ; )
        {

            // 半角・全角判定
            // 1byte 0xxx-xxxx
            // 2byte 110x-xxxx 10xx-xxxx
            // 3byte 1110-xxxx 10xx-xxxx 10xx-xxxx
            if( ( word[ i ] & 0x80 ) == 0 )
            {
                // 半角表示の場合
                string w = "";
                w ~= word[ i ];

                buffer[ x ][ y ].text = w;
                buffer[ x ][ y ].color = cl;
                addCurXY( x , y , 1 , 0 );
                
                i++;
            }
            else
            {
                // 全角表示の場合

                // 平仮名・カタカナの場合 E3 82 A1 〜 E3 83 B6
                string w = "";
                w ~= word[ i ];
                w ~= word[ i + 1 ];
                w ~= word[ i + 2 ];

                buffer[ x ][ y ].text = w;
                buffer[ x ][ y ].color = cl;

                addCurXY( x , y , 2 , 0 );
                i += 3;
                
            }
        }

        return; 

    }

    /*--------------------
       saveBuffer - buffer 保存
       --------------------*/
    void saveBuffer()
    {
        for( int y = 0 ; y < TEXT_HEIGHT ; y++ )
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
            {
                _buffer[ x ][ y ].text  = buffer[ x ][ y ].text;
                _buffer[ x ][ y ].color = buffer[ x ][ y ].color;
            }
        return;
    }

    /*--------------------
       checkBufferDoesNotChange - 画面変更をチェック
       --------------------*/
    bool checkBufferDoesNotChange()
    {
        /* writeln( "checkBufferDoesNotChange." ); */
        for( int y = 0 ; y < TEXT_HEIGHT ; y++ )
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
            {
                if(  ( _buffer[ x ][ y ].text != buffer[ x ][ y ].text )
                  || ( _buffer[ x ][ y ].color != buffer[ x ][ y ].color ) )
                {
                    /* writeln( "change." ); */
                    return false;
                }
            }
        /* writeln( "same." ); */
        return true;
    }

public:
    /*--------------------
       コンストラクタ
       --------------------*/
    this( MySDL s , SDL_Renderer* r )
    {

        sdl = s;
        renderer = r;

        // SDL_TTF 初期化
        TTF_Init();

        ubyte c;
        c = 255;
        /*           createFont( r,  g,  b ) */
        setPalette(  0 , 0 , 0 , 0 );
        setPalette(  1 , 0 , 0 , c );
        setPalette(  2 , 0 , c , 0 );
        setPalette(  3 , 0 , c , c );
        setPalette(  4 , c , 0 , 0 );
        setPalette(  5 , c , 0 , c );
        setPalette(  6 , c , c , 0 );
        setPalette(  7 , c , c , c );

        c = 80;
        setPalette(  8 , 0 , 0 , 0 );
        setPalette(  9 , 0 , 0 , c );
        setPalette( 10 , 0 , c , 0 );
        setPalette( 11 , 0 , c , c );
        setPalette( 12 , c , 0 , 0 );
        setPalette( 13 , c , 0 , c );
        setPalette( 14 , c , c , 0 );
        setPalette( 15 , c , c , c );

        curx = 0;
        cury = 0;
        color = 7;

        cls;

        return;
    }

    ~this()
    {
        sdl = null;
        renderer = null;
        return;
    }

    /*-------------------- 
       setPalette - フォント色追加`
       --------------------*/
    void setPalette( int cl , ubyte r , ubyte g , ubyte b )
    {
        font[ cl ] = createFont( r , g , b );
        return;
    }

    /*-------------------- 
       cls - バッファクリア
       --------------------*/
    void cls()
    {

        // バッファクリア
        for( int y = 0 ; y < TEXT_HEIGHT ; y++)
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
            {
                buffer[ x ][ y ].text = "";
                buffer[ x ][ y ].color = color;
            }

        return;

    }

    /*-------------------- 
       color - 文字色変更
       --------------------*/
    void setColor( int c )
    {
        assert( c >= 0 && c < 100 );
        color = c;
        return;
    }


    /*-------------------- 
       locate - カーソル位置変更 
       --------------------*/
    void locate( int x , int y )
    {

        assert( x >= 0 && x < TEXT_WIDTH );
        assert( y >= 0 && y < TEXT_HEIGHT );

        curx = x;
        cury = y;

        return;
    }

    /*-------------------- 
       getCurX / getCurY - カーソル位置取得
       --------------------*/
    @property int getCurX(){ return curx; }
    @property int getCurY(){ return cury; }


    /*-------------------- 
       disp - 画面表示 
       --------------------*/
    void disp()
    {

        static int count;
        /* static int counter; */

        // buffer 変更があったかどうか
        if( checkBufferDoesNotChange )
            if( count != 0 )
            {
                count --;
                // gsdl.delay( 2 );
                /* writeln( " same - delay. " ); */
                return;
            }

        // ウィンドウを背景色で塗りつぶす
        sdl.renderClear;

        // 画面表示
        for( int y = 0 ; y < TEXT_HEIGHT ; y++ )
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
            {
                Buffer* buf = &buffer[ x ][ y ];
                font[ buf.color ].print( x , y , buf.text );
                if( buf.text.length > 1 )
                    x++;    // 全角幅
            }

        /* writef( "disp. %d\n" , counter ); */
        /* if( counter ++ > 1000 ) */
        /*     counter = 0; */

        saveBuffer;
        count = 3;  // たまに更新されない？

        sdl.disp;
        sdl.delayFPS;

        return;

    }

    /*-------------------- 
       debugDisp - デバッグ用
       --------------------*/
    void debugDisp()
    {
        string line;
        for( int y = 0 ; y < TEXT_HEIGHT ; y++ )
        {
            line = "";
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
                line ~= buffer[ x ][ y ].text;
            writeln( line );
        }
        writeln( "------------------------------" );
    }
    /*-------------------- 
       debugDisp - デバッグ用
       --------------------*/
    void debugDispColor()
    {
        string line;
        for( int y = 0 ; y < TEXT_HEIGHT ; y++ )
        {
            line = "";
            for( int x = 0 ; x < TEXT_WIDTH ; x++ )
                writef( "%x" , buffer[ x ][ y ].color );
            writef( "\n" );
        }
        writeln( "------------------------------" );
    }


    /*-------------------- 
       print - 文字表示
       --------------------*/
    void print( string word )
    {
        bufferPrint( curx , cury , color , word );
        return;
    }

    // 色指定
    void print( string word , int c )
    {
        bufferPrint( curx , cury , c , word );
        return;
    }

    // 位置指定
    void print( int x , int y , string word )
    {
        locate( x , y );
        print( word );
        return;
    }

    // 位置・色指定`
    void print( int x , int y , string word , int c )
    {
        locate( x , y );
        print( word , c );
        return;
    }

    // 改行つき
    void println( string word )
    {
        println( word , color );
        return;
    }
    void println( string word , int c )
    {
        int x = curx;
        print( word , c );
        curx = x;
        addCurXY( curx , cury , 0 , 1 );
        return;
    }
    void println( int x , int y , string word )
    {
        locate( x , y );
        println( word );
        return;
    }
    void println( int x , int y , string word , int c )
    {
        locate( x , y );
        println( word , c );
        return;
    }
    void println( string[] word )
    {
        foreach( w ; word )
            println( w );
        return;
    }


    /*-------------------- 
       backSpace - １文字表示…文字入力で使用
       --------------------*/
    void backSpace( int len = 1 )
    {
        for( int i = 0 ; i < len ; i++ )
        {
            addCurXY( curx , cury , -1 , 0 );
            buffer[ curx ][ cury ].text = " ";
        }
        return;
    }
}

