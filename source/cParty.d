// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string : indexOf;
/* import std.file; */
/* import std.random; */

// derelict SDL
/* import derelict.sdl2.sdl; */

// mysource 
import def;
import app;

import cMember;
import cMap;
import cEvent;
import cItem;
/* import spell; */
/* import cItem; */

class Party
{

private:
    enum BIT_PARTY_STS_SHINE    = 0x08;
    enum BIT_PARTY_STS_MAPPER   = 0x10;
    enum BIT_PARTY_STS_LIGHT    = 0x20;
    enum BIT_PARTY_STS_FLOAT    = 0x40;
    enum BIT_PARTY_STS_IDENTIFY = 0x80;

    /*--------------------
       addMem_disp - 追加メンバーリスト表示
       --------------------*/
    void addMem_disp()
    {
        int i, j, disp_count;
        string name;
      
        scrwin_clear();
      
        rewriteOff;

        disp_count = 0;

        for ( i = 0; i < 20; i++ )
        {
            if ( member[ i ].name != "" && member[ i ].outflag == 0 )
            {

                for ( j = 0; j < num; j++ )
                    if ( mem[ j ] == member[ i ] )
                        break;

                if ( j != num )
                    continue;
                
                name = to!string( cast(char)( 'a' + i ) );
                name ~= ")";
                name ~= leftB( member[ i ].name , 14 );

                if ( disp_count % 2 == 0 )
                    mvprintw( SCRW_Y_TOP + 1 + ( disp_count / 2 ),  0, name ) ;
                else
                    mvprintw( SCRW_Y_TOP + 1 + ( disp_count / 2 ), 16, name ) ;

                disp_count ++;

            }
        }

        rewriteOn;
        
        return;

    }


public:
    Member[ 6 ] mem;
    Member[ 6 ] memsv;      // ?????
    Map dungeon;

    int step;
    byte x;
    byte y;
    byte layer; // 0:castle , 1-8:dungeon
    byte ox;
    byte oy;
    byte olayer;
    byte status;  // bit7:i, latumapic
                  // bit6:f, litofeit
                  // bit5:l, milwa/lomilwa
                  // bit4:p, mapper
                  // bit3:s, shine
    int lightCount;   // milwacnt
    int shineCount;
    byte num;
    byte actnum;
    byte ac;

    bool suprised;

    /*--------------------
       this - コンストラクタ
       --------------------*/
    this()
    {
        ox     = 1;
        oy     = 2;
        x      = 1;
        y      = 2;
        layer  = 0;
        olayer = 0;
        status = 0;
        num    = 0;
        actnum = 0;
        ac     = 0;
        for ( int i = 0 ; i < 6 ; i++ )
        {
            mem[ i ] = null;
            memsv[ i ] = null;
        }
        return;
    }

    /*--------------------
       setDungeon - ダンジョンセット
       --------------------*/
    void setDungeon()
    {
        if( layer == 0 )
        {
            dungeon = null;
        }
        else
        {
            dungeon = dungeonMap[ layer - 1 ];
            dungeon.resetEncounterArea;
            dungeon.resetEventFlg;
        }
        return;
    }


    bool isMapper()   { return ( ( status & BIT_PARTY_STS_MAPPER   ) != 0 ); }
    bool isFloat()    { return ( ( status & BIT_PARTY_STS_FLOAT    ) != 0 ); }
    bool isLight()    { return ( ( status & BIT_PARTY_STS_LIGHT    ) != 0 ); }
    bool isShine()    { return ( ( status & BIT_PARTY_STS_SHINE    ) != 0 ); }
    bool isIdentify() { return ( ( status & BIT_PARTY_STS_IDENTIFY ) != 0 ); }
    void setShine()    { status |= BIT_PARTY_STS_SHINE    ; }
    void setMapper()   { status |= BIT_PARTY_STS_MAPPER   ; }
    void setFloat()    { status |= BIT_PARTY_STS_FLOAT    ; }
    void setLight()    { status |= BIT_PARTY_STS_LIGHT    ; }
    void setIdentify() { status |= BIT_PARTY_STS_IDENTIFY ; }
    void resetShine()    { status ^= BIT_PARTY_STS_SHINE    ; }
    void resetMapper()   { status ^= BIT_PARTY_STS_MAPPER   ; }
    void resetFloat()    { status ^= BIT_PARTY_STS_FLOAT    ; }
    void resetLight()    { status ^= BIT_PARTY_STS_LIGHT    ; }
    void resetIdentify() { status ^= BIT_PARTY_STS_IDENTIFY ; }

