// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;


// my source
import def;
import app;

class MonsterEncountTable
{

private
    int[] table;

public:
    int specialRate;
    string id;

    this( string _id )
    {
        id = _id;
        return;
    }

    void add( int mon_no )
    {
        table.length ++;
        table.back = mon_no;
        return;
    }

    int getEncount()
    {
        return table[ get_rand( to!int( table.length - 1 ) ) ];
    }

}
