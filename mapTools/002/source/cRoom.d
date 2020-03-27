import std.stdio;
import std.array;
import std.conv;
import core.stdc.stdio;

import app;
import cMap;

class Room
{

    struct Point
    {
        int clock;  // 0:clock , 1 counterClock
        int x;
        int y;
    }

    Point start;
    Point[] pnt;

    Point startWall;
    Point[] wall;

    int[] temp;
    void settemp( int x , int y  ) 
    {
        temp[ map.width * y + x ] = 1;
    }
    void drawtemp( int x , int y  )
    {
        temp[ map.width * y + x ] = 2;
    }
    int gettemp( int x , int y )
    {
        // 範囲判定
        if( x < 0 || x >= map.width )
            return 9;
        if( y < 0 || y >= map.height )
            return 9;

        return temp[ map.width * y + x ];
    }


    void settempWall( int x , int y  ) 
    {
        temp[ map.width * y + x ] = 3;
    }




    // for debug
    void disp()
    {
        writef( "--------\n" );
        writef( " x: %d , y %d \n" , start.x , start.y );
        foreach( p ; pnt )
            writef( " dir: %d ,  x: %d , y %d \n" , p.clock , p.x , p.y );
        writef( "--------\n" );
        return;
    }
    void dispWallPnt()
    {
        writef( "--------\n" );
        writef( " x: %d , y %d \n" , startWall.x , startWall.y );
        foreach( w ; wall )
            writef( " dir: %d ,  x: %d , y %d \n" , w.clock , w.x , w.y );
        writef( "--------\n" );
        return;
    }


    bool checkClockwise( int dir , int x , int y )
    {
        int dx , dy;
        checkDir( dir , dx , dy );
        x += dx;
        y += dy;

        // 一歩先が壁なら時計周りにまわる
        if( ! map.isSpace( x , y ) )
            return true;

        // スペースでも通路だったら周る
        if( map.isPassage( x , y ) )
            return true;

        return false;
        
    }
    bool checkClockwiseWall( int dir , int x , int y )
    {
        // up
        if( dir == 0 && gettemp( x + 1 , y ) != 1 )
            return true;

        // right
        if( dir == 1 && gettemp( x , y + 1 ) != 1 )
            return true;

        // down 
        if( dir == 2 && gettemp( x - 1 , y ) != 1 )
            return true;

        // left
        if( dir == 3 && gettemp( x , y - 1 ) != 1 ) 
            return true;

        return false;
    }

    bool checkCounterClockwise( int dir , int x , int y )
    {
        int count = 0;

        if( map.isWall( x     , y - 1 ) ) count ++;
        if( map.isWall( x + 1 , y - 1 ) ) count ++;
        if( map.isWall( x + 1 , y     ) ) count ++;
        if( map.isWall( x + 1 , y + 1 ) ) count ++;
        if( map.isWall( x     , y + 1 ) ) count ++;
        if( map.isWall( x - 1 , y + 1 ) ) count ++;
        if( map.isWall( x - 1 , y     ) ) count ++;
        if( map.isWall( x - 1 , y - 1 ) ) count ++;
        assert( count != 0 , to!string ( x ) ~ ":" ~ to!string( y ) );   // 空間の真ん中？


        // if count == 1
        // up
        if( dir == 0 
                && ! map.isWall( x - 1 , y ) 
                && ! map.isPassage ( x - 1 , y ) ) return true;
        // right
        if( dir == 1 
                && ! map.isWall( x , y - 1 ) 
                && ! map.isPassage ( x , y - 1 ) ) return true;
        // down 
        if( dir == 2 
                && ! map.isWall( x + 1 , y )
                && ! map.isPassage ( x + 1 , y ) ) return true;
        // left
        if( dir == 3 
                && ! map.isWall( x , y + 1 )
                && ! map.isPassage ( x , y + 1 ) ) return true;

        return false;
    }

    bool checkCounterClockwiseWall( int dir , int x , int y )
    {
        int dx , dy;
        checkDir( dir , dx , dy );
        x += dx;
        y += dy;

        // 一歩先が壁なら反時計周りにまわる
        if( gettemp( x , y ) == 1 )
            return true;

        return false;
    }


    void setPoint( int cl , int x , int y )
    {
        pnt.length ++;
        pnt[ $ - 1 ].clock = cl;
        pnt[ $ - 1 ].x = x;
        pnt[ $ - 1 ].y = y;
        /* writef( " dir: %d ,  x: %d , y %d \n" , cl , x , y ); */
        return;
    }

