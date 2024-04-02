// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.file;
import std.conv;
import std.array;
import std.string : format , split , chop , indexOf ;
import std.math : abs ;
import std.ascii : toLower ;

// mysource 
import ctextarea;
import ctextarea_map;

import cparty;
import cmember;
import cevent;

import cmap_encountroom;


import def;
import app;

/* import lib_sdl; */


class Map   // -> Map dungeon;
{

private:
    int layer;
    Event event;
    MapTextarea mapmsg;

    int mapWidth;
    int mapHeight;

    /* char[ mapWidth ][ mapHeight ] map; */
    /* char[ mapWidth ][ mapHeight ] orgmap; */
    char[][] map;
    char[][] orgmap;
    MapEncountRoom encountRoom;

    int startX , startY;
    int endX , endY;

    /* char vram1[ 29 * 15 ]; */
    char[ SCRW_Y_SIZ ][ ( SCRW_X_SIZ - 1 ) ] vram;
    int [ SCRW_Y_SIZ ][ ( SCRW_X_SIZ - 1 ) ] vramCl;

    int dispScrX;
    int dispScrY;
    int dispPartyX;
    int dispPartyY;


    /*-------------------- 
       isVisibleVram - 視線をさえぎるかどうか(VRAM)
       --------------------*/
    bool isVisibleVram( int x , int y )
    {
        switch( vram[ x ][ y ] )
        {
            case ' ':
            case '<':
            case '>':
            case '#':
                return true;
            case '-':
            case '|':
            case '+':
            case '=':
            case '^':
                return false;
            case '$':
                return party.isLight ;
            default:
                return false;
        }
    }

    /*-------------------- 
       isVisibleOrgMap - 視線をさえぎるかどうか(orgmap)
       --------------------*/
    bool isVisibleOrgMap( int x , int y )
    {
        switch( orgmap[ y ][ x ] )
        {
            case ' ':
            case '<':
            case '>':
            case '#':
            case '_':   // pit
                return true;
            case '-':
            case '|':
            case '+':
            case '=':
            case '*':
            case '^':
            case 'X':   // except 'X'
                return false;
            case '$':
                return party.isLight ;
            default:
                if( orgmap[ y ][ x ] >= 'a' && orgmap[ y ][ x ] <= 'z' )
                    return true;
                else if( orgmap[ y ][ x ] >= 'A' && orgmap[ y ][ x ] <= 'Z' )   // except 'X'
                    return true;
                else if( orgmap[ y ][ x ] >= '0' && orgmap[ y ][ x ] <= '9' )
                    return true;
                else
                    return false;
        }
    }


public:

    @property int width(){ return mapWidth; }
    @property int height(){ return mapHeight; }

    /**--------------------
       this - コンストラクタ
       --------------------*/
    this( int l )
    {
        layer = l; // 1 - xx

        mapmsg = new MapTextarea( MAPMSG_X_SIZ , MAPMSG_Y_SIZ );

        return;
    }

    /**--------------------
       testOutputEncountRoom - TEST用
       --------------------*/
    void testOutputEncountRoom()
    {
        for( int y = 0 ; y < mapHeight ; y++ )
        {
            for( int x = 0 ; x < mapWidth ; x++ )
            {
                if( encountRoom.isEncount( y , x ) )
                    writef( "X" );
                else
                    writef( "." );
            }
            writef( "\n" );
        }
        writef( "\n" );
        return;
    }

    /**--------------------
       initalize - 初期化
       --------------------*/
    bool initialize()
    {

        // イベントクラス
        event = new Event( layer );

        // read file
        if( ! readMap() )
        {
            printf( "\ncannot read map layer %d file\n" , layer  );
            return false;
        }

        return true;
    }


    /*--------------------
       setStartPos - パーティを登り階段位置に
       --------------------*/
    void setStartPos()
    {
        party.x = startX;
        party.y = startY;
        setDispPos;
        return;
    }

    /*--------------------
       setEndPos - パーティを下り階段位置に
       --------------------*/
    void setEndPos()
    {
        party.x = endX;
        party.y = endY;
        setDispPos;
        return;
    }

