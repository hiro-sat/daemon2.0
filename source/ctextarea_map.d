// vim: set nowrap :

import std.stdio;

// mysource 
import def;
import ctextarea;

class MapTextarea : Textarea
{

    int count;

    this( int x , int y)
    {
        super( x , y );
        dispflg = false;
        return;
    }

    void textout( string s )
    {
        super.textout( s );
        count = 3;
        return;
    }

    void textoutNow( string s )
    {
        textout( s );
        party.dungeon.disp;
        return;
    }

    /*-------------------- 
       disp - マップ用一次メッセージ表示
       party_x , party_y : 画面上のパーティ表示位置
       --------------------*/
    void disp( int party_x , int party_y )
    {

        if( count == 0 )
            return;

        int x , y;

        if( party_x < SCRW_X_SIZ / 2  )
            x = SCRW_X_TOP + SCRW_X_SIZ - MAPMSG_X_SIZ - MAPMSG_X_MARGIN;
        else
            x = SCRW_X_TOP + MAPMSG_X_MARGIN;

        if( party_y < SCRW_Y_SIZ / 2  )
            y = SCRW_Y_TOP + SCRW_Y_SIZ - MAPMSG_Y_SIZ - MAPMSG_Y_MARGIN;
        else
            y = SCRW_Y_TOP + MAPMSG_Y_MARGIN;

        setDispPos( x , y );
        super.disp;

        count --;

        return;
    }

}

