import std.stdio;
import std.file;
import std.string;

import cMap;
import cRoom;
import cPassage;

/* string filename = "mapdata/The Black Hive of Doom 01 (tsv).txt"; */
string filename = "mapdata/The Dread Hive of Worms 01 (tsv).txt";

/+
char SPC = '@';
char WALLV = '|';
char WALLH = '-';
char WALLROOM = 'X';
+/

const char NUL = '.';
const char SPC = '@';
const char WALLV = '|';
const char WALLH = '-';
const char WALL = 'X';


Map map;
RoomsManager rooms;
PassageManager passages;

void main( string[] args )
{

    if( args.length < 2 || !exists( args[ 1 ] ) )
    {
        writeln( "file is not exists." );
    }
    else
    {
        filename = args[ 1 ];
    }
    

    map = new Map( filename );
    rooms = new RoomsManager;
    passages = new PassageManager;

    map.setRoom;
    rooms.setRoomFlg;   // roomflg = map.flg;

    /* map.dispFlg; */

    map.setPassage;
    /* map.dispFlg; */

    map.setWide;    // これ以降、xは2倍

    map.reTile;
    map.setWall;

    map.dispTile;

    map.write( filename ~ ".orgmap" );

    return;
}