    /*--------------------
       setDispPos - 画面スクロール用座標設定
       --------------------*/
    void setDispPos()
    {
        dispPartyX = SCRW_X_SIZ / 2;
        dispPartyY = SCRW_Y_SIZ / 2;
        dispScrX = party.x - dispPartyX;
        dispScrY = party.y - dispPartyY;
        return;
    }


    /**--------------------
       readMap - マップ情報読み込み（フロア別）
       --------------------*/
    bool readMap()
    {

        char c;
        char _c;
        int enc_cnt;
        bool encountFlg;

        string[] line;

        auto fin = File( formatText( ORGMAPFILE , fill0( layer , 2 ) ) , "r" );
        // writef( "initializing... %s\n", formatText( ORGMAPFILE , fill0( layer , 2 ) ) );

        foreach( s ; fin.byLine )
        {
            line.length++;
            line.back = to!string ( s );
        }

        // 初期化
        mapWidth = to!int( line[ 0 ].length );
        mapHeight = to!int( line.length );
        map    = new char[][]( mapHeight , mapWidth );
        orgmap = new char[][]( mapHeight , mapWidth );
        for ( int y = 0 ; y < mapHeight ; y++ )
            for( int x = 0 ; x < mapWidth ; x++ )
            {
                map[ y ][ x ] = '^';
                orgmap[ y ][ x ] = '.';
            }


        // 初期化(エンカウントエリア)
        encountRoom = new MapEncountRoom( mapWidth , mapHeight );


        foreach ( y , ln ; line )
        {
            if( y < mapHeight )
            {
                // map情報
                for( int x = 0 ; x < mapWidth ; x++ )
                {
                    /* writef( "map : x , %d / y , %d \n" , x , y ); */

                    encountFlg = false;
                    c = to!char( ln[ x .. x + 1 ] );

                    if( c == '<' )
                    {
                        startX = x;
                        startY = to!int( y );
                    }
                    else if( c == '>' )
                    {
                        endX = x; endY = to!int( y );
                    }
                    else if( c == '^' )
                    {   // pit
                        c = '_';
                    }
                    else if( c == '@' )
                    {
                        c = ' ';
                        encountFlg = true;
                    }
                    else if( c == '~' )
                    {   // pit
                        c = '_';
                        encountFlg = true;
                    }
                    else if( c == '&' )
                    {   // darkzone
                        c = '$';
                        encountFlg = true;
                    }
                    else if( ( c >= 'a' && c <= 'z' ) ||
                             ( ( c >= 'A' && c <= 'Z' ) && c != 'X' ) )
                    {   // event
                        enc_cnt = 0;
                        if( encountRoom.isEncount( to!int( y ) , x - 1 ) )
                            enc_cnt ++;
                        if( encountRoom.isEncount( to!int( y - 1 ) , x ) )
                            enc_cnt ++;

                        string _ln;
                        _ln = line[ y + 1 ];
                        _c = to!char( _ln[ x .. x + 1 ] );
                        if( _c == '@' || _c == '~' || _c == '&' )
                            enc_cnt ++;

                        _c = to!char( ln[ x + 1 .. x + 2 ] );
                        if( _c == '@' || _c == '~' || _c == '&' )
                            enc_cnt ++;

                        if( enc_cnt >= 2 )
                            encountFlg = true;

                    }

                    orgmap[ y ][ x ] = c;
                    encountRoom.setEncount( to!int( y ) , x , encountFlg );
                }
            }
        }

        if( ! exists( formatText( MAPFILE , fill0( layer , 2 ) ) ) )
        {
            for ( int y = 0; y < mapHeight; y++ )
                for ( int x = 0; x < mapWidth; x++ )
                    map[ y ][ x ] = '^';
        }
        else
        {
            auto fin2  = File( formatText( MAPFILE , fill0( layer , 2 ) ) ,"r");
            int y = 0;

            foreach( l ; fin2.byLine )
            {
                for( int x = 0 ; x < mapWidth ; x++ )
                    map[ y ][ x ] = to!char( l[ x .. x + 1 ] );
                y++;
            }
        }

        return true;

    }


