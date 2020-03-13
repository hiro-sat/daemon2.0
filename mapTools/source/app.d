import std.stdio;
import std.file;
import std.array;
import std.conv;
import std.json;

import lib_json;

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
    int dir_x;
    int dir_y;
}
Doors[] doors;

class Map
{
    enum SPACE = '@';

    int dx;
    int dy;

    int width;
    int height;

    int min_x;
    int min_y;
    int max_x;
    int max_y;

    char[] map_chip;
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
        foreach( r ; rooms )
        {
            for( y = 0 ; y < r.h ; y++ )
                for( x = 0 ; x < r.w ; x++ )
                    setChip( r.x + x , r.y + y , SPACE );
        }
        return;
    }

    void setDoors()
    {
        char dor;

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
        }
        return;
    }


}
Map map;

void main( string[] args )
{

    map = new Map;

    if( args.length < 2 )
    {
        writeln( "file is not exists." );
        return;
    }
    
    if( !exists( args[ 1 ] ) )
    {
        writeln( "file is not exists." );
        return;
    }

    string filename = args[ 1 ];

    json = new Json( filename );

    if( !readMapJson )
    {
        writeln( "error." );
        return;
    }

    map.initChip;

    map.setRoomsSpace;
    map.setDoors;
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

        door.dir_x = to!int( dir[ "x" ].integer );
        door.dir_y = to!int( dir[ "y" ].integer );
    }

    return true;
}