    /*--------------------
       add - 最後尾にメンバー追加
       --------------------*/
    void add()
    {

        char keycode;

        if( num == 6 )
            return;

        addMem_disp();

        textout( "select members(a,b,... ,z:leave(9))\n" );
        while ( true )
        {
            keycode = getChar();
            if ( keycode == 'z' || keycode == '9' )
                break;
            if ( keycode >= 'a' && keycode <= 't'
                && member[ keycode - 'a' ].name != ""
                && member[ keycode - 'a' ].outflag == 0 )
            {

                mem[ num ]   =  member[ keycode - 'a' ];
                memsv[ num ] =  member[ keycode - 'a' ];
                num++;
                actnum++;

                member[ keycode - 'a' ].outflag = OUT_F.CASTLE;

                addMem_disp();
                win_disp_sub();
                if ( num == 6 )
                    break;
            }
        }

        win_disp();
        return;
    }

    /*--------------------
       remove - 指定したメンバーを外す
       --------------------*/
    void remove()
    {

        char keycode , c;

        if ( num == 0 )
            return;

        addMem_disp();
        textout( "remove who(z:leave(9))?\n" );

        while( true )
        {
            if ( num == 0)
                break;

            keycode = getChar();

            if ( keycode == 'z' || keycode == '9' )
                break;

            c = to!char( keycode - '1' );
            if ( ( c < 0 ) || ( c > 6 ) )
                break;

            if ( mem[ c ] is null )
                break;

            num--;
            actnum--;
            mem[ c ].outflag = OUT_F.BAR;
            mem[ c ] = null;

            for ( int i = c ; i < 5; i++ )
            {
                mem[ i ] = mem[ i + 1 ];
                memsv[ i ] = mem[ i + 1 ];
            }
            mem[ 5 ] = null;
            memsv[ 5 ] = null;

            addMem_disp();
            win_disp_sub();
        }

        return;
    }

    /*--------------------
       divvy - ゴールドを分ける
       --------------------*/
    void divvy()
    {
        int i;
        long sum , each;

        if( num == 0 )
            return;

        sum = 0;

        for( i = 0 ; i < num ; i++ )
            sum += mem[ i ].gold;
        each = sum / num;
        for( i = 0 ; i < num ; i++ )
        {
            mem[ i ].gold = each;
            sum -= each;
        }
        mem[ 0 ].gold = sum + each;

        return;
    }


    /*--------------------
       poolGold - ゴールドを集める
       no : 集めるメンバー 
       --------------------*/
    void poolGold( Member m )
    {
        int i;
        long poolgold = 0;

        for ( i = 0; i < num; i++ )
        {
            poolgold += mem[ i ].gold;
            mem[ i ].gold = 0;
        }
        m.gold = poolgold;
        textout( m.name ~ " has " );
        textout( poolgold );
        textout(" g.p.\n");

        return;
    }
    /*--------------------
       poolGold - ゴールドを集める
       no : 集めるメンバー 
       --------------------*/
    void poolGold( int no )
    {
        int i;
        long poolgold = 0;

        for ( i = 0; i < num; i++ )
        {
            poolgold += mem[ i ].gold;
            mem[ i ].gold = 0;
        }
        mem[ no ].gold = poolgold;
        textout( mem[ no ].name ~ " has " );
        textout( poolgold );
        textout(" g.p.\n");

        return;
    }


    /*--------------------
       win_disp - パーティウィンドウ表示
       --------------------*/
    /* void partywin_disp() */
    void win_disp( bool rewrite = true )
    {
        int color = getColor;
        setColor( CL.NORMAL );

        order();
        win_disp_sub( rewrite );

        setColor( color );
        return;
    }