    /**--------------------
       saveMap - マップ情報書き込み（フロア別）
       --------------------*/
    bool saveMap()
    {
        int x , y ;

        /* auto fout = File( ( MAPFILE ~ to!string( layer ) ) , "w" ); */
        auto fout = File( formatText( MAPFILE , fill0( layer , 2 ) ) , "w" );

        string line = "";
        for ( y = 0; y < mapHeight ; y++ )
        {

            for ( x = 0; x < mapWidth; x++ )
               line ~= map[ y ][ x ];

            fout.writef( line ~ "\n" );
            line = "";

        }

        return true;
    }


    /**--------------------
       upStairs - 上り階段チェック
       --------------------*/
    int upStairs()
        { return event.upStairs( orgmap[ party.y ][ party.x ] ); }

    /**--------------------
       downStairs - 下り階段チェック
       --------------------*/
    int downStairs()
        { return event.downStairs( orgmap[ party.y ][ party.x ] ); }

    /**--------------------
       checkEvent - 移動後のイベントチェック
       --------------------*/
    int checkEvent()
    {

        int ret;
        ret = event.checkEvent( orgmap[ party.y ][ party.x ] );
        if( ret != 0 )
            return ret;

        return checkEncounterArea;

    }

    /**--------------------
       encounter - 移動後のエンカウントチェック
       t = TRE gold / treasure / alarm
       --------------------*/
    BATTLE_RESULT encounter( int t )
    {
        assert( t == TRE.GOLD || t == TRE.TREASURE || t == TRE.ALARM );
        return event.encounter( cast( TRE ) t );
    }

    /**--------------------
       resetEventFlg - イベントフラグ リセット
       --------------------*/
    void resetEventFlg()
    {
        event.resetFlg;
        return;
    }

    /**--------------------
       resetEncounterArea - エンカウントエリア リセット
       --------------------*/
    void resetEncounterArea()
    {
        encountRoom.reset;
        return;
    }

    /**--------------------
       checkEncounter - エンカウントエリアチェック
       --------------------*/
    int checkEncounterArea()
    {


        /+
        /////////////////////////
        // debug 用 
        if( party.x > -99 )
            return 0;
        /////////////////////////
        +/

        bool encount;
        int dx , dy;

        bool checkEncount( int _y , int _x )
        {
            if( party.x + _x < 0 ) return false;
            if( party.y + _y < 0 ) return false;
            if( party.x + _x >= mapWidth ) return false;
            if( party.y + _y >= mapHeight ) return false;

            return encountRoom.isEncount( party.y + _y , party.x + _x );
        }

        encount = false;
        while( true )
        {
            dy = 0;
            dx = 0;
            encount = checkEncount( dy , dx );
            if( encount )
                break;

            dy = 1;
            dx = 0;
            encount = checkEncount( dy , dx );
            if( encount )
                break;

            dy = -1;
            dx = 0;
            encount = checkEncount( dy , dx );
            if( encount )
                break;
            
            dy = 0;
            dx = 1;
            encount = checkEncount( dy , dx );
            if( encount )
                break;

            dy = 0;
            dx = -1;
            encount = checkEncount( dy , dx );
            if( encount )
                break;

            break;
        }


        if( encount )
        {
            if ( get_rand( 9 ) > 0 )
            {   // encount
                if ( event.encounter( TRE.TREASURE ) == 2 ) // ran
                {
                    // encounter *undone*
                }
                else
                {
                    encountRoom.clear( party.y + dy , party.x + dx );     // encount done
                }    
                return 1;
            }
            else
            {   // not encount
                encountRoom.clear( party.y + dy , party.x + dx );     // encount done
            }
        }
        return 0;

    }

    /*--------------------
       convertRelativePositionX - spell Map用
       --------------------*/
    int convertRelativePositionX( int x )
    {
        return x - mapWidth / 2;
    }

    /*--------------------
       convertRelativePositionY - spell Map用
       --------------------*/
    int convertRelativePositionY( int y )
    {
        return y - mapHeight / 2;
    }