    void setPointWall( int cl , int x , int y )
    {
        wall.length ++;
        wall[ $ - 1 ].clock = cl;
        wall[ $ - 1 ].x = x;
        wall[ $ - 1 ].y = y;
        /* writef( " dir: %d ,  x: %d , y %d \n" , cl , x , y ); */
        return;
    }

    void checkDir( int dir , ref int dx , ref int dy )
    {
        switch( dir )
        {
            case 0:
                dx = 0;
                dy = -1;
                break;
            case 1:
                dx = 1;
                dy = 0;
                break;
            case 2:
                dx = 0;
                dy = 1;
                break;
            case 3:
                dx = -1;
                dy = 0;
                break;
            default:
                assert( 0 );
        }
        return;
    }

    this( int x , int y )
    {

        // initialize
        temp.length = map.height * map.width;   // all 0

        start.x = x;
        start.y = y;

        // 0:up , 1:right , 2:down , 3:left
        int dir = 1;    // スタートは常に左上角のはず    
        int dx , dy;
        settemp( x , y );       // 1

        checkDir( dir , dx , dy );
        x += dx;
        y += dy;

        while( ! ( x == start.x && y == start.y ) )
        {

            if( checkClockwise( dir , x , y ) )
            {
                setPoint( 0 , x , y );
                dir ++;
                if( dir == 4 )
                    dir = 0;
            }
            else if( checkCounterClockwise( dir , x , y ) )
            {
                setPoint( 1 , x , y );
                dir --;
                if( dir == -1 )
                    dir = 3;
            }

            settemp( x , y );   // 1

            checkDir( dir , dx , dy );
            x += dx;
            y += dy;

        }
        // 一周終わり

        /* writeln( "room-1 ok.") ; */

        // wall 設定
        x = start.x - 1;
        y = start.y - 1;

        startWall.x = x;
        startWall.y = y;
        dir = 1;

        settempWall( x , y );       // 3

        /* writef( "start dir: %d , x:%d , y:%d\n" , dir , x , y ); */

        checkDir( dir , dx , dy );
        x += dx;
        y += dy;

        while( ! ( x == startWall.x && y == startWall.y ) )
        {

            /* writef( "dir: %d , x:%d , y:%d\n" , dir , x , y ); */
            /* getchar(); */

            if( checkCounterClockwiseWall( dir , x , y ) )
            {
                while( checkCounterClockwiseWall( dir , x , y ) )
                {
                    setPointWall( 1 , x , y );
                    dir --;
                    if( dir == -1 )
                        dir = 3;
                }
                /* writef( "CNTclockwise dir:%d\n" , dir ); */
            }
            else if( checkClockwiseWall( dir , x , y ) )
            {
                setPointWall( 0 , x , y );
                dir ++;
                if( dir == 4 )
                    dir = 0;
                /* writef( "clockwise dir:%d\n" , dir ); */
            }

            settempWall( x , y );   // 3

            checkDir( dir , dx , dy );
            x += dx;
            y += dy;

        }

        /* writeln( "room-2 ok.") ; */


        // rooms 抽出
        // temp を 2で埋める -> 再帰処理
        drawRooms( 0 , 0 );  // 2



        // map.flg とマージ
        for( y = 0 ; y < map.height ; y++ )
            for( x = 0 ; x < map.width ; x++ )
                switch( gettemp( x , y ) )
                {
                    case 0:
                    case 1:
                        // 部屋の内側のみが 0 で残っている。
                        // 1 : 部屋の壁 / 2 : 部屋の外部※今回処理対象外
                        map.setFlg( x , y );
                        break;
                    case 3:     // wall
                    default:
                        break;
                }

        return;

    }

    void drawRooms( int x , int y )
    {
        drawtemp( x , y );  // 0 -> 2

        if( gettemp( x     , y - 1 ) == 0 )
            drawRooms( x     , y - 1 );

        if( gettemp( x + 1 , y - 1 ) == 0 )
            drawRooms( x + 1 , y - 1 );

        if( gettemp( x + 1 , y     ) == 0 )
            drawRooms( x + 1 , y     );

        if( gettemp( x + 1 , y + 1 ) == 0 )
            drawRooms( x + 1 , y + 1 );

        if( gettemp( x     , y + 1 ) == 0 )
            drawRooms( x     , y + 1 );

        if( gettemp( x - 1 , y + 1 ) == 0 )
            drawRooms( x - 1 , y + 1 );

        if( gettemp( x - 1 , y     ) == 0 )
            drawRooms( x - 1 , y     );

        if( gettemp( x - 1 , y - 1 ) == 0 )
            drawRooms( x - 1 , y - 1 );

        return;
    }