    // partywin_disp without reordering
    void win_disp_noreorder()
    {
        int row;
        Member p;

        int color = getColor;
        setColor( CL.NORMAL );

        rewriteOff;

        for ( row = 0; row < num; row++ )
        {

            p = party.mem[ row ];

            if ( p.ac[ 0 ] + p.ac[ 1 ] >=  - 99 )
                mvIntDispD( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 25, p.ac[0] + p.ac[1] + party.ac, 3 );
            else
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 25, " VL" );
    
            mvprintw  ( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 29, "     " );
            mvIntDispD( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 29, p.hp, 5 );
            mvprintw  ( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 34, "/" );
            intDisp   ( p.maxhp );
    
            switch ( p.status )
            {
                case STS.OK:
                    if ( p.poisoned )
                        mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "poison");
                    else if ( p.silenced )
                        mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "silenc");
                    else
                        /* mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "ok    "); */
                        mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41
                                     , "lv." ~ intFormat( p.level , 3 ) );
                    break;
                case STS.SLEEP: 
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "sleep ");
                    break;
                case STS.AFRAID :
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "afraid");
                    break;
                case STS.PARALY :
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "pararz");
                    break;
                case STS.STONED : 
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "stoned");
                    break;
                case STS.DEAD:
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "dead  ");
                    break;
                case STS.ASHED:
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "ashed ");
                    break;
                case STS.LOST:
                    mvprintw(CHRW_Y_TOP + row + 1, CHRW_X_TOP + 41, "lost  ");
                    break;
                default:
                    assert( 0 );
            }
        }

        rewriteOn;

        setColor( color );
        return;
    }

    /*--------------------
       win_disp_sub - パーティウィンドウ表示
       --------------------*/
    /* void partywin_disp_sub() */
    void win_disp_sub( bool rewrite = true )
    {
        int i;
        calcAtkAC();

        rewriteOff;

        string spc = "                                                                              ";

        mvprintw( CHRW_Y_TOP , CHRW_X_TOP 
                , "# name             class  ac   hp /maxhp status action option" );
        for ( i = 0 ; i < 6 ; i++ )
        {
            if ( mem[ i ] is null || num <= i )
            {
                mvprintw( CHRW_Y_TOP + i + 1 , CHRW_X_TOP 
                        ,  to!string( i + 1 ) ~ spc );
                continue;
            }
            else
            {
                mem[ i ].dispStatusLine( i );
            }
        }

        if( rewrite )
            rewriteOn;

        return;
    }


    /*--------------------
       order - メンバー並び換え（表示用ステータス識別）
       --------------------*/
    void order()
    {
        int i;
        byte ok_cnt = 0 , ng_cnt = 0 , dead_cnt = 0;

        Member[ 6 ] ok;
        Member[ 6 ] ng;
        Member[ 6 ] dead;
      
        for ( i = 0 ; i < num ; i++ )
        {
            if( mem[ i ] is null )
                continue;

            if( mem[ i ].status <= STS.SLEEP )
            {
                ok[ ok_cnt ] = mem[i];
                ok_cnt ++;
            }
            else if( mem[ i ].status < STS.DEAD )
            {
                ng[ ng_cnt ] = mem[ i ];
                ng_cnt++;
            }
            else
            {
                dead[ dead_cnt ] = mem[i];
                dead_cnt++;
            }
        }

        int no = 0;
        for ( i = 0 ; i < ok_cnt ; i++ )
            mem[ no++ ] = ok[ i ];

        for ( i = 0 ; i < ng_cnt ; i++ )
            mem[ no++ ] = ng[ i ];

        for ( i = 0 ; i < dead_cnt ; i++ )
            mem[ no++ ] = dead[ i ];

        actnum = ok_cnt;

        return;
    }

    /*--------------------
       reorder - メンバー並び換え（キャンプ中）
       --------------------*/
    void reorder( Member m )
    {
        char ch;
        int i;
        Member[ 6 ] tmp;
        string order = "";

        bool reorder_sub( string step )
        {
            textout("who comes " ~ step ~ "(z:leave(9))? ");
            while ( true )
            {
                ch = getChar();
                if ( ch == 'z' || ch == '9' )
                {
                    textout( "leave\n" );
                    return false;
                }

                if (ch >= '1' && ch <= '0' + party.num )
                {
                    if( indexOf( order , ch ) >= 0 )
                        continue;

                    textout( ch );
                    textout( '\n' );
                    break;
                }
            }
            order ~= to!string( ch );
            return true;
        }



        if( ! reorder_sub( "first" ) )
            return;
        if ( party.num <= 1 )
            goto EXIT;

        if( ! reorder_sub( "second" ) )
            return;
        if ( party.num <= 2 )
            goto EXIT;

        if( ! reorder_sub( "third" ) )
            return;
        if ( party.num <= 3 )
            goto EXIT;

        if( ! reorder_sub( "fourth" ) )
            return;
        if ( party.num <= 4 )
            goto EXIT;

        if( ! reorder_sub( "fifth" ) )
            return;
        if ( party.num <= 5 )
            goto EXIT;

        if( ! reorder_sub( "sixth" ) )
            return;

    EXIT:
        for ( i = 0; i < 6; i++ )
          tmp[ i ] = party.mem[i];
        i = 0;
        foreach( char o ; order )
            party.mem[ i++ ] = tmp[ o - '1' ];

        party.win_disp();

        m.inspect();

        return;
    }


    /*--------------------
       calcAtkAC - AC 計算
       --------------------*/
    void calcAtkAC()
    {
        int i;

        for( i = 0 ; i < num ; i++ )
            if( mem[ i ] !is null )
                mem[ i ].calcAtkAC;

        return;
    }

    /*--------------------
       hpplus - 移動時のHP増加処理
       --------------------*/
    void hpplus()
    {
        
        int i, j;

        for ( i = 0; i < party.num; i++ )
        {
            if ( ( party.mem[ i ].status ) >= STS.DEAD )
                continue;

            for ( j = 0; j < MAXCARRY; j++ )
                if ( ! party.mem[ i ].item[ j ].isNothing )
                    party.mem[ i ].healHP( party.mem[ i ].item[ j ].hpplus );
        }
        return;
    }


    /*--------------------
       theyGet - アイテム取得
       --------------------*/
    bool theyGet( int itemno )
    {
        Item itm;

        for( int j = num - 1 ; j >= 0 ; j -- )
        {
            if( mem[ j ].canCarry )
            {
                itm = mem[ j ].getItem( itemno );
                itm.undefined = true;

                textout("  ");
                textout( mem[ j ].name );
                textout( " got a " );
                textout( itm.getDispName );
                textout( ".\n" );
                getChar();
                return true;
            }
        }
        textout( "you cannot carry anything more.\n" );
        return false;
    }


    /*--------------------
       doTheyHave - アイテム所持確認
       --------------------*/
    // rtn=1 as Yes.  Someone in the party has it.
    //     0 as No.  Noone in the party has it.
    bool doTheyHave( int item )
    {
        int i;
        for( i = 0 ; i < num ; i++ )
            if ( mem[ i ].doesHeHave( item ) != 0 )
                return true;
        return false;
    }

    /*--------------------
       equip - メンバー選んで装備
       --------------------*/
    void equip()
    {

        char c;

        if( num < 1 )
            return;

        textout( "who(z:leave(9))? " );
        while( true )
        {
            c = getChar();
            if( c == 'z' || c == '9' )
                break;
            if( c >= '1' && c <= num + '0' )
                break;
        }

        textout( to!string( c ) ~ "\n" );

        if( c != 'z' && c != '9' )
        {
            mem[ c - '1' ].inspect;
            mem[ c - '1' ].equip;
        }

        return;
    }

    /*--------------------
       inspect - メンバー情報表示
       --------------------*/
    /* void inspect_party() */
    void inspect()
    {
        char c;
        
        textout( "who do you want to inspect(z:leave(9))? " );
        while ( true )
        {
            c = getChar();
            if ( c-'0' > 0 && c - '0' <= num )
                break;
            if ( c=='z' || c=='9' )
                break;
        }
        textout ( to!string( c ) ~ "\n" );

        if ( c == 'z' || c == '9' )
            return;

        mem[ c - '1' ].inspect_chr;

        return;
    }


    /*--------------------
       heal_all - 全回復
       --------------------*/
    void heal_all()
    {
        int i, j;
        for ( i = 0; i < party.num; i++ )
        {
            if ( mem[ i ].status < STS.DEAD )
            {
                if ( mem[ i ].status != STS.OK || mem[ i ].hp < mem[ i ].maxhp )
                {
                    for ( j = 0; j < num; j++ )
                    {
                        if ( mem[ j ].status != STS.OK )
                            continue;
                        if ( mem[ j ].consume_spell( 0x34 ) == 0 )
                        {
                            mem[ i ].hp = mem[ i ].maxhp;
                            mem[ i ].status = STS.OK;
                            break;
                        }
                    }
                }
            }
        }
        return;
    }


    // vyzaakt&vyzakt&vetteny&xiang&mapper
    void protect_all()
    {
        int i;
        // awaken
        if ( ! isIdentify ){
          for (i = 0; i < num; i++)
            if ( mem[ i ].consume_spell( 0x28 ) == 0 )
            {
              setIdentify;
              textout("  awaken...done.\n");
              break;
            }
        }
        // floatn
        if ( ! isFloat )
        {
          for ( i = 0; i < num; i++ )
            if ( mem[ i ].consume_spell( 0xb ) == 0)
            {
                setFloat;
                textout("  floatn...done.\n");
                break;
            }
        }
        // birdseye
        if ( ! isLight ){
          for (i = 0; i < num; i++)
            if ( mem[ i ].consume_spell( 0x29 ) == 0 )
            {
                setLight;
                lightCount += LIGHT_COUNT;
              textout("  birdseye...done.\n");
              break;
            }
        }
        // mapper
        if ( ! isMapper )
        {
          for ( i = 0; i < num; i++ )
              if ( mem[ i ].consume_spell( 0x3 ) == 0 )
              {
                  setMapper;
                  textout( "  mapper...done.\n" );
                  break;
              }
        }
        // vyzaakt
        if ( ac == 0 )
        {
          for (i = 0; i < num; i++)
            if ( mem[ i ].consume_spell( 0x2e ) == 0 )
            {
              ac = -2;
              textout( "  mgcshld...done.\n" );
              break;
            }
        }

        return;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //
    //------ battle --------------------------
    //
    //////////////////////////////////////////////////////////////////////////////////
    void action_input()
    {
        char c;
        int j , row; 

        Member pl;


        header_disp( HSTS.BATTLE );
        textout( "input action...\n" );
      
    AGAIN:
        for ( j = 0; j < num; j++ )
          mvprintw( CHRW_Y_TOP + j + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
      
        for ( row = 0; row < num; row++)
        {
            if ( mem[ row ].status != STS.OK )
                continue;

            pl = mem[ row ];
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48, "what?  " );

            while ( true )
            {
                c = getChar();
                if ( c == '?' )
                {
                    setColor( CL.MENU );
                    textout( "*********** assigned keys ***********\n" );
                    textout( "f/4:fight, p/5:parry, s/6:spell,\n" );
                    textout( "r/7:run, u/8:use, t/9:take back, \n" );
                    textout( "d/0:dispell, i:monster info\n" );
                    textout( "------ short cut ------\n" );
                    textout( "j/1:fight1, h/2:fight2, n/3:fight3\n" );
                    textout( "k:parry, l:take back, ;:run\n" );
                    textout( "*************************************" );
                    setColor( CL.MONSTER );
                    textout( "\n****** encounter ****** - push any key -" );
                    getChar();
                    textout( "\n" );
                    monParty.disp;
                    textout( "***********************\n" );
                    setColor( CL.NORMAL );
                    textout( "input action...\n" );
                }
                else if ( c == 'i' )
                {
                    monParty.dispMonsterInfo;
                    setColor( CL.MONSTER );
                    textout( "****** encounter ****** - push any key -" );
                    getChar();
                    textout( "\n" );
                    monParty.disp();
                    textout( "***********************\n" );
                    setColor( CL.NORMAL );
                    textout( "input action...\n" );
                }
                else if ( c == 't'  // take back
                        || c == 'l' 
                        || c == '9' )
                {
                    for ( j = 0; j < num; j++ )
                        mvprintw( CHRW_Y_TOP + j + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
                    goto AGAIN;
                }
                else if (c == 'r'   // run
                        || c == ';' 
                        || c == '7')
                {
                    for ( j = 0; j < num; j++ )
                    {
                        mvprintw( CHRW_Y_TOP + j + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
                        mem[ j ].action = ACT.RUN;
                    }
                    goto EXIT;
                }
                else
                {
                    if( pl.inputAction( row , c ) )
                        break;
                }
            }
        }
        textout( " ok?(t:take back)" );
        c = getChar();
        if ( c == 't' || c == ';' || c == '9' )
        {
            textout( "\ninput again ..." );
            goto AGAIN;
        }
    EXIT:
        textout( "\n" );
        return;
    }
    

    /*--------------------
       selectActiveMember - status OK のメンバーを選択
       --------------------*/
    Member selectActiveMember( string msg )
    {

        char c;

        textout( msg ~ "\n" );
        while( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c <= '0' + num 
                    && mem[ c - '1' ].status == STS.OK )
                break;
        }

        if ( c == 'z' || c == '9' )
        {
            textout( c );
            textout( "\n" );
            return null;
        }

        textout( c );
        c -= '1';
        textout( "(" ~ mem[ c ].name ~ ")\n" );
        return mem[ c ];

    }


    /*--------------------
       selectMemberInBattle - メンバー選択（戦闘時）
       --------------------*/
    int selectMemberInBattle( int row )
    {
        char c;

        mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, " who?                   " );
        while ( true )
        {
            c = getChar();
            if ( c >= '1' && c <= num + '0' )
            {
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, "                        " );
                return c - '1';
            }
        }
    }
    
    
}
    
