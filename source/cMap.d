// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.file;
import std.conv;
import std.string : format , split , chop , indexOf ;
import std.math : abs ;
import std.ascii : toLower ;

// mysource 
import cParty;
import cMember;
import cEvent;

import cMapEncountRoom;


import def;
import app;

/* import lib_sdl; */


class Map
{

private:
    int layer;
    Event event;

    char[ MAP_MAX_X ][ MAP_MAX_Y ] map;
    char[ MAP_MAX_X ][ MAP_MAX_Y ] orgmap;
    MapEncountRoom encountRoom;

    int startX , startY;
    int endX , endY;

    /* char vram1[ 29 * 15 ]; */
    char[ SCRW_Y_SIZ ][ ( SCRW_X_SIZ - 1 ) ] vram;
    int [ SCRW_Y_SIZ ][ ( SCRW_X_SIZ - 1 ) ] vramCl;


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
                return true;
            case '-':
            case '|':
            case '+':
            case '=':
            case '^':
                return false;
            case '$':
                return party.isShine ;
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
                return false;
            case '$':
                return party.isShine ;
            default:
                if( orgmap[ y ][ x ] >= 'a' && orgmap[ y ][ x ] <= 'z' )
                    return true;
                else
                    return false;
        }
    }


public:

    /**--------------------
       this - コンストラクタ
       --------------------*/
    this( int l )
    {
        layer = l + 1;  // 1 - 8
        return;
    }

    /**--------------------
       testOutputEncountRoom - TEST用
       --------------------*/
    void testOutputEncountRoom()
    {
        for( int y = 0 ; y < MAP_MAX_Y ; y++ )
        {
            for( int x = 0 ; x < MAP_MAX_X ; x++ )
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
        switch( layer )
        {
            case 1:
                event = new EventL1;
                break;
            case 2:
                event = new EventL2;
                break;
            case 3:
                event = new EventL3;
                break;
            case 4:
                event = new EventL4;
                break;
            case 5:
                event = new EventL5;
                break;
            case 6:
                event = new EventL6;
                break;
            case 7:
                event = new EventL7;
                break;
            case 8:
                event = new EventL8;
                break;
            default:
                assert( 0 );
        }

        // 初期化
        char* p1 = &map[ 0 ][ 0 ];
        char* p2 = &orgmap[ 0 ][ 0 ];
        for ( int i = 0; i < MAP_MAX_Y * MAP_MAX_X; i++ )
        {
            * p1++ = '^';
            * p2++ = '.';
        }

        // 初期化(エンカウントエリア)
        encountRoom = new MapEncountRoom;
                
        // read file
        if( ! readMap() )
        {
            printf("\ncannot read map layer %d file\n" , layer );
            return false;
        }

        return true;
    }


    /*--------------------
       setStartPos - パーティを登り階段位置に
       --------------------*/
    void setStartPos()
    {
        party.x = to!byte( startX );
        party.y = to!byte( startY );
        return;
    }

    /*--------------------
       setEndPos - パーティを下り階段位置に
       --------------------*/
    void setEndPos()
    {
        party.x = to!byte( endX );
        party.y = to!byte( endY );
        return;
    }


    /**--------------------
       readMap - マップ情報読み込み（フロア別）
       --------------------*/
    bool readMap()
    {

        int y = 0;
        char c;
        bool encountFlg;

        auto fin  = File( ORGMAPFILE ~ to!string( layer ) ,"r");
        y = 0;
        foreach ( line ; fin.byLine )
        {

            if( y < MAP_MAX_Y )
            {
                // map情報
                for( int x = 0 ; x < MAP_MAX_X ; x++ )
                {
                    encountFlg = false;
                    c = to!char( line[ x .. x + 1 ] );
                    if( c == '<' )
                    {
                        startX = x;
                        startY = y;
                    }
                    else if( c == '>' )
                    {
                        endX = x;
                        endY = y;
                    }
                    else if( c == '@' )
                    {
                        c = ' ';
                        encountFlg = true;
                    }
                    else if( ( c >= 'A' && c <= 'Z' ) && c != 'X' )
                    {   // event
                        c = toLower( c ); 
                        encountFlg = true;
                    }
                    else if( c == '^' )
                    {   // pit
                        c = '_';
                        encountFlg = false;
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
                    orgmap[ y ][ x ] = c;
                    /* encountRoom[ y ][ x ].setEncount = encountFlg; */
                    encountRoom.setEncount( y , x , encountFlg );
                }
            }
            y++;
        }

        if( ! exists( MAPFILE ~ to!string( layer ) ) )
        {
            writef( "initializing... %s%d\n", MAPFILE , layer );
            for (y = 0; y < MAP_MAX_Y; y++)
                for (int x = 0; x < MAP_MAX_X; x++)
                    map[ y ][ x ] = '^';
        }
        else
        {
            auto fin2  = File( MAPFILE ~ to!string( layer ) ,"r");
            y = 0;
            foreach ( line; fin2.byLine )
            {
                for( int x = 0 ; x < MAP_MAX_X ; x++ )
                    map[ y ][ x ] = to!char( line[ x .. x + 1 ] );
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

        auto fout = File( ( MAPFILE ~ to!string( layer ) ) , "w" );

        string line = "";
        for ( y = 0; y < MAP_MAX_Y ; y++ )
        {

            for ( x = 0; x < MAP_MAX_X; x++ )
               line ~= map[ y ][ x ];

            fout.writef( line ~ "\n" );
            line = "";

        }

        return true;
    }


    /**--------------------
       event_chk - 移動後のイベントチェック
       --------------------*/
    int event_chk()
    {

        int ret;
        ret = event.event_chk( orgmap[ party.y ][ party.x ] );
        if( ret != 0 )
            return ret;

        return checkEncounterArea;

    }

    /**--------------------
       encounter - 移動後のイベントチェック
       t = TRE gold / treauser / alarm
       --------------------*/
    int encounter( int t )
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

        bool encount;
        int dx , dy;

        bool checkEncount( int _y , int _x )
        {
            if( party.x + _x < 0 ) return false;
            if( party.y + _y < 0 ) return false;
            if( party.x + _x >= MAP_MAX_X ) return false;
            if( party.y + _y >= MAP_MAX_Y ) return false;

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
       isPassable - 通行可能？
       --------------------*/
    bool isPassable( int y , int x ,  bool doorFlg = false )
    {
        char c = map[ y ][ x ];

        if( c >= 'a' && c <= 'z' )
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

        for ( int i = 0; i < party.num; i++ )
        {
            if ( party.mem[ i ].Class == CLS.THI 
                    && party.mem[ i ].level > level )
                level = party.mem[ i ].level;
        }
        ratio = ( level - party.layer ) * 10;

        if (ratio < 0)
            ratio = 0;

        textout( "unlock door.\nwhich side? " );
        c = getChar();
        textout( c );
        textout( '\n' );

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

        if( orgmap[ party.y + dy ][ party.x - dx ] != '=' )
        {
            textout( "what ?\n" );
            return false;
        }

        if ( ratio == 0 )
        {
            textout( "locks around here is too complicated!\n" );
            return false;
        }

        if( get_rand( 99 ) + 1 < ratio )
        {
            map[ party.y + dy ][ party.x - dx ] = '+';
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
            discover = "";
            for ( i = 0; i < MAXMEMBER; i++ )
            {
                if ( member[ i ].outflag == OUT_F.DUNGEON 
                        && member[ i ].layer == party.layer )
                {

                    if( abs( party.x - member[ i ].x ) > 2 
                     || abs( party.y - member[ i ].y ) > 2 ) 
                        continue;

                    if( ! checkViewOrgMap( party.x , party.y , member[ i ].x , member[ i ].y ) )
                        continue;

                    for ( j = 0; j < party.num; j++ )
                        if ( party.mem[ j ] is member[ i ] )
                            break;
                    if ( j != party.num )
                        continue;

                    c = to!char( 'a' + i );
                    discover ~= c;

                    textout( c );
                    textout( ")" ~ member[ i ].name );
                    textout( "\n" );
                    if( firstflg )
                        getChar();
                }
            }
            return;
        }

        searchMemberDisp( true );

        if ( discover.length == 0 )
            return;

        while ( party.num < 6 )
        {
            textout( "who do you want to pick(z:leave(9))? " );
            while ( true )
            {
                c = getChar();
                if ( c == 'z' || c == '9' )
                    break;
                if( indexOf( discover , c ) >= 0 )
                {
                    textout( c );
                    textout( '\n' );
                    member[ c - 'a' ].layer = 99;
                    party.mem[ party.num ] =  member[ c - 'a' ];
                    party.num++;
                    party.win_disp();

                    searchMemberDisp( false );
                    break;
                }
            }
            if ( c == 'z' || c == '9' )
                break;
        }
        textout( "done.\n" );

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
                textout( "you found a hidden door!\n" );
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
       disp - マップ表示
       --------------------*/
    void disp()
    {

        int x,y;
        int xmax,ymax;
        int viewarea;
        char c;
        

        rewriteOff;
      
        /* if (debugmode == 1  */
        /*         && (keycode == 'H' || keycode == 'J' || keycode == 'K' || keycode == 'L')) */
        /*     viewarea = 16; */
        
        if( party.isLight )
            viewarea = 2;
        else
            viewarea = 1;
      

        if ( party.y + viewarea > MAP_MAX_Y - 1 )
            ymax = MAP_MAX_Y - 1;
        else
            ymax = party.y + viewarea;

        if ( party.x + viewarea > MAP_MAX_X - 2 )    // -2 ??? -> 78
            xmax = MAP_MAX_X - 2;
        else
            xmax = party.x + viewarea;
      

        // set map data
        for ( y = party.y - viewarea; y <= ymax; y++ )
        {
            if (y < 0)
                y = 0;
            for (x = party.x - viewarea; x <= xmax; x++)
            {
                if (x < 0)
                    x = 0;
                if ( map[ y ][ x ] == '^' )
                {
                    if( viewarea != 1 )
                        if( ! checkViewOrgMap( party.x , party.y , x , y ) )
                            continue;

                    c = orgmap[ y ][ x ];

                    if (c == '*' && ! debugmode )  // secret door
                    {
                        if ( orgmap[ y ][ x - 1 ] == ' ' 
                          || orgmap[ y ][ x + 1 ] == ' ' )
                            c = '|';
                        else
                            c = '-';
                    }
                    map[ y ][ x ] = c;
                }
            }
        }


        /* virtual vram make */
        int _x , _y;
        for ( y = 0; y < SCRW_Y_SIZ; y++ )
        {
            for ( x = 0; x < SCRW_X_SIZ - 1 ; x++ )
            {
                if ( party.x - SCRW_X_SIZ / 2 + x + 1 < 0 
                  || party.x - SCRW_X_SIZ / 2 + x + 1 >= MAP_MAX_X
                  || party.y - SCRW_Y_SIZ / 2 + y < 0 
                  || party.y - SCRW_Y_SIZ / 2 + y >= MAP_MAX_Y 
                  || ( orgmap[ party.y ][ party.x ] == '$' 
                      && !party.isLight && !party.isShine ) ) 
                {
                    vram[ x ][ y ] = '^';
                    continue;
                }
                else
                {

                    if( orgmap[ party.y ][ party.x ] == '$' )  
                    {
                        if( party.isLight && !party.isShine )
                        {   // 3 x 3
                            _x = ( party.x - ( SCRW_X_SIZ / 2 ) + x + 1 );
                            _y = ( party.y - ( SCRW_Y_SIZ / 2 ) + y );
                            if( ( abs( party.x - _x ) > 1 ) 
                             || ( abs( party.y - _y ) > 1 ) )
                            {
                                vram[ x ][ y ] = '^';
                                continue;
                            }
                        }
                    }

                    c = map[ party.y - ( SCRW_Y_SIZ / 2 ) + y ]
                           [ party.x - ( SCRW_X_SIZ / 2 ) + x + 1 ];

                    if (c == '#' && ! debugmode )
                        c = ' ';

                    if (c == '_' && ! debugmode )  // pit
                        c = ' ';

                    /* if (c == '*' && ! debugmode )  // secret door */
                    /*     c = ' '; */

                    if ( ( c >= 'a' && c <= 'z' ) && ! debugmode )
                        c = ' ';

                    vram[ x ][ y ] = c;

                }
            }
        }

        int px = ( SCRW_X_TOP + SCRW_X_SIZ / 2 - 1 - 1 );
        int py = ( SCRW_Y_TOP + SCRW_Y_SIZ / 2 - 1 );

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
                if( ! checkViewVram( px , py , x , y ) )
                {
                    if( party.isLight )
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

                // 灯りチェック
                if( ( abs( px - x ) <= viewarea )
                 && ( abs( py - y ) <= viewarea ) )
                {
                    if( vram[ x ][ y ] == '$' )
                        vramCl[ x ][ y ] = MAP_CL.DARKZONE;
                    else if( vram[ x ][ y ] == '>' || vram[ x ][ y ] == '<' )
                        vramCl[ x ][ y ] = MAP_CL.STAIRS;
                    else
                        vramCl[ x ][ y ] = MAP_CL.LIGHT;
                    continue;
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
                    default:
                        vramCl[ x ][ y ] = CL.NORMAL;
                        break;
                }
            }

      
        /* scroll disp */
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

        setColor( MAP_CL.PARTY );
        mvprintw( SCRW_Y_TOP + SCRW_Y_SIZ / 2, SCRW_X_TOP + SCRW_X_SIZ / 2 - 1 , '@' );
        setColor( CL.NORMAL );

        header_disp( HSTS.DUNGEON );

        rewriteOn;

        return;
    }


    /+ 
       視界の確認（全体マップ）
    +/   
    bool checkViewOrgMap( int mx , int my , int x , int y )
    {
        return ( checkView( mx , my , x , y , &isVisibleOrgMap ) );
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

}

