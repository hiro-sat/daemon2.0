import std.stdio;
import std.file;
import std.array;
import std.conv;
import std.json;

import lib_json;

import core.stdc.stdio;

/* https://watabou.itch.io/one-page-dungeon */


Json json;

class Rooms
{
    int x;
    int y;
    int w;
    int h;
}
Rooms[] rooms;


class Doors
{
    int x;
    int y;
    int type;
    bool dir_x;
    bool dir_y;
}
Doors[] doors;


class Parts
{

    int type;   // 0 : door , 
                // 1 : point wall , 2 : line wall , 3 : box wall

    int x;
    int y;

    int x1;
    int y1;
    int x2;
    int y2;

    // door
    bool dir_x;
    bool dir_y;

    void setDoor( int _x , int _y , bool dx , bool dy )
    {

        type = 0;

        x = _x;
        y = _y;
    
        dir_x = dx;
        dir_y = dy;
    }

    void setWallPoint( int _x , int _y )
    {

        type = 1;

        x = _x;
        y = _y;
    
    }

    void setWallLine( int _x1 , int _y1 , int _x2 , int _y2 )
    {

        type = 2;

        x1 = _x1;
        y1 = _y1;
        x2 = _x2;
        y2 = _y2;
    
    }

    void setWallBox( int _x1 , int _y1 , int _x2 , int _y2 )
    {

        type = 3;

        x1 = _x1;
        y1 = _y1;
        x2 = _x2;
        y2 = _y2;
    
    }

}

class PartsManager
{
    Parts[] parts;

    Parts add()
    {
        parts.length ++;
        parts.back = new Parts;
        return parts.back;
    }

    Parts[] all()
    {
        return parts;
    }

    /+
    bool checkWallParts( int x , int y )
    {
        foreach( p ; points )
            if( p.type == 0 && p.x == x && p.y == y)
                return true;
        return false;
    }

    // 重複を除く
    void excludeDupulicate()
    {
        int i;
        foreach( j , p ; points )
        {
            if( p.type == 1 )
                continue;
            for( i = to!int( j + 1 ) ; i < points.length ; i++ )
            {
                if( points[ i ].type == 1 )
                    continue;
                if( p.x == points[ i ].x && p.y == points[ i ].y )
                {
                    points = points[ 0 .. i ] ~ points[ i + 1 .. $ ];
                    i--;    // 要素が減ったので-1して再度ループ
                }
            }
        }
    }
    +/

    // xを二倍
    void setWide()
    {
        foreach( p ; partsManager.all )
        {

            switch( p.type )
            {
                case 0 : // door
                case 1 : // point
                    p.x *= 2;
                    break;
                case 2 : // line
                case 3 : // box
                    p.x1 *= 2;
                    p.x2 *= 2;
                    break;
                default :
                    break;
            }
        }
        return;
    }
    
}
PartsManager partsManager;

class Map
{
    enum SPACE = '@';

    int dx;
    int dy;

    int width;
    int widthWide;
    int height;

    int min_x;
    int min_y;
    int max_x;
    int max_y;

    char[] map_chip;
    char[] map_chipWide;

    void initChip()
    {
        map_chip.length = width * height;
        foreach( i , c ; map_chip )
            map_chip[ i ] = '.';
    }
    @property char chip( int x , int y )
    {
        return map_chip[ y * width + x ];
    }
    void setChip( int x , int y , char c )
    {
        map_chip[ y * width + x ] = c;
    }

    void initChipW()
    {
        widthWide = width * 2;
        map_chipWide.length = widthWide * height;
        foreach( i , c ; map_chipWide )
            map_chipWide[ i ] = '.';
    }
    @property char chipW( int x , int y )
    {
        return map_chipWide[ y * widthWide + x ];
    }
    void setChipW( int x , int y , char c )
    {
        map_chipWide[ y * widthWide + x ] = c;
    }