    /*--------------------
       convertAbsolutePositionX - spell teleport用
       --------------------*/
    int convertAbsolutePositionX( int x )
    {
        return x + mapWidth / 2;
    }

    /*--------------------
       convertAbsolutePositionY - spell teleport用
       --------------------*/
    int convertAbsolutePositionY( int y )
    {
        return y + mapHeight / 2;
    }

    /*--------------------
       getMapTile - マップ取得
       --------------------*/
    char getMapTile( int y , int x )
    {
        return map[ y ][ x ];
    }

    /*--------------------
       isPassable - 通行可能？
       --------------------*/
    bool isPassable( int y , int x ,  bool doorFlg = false )
    {
        char c = map[ y ][ x ];

        if( ( c >= 'a' && c <= 'z' )
         || ( c != 'X' && ( c >= 'A' && c <= 'Z' ) )
         || ( c >= '0' && c <= '9' ) )
            return true;

        if ( c == '<' 
          || c == '>' 
          || c == '$' 
          || c == '#' 
          || c == ' ' 
          || c == '_'
          || ( c == '+' && doorFlg ) )
            return true;
        else
            return false;
    }

    /*--------------------
       isPassableOrgmap - 通行可能？
       --------------------*/
    bool isPassableOrgmap( int y , int x ,  bool doorFlg = false )
    {
        char c = orgmap[ y ][ x ];

        if( ( c >= 'a' && c <= 'z' )
         || ( c != 'X' && ( c >= 'A' && c <= 'Z' ) )
         || ( c >= '0' && c <= '9' ) )
            return true;

        if ( c == '<' 
          || c == '>' 
          || c == '$' 
          || c == '#' 
          || c == ' ' 
          || c == '_'
          || ( c == '+' && doorFlg ) )
            return true;
        else
            return false;
    }

    /*--------------------
       isPit - 落とし穴？
       --------------------*/
    bool isPit()
    {
        return ( orgmap[ party.y ][ party.x ] == '_' );
    }

    /*--------------------
       checkInRock - 岩の中？
       --------------------*/
    bool checkInRock()
    {

        if( ! checkMapRange( party.x , party.y ) )
            return true;

        char c = orgmap[ party.y ][ party.x ];
        return ( ( c == '-' || c == '|' || c == 'X' || c == '.' ) && ! debugmode );
    }

    /*--------------------
       unlockDoor - ドア開錠チェック
       --------------------*/
    bool unlockDoor()
    {
        int level = 0;
        int ratio = 0;
        char c;
        int dx,dy;

        foreach( p ; party )
        {
            if ( p.Class == CLS.THI && p.level > level )
                level = p.level;
        }
        ratio = ( level - party.layer ) * 10;

        if (ratio < 0)
            ratio = 0;

        mapmsg.textoutNow( _( "\nunlock door. which side? " ) );
        c = getChar();

        if ( c=='h' || c=='4' ) 
        {
            dx = -1;
            dy = 0;
        }
        else if (c == 'j' || c == '2')
        {
            dx = 0;
            dy = 1;
        }
        else if  ( c == 'k' || c == '8' )
        {
            dx = 0;
            dy = -1;
        }
        else if  (c == 'l' || c == '6')
        {
            dx = 1;
            dy = 0;
        }

        if( orgmap[ party.y + dy ][ party.x + dx ] != '=' )
        {
            mapmsg.textoutNow( _( "\nwhat ?" ) );
            getChar;
            return false;
        }

        if ( ratio == 0 )
        {
            mapmsg.textoutNow( _( "\ntoo complicated!" ) );
            getChar;
            return false;
        }

        if( get_rand( 99 ) + 1 < ratio )
        {
            map[ party.y + dy ][ party.x + dx ] = '+';
            disp;
            return true;
        }

        return false;

    }