    void setWide()
    {
        start.x *= 2;
        for( int i = 0 ; i < pnt.length ; i++ )
            pnt[ i ].x *= 2;
        startWall.x *= 2;
        for( int i = 0 ; i < wall.length ; i++ )
            wall[ i ].x *= 2;
        return;
    }

    void reTile()
    {
        temp.length = 0;
        temp.length = map.width * map.height;   // all 0

        int dir;
        int x;
        int y;
        int dx , dy;


        // ラインを引く（壁 : temp 1 で引く）
        dir = 1;    // right
        x = startWall.x;
        y = startWall.y;
        checkDir( dir , dx , dy );

        foreach( w ; wall )
        {
            /* writef( " px : %d , py : %d \n" , p.x , p.y ); */

            while( ! ( x == w.x && y == w.y ) )
            {
                settemp( x , y );   // 1
                x += dx;
                y += dy;
            }

            if( w.clock == 0 )
            {
                dir ++;
                if( dir > 3 )
                    dir = 0;
            }
            else    // p.clock == 1
            {
                dir --;
                if( dir < 0 )
                    dir = 3;
            }
            checkDir( dir , dx , dy );
        }

        checkDir( dir , dx , dy );

        while( ! ( x == startWall.x && y == startWall.y ) )
        {
            settemp( x , y );   // 1
            x += dx;
            y += dy;
        }


        // 塗り潰す
        // temp を 2で埋める -> 再帰処理
        drawRooms( 0 , 0 );  // 2


        // ラインを引く（壁 : temp 3 で引く）
        dir = 1;    // right
        x = startWall.x;
        y = startWall.y;
        checkDir( dir , dx , dy );

        foreach( w; wall )
        {
            while( ! ( x == w.x && y == w.y ) )
            {
                settempWall( x , y );   // 3
                x += dx;
                y += dy;
            }

            if( w.clock == 0 )
            {
                dir ++;
                if( dir > 3 )
                    dir = 0;
            }
            else    // p.clock == 1
            {
                dir --;
                if( dir < 0 )
                    dir = 3;
            }
            checkDir( dir , dx , dy );
        }

        checkDir( dir , dx , dy );

        while( ! ( x == startWall.x && y == startWall.y ) )
        {
            settempWall( x , y );   // 3
            x += dx;
            y += dy;
        }


        // mapに反映`
        for( y = 0 ; y < map.height ; y++ )
            for( x = 0 ; x < map.width ; x++ )
                switch( gettemp( x , y ) )
                {
                    case 0:
                    case 1:
                        // 部屋の内側のみが 0 で残っている。
                        // 1 : 部屋の壁 / 2 : 部屋の外部※今回処理対象外
                        map.setTile( SPC , x , y );
                        break;
                    case 3:
                        // 壁
                        map.setTile( WALL , x , y );
                        break;
                    default:
                        break;
                }

        return;

    }

}


class RoomsManager
{
    Room[] room;
    bool[] roomflg;

    void add( int x , int y )
    {

        /* writef( "set Room / x : %d , y : %d \n" , x , y ); */

        Room r;

        room.length ++;
        room.back = new Room( x , y );
        /* room.back.disp; */
        /* room.back.dispWallPnt; */

    }

    void setRoomFlg()
    {
        roomflg.length = map.height * map.width;
        for( int y = 0 ; y < map.height ; y++ )
            for( int x = 0 ; x < map.width ; x++ )
                roomflg[ y * map.width + x ] = map.getFlg( x, y );
        return;
    }


    bool checkRoom( int x , int y )
    {
        // 範囲判定
        if( x < 0 || x >= map.width )
            return false;
        if( y < 0 || y >= map.height )
            return false;
        return roomflg[ y * map.width + x ];
    }

    void setWide()
    {
        foreach( r ; room )
            r.setWide;
        return;
    }

    void reTile()
    {
        foreach( r ; room )
            r.reTile;
        return;
    }
}