    // ポイントtoポイントで壁をのばす
    void drawWideWall()
    {

        foreach( p ; partsManager.all )
        {

            void setWall( int x , int y )
            {
                if( chipW( x , y ) == ' ' )
                    return;
                setChipW( x , y , 'X' );
                return;
            }

            switch( p.type )
            {
                case 0: // door
                    setChipW( p.x , p.y , '+' );
                    if( p.dir_x )
                    {
                        setChipW( p.x - 1 , p.y , ' ' );
                        setChipW( p.x + 1 , p.y , ' ' );
                    }
                    else
                    {
                        setChipW( p.x , p.y - 1 , ' ' );
                        setChipW( p.x , p.y + 1 , ' ' );
                    }
                    break;
                case 1: // point
                    setChipW( p.x,     p.y     , ' ' );
                    setWall( p.x,     p.y - 1 );
                    setWall( p.x + 1, p.y - 1 );
                    setWall( p.x + 1, p.y     );
                    setWall( p.x + 1, p.y + 1 );
                    setWall( p.x,     p.y + 1 );
                    setWall( p.x - 1, p.y + 1 );
                    setWall( p.x - 1, p.y     );
                    setWall( p.x - 1, p.y - 1 );
                    break;
                case 2: // line
                    if( p.y1 == p.y2 )
                    {   // horizonal
                        for( int x = p.x1 - 1 ; x <= p.x2 ; x++  )
                        {
                            if( x != p.x1 - 1 )
                                setChipW( x , p.y1 , ' ' );
                            setWall( x , p.y1 - 1 );
                            setWall( x , p.y1 + 1 );
                        }
                    }
                    else 
                    {   // vertical
                        for( int y = p.y1 ; y <= p.y2 ; y++  )
                        {
                            setChipW( p.x1 , y , ' ' );
                            setWall( p.x1 - 1 , y );
                            setWall( p.x1 + 1 , y );
                        }
                    }
                    break;
                case 3: 
                    // box
                    for( int x = p.x1 ; x <= p.x2 ; x++  )
                        setWall( x , p.y1 );
                    for( int y = p.y1 + 1 ; y < p.y2 ; y ++  )
                    {
                        setWall( p.x1 , y );
                        for( int x = p.x1 + 1 ; x < p.x2 ; x++  )
                            setChipW( x , y , ' ');
                        setWall( p.x2 , y );
                    }
                    for( int x = p.x1 ; x <= p.x2 ; x++  )
                        setWall( x , p.y2 );
                    break;
                default:
                    assert(0);
            }
        }
        /* getchar; */
        /* dispWide; */
    }

    void write( string filename )
    {
        string line;

        auto fout  = File( filename,"w");

        for( int y ; y < height ; y++ )
        {
            line = "";
            for( int x ; x < width ; x++ )
                line ~= chip( x , y );
            fout.writeln( line );
        }
        return;

    }

    void disp()
    {
        string line;

        writeln("");

        for( int y ; y < height ; y++ )
        {
            line = "";
            for( int x ; x < width ; x++ )
                line ~= chip( x , y );
            writeln( line );
        }

        return;
    }

    void dispWide()
    {
        string line;

        writeln("");

        for( int y ; y < height ; y++ )
        {
            line = "";
            for( int x ; x < widthWide ; x++ )
                line ~= chipW( x , y );
            writeln( line );
        }

        return;
    }

    void setRoomWallSub( int x , int y )
    {
        char c = chip( x , y );
        switch( c )
        {
            case SPACE:
            case '+':
            case '*':
            case '<':
                return;
            default:
                /* if( c >= '0' && c <= '9') */
                /*     return; */
                break;
        }

        if( chip( x - 1 , y) == SPACE || chip( x + 1 , y ) == SPACE ||
            chip( x - 1 , y) == '<' || chip( x + 1 , y ) == '<' ) 
            setChip( x , y , '|' );
        else
            setChip( x , y , '-' );

        return;
    }

    void setRoomsWall()
    {
        int x , y;
        foreach( r ; rooms )
        {

            for( x = -1 ; x < r.w + 1 ; x++ )
                setRoomWallSub( r.x + x , r.y - 1 );

            for( y = 0 ; y < r.h ; y++ )
            {
                setRoomWallSub( r.x - 1 , r.y + y );
                setRoomWallSub( r.x + r.w , r.y + y );
            }

            for( x = -1 ; x < r.w + 1 ; x++ )
                setRoomWallSub( r.x + x , r.y + y );

        }
        return;
    }