    /*--------------------
       searchMember - 他プレイヤー探索
       --------------------*/
    void searchMember()
    {
        string discover = "";
        char c;

        void searchMemberDisp( bool firstflg )
        {
            int i , j;
            int flg;
            discover = "";
            for ( i = 0; i < MAXMEMBER; i++ )
            {
                if ( member[ i ].outflag == OUT_F.DUNGEON 
                        && member[ i ].layer == party.layer )
                {
                    // 既にパーティ内にいる
                    flg = false;
                    foreach( p ; party )
                        if ( p is member[ i ] )
                        {
                            flg = true;
                            break;
                        }
                    if( flg ) continue;

                    // 近くにいないと見つからない
                    if( ( abs( party.x - member[ i ].x ) > CORPSE_X_RANGE )
                     || ( abs( party.y - member[ i ].y ) > CORPSE_Y_RANGE ) )
                        continue;

                    // 視界にいないと見つからない
                    if( ! checkViewOrgMap( party.x , party.y , member[ i ].x , member[ i ].y ) )
                        continue;

                    if( firstflg && discover == "" )
                        txtMessage.clear;

                    c = to!char( 'a' + i );
                    discover ~= c;

                    member[ i ].setStatusColor;
                    txtMessage.textout( c );
                    txtMessage.textout( ")" ~ member[ i ].name );
                    txtMessage.textout( "\n" );
                    setColor( CL.NORMAL );
                    if( firstflg )
                        getChar();
                }
            }
            return;
        }

        searchMemberDisp( true );

        if ( discover.length == 0 )
            return;

        while ( party.memCount < 6 )
        {
            txtMessage.textout( _( "who do you want to pick(z:leave(9))? " ) );
            while ( true )
            {
                c = getChar();
                if ( c == 'z' || c == '9' )
                    break;
                if( indexOf( discover , c ) >= 0 )
                {
                    txtMessage.textout( c );
                    txtMessage.textout( '\n' );
                    member[ c - 'a' ].layer = 99;
                    party.add( member[ c - 'a' ] );
                    party.dispPartyWindow();

                    searchMemberDisp( false );
                    break;
                }
            }
            if ( c == 'z' || c == '9' )
                break;
        }
        txtMessage.textout( "done.\n" );

        return;
    }


    /*--------------------
       searchHiddenDoor - 隠し扉探索
       --------------------*/
    void searchHiddenDoor()
    {
        void searchHiddenDoorSub( int dy , int dx )
        {
            if ( orgmap[ party.y + dy ][ party.x + dx ] == '*' )
            {
                mapmsg.textoutNow( _( "\nyou found a hidden door!" ) );
                /* orgmap[ party.y + dy ][ party.x + dx ] = '+'; */
                map[ party.y + dy ][ party.x + dx ] = '+';
            }
            return;
        }

        searchHiddenDoorSub( 0 ,  1 );
        searchHiddenDoorSub( 0 , -1 );
        searchHiddenDoorSub(  1 , 0 );
        searchHiddenDoorSub( -1 , 0 );
        disp();

        return;

    }


    /*====== scroll window ===========================================*/
    /*--------------------
       initDisp - 画面初期化
       --------------------*/
    void initDisp()
    {
        int x,y;
      
        for ( y = 0; y < SCRW_Y_SIZ; y++ )
            for ( x = 0; x < SCRW_X_SIZ - 1; x++ )
            {
                vram[ x ][ y ] = 0;
                vramCl[ x ][ y ] = 0;
            }

        return;
    }

    /*--------------------
       clear - 表示初期化
       --------------------*/
    void clear()
    {
        int x, y , i;
        string spc;
        
        for( x = SCRW_X_TOP ; x < SCRW_X_SIZ ; x++ )
            spc ~= " ";

        rewriteOff;
        for( y = SCRW_Y_TOP ; y < SCRW_Y_TOP ; y++ )
            mvprintw( y, x , spc );
        rewriteOn;

        return;
    }

    /*--------------------
       textout - マップ用メッセージ設定
       --------------------*/
    void textout( string msg )
    {
        mapmsg.textout( msg );
        return;
    }

    void textoutNow( string msg )
    {
        mapmsg.textoutNow( msg );
        return;
    }

    void textoutOff()
    {
        mapmsg.count = 0;
        return;
    }

