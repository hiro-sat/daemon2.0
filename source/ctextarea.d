// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string;
import std.conv;


// mysource 
import def;
import app;
import cmember;


/*====== text window ===========================================*/
class Textarea
{

private:
    /* for text window */
    int text_curx, text_cury;
    int text_top;

    int disp_x;
    int disp_y;
    int width;
    int height;

    string[] text_win_buffer;
    int   [] text_win_buffer_size;
    int   [] text_win_buffer_color;

    /*-------------------- 
    line_disp - 行表示
    --------------------*/
    void line_disp( int winline , int lineno )
    {

        if( !dispflg )
            return;

        int i , pos ;
        string buf;

        assert( lineno < text_win_buffer.length , to!string( lineno ) );

        char[] bufline = text_win_buffer[ lineno ].dup;
        char* c;

        bool flg = false ;
        pos = 0;

        for( i = 0; i < width; i++)
        {
            if( ! flg )
                if( pos >= bufline.length )
                    flg = true;

            if( flg )
            {
                buf ~= ' ';
            }
            else
            {
                c = &bufline[ pos ];
                if( isHankaku( *c ) )
                {
                    buf ~= *c;
                    pos++;
                }
                else
                {
                    buf ~= *c; c++;
                    buf ~= *c; c++;
                    buf ~= *c;
                    pos += 3;
                    i++;
                }
            }
        }

        CL tmp = cast(CL)text_color;
        setColor( text_win_buffer_color[ lineno ] );
        mvprintw( winline + disp_y , disp_x ,  buf );
        setColor( tmp );

        return;
    }


    /*-------------------- 
    scroll - スクロール
    --------------------*/
    void scroll()
    {
        int i;
        text_top++;

        if( text_top >= height )
            text_top = 0;

        for( i = 0 ; i < height - 1 ; i++ )
            line_disp( i , ( text_top + i ) % height );

        string spc;
        for( i = 0 ; i < width ; i++ )
            spc ~= " ";
        mvprintw( disp_y + height - 1 , disp_x , spc );

        return;
    }


    /*-------------------- 
    crlf - 改行
    --------------------*/
    void crlf()
    {

        /* if( text_win_buffer_size[ ( text_top + text_cury ) % height ] > width - 2 ) */
        /*     crlf; */

        line_disp( text_cury , ( text_top + text_cury ) % height );
        text_cury++;
        text_win_buffer     [ ( text_top + text_cury ) % height ] = "";
        text_win_buffer_size[ ( text_top + text_cury ) % height ] = 0;

        if( text_cury > height - 1)
        {
            text_cury = height - 1;
            scroll();
        }
        return;
    }



public:

    bool dispflg;

    @property int getWidth() { return width; }
    @property int getHeight() { return height; }


    this( int x , int y )
    {
        width  = x;
        height = y;
    
        text_win_buffer.length       = height;
        text_win_buffer_size.length  = height;
        text_win_buffer_color.length = height;
        
        text_color = CL.NORMAL;
        text_cury = 0;
        text_curx = 0;
        text_top  = 0;

        dispflg = true;

        return;

    }

    void setDispPos( int x , int y )
    {
        disp_x = x;
        disp_y = y;
        return;
    }

    void disp()
    {
        bool _flg = dispflg;

        dispflg = true;
        for( int i = 0 ; i < text_win_buffer.length ; i++ )
        {
            /* line_disp( text_top + i , i ); */
            line_disp( i , ( text_top + i ) % height );
        }

        dispflg = _flg;
        return;
    }

    void close()
    {
        dispflg = false;
        return;
    }

    void clear()
    {
        /+
        for( int i = 0 ; i < height ; i ++ )
            textout( "\n" );
        +/

        int x, y , i;
        string spc;
        
        for( x = 0 ; x < width ; x++ )
            spc ~= " ";

        rewriteOff;
        for( y = disp_y ; y < disp_y + height ; y++ )
            mvprintw( y, disp_x , spc );
        rewriteOn;

        for( i = 0 ; i < text_win_buffer.length ; i ++  )
            text_win_buffer[ i ] = "";
        for( i = 0 ; i < text_win_buffer_size.length ; i ++  )
            text_win_buffer_size[ i ] = 0;
        for( i = 0 ; i < text_win_buffer_color.length ; i ++  )
            text_win_buffer_color[ i ] = CL.NORMAL;
        
        text_color = CL.NORMAL;
        text_cury = 0;
        text_curx = 0;
        text_top  = 0;

        return;

    }


    /** (変換あり) */
    void print( T... )( string fmt , T args )
    {
        printw( formatText( fmt , args ) );
        return;
    }
    /+
    void print( string txt )
    {
        printw( txt );
    }
    +/

    void print( int y , int x , string txt )
    {
        mvprintw( disp_y + y , disp_x + x , txt );
        return;
    }
    /** (変換あり) */
    void print( T... )( int y , int x , string fmt , T args )
    {
        print( y , x , formatText( fmt , args ) );
        return;
    }

    
    /** テキストエリア表示(変換あり) */
    void textout( T... )( string fmt , T args )
    {
        textout( formatText( fmt , args ) );
        return;
    }

    /** テキストエリア表示 */
    void textout( T )( T value )
    {

        string text;
        text = to!string( value );

        rewriteOff;

        char[] txt = text.dup;
        for( int i = 0 ; i < txt.length ; i++ )
            if ( txt[ i ] == '\n' )
            {
                if( txt.length > 1      // 2文字以上
                && i == txt.length - 1  // 末尾文字
                && text_win_buffer_size[ ( text_top + text_cury ) % height ] == 0 )    // 改行直後
                {
                    /* writeln( "禁則処理" ); */
                }
                else
                {
                    crlf;
                }
            }
            else
            {
                if( isHankaku( txt[ i ] ) )
                {   // 半角
                    text_win_buffer     [ ( text_top + text_cury ) % height ] ~= txt[ i ];
                    text_win_buffer_size[ ( text_top + text_cury ) % height ] ++;
                    text_win_buffer_color[ ( text_top + text_cury ) % height ] = text_color;
                    if( text_win_buffer_size[ ( text_top + text_cury ) % height ] > width - 2 )
                        crlf;
                }
                else
                {   // 全角
                    text_win_buffer[ ( text_top + text_cury ) % height ] ~= txt[ i++ ];
                    text_win_buffer[ ( text_top + text_cury ) % height ] ~= txt[ i++ ];
                    text_win_buffer[ ( text_top + text_cury ) % height ] ~= txt[ i ];
                    text_win_buffer_size[ ( text_top + text_cury ) % height ] += 2;
                    text_win_buffer_color[ ( text_top + text_cury ) % height ] = text_color;
                    if( text_win_buffer_size[ ( text_top + text_cury ) % height ] > width - 2 )
                        crlf;
                }
            }
        line_disp( text_cury, ( text_top + text_cury ) % height );

        rewriteOn;

        return;
    }

    string input( int size_max )
    {
        return tline_input( size_max , text_cury + disp_y, text_curx + disp_x );
    }

    string inputSpell( Member mem , int size_max )
    {
        return tline_input_spell( mem , size_max , text_cury + disp_y, text_curx + disp_x );
    }

}
