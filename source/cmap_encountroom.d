// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;

// mysource 
import def;


/**
  MapEncountRoom - エンカウントを管理
  */
class MapEncountRoom
{
private:

    int MAP_MAX_X;
    int MAP_MAX_Y;

    MapEncountRoomChip[][] chip;

    class MapEncountRoomChip
    {
    private:
        int x , y;
        bool checked;
        bool encount;
        bool map_encount;
        MapEncountRoomChip up;
        MapEncountRoomChip down;
        MapEncountRoomChip left;
        MapEncountRoomChip right;

    public:
        @property void setUp   ( MapEncountRoomChip r ){ up = r; }
        @property void setDown ( MapEncountRoomChip r ){ down = r; }
        @property void setLeft ( MapEncountRoomChip r ){ left = r; }
        @property void setRight( MapEncountRoomChip r ){ right = r; }
        @property void setEncount( bool e )
        { 
            map_encount = e;
            encount = e;
            return;
        }

        this( int _y , int _x )
        {
            x = _x;
            y = _y;
            return;
        }
        bool isEncount() { return encount; }
        bool isChecked() { return checked; }
        void reset() 
        {
            checked = false; 
            encount = map_encount;
            return;
        }

        void clear()
        {

            void checkClear( MapEncountRoomChip c )
            {
                if( c !is null )
                    if( ! c.isChecked && c.isEncount )
                        c.clear;
                return;
            }

            encount = false;
            checked = true;

            checkClear( up );
            checkClear( down );
            checkClear( left );
            checkClear( right );

            return;
        }

    }


public:
    this( int maxx , int maxy )
    {

        MAP_MAX_X = maxx;
        MAP_MAX_Y = maxy;

        chip = new MapEncountRoomChip[][]( MAP_MAX_Y , MAP_MAX_X );

        // インスタンス
        for( int y = 0 ; y < MAP_MAX_Y ; y++ )
            for( int x = 0 ; x < MAP_MAX_X ; x++ )
                chip[ y ][ x ] = new MapEncountRoomChip( y , x );

        // 上下左右
        for( int y = 0 ; y < MAP_MAX_Y ; y++ )
            for( int x = 0 ; x < MAP_MAX_X ; x++ )
            {
                if( y - 1 < 0 )
                    chip[ y ][ x ].setUp = null;
                else
                    chip[ y ][ x ].setUp = chip[ y - 1 ][ x ];

                if( y + 1 >= MAP_MAX_Y )
                    chip[ y ][ x ].setDown = null;
                else
                    chip[ y ][ x ].setDown = chip[ y + 1 ][ x ];

                if( x - 1 < 0 )
                    chip[ y ][ x ].setLeft = null;
                else
                    chip[ y ][ x ].setLeft = chip[ y ][ x - 1 ];

                if( x + 1 >= MAP_MAX_X )
                    chip[ y ][ x ].setRight = null;
                else
                    chip[ y ][ x ].setRight = chip[ y ][ x + 1 ];
            }

        return;
    }

    void setEncount( int y , int x ,bool e )
    { 
        chip[ y ][ x ].setEncount = e;
        return;
    }

    @property bool isEncount( int y , int x )
    { 
        return chip[ y ][ x ].isEncount;
    }

    void clear( int y , int x )
    {
        chip[ y ][ x ].clear;
        return;
    }

    /**--------------------
       resetEncounterArea - エンカウントエリア初期化
       --------------------*/
    void reset()
    {
        for( int y = 0 ; y < MAP_MAX_Y ; y++ )
            for( int x = 0 ; x < MAP_MAX_X ; x++ )
                chip[ y ][ x ].reset;
        return;
    }

}