    void dispInRock()
    {

        rewriteOff; 

        setColor( MAP_CL.NUL );
        for ( int y = 0; y < SCRW_Y_SIZ ; y++ )     // 15
            for ( int x = 0; x < SCRW_X_SIZ - 1 ; x++ )       // 29
                mvprintw( y + SCRW_Y_TOP, x + SCRW_X_TOP, '^' );

        // プレイヤー表示
        setColor( MAP_CL.PARTY );
        mvprintw( SCRW_Y_TOP + SCRW_Y_SIZ / 2 , SCRW_X_TOP + SCRW_X_SIZ / 2 , '@' );
        setColor( CL.NORMAL );

        // ヘッダ情報表示
        dispHeader( now_mode );

        rewriteOn;
        return;
    }

    /*--------------------
       disp - マップ表示
       --------------------*/
    void disp( bool txtMessageDispFlg = false )
    {

        int x,y;
        int xmin,ymin;
        int xmax,ymax;
        char c;
        

        // in rock
        if ( party.layer < 1 || party.layer >= MAXLAYER 
                || ! party.dungeon.checkMapRange( party.x , party.y ) )
        {
            dispInRock;
            return;
        }

        // scroll check
        dispPartyX = party.x - dispScrX;
        dispPartyY = party.y - dispScrY;
        if( dispPartyX < SCR_X_MARGIN )
        {
            dispScrX --;
            dispPartyX ++; 
        }
        else if( SCRW_X_SIZ - dispPartyX - 2 < SCR_X_MARGIN )
        {
            dispScrX ++;
            dispPartyX --; 
        }

        if( dispPartyY < SCR_Y_MARGIN )
        {
            dispScrY --;
            dispPartyY++; 
        }
        else if( SCRW_Y_SIZ - dispPartyY - 1 < SCR_Y_MARGIN )
        {
            dispScrY ++;
            dispPartyY --; 
        }


        rewriteOff;
      
        // ( orgmap -> map )
        // set map data 

        if ( party.x - SCRW_X_SIZ / 2 < 0 )    // -2 ??? -> 78
            xmin = 0;
        else
            xmin = party.x - SCRW_X_SIZ / 2;

        if ( party.x + SCRW_X_SIZ / 2 > mapWidth - 2 )    // -2 ??? -> 78
            xmax = mapWidth - 2;
        else
            xmax = party.x + SCRW_X_SIZ / 2;


        if ( party.y - SCRW_Y_SIZ / 2 < 0 )
            ymin = 0;
        else
            ymin = party.y - SCRW_Y_SIZ / 2;

        if ( party.y + SCRW_Y_SIZ / 2 > mapHeight - 1 )
            ymax = mapHeight - 1;
        else
            ymax = party.y + SCRW_Y_SIZ / 2;

        for ( y = ymin ; y <= ymax ; y++ )
            for (x = xmin ; x <= xmax ; x++)
            {
                if ( map[ y ][ x ] == '^' )
                {
                    if( orgmap[ y ][ x ] == '.' )
                        continue;

                    if( ! checkViewOrgMap( party.x , party.y , x , y ) )
                        continue;

                    c = orgmap[ y ][ x ];

                    if (c == '*' && ! debugmode )  // secret door
                    {
                        if ( orgmap[ y ][ x - 1 ] == 'X' 
                          || orgmap[ y ][ x + 1 ] == 'X' )
                            c = 'X';
                        else if ( isPassableOrgmap( y , x - 1 )
                               || isPassableOrgmap( y , x + 1 ) )
                            c = '|';
                        else
                            c = '-';
                    }
                    map[ y ][ x ] = c;
                }
            }


        // ( map -> vram )
        /* virtual vram make */
        int _x , _y;
        for ( y = 0; y < SCRW_Y_SIZ; y++ )
            for ( x = 0; x < SCRW_X_SIZ - 1 ; x++ )
            {

                if( ! checkMapRange( dispScrX + x , dispScrY + y ) )
                {
                    vram[ x ][ y ] = '^';
                    continue;
                }
                else
                {

                    if( orgmap[ party.y ][ party.x ] == '$' )  
                    { 
                        /* if( ! party.isLight && ! party.isScope  ) */
                        if( ! party.isLight )
                        {
                            vram[ x ][ y ] = '^';
                            continue;
                        }
                    }

                    /* c = map[ party.y - ( SCRW_Y_SIZ / 2 ) + y ] */
                    /*        [ party.x - ( SCRW_X_SIZ / 2 ) + x + 1 ]; */
                    c = map[ dispScrY + y ][ dispScrX + x ];

                    if (c == '_' && ! debugmode )  // pit
                        c = ' ';

                    if ( ( c >= 'a' && c <= 'z' ) && ! debugmode )
                        c = '#';
                    if ( ( c != 'X' && ( c >= 'A' && c <= 'Z' ) ) && ! debugmode )
                        c = '#';
                    if ( ( c >= '0' && c <= '9' ) && ! debugmode )
                        c = '#';

                    vram[ x ][ y ] = c;

                }
            }

        /* set light */
        for ( y = 0; y < SCRW_Y_SIZ ; y++ )             // 15
            for ( x = 0; x < SCRW_X_SIZ - 1 ; x++ )     // 29
            {

                if( vram[ x ][ y ] == '^' ) 
                {
                    vramCl[ x ][ y ] = MAP_CL.NUL;
                    continue;
                }

                // 可視チェック
                if( ! checkViewVram( dispPartyX , dispPartyY , x , y ) )
                {
                    if( party.isMapper )
                    {
                        vramCl[ x ][ y ] = MAP_CL.NUL;
                        continue;
                    }
                    else
                    {
                        vram[ x ][ y ] = '^';
                        vramCl[ x ][ y ] = MAP_CL.NUL;
                        continue;
                    }
                }

                switch( vram[ x ][ y ] )
                {
                    case '-':
                    case '|':
                        vramCl[ x ][ y ] = MAP_CL.WALL;
                        break;
                    case 'X':
                        vramCl[ x ][ y ] = MAP_CL.WALL2;
                        break;
                    case '$':
                        vramCl[ x ][ y ] = MAP_CL.DARKZONE;
                        break;
                    case '+':
                    case '=':
                        vramCl[ x ][ y ] = MAP_CL.DOOR;
                        break;
                    case '>':
                    case '<':
                        vramCl[ x ][ y ] = MAP_CL.STAIRS;
                        break;
                    case '#':
                        vramCl[ x ][ y ] = MAP_CL.NUL;
                        break;
                    default:
                        vramCl[ x ][ y ] = CL.NORMAL;
                        break;
                }
            }

      
        // ( vram -> screen )
        /*  disp */
        int tmp = -1;
        for ( y = 0; y < SCRW_Y_SIZ ; y++ )     // 15
            for ( x = 0; x < SCRW_X_SIZ - 1 ; x++ )       // 29
            {
                if( tmp != vramCl[ x ][ y ] )
                {
                    tmp = vramCl[ x ][ y ];
                    setColor( tmp );
                }
                mvprintw( y + SCRW_Y_TOP, x + SCRW_X_TOP, vram[ x ][ y ] );
            }

        // プレイヤー表示
        int color = MAP_CL.PARTY;
        setColor( color );
        /* mvprintw( SCRW_Y_TOP + SCRW_Y_SIZ / 2, SCRW_X_TOP + SCRW_X_SIZ / 2 - 1 , '@' ); */
        mvprintw( SCRW_Y_TOP + dispPartyY , SCRW_X_TOP + dispPartyX , '@' );
        setColor( CL.NORMAL );


        // マップ用メッセージ表示
        mapmsg.disp( dispPartyX , dispPartyY );

        // 通常メッセージ表示
        if( txtMessageDispFlg )
            txtMessage.disp;

        // ヘッダ情報表示
        dispHeader( now_mode );

        rewriteOn;

        return;
    }


