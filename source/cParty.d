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
    enum BIT_PARTY_STS_SCOPE    = 0x08;
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
        int x;
        string name;
      
        win_status.clear();
      
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
                
                name = formatText( "%1)%2"  
                                , to!string( cast(char)( 'a' + i ) )
                                , leftB( member[ i ].name , 14 ) );

                x = ( ( disp_count % 2 == 0 ) ? 0 : 16 );
                win_status.print( 1 + ( disp_count / 2 ),  x , name ) ;

                disp_count ++;

            }
        }

        rewriteOn;
        
        return;

    }


public:
    Member[ 6 ] mem;
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
                  // bit3:s, scope
    int lightCount;   // milwacnt
    int scopeCount;
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
            mem[ i ] = null;
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
    bool isScope()    { return ( ( status & BIT_PARTY_STS_SCOPE    ) != 0 ); }
    bool isIdentify() { return ( ( status & BIT_PARTY_STS_IDENTIFY ) != 0 ); }
    void setScope()    { status |= BIT_PARTY_STS_SCOPE    ; }
    void setMapper()   { status |= BIT_PARTY_STS_MAPPER   ; }
    void setFloat()    { status |= BIT_PARTY_STS_FLOAT    ; }
    void setLight()    { status |= BIT_PARTY_STS_LIGHT    ; }
    void setIdentify() { status |= BIT_PARTY_STS_IDENTIFY ; }
    void resetScope()    { status ^= BIT_PARTY_STS_SCOPE    ; }
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

        win_msg.textout( _( "select members(a,b,... ,z:leave(9))\n" ) );
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
        win_msg.textout( _( "remove who(z:leave(9))?\n" ) );

        while( true )
        {
            if ( num == 0)
                break;

            keycode = getChar();

            if ( keycode == 'z' || keycode == '9' )
                break;

            c = to!char( keycode - '1' );
            if ( ( c < 0 ) || ( c >= num ) )
                break;

            if ( mem[ c ] is null )
                break;

            num--;
            actnum--;
            mem[ c ].outflag = OUT_F.BAR;
            mem[ c ] = null;

            for ( int i = c ; i < 5; i++ )
                mem[ i ] = mem[ i + 1 ];
            mem[ 5 ] = null;

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
        win_msg.textout( _( "%1 has %2 gp.\n" ) , m.name , poolgold );

        return;
    }
    /*--------------------
       poolGold - ゴールドを集める
       no : 集めるメンバー 
       --------------------*/
    void poolGold( int no )
    {
        poolGold( mem[ no ] );
        return;
    }

    /*--------------------
       checkAlive - 全滅判定
       --------------------*/
    bool checkAlive()
    {
        for ( int i = 0; i < num; i++ )
            if ( ( mem[ i ].status ) < STS.PARALY )
                return true;

        return false;
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
            win_msg.textout( _( "who comes %1(z:leave(9))? " ) , step  );
            while ( true )
            {
                ch = getChar();
                if ( ch == 'z' || ch == '9' )
                {
                    win_msg.textout( "leave\n" );
                    return false;
                }

                if (ch >= '1' && ch <= '0' + party.num )
                {
                    if( indexOf( order , ch ) >= 0 )
                        continue;

                    win_msg.textout( "%1(%2)" , ch , mem[ ch - '1' ].name );
                    win_msg.textout( '\n' );
                    break;
                }
            }
            order ~= to!string( ch );
            return true;
        }



        if( ! reorder_sub( _( "first" ) ) )
            return;
        if ( party.num <= 1 )
            goto EXIT;

        if( ! reorder_sub( _( "second" ) ) )
            return;
        if ( party.num <= 2 )
            goto EXIT;

        if( ! reorder_sub( _( "third" ) ) )
            return;
        if ( party.num <= 3 )
            goto EXIT;

        if( ! reorder_sub( _( "fourth" ) ) )
            return;
        if ( party.num <= 4 )
            goto EXIT;

        if( ! reorder_sub( _( "fifth" ) ) )
            return;
        if ( party.num <= 5 )
            goto EXIT;

        if( ! reorder_sub( _( "sixth" ) ) )
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

                win_msg.textout( _( "  %1 got a %2.\n" ) , mem[ j ].name , itm.getDispName );
                getChar();
                return true;
            }
        }
        win_msg.textout( _( "you cannot carry anything more.\n" ) );
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

        win_msg.textout( _( "who(z:leave(9))? " ) );
        while( true )
        {
            c = getChar();
            if( c == 'z' || c == '9' )
                break;
            if( c >= '1' && c <= num + '0' )
                break;
        }

        win_msg.textout( to!string( c ) ~ "\n" );

        if( c != 'z' && c != '9' )
        {
            mem[ c - '1' ].inspect;
            mem[ c - '1' ].equip;
        }

        return;
    }

    /*--------------------
       inspect - メンバー情報表示
        type: 1:camp , 2:battle
       --------------------*/
    /* void inspect_party() */
    void inspect( int type = 0 )
    {
        char c;
        
        win_msg.textout( _( "who do you want to inspect(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c-'0' > 0 && c - '0' <= num )
                break;
            if ( c=='z' || c=='9' )
                break;
        }
        win_msg.textout ( to!string( c ) ~ "\n" );

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
              win_msg.textout( _( "  rcgnize...done.\n" ) );
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
                win_msg.textout( _( "  floatn...done.\n" ) );
                break;
            }
        }
        // shine
        if ( ! isLight ){
          for (i = 0; i < num; i++)
            if ( mem[ i ].consume_spell( 0x29 ) == 0 )
            {
                party.setLight;
                party.lightCount += L_LIGHT_COUNT;
                party.setScope;
                party.scopeCount += L_SCOPE_COUNT;
              win_msg.textout( _( "  shine...done.\n" ) );
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
                  dungeon.disp;
                  win_msg.textout( _( "  mapper...done.\n" ) );
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
              win_msg.textout( _( "  guard...done.\n" ) );
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

        win_msg.textout( _( "input action...\n" ) );

    AGAIN:
        for ( j = 0; j < num; j++ )
            mvprintw( CHRW_Y_TOP + j + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
      
        for ( row = 0; row < num; row++)
        {

            pl = mem[ row ];

            if ( pl.status != STS.OK )
            {
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48 - 1, " " );
                switch( pl.status )
                {
                    case STS.SLEEP:
                        printw( "sleep " );
                        break;
                    case STS.AFRAID:
                        printw( "afraid" );
                        break;
                    case STS.PARALY:
                        printw( "paraly" );
                        break;
                    case STS.STONED:
                        printw( "stoned" );
                        break;
                    case STS.DEAD:
                        printw( "dead  " );
                        break;
                    case STS.ASHED:
                        printw( "ashed " );
                        break;
                    case STS.LOST:
                        printw( "lost  " );
                        break;
                    default:
                        assert( 0 );
                }
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48 + 6, "                        " );
                continue;
            }

            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48, "what?  " );

            while ( true )
            {
                c = getChar();
                if ( c == '?' )
                {
                    setColor( CL.MENU );
                    win_msg.textout( _( "************ assigned keys ************\n" ) );
                    win_msg.textout( _( "f/4:fight, p/5:parry, s/c/6:cast spell,\n" ) );
                    win_msg.textout( _( "e/7:run, u/8:use, t/9:take back, \n" ) );
                    win_msg.textout( _( "d/0:dispell, i:monster info\n" ) );
                    win_msg.textout( _( "r/:read spells book\n" ) );
                    win_msg.textout( _( "------ short cut ------\n" ) );
                    win_msg.textout( _( "j/1:fight1, h/2:fight2, n/3:fight3\n" ) );
                    win_msg.textout( _( "k:parry, l:take back, ;:run\n" ) );
                    win_msg.textout( _( "***************************************" ) );
                    setColor( CL.MONSTER );
                    win_msg.textout( "\n****** encounter ****** - push any key -" );
                    getChar();
                    win_msg.textout( "\n" );
                    monParty.disp;
                    win_msg.textout( "***********************\n" );
                    setColor( CL.NORMAL );
                    win_msg.textout( _( "input action...\n" ) );
                }
                else if ( c == 'i' )
                {
                    monParty.dispMonsterInfo;
                    setColor( CL.MONSTER );
                    win_msg.textout( "****** encounter ****** - push any key -" );
                    getChar();
                    win_msg.textout( "\n" );
                    monParty.disp();
                    win_msg.textout( "***********************\n" );
                    setColor( CL.NORMAL );
                    win_msg.textout( _( "input action...\n" ) );
                }
                else if( c == 'r' ) // read spell
                {
                    pl.dispSpellsInBattle();

                    setColor( CL.MONSTER );
                    win_msg.textout( "****** encounter ****** - push any key -" );
                    getChar();
                    win_msg.textout( "\n" );
                    monParty.disp();
                    win_msg.textout( "***********************\n" );
                    setColor( CL.NORMAL );
                    win_msg.textout( _( "input action...\n" ) );
                }
                else if ( c == 't'  // take back
                        || c == 'l' 
                        || c == '9' )
                {
                    for ( j = 0; j < num; j++ )
                        mvprintw( CHRW_Y_TOP + j + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
                    goto AGAIN;
                }
                else if (c == 'e'   // escape
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
        win_msg.textout( _( " ok?(t:take back)" ) );
        c = getChar();
        if ( c == 't' || c == ';' || c == '9' )
        {
            win_msg.textout( _( "\ninput again ..." ) );
            goto AGAIN;
        }
    EXIT:
        win_msg.textout( "\n" );
        return;
    }
    

    /*--------------------
       selectMember - メンバーを選択
       --------------------*/
    Member selectMember( string msg )
    {

        char c;

        win_msg.textout( msg ~ "\n" );
        while( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c <= '0' + num )
                break;
        }

        if ( c == 'z' || c == '9' )
        {
            win_msg.textout( c );
            win_msg.textout( "\n" );
            return null;
        }

        win_msg.textout( c );
        c -= '1';
        win_msg.textout( "(" ~ mem[ c ].name ~ ")\n" );
        return mem[ c ];

    }

    /*--------------------
       selectActiveMember - status OK のメンバーを選択
       --------------------*/
    Member selectActiveMember( string msg , string msg_ret )
    {

        char c;

        win_msg.textout( msg ~ "\n" );
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
            win_msg.textout( "%1:%2\n" , c , msg_ret );
            return null;
        }

        win_msg.textout( c );
        c -= '1';
        win_msg.textout( "(" ~ mem[ c ].name ~ ")\n" );
        return mem[ c ];

    }


    /*--------------------
       selectMemberInBattle - メンバー選択（戦闘時）
       --------------------*/
    int selectMemberInBattle( int row )
    {
        char c;

        mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, _( " who?                   " ) );
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
    
    /*--------------------
       getMemberNoy - メンバーの並び順を取得
       --------------------*/
    int getMemberNo( Member _m )
    {
        foreach( i , m ; mem )
            if( m is _m )
                return to!int( i );
        assert( 0 );
    }
    
}
    
