import std.stdio;
import std.file;
import std.array;

import app;
import cRoom;

class Map
{

    char[] tile;
    bool[] flg;
    int width;
    int height;

    void initFlg()
    {
        flg.length = 0;
        flg.length = tile.length;
        return;
    }
    void setFlg( int x , int y )
    {
        flg[ width * y + x ] = true;
        return;
    }
    void resetFlg( int x , int y )
    {
        flg[ width * y + x ] = false;
        return;
    }
    bool getFlg( int x , int y )
    {
        return flg[ width * y + x ];
    }

    void setTile( char c )
    {
        tile.length ++;
        tile[ $ - 1 ] = c;
        return;
    }
    void setTile( char c , int x , int y)
    {
        tile[ width * y + x ] = c;
        return;
    }
    char getTile( int x  , int y )
    {
        return tile[ width * y + x ];
    }


    bool isWall( int x , int y )
    {
        return ! isSpace( x , y );
    }
    bool isSpace( int x , int y )
    {
        if( x < 0 || x >= width )
            return false;
        if( y < 0 || y >= height )
            return false;

        switch( getTile( x , y ) )
        {
            case ' ':
            case '<':
            case '>':
            case '+':
                return true;
            default:
                return false;
        }
    }

    bool isPassage( int px , int py )
    {
        if( ! isSpace( px - 1 , py ) && ! isSpace( px + 1 , py ) )
            return true;
        if( ! isSpace( px , py - 1 ) && ! isSpace( px , py + 1 ) )
            return true;

        return false;
    }

    // set Room
    void setRoom()
    {

        initFlg;
        for( int y = 0 ; y < height ; y++ )
        {
            for( int x = 0 ; x < width ; x ++ )
            {
                if( getFlg( x , y ) )
                    continue;
                
                if( ! isSpace( x , y ) )
                    continue;

                if( isSpace( x + 1 , y ) 
                 && isSpace( x , y + 1 )  
                 && isSpace( x + 1 , y + 1 ) )
                {
                    rooms.add( x , y );
                }
            }
        }
        return;
    }

    // set Passage
    void setPassage()
    {
        for( int y = 0 ; y < height ; y++ )
            for( int x = 0 ; x < width ; x++ )
            {
                if( getFlg( x , y ) )
                    continue;

                if( ! isSpace( x , y ) )
                    continue;

                passages.add( x , y );

            }
        return;
    }

    void setWide()
    {
        width *= 2;
        tile.length = 0;
        tile.length = width * height;

        rooms.setWide;
        passages.setWide;
        return;
    }

    void reTile()
    {

        for( int i = 0 ; i < tile.length ; i++ )
            tile[ i ] = NUL;

        rooms.reTile;
        /* rooms.setWall; */

        passages.reTile;

        return;
    }

    // read file
    this( string filename )
    {

        int x;
        int y;

        auto fin  = File(filename,"r");
        y = 0;
        
        foreach(line; fin.byLine )
        {
            x = 0;
            char[][] chip = line.split( "\t");

            char t;
            foreach( c ; chip )
            {
                switch( c )
                {
                    case "":
                        t = 'X';
                        break;
                    case "F":
                    case "SD":
                    case "SU":
                        t = ' ';
                        break;
                    case "SUU":
                        t = '<';
                        break;
                    case "SDD":
                        t = '>';
                        break;
                    default:
                        t = '+';
                }
                setTile( t );
                x++;
            }
            width  = x;
            y ++;
        }
        height = y;

        return;

    }

    void setWall()
    {

        char gettile( int _x , int _y  )
        {
            if( _x < 0 || _x >= width )
                return NUL;
            if( _y < 0 || _y >= height )
                return NUL;
            return getTile( _x , _y );
        }
        bool getspace( int _x , int _y )
        {
            switch( gettile( _x , _y ) )
            {
                case '+':
                case ' ':
                case '@':
                    return true;
                default:
                    break;
            }
            return false;
        }

        char tile;

        for( int y = 0 ; y < height ; y ++ )
            for( int x = 0 ; x < width ; x ++ )
            {

                switch( getTile( x , y ) )
                {
                    case NUL:
                    case ' ':
                    case '@':
                    case '+':
                        continue;
                    default:
                        break;
                }

                if( gettile( x - 1 , y ) == '+' || gettile( x + 1 , y ) == '+' )
                {
                    setTile( WALLH , x , y );
                    continue;
                }

                if( gettile( x , y - 1 ) == '+' || gettile( x , y + 1 ) == '+' )
                {
                    if( ! getspace( x - 1 , y ) && ! getspace( x + 1 , y ) )
                        setTile( WALLH , x , y );
                    else
                        setTile( WALLV , x , y );
                    continue;
                }

                if( ! getspace( x - 1 , y ) && ! getspace( x + 1 , y ) )
                {
                    setTile( WALLH , x , y );
                    continue;
                }

                if( getspace( x , y - 1 ) || getspace( x , y + 1 ) )
                {
                    setTile( WALLH , x , y );
                    continue;
                }

                if( getspace( x - 1 , y ) || getspace( x + 1 , y ) )
                {
                    setTile( WALLV , x , y );
                    continue;
                }
            }

        return;
    }


    void dispTile()
    {
        for( int y = 0 ; y < height ; y++ )
        {
            for( int x = 0 ; x < width ; x++ )
                writef( "%c" , getTile( x , y ) );
            writef( "\n" );
        }
        return;
    }

    void dispFlg()
    {
        for( int y = 0 ; y < height ; y++ )
        {
            for( int x = 0 ; x < width ; x++ )
                writef( "%b" , getFlg( x , y ) );
            writef( "\n" );
        }
        return;
    }

    void write( string filename )
    {
        string line;

        auto fout  = File( filename,"w");

        for( int y ; y < height ; y++ )
        {
            line = "";
            for( int x ; x < width ; x++ )
                line ~= getTile( x , y );
            fout.writeln( line );
        }
        return;

    }

}