    /+ 
       視界の確認（全体マップ）
    +/   
    bool checkViewOrgMap( int mx , int my , int x , int y )
    {
        if( checkView( mx , my , x , y , &isVisibleOrgMap ) )
            return true;

        int _x = ( x > mx ) ? -1 : 1; 
        int _y = ( y > my ) ? -1 : 1; 

        // 再チェック（x）
        if( ( isVisibleOrgMap( x + _x , y ) ) 
                && ( checkView( mx , my , x + _x , y , &isVisibleOrgMap ) ) )
            return true;

        // 再チェック（y）
        if( ( isVisibleOrgMap( x , y + _y ) ) 
                && ( checkView( mx , my , x , y + _y , &isVisibleOrgMap ) ) )
            return true;

        // 再チェック（x,y）
        if( ( isVisibleOrgMap( x + _x , y + _y ) ) 
                && ( checkView( mx , my , x + _x , y + _y , &isVisibleOrgMap ) ) )
            return true;

        return false;

    }


    /+ 
       視界の確認（Vram上）
       角が見えなくなるので、複数回チェック
    +/   
    bool checkViewVram( int mx , int my , int x , int y )
    {

        if( checkView( mx , my , x , y , &isVisibleVram ) )
            return true;

        int _x = ( x > mx ) ? -1 : 1; 
        int _y = ( y > my ) ? -1 : 1; 

        // 再チェック（x）
        if( ( isVisibleVram( x + _x , y ) ) 
                && ( checkView( mx , my , x + _x , y , &isVisibleVram ) ) )
            return true;

        // 再チェック（y）
        if( ( isVisibleVram( x , y + _y ) ) 
                && ( checkView( mx , my , x , y + _y , &isVisibleVram ) ) )
            return true;

        // 再チェック（x,y）
        if( ( isVisibleVram( x + _x , y + _y ) ) 
                && ( checkView( mx , my , x + _x , y + _y , &isVisibleVram ) ) )
            return true;

        return false;

    }



