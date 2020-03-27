
import std.stdio;
import std.array;
import std.conv;

import app;
import cMap;
import cRoom;


class Passage
{

    int type;   // 0 : horizonal , 1 : vertical , 2 : point
    int x1 , y1;
    int x2 , y2;
    bool door1;
    bool door2;

    // point only
    bool doorH;
    bool doorV;

    bool openU;
    bool openL;
    bool openR;
    bool openD;


    void setPoint( int x , int y )
    {
        map.setFlg( x , y );
        x1 = x;
        y1 = y;
        if( rooms.checkRoom( x + 1 , y ) )
        {
            if( rooms.checkRoom( x - 1 , y ) )
            {
                type = 2;
                doorH = true;
                doorV = false;
            }
            else
            {
                type = 0;
                x1 = x - 1;
                y1 = y;
                x2 = x;
                y2 = y;
                door1 = false;
                door2 = true;
            }
            return;
        }
        else if( rooms.checkRoom( x - 1 , y ) )
        {
            if( rooms.checkRoom( x + 1 , y ) )
            {
                type = 2;
                doorH = true;
                doorV = false;
            }
            else
            {
                type = 0;
                x1 = x;
                y1 = y;
                x2 = x + 1;
                y2 = y;
                door1 = true;
                door2 = false;
            }
            return;
        }
        else if( rooms.checkRoom( x , y + 1 ) )
        {
            if( rooms.checkRoom( x , y - 1 ) )
            {
                type = 2;
                doorH = false;
                doorV = true;
            }
            else
            {
                type = 1;
                x1 = x;
                y1 = y - 1;
                x2 = x;
                y2 = y;
                door1 = false;
                door2 = true;
            }
            return;
        }
        else if( rooms.checkRoom( x , y - 1 ) )
        {
            if( rooms.checkRoom( x , y + 1 ) )
            {
                type = 2;
                doorH = false;
                doorV = true;
            }
            else
            {
                type = 1;
                x1 = x;
                y1 = y;
                x2 = x;
                y2 = y + 1;
                door1 = true;
                door2 = false;
            }
            return;
        }

        type = 2;
        x1 = x;
        y1 = y;
        if( map.isSpace( x , y - 1 ) )
            openU = true;
        if( map.isSpace( x + 1 , y ) )
            openR = true;
        if( map.isSpace( x , y + 1 ) )
            openD = true;
        if( map.isSpace( x - 1 , y ) )
            openL = true;

        return;
    }

    void setPassage( int typ , int x , int y )
    {

        int dx = 0;
        int dy = 0;

        x1 = x;
        y1 = y;
        type = typ;
        map.setFlg( x , y );

        if( type == 0 )
        {
            while( map.isSpace( x1 - 1 , y1 ) && ! rooms.checkRoom( x1 - 1 , y1 ) )
            {
                map.setFlg( x1 , y1 );
                x1 --;
            }

            if( rooms.checkRoom( x1 , y1 - 1 ) )
                door1 = true;
            else if( rooms.checkRoom( x1 - 1 , y1 ) )
                door1 = true;
            else if( rooms.checkRoom( x1 , y1 + 1 ) )
                door1 = true;
            else 
                door1 = false;

            dx = 1;
        }
        else
        {   // type == 1
            while( map.isSpace( x1 , y1 - 1 ) && ! rooms.checkRoom( x1 , y1 - 1 ) )
            {
                map.setFlg( x1 , y1 );
                y1 --;
            }

            dy = 1;
            if( rooms.checkRoom( x1 - 1 , y1 ) )
                door1 = true;
            else if( rooms.checkRoom( x1 , y1 - 1 ) )
                door1 = true;
            else if( rooms.checkRoom( x1 + 1 , y1 ) )
                door1 = true;
            else 
                door1 = false;
        }

        x = x1;
        y = y1;

        while( ( map.isSpace( x + dx , y + dy ) ) && ! rooms.checkRoom( x + dx , y + dy ) )
        {
            x += dx;
            y += dy;
            map.setFlg( x , y );
        }

        x2 = x;
        y2 = y;
        map.setFlg( x , y );

        if( type == 0 )
        {
            if( rooms.checkRoom( x , y - 1 ) )
                door2 = true;
            else if( rooms.checkRoom( x + 1 , y ) )
                door2 = true;
            else if( rooms.checkRoom( x , y + 1 ) )
                door2 = true;
            else 
                door2 = false;
        }
        else
        {
            dy = 1;
            if( rooms.checkRoom( x - 1 , y ) )
                door2 = true;
            else if( rooms.checkRoom( x , y + 1 ) )
                door2 = true;
            else if( rooms.checkRoom( x + 1 , y ) )
                door2 = true;
            else 
                door2 = false;
        }

        /* writef( "( %d , %d ) - ( %d , %d ) \n" , x1 , y1 , x2 , y2 ); */
        return;

    }

    void setWall( int x , int y , char c = WALL )
    {
        if( x < 0 || x >= map.width )
            return;
        if( y < 0 || y >= map.height )
            return;

        char t = map.getTile( x , y );
        switch( t )
        {
            case ' ':
            case '@':
            case '+':
                break;
            default:    // X , ^
                map.setTile( c , x , y );
        }
        return;
    }
    void setSpace( int x , int y )
    {
        if( x < 0 || x >= map.width )
            return;
        if( y < 0 || y >= map.height )
            return;

        char t = map.getTile( x , y );
        switch( t )
        {
            case '+':
                break;
            default:    // X , ^
                map.setTile( ' ' , x , y );
        }
        return;
    }