    void setRoomsSpace()
    {
        int x , y;
        Parts pt;

        foreach( r ; rooms )
        {
            for( y = 0 ; y < r.h ; y++ )
                for( x = 0 ; x < r.w ; x++ )
                    setChip( r.x + x , r.y + y , SPACE );

            if( r.w == 1 && r.h == 1 )
            {
                pt = partsManager.add();
                pt.setWallPoint( r.x , r.y );
            }
            else if( r.w == 1 || r.h == 1 )
            {
                pt = partsManager.add();
                pt.setWallLine( r.x , r.y , r.x + r.w - 1 , r.y + r.h - 1 );
            }
            else
            {
                pt = partsManager.add();
                pt.setWallBox( r.x - 1   , r.y - 1   , r.x + r.w , r.y + r.h );
            }
        }
        return;
    }

    void setDoors()
    {
        char dor;
        Parts pt;

        foreach( d ; doors )
        {
            switch( d.type )
            {
                case 0:
                case 2:
                    dor = SPACE;
                    break;
                case 1:
                case 4:
                    dor = '+';
                    break;
                case 3:
                    dor = '<';
                    break;
                case 5:
                    dor = '=';
                    break;
                case 6:
                    dor = '*';
                    break;
                default:
                    dor = '+';
                    break;
            }
            /* setChip( d.x , d.y , to!char( d.type + '0' ) ); */
            setChip( d.x , d.y , dor );

            pt = partsManager.add();
            pt.setDoor( d.x , d.y , d.dir_x , d.dir_y );

        }
        return;
    }


}
Map map;

void main( string[] args )
{

    map = new Map;
    partsManager = new PartsManager;

    string filename;

    if( args.length < 2 || !exists( args[ 1 ] ) )
    {
        writeln( "file is not exists." );
        /* filename = "../data/catacombs_of_lech.json"; */
        filename = "../data/chapel_of_the_immortal_dragon.json";
        /* return; */
    }
    else
    {
        filename = args[ 1 ];
    }
    

    json = new Json( filename );

    if( !readMapJson )  // set Rooms / Doors
    {
        writeln( "error." );
        return;
    }


    map.initChip;

    map.setRoomsSpace;
    map.setDoors;
    map.setRoomsWall;
    map.disp;


    // 重複を除く
    /* points.excludeDupulicate; */

    // xを二倍
    partsManager.setWide;


    // 壁をかく
    map.initChipW;
    map.drawWideWall;



    map.dispWide;

    map.setRoomsWall;
    map.disp;
    map.write( filename ~ ".txt" );

    return;

}

bool readMapJson()
{

    Rooms room;
    Doors door;


    writeln( "read Rooms" );

    // read Rooms
    foreach( r ; json[ "rects" ].array )
    {
        rooms.length ++;
        rooms.back = new Rooms;
        room = rooms.back;

        room.x = to!int( r[ "x" ].integer );
        room.y = to!int( r[ "y" ].integer );
        room.w = to!int( r[ "w" ].integer );
        room.h = to!int( r[ "h" ].integer );

        if( map.min_x > room.x )
            map.min_x = room.x;
        if( map.min_y > room.y )
            map.min_y = room.y;

        if( map.max_x < room.x + room.w )
            map.max_x = room.x + room.w;
        if( map.max_y < room.y + room.h )
            map.max_y = room.y + room.h;
    }

    writeln( "read Doors" );


    // map 範囲確認
    map.width = map.max_x - map.min_x + 4;
    map.height = map.max_y - map.min_y + 4;
    map.dx = 0 - map.min_x + 2;
    map.dy = 0 - map.min_y + 2;

    // rooms 再変換
    foreach( r ; rooms)
    {
        r.x += map.dx;
        r.y += map.dy;
    }

    // read Doors
    foreach( i , d ; json[ "doors" ].array )
    {
        doors.length ++;
        doors.back = new Doors;
        door = doors.back;

        door.x     = to!int( d[ "x" ].integer ) + map.dx;
        door.y     = to!int( d[ "y" ].integer ) + map.dy;
        door.type  = to!int( d[ "type" ].integer );

        JSONValue dir = d[ "dir" ].object;

        if( to!int( dir[ "x" ].integer ) == 0 )
        {
            door.dir_x = false;
            door.dir_y = true;
        }
        else
        {
            door.dir_x = true;
            door.dir_y = false;
        }
    }

    return true;
}