    /+ 
       視界の確認
            ( x1 , y1 ) 自分の位置
            ( x2 , y2 ) チェックする座標
       (x1,y1) と (x2,y2) の直線上の視界を確認
       直線上に遮るものがなければ直線上すべてのマスがＯＫ 
    +/   
    bool checkView( int x1 , int y1 , int x2 , int y2 , bool delegate( int , int ) isVisible )
    {

        int x = x1;
        int y = y1;  

        int dx = ( x2 > x1 ) ? ( x2 - x1) : ( x1 - x2 );
        int dy = ( y2 > y1 ) ? ( y2 - y1) : ( y1 - y2 );
        int sx = ( x2 > x1 ) ? 1 : -1 ;
        int sy = ( y2 > y1 ) ? 1 : -1 ;

        int e;  // 誤差


        // dx が大きい場合
        if ( dx >= dy ) 
        {

            e = 2 * dy - dx;

            for( int i = 0 ; i < dx ; i++ ) 
            {   
                // 障害物確認・自位置はＯＫ
                if( ! ( ( x1 == x ) && ( y1 == y ) ) 
                        && ! isVisible( x , y ) )
                    // NGだったら処理を抜ける
                    return false;
           
                x += sx;
                e += 2 * dy;
                if (e >= 0 ) 
                {
                    y += sy;
                    e -= 2 * dx;
                }
            }
        }
        else
        // dy が大きい場合
        {

            e = 2 * dx - dy;

            for( int i = 0 ; i < dy ; i++ ) 
            {
                // 障害物確認・自位置はＯＫ
                if( ! ( ( x1 == x ) && ( y1 == y ) ) 
                        && ! isVisible( x , y ) )
                    // NGだったら処理を抜ける
                    return false;
           
                y += sy;
                e += 2 * dx;
                if (e >= 0) 
                {
                    x += sx;
                    e -= 2 * dy;
                }
            }
        }
        
        return true;

    }

    /+
        マップ範囲内かどうかチェック
        +/
    bool checkMapRange( int x , int y )
    {
        if ( x < 0 
          || x >= mapWidth
          || y < 0
          || y >= mapHeight )
            return false;
        else
            return true;
                        
    }

}

