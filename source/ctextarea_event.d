// vim: set nowrap :

import std.stdio;

// mysource 
import def;
import ctextarea;

class EventTextarea : Textarea
{

    public bool eventDispFlg;

    private int saved_party_x;
    private int saved_party_y;

    this( int x , int y)
    {
        super( x , y );
        dispflg = false;
        return;
    }

    void resetEventDispFlg()
    {
        eventDispFlg = false;
    }

    void dispNow()
    {
        eventDispFlg = true; 
        disp( saved_party_x , saved_party_y );
        return;
    }
    /*-------------------- 
       disp - イベント用メッセージ表示
       party_x , party_y : 画面上のパーティ表示位置
       --------------------*/
    void disp( int party_x , int party_y )
    {

        saved_party_x = party_x;
        saved_party_y = party_y;

        int x , y;

        if( party_x < SCRW_X_SIZ / 2  )
            x = SCRW_X_TOP + SCRW_X_SIZ - EVENT_X_SIZ - EVENT_X_MARGIN;
        else
            x = SCRW_X_TOP + EVENT_X_MARGIN;

        if( party_y < SCRW_Y_SIZ / 2  )
            y = SCRW_Y_TOP + SCRW_Y_SIZ - EVENT_Y_SIZ - EVENT_Y_MARGIN;
        else
            y = SCRW_Y_TOP + EVENT_Y_MARGIN;

        setDispPos( x , y );
        super.disp;

        return;
    }

}