    void reTile()
    {

        int x;
        int y;

        // 0 : horizonal , 1 : vertical , 2 : point
        switch( type )
        {
            case 0:     // horizonal
                /* writef( " hor : ( %d , %d ) - ( %d , %d ) \n" , x1 , y1 , x2 , y2 ); */
                setWall( x1 - 1 , y1 - 1 , WALL );
                setWall( x1 - 1 , y1     , WALL );
                setWall( x1 - 1 , y1 + 1 , WALL );
                if( door1 )
                    map.setTile( '+' , x1 , y1 );

                x = x1;
                y = y1;
                while( x <= x2 )
                {
                    setWall ( x , y - 1 , WALL );
                    setSpace( x , y     );
                    setWall ( x , y + 1 , WALL );
                    x ++;
                }

                setWall( x2 + 1 , y2 - 1 , WALL );
                setWall( x2 + 1 , y2     , WALL );
                setWall( x2 + 1 , y2 + 1 , WALL );
                if( door2 )
                    map.setTile( '+' , x2 , y2 );
                break;
            case 1:     // vertical
                /* writef( " ver : ( %d , %d ) - ( %d , %d ) \n" , x1 , y1 , x2 , y2 ); */
                setWall( x1 - 1 , y1 - 1 , WALL );
                setWall( x1     , y1 - 1 , WALL );
                setWall( x1 + 1 , y1 - 1 , WALL );
                if( door1 )
                    map.setTile( '+' , x1 , y1 );

                x = x1;
                y = y1;
                while( y <= y2 )
                {
                    setWall ( x - 1 , y , WALL );
                    setSpace( x     , y );
                    setWall ( x + 1 , y , WALL );
                    y ++;
                }

                setWall( x2 - 1 , y2 + 1 , WALL );
                setWall( x2     , y2 + 1 , WALL );
                setWall( x2 + 1 , y2 + 1 , WALL );
                if( door2 )
                    map.setTile( '+' , x2 , y2 );
                break;
            case 2:     // point
                /* writef( " pnt : ( %d , %d ) %b %b %b %b \n" , x1 , y1 , openU , openR , openD , openD ); */
                if( doorH )
                {
                    map.setTile( '+' , x1 , y1 );
                    setWall( x - 1 , y - 1 );
                    setWall( x     , y - 1 );
                    setWall( x + 1 , y - 1 );

                    setWall( x - 1 , y + 1 );
                    setWall( x     , y + 1 );
                    setWall( x + 1 , y + 1 );

                    setSpace( x     , y - 1 );
                    setSpace( x     , y + 1 );
                }
                else if( doorV )
                {
                    map.setTile( '+' , x1 , y1 );
                    setWall( x - 1 , y - 1 );
                    setWall( x - 1 , y     );
                    setWall( x - 1 , y + 1 );

                    setWall( x + 1 , y - 1 );
                    setWall( x + 1 , y     );
                    setWall( x + 1 , y + 1 );

                    setSpace( x - 1 , y     );
                    setSpace( x + 1 , y     );
                }
                else
                {
                    x = x1;
                    y = y1;
                    setSpace( x , y );
                    setWall( x - 1 , y - 1 );
                    setWall( x + 1 , y - 1 );
                    setWall( x - 1 , y + 1 );
                    setWall( x + 1 , y + 1 );

                    if( openU )
                        setSpace( x     , y - 1 );
                    else
                        setWall ( x     , y - 1 );

                    if( openR )
                        setSpace( x + 1 , y     );
                    else
                        setWall ( x + 1 , y     );

                    if( openD )
                        setSpace( x     , y + 1 );
                    else
                        setWall ( x     , y + 1 );

                    if( openL )
                        setSpace( x - 1 , y     );
                    else
                        setWall ( x - 1 , y     );
                }
                break;
            default:
                assert( 0 );
        }
        return;
    }


    this( int x , int y )
    {

        // check V or H
        if( map.isSpace( x + 1 , y ) && map.isPassage( x + 1 , y ) )
        {   // horizonal
            setPassage( 0 , x , y );
        }
        else if( map.isSpace( x , y + 1 ) && map.isPassage( x , y + 1 ) )
        {   // vertical
            setPassage( 1 , x , y );
        }
        else
        {   // point
            setPoint( x , y );
        }

        return;

    }

}

class PassageManager
{
    Passage[] passage;

    void add( int x , int y )
    {

        /* writef( " %d , %d \n" , x , y ); */

        Passage p;

        passage.length ++;
        passage.back = new Passage( x , y );
        /* room.back.disp; */

    }

    void setWide()
    {
        foreach( p ; passage )
        {
            switch( p.type )
            {
                case 0: // hirizonal
                case 1: // vertical
                    p.x1 *= 2;
                    p.x2 *= 2;
                    break;
                case 2:
                    p.x1 *= 2;
                    break;
                default:
                    assert( 0 );
            }
        }
        return;
    }

    void reTile()
    {
        foreach( p ; passage )
            p.reTile;
        return;
    }

}
