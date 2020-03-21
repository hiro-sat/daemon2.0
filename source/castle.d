// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
/* import std.string : format , split , chop; */
/* import std.file; */
/* import std.random; */

/* // derelict SDL */
/* import derelict.sdl2.sdl; */

// mysource 
import lib_sdl;
import lib_screen;

import def;
import app;
import edgeoftown;
import cParty;
import cMember;
import cItem;



/**====== castle ==================================================*/
bool castle_main()
{
    int rtncode=0;
    int i, j;
  
    for( i = 0 ; i < party.num ; i++ )
    {
        party.mem[ i ].poisoned = false;

        if( party.mem[ i ].status <= STS.AFRAID )
        {
            party.mem[ i ].status = STS.OK;

            /+
            // どうせみんな馬小屋にしか泊まらないんでしょ。
            // だからHP全回復にした。
            party.mem[ i ].hp = party.mem[ i ].maxhp;
            for ( j = 0; j < 7; j++ )
            {
                party.mem[ i ].msplcnt[ j ] &= 0xf0;
                party.mem[ i ].msplcnt[ j ] |= party.mem[ i ].msplcnt[ j ] >> 4;
                party.mem[ i ].psplcnt[ j ] &= 0xf0;
                party.mem[ i ].psplcnt[ j ] |= party.mem[ i ].psplcnt[ j ] >> 4;
            }
            textout( party.mem[ i ].name ~ " have been healed.\n" );
            party.mem[ i ].day++; // modified to: one night stay(not one week)
            +/
            party.win_disp_noreorder;

        }
    

        if (party.mem[ i ].status >= STS.PARALY)
        {
            party.num--;
            party.mem[ i ].outflag = OUT_F.BAR; // in bar (and Temple of Cant)
            party.mem[ i ] = null;
            for ( j = i ; j < 5 ; j++ )
                party.mem[ j ] = party.mem[ j + 1 ];
            party.mem[ 5 ] = null;
            i--;
        } 
        else 
        {
            party.mem[ i ].outflag = OUT_F.CASTLE; // in castle
        }
    }
  
    for ( i = 0 ; i < 6 ; i++)
        party.memsv[ i ] = party.mem[ i ];      // ?????
  
    header_disp( HSTS.CASTLE );
    party.win_disp();
    scrwin_clear();
  
    // ending check
    if ( party.num >= 1 && party.doTheyHave( 171 ) == 1 )
        ending();
  

    while( true )
    {
        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "******** castle ********\n"  ));
        textout( _( "g)inger's forest bar\n"  ));
        textout( _( "s)helton yankee flipper\n"  ));
        textout( _( "t)emple of dice\n"  ));
        textout( _( "a)lbertsan's mart\n"  ));
        textout( _( "e)dge of town\n"  ));
        textout( _( "************************\n"  ));
        setColor( CL.NORMAL );
        textout( _( "option? "  ));


        char keycode;
        while( true )
        {
            keycode = getChar ;
            if (keycode=='g' || keycode=='s' || keycode=='t' || keycode=='a' 
              || keycode=='e') break;
        }
        /* textout( to!string( keycode ) ~ "\n" ); */

        switch( keycode )
        {
            case 's': // shelton hotel
                if ( party.num == 0 )
                    continue;
                textout( _( "shelton hotel\n"  ));
                inn();
                break;
            case 'a': // albertsan's
                if ( party.num == 0 )
                    continue;
                textout( _( "albertsan's mart\n"  ));
                boltac();
                break;
            case 'g': // ginger's bar
                textout( _( "ginger's forest bar\n"  ));
                gilgamesh();
                break;
            case 't': /* temple of dice */ 
                if ( party.num == 0 )
                    continue;
                textout( _( "temple of dice\n"  ));
                temple();
                break;
            case 'e': /* edge of town */ 
                textout( _( "edge of tonw\n"  ));
                rtncode = eoftown();
                if ( rtncode==1 )
                {
                    goto MAZE;
                } 
                else if ( rtncode == 2 )
                {
                    goto EXIT;
                }
                header_disp( HSTS.CASTLE );
                party.win_disp();
                break;
            default:
                continue;
        }
        scrwin_clear();
    }
    EXIT:
    return false;  /* leave game */
  
    MAZE:
    return true;
}

/**--------------------
   see Monster marks
   --------------------*/
void seeMonsterMarks()
{

    int i , top;
    char c;

    setColor( CL.MENU );
    textout( "\n" );
    textout( "****** monster marks! ******\n" );
    textout( _( "n)ext(6) z)leave(9)\n"  ));
    setColor( CL.NORMAL );
    textout( "option?\n" );
    top = 0;
    while( true )
    {

        rewriteOff;
        
        for( i = 0; i < SCRW_Y_SIZ - 2 ; i++ )
        {
            mvprintw( SCRW_Y_TOP + i + 1, SCRW_X_TOP, "                             ");
            if( top + i > 108)
                continue; // 108 as # of DAEMON
            if( monstermarks[ top + i ] != 0)
            {
                mvIntDispD( SCRW_Y_TOP + i + 1, SCRW_X_TOP, top + i, 3 );
                printw(")");
                printw( monster_data[ top + i ].name );
                mvIntDispD( SCRW_Y_TOP + i + 1 , SCRW_X_TOP + SCRW_X_SIZ - 8 , monstermarks[ top + i ] , 7 );
            }
            else
            {
                mvIntDispD( SCRW_Y_TOP + i + 1, SCRW_X_TOP, top + i, 3);
                printw( ")?????" );
            }
        }

        rewriteOn;

        while( true )
        {
            c = getChar();
            if( c == 'z' || c == '9' )
                break;
            if( c == 'n' || c == '6' )
            {
                top += SCRW_Y_SIZ - 2;
                if (top > 108)
                    top = 0; // 108 as # of DAEMON ++++++++++++++++++
                break;
            }
        }
        if (c == 'z' || c == '9')
            break;
    }

}


//////////////////////////////////////////////////////////////////////////////////
//
//------ shelton yankee flipper hotel --------------------------
//
//////////////////////////////////////////////////////////////////////////////////
void inn()
{
    int i;
    char ch;
    Member mem;
  
    header_disp( HSTS.INN );
  
    while ( true )
    {
        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "****** shelton yankee flipper hotel ******\n" ));
        setColor( CL.NORMAL );
        textout( _( "who will stay(z:leave(9))? "  ));
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' || ( ch >= '1' && ch <= '0' + party.num ) )
                break;
        }
        if ( ch == 'z' || ch == '9' ) 
            break;
        if ( !( ch >= '1' && ch <= '0' + party.num ) )
            continue;
  


        mem = party.mem[ ch - '1' ];
        textout( mem.name ~ "\n" );
  
        if( mem.status >= STS.PARALY )
        {
            textout( _( "\n  ...You must be joking!\n\n"  ));
            continue;
        }

        mem.char_disp;

        // どうせみんな馬小屋にしか泊まらないんでしょ？
        // だからHP全回復にした。
        textout( _( "sleeping ...\n" ) );
        if( mem.hp < mem.maxhp )
        {
            mem.hp = mem.maxhp;
            textout( _( "%1 have been healed.\n" ) , mem.name );
        }

        mem.levelup_chk();
        for ( i = 0; i < 7; i++ )
        {
            mem.mspl_pt[ i ] = mem.mspl_max[ i ];
            mem.pspl_pt[ i ] = mem.pspl_max[ i ];
        }
        mem.day++; // modified to: one night stay(not one week)
        if ( mem.day > 365 )
        {
            mem.age++;
            mem.day = 0;
            party.win_disp();
            textout( "*** happy birthday to you! ***\n" );
            getChar();
        }
        party.win_disp();

        mem.char_disp;
        getChar;
    }
    textout( "\n" );
    header_disp( HSTS.CASTLE );

    return;
}



//////////////////////////////////////////////////////////////////////////////////
//
//------ ginger's forest bar -----------------------------------
//
//////////////////////////////////////////////////////////////////////////////////
//
void gilgamesh()
{

    //////////////////// 
    // Menu 表示
    //////////////////// 
    void dispGilgameshMenu()
    {
        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "*** ginger's forest bar ***\n"  ));
        textout( _( "a)dd  r)emove  n)inspect\n"  ));
        textout( _( "d)ivvy gold  z)leave(9)\n"  ));
        textout( _( "e)quip #)see character\n"  ));
        textout( _( "s)ee monster marks\n"  ));
        textout( _( "***************************\n"  ));
        setColor( CL.NORMAL );
        /* textout( "option? \n" ); */
        textout( "option? " );
        return;
    }
    //////////////////// 


    int i, current=0;
    char keycode;

    header_disp( HSTS.BAR );
    dispGilgameshMenu;

    while( true )
    {
        keycode = getChar;

        if( keycode >= '1' && keycode <= party.num + '0')
        {
            current = keycode - '1';
            party.mem[ current ].char_disp;
            continue;
        }

        switch( keycode )
        {
            case 's':   // see monster marks 
                textout( _( "see monster marks\n"  ));
                seeMonsterMarks;
                scrwin_clear();
                dispGilgameshMenu;
                break;

            case 'e':   // equip
                if( party.num < 1 )
                    break;
                textout( _( "equip\n"  ));
                party.equip;
                dispGilgameshMenu;
                break;

            case 'i':
            case 'n':   // n) inspect
                if( party.num < 1 )
                    break;
                textout( _( "inspect\n"  ));
                party.inspect();
                scrwin_clear();
                dispGilgameshMenu;
                break;

            case 'd':   // divvy
                if( party.num < 1 )
                    break;
                textout( _( "divvy gold\n"  ));
                party.divvy;
                party.mem[ current ].char_disp;
                dispGilgameshMenu;
                break;

            case 'z': 
            case '9':   // z)leave(9)
                textout( _( "leave the bar\n"  ));
                for( i = 0 ; i < 6 ; i++ )
                    party.memsv[ i ] = party.mem[ i ];
                header_disp( HSTS.CASTLE );
                return;

            case 'a': /* add */
                if( party.num == 6 )
                    break;
                textout( _( "add\n"  ));
                party.add();
                scrwin_clear();
                dispGilgameshMenu;
                break;

            case 'r': /* remove */
                if( party.num < 1 )
                    break;
                textout( _( "remove\n"  ));
                party.remove();
                scrwin_clear();
                dispGilgameshMenu;
                break;

            default:
                break;
        }
    }

}


//////////////////////////////////////////////////////////////////////////////////
//
//------ albertsan's mart --------------------------------------
//
//////////////////////////////////////////////////////////////////////////////////

void boltac()
{
    char c;
  
    header_disp( HSTS.SHOP );
  
    while ( true )
    {
        scrwin_clear();
        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "****** albertsan's mart ******\n"  ));
        textout( _( "b)uy s)ell u)ncurse i)dentify\n"  ));
        textout( _( "p)ool gold z)leave(9)\n"  ));
        textout( _( "******************************\n"  ));
        setColor( CL.NORMAL );
        textout( "option? " );

        while ( true )
        {
            c = getChar();
            if ( c == 'b' || c == 's' || c == 'u' || c == 'i' || c == 'p' || c == 'z' || c == '9' )
                break;
        }

        switch ( c )
        {
            case 'p': /* pool gold */
                textout( _( "pool gold\n"  ));
                textout( _( "pool gold to whom(z:leave(9))? "  ));
                while ( true )
                {
                  c = getChar();
                  if ( c == 'z' || c == '9' || 
                          ( c >= '1' && c <= '1' + party.num - 1 ) )
                      break;
                }
                textout( to!string( c ) ~ "(" ~ party.mem[ c - '1' ].name ~ ")\n" );

                if ( c >= '1' && ( c <= '1' + party.num - 1 ) )
                    party.poolGold( c - '1' );

                break;
            case 'z': /* leave */
            case '9': /* leave */
                textout( _( "leave the mart\n"  ));
                header_disp( HSTS.CASTLE );
                return;
            case 'b': /* buy */
                textout( _( "buy\n"  ));
                header_disp( HSTS.CASTLE );
                boltac_buy();
                break;
            case 's': /* sell */
                textout( _( "sell\n"  ));
                boltac_sell();
                break;
            case 'u': // uncurse
                textout( _( "uncurse\n"  ));
                uncurse();
                party.calcAtkAC;
                party.win_disp();
                break;
            case 'i': // identify
                textout( _( "identify\n"  ));
                boltac_identify();
                break;
            default:
                break;
        }

    }
}


/**
  boltac_buy - 
  */
void boltac_buy()
{
    char c;
    ITM_KIND kind = ITM_KIND.WEAPON; // weapon
    int top = 1, last;
    int i, disp_lines;
    int[ MAXITEM ] item;

    Member mem;
    Member mem_takes;


    void dispBoltacBuyMenu()
    {
        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "********* buy **********\n"  ));
        textout( _( "b)uy p)ick it up\n"  ));
        textout( _( "n)ext page(6) z)leave(9)\n"  ));
        textout( _( "------\n"  ));
        textout( _( "w)eapon a)rmor s)hield\n"  ));
        textout( _( "h)elm g)loves i)tem\n"  ));
        textout( _( "************************\n"  ));
        setColor( CL.NORMAL );
        textout( "option? " );
        return;
    }

WHO_BUY:
    mem = party.selectActiveMember( _( "who will buy(z:leave(9))? " ) , _( "leave" ) );
    if( mem is null )
        return;

    dispBoltacBuyMenu;

    while ( true )
    {
        scrwin_clear();
        // ref: disp_lines , item[]
        last = boltac_list( mem , top, kind, disp_lines, item );   

        while ( true )
        {
            c = getChar();
            if ( c == 'p' || c == 'z' || c == 'n' || c == '9' || c == 'w'
              || c == 'a' || c == 's' || c == 'h' || c == 'g' || c == 'i' 
              || c == 'b' )
                break;
        }
        switch ( c )
        {
            case 'z':
            case '9':
                textout( _( "leave\n"  ));
                scrwin_clear();
                return;
            case 'w':
                kind = ITM_KIND.WEAPON; // weapon
                top = 1;
                break;
            case 'a':
                kind = ITM_KIND.ARMOR;  // armor
                top = 1;
                break;
            case 's':
                kind = ITM_KIND.SHIELD; // shield
                top = 1;
                break;
            case 'h':
                kind = ITM_KIND.HELM;   // helm
                top = 1;
                break;
            case 'g':
                kind = ITM_KIND.GLOVES; // gloves
                top = 1;
                break;
            case 'i':
                kind = ITM_KIND.ITEM;   // item
                top = 1;
                break;
            case 'n':   // next page
            case '6':
                if ( disp_lines < SCRW_Y_SIZ - 2 )
                {
                    top = 1;
                    break;
                }
                top = last + 1;
                break;
            case 'p':
                textout( _( "pick it up\n"  ));
                textout( _( "which pick it up(a,b,...,z:quit(9))? "  ));
                while ( true )
                {
                  c = getChar();
                  if ( c == 'z' || c == '9' || 
                          ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                      break;
                }
                textout( c );
                textout( '\n' );
                if ( c == 'z' || c == '9' )
                    break;

                i = item[ c - 'a' ];
                item_data[ i ].dispInfo;
                getChar;
                dispBoltacBuyMenu;
                break;
            case 'b':
                textout( _( "buy\n"  ));
                while ( true )
                {
                    textout( _( "which buy(a,b,...,z:quit(9))? "  ));
                    while ( true )
                    {
                      c = getChar();
                      if ( c == 'z' || c == '9' || 
                              ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                          break;
                    }
                    textout( c );
                    textout( '\n' );
                    if ( c == 'z' || c == '9' )
                    {
                      break;
                    }
                    else
                    {
                        i = item[ c - 'a' ];
                        if ( i >= MAXITEM || boltacitem[ i ] == 0 )
                        {
                            textout( _( "out of stock.\n"  ));
                            break;
                        }
                        textout( '>' );
                        textout( item_data[ i ].name );
                        textout( '\n' );

                        textout(_( "  classes :  " ));
                        if ( item_data[ i ].canBeEquipped( CLS.FIG ) ) textout( 'f' );
                        if ( item_data[ i ].canBeEquipped( CLS.THI ) ) textout( 't' );
                        if ( item_data[ i ].canBeEquipped( CLS.PRI ) ) textout( 'p' );
                        if ( item_data[ i ].canBeEquipped( CLS.MAG ) ) textout( 'm' );
                        if ( item_data[ i ].canBeEquipped( CLS.BIS ) ) textout( 'b' );
                        if ( item_data[ i ].canBeEquipped( CLS.SAM ) ) textout( 's' );
                        if ( item_data[ i ].canBeEquipped( CLS.LOR ) ) textout( 'l' );
                        if ( item_data[ i ].canBeEquipped( CLS.NIN ) ) textout( 'n' );
                        textout(" \n");

                        if ( mem.canCarry )
                        {
                            mem_takes = mem;
                        }
                        else
                        {
                            textout( _( "you cannot carry anything more.\n"  ));

                        ANOTHER_PUR:
                            textout( _( "anyone else takes it(y/n)?"  ));

                            if ( answerYN != 'y')
                                break;

                            mem_takes = party.selectActiveMember( _( "who takes it(z:leave(9))? " ) 
                                                                , _( "leave" ) );
                            if( mem_takes is null )
                                break;
                            if( ! mem_takes.canCarry )
                            {
                                textout( _( "%1 cannot carry anything more.\n" ) , mem_takes.name );
                                goto ANOTHER_PUR;
                            }
                        }

                        if ( mem.gold < item_data[ i ].gold )
                        {
                            textout( _( "sorry, you cannot afford it.\n"  ));
                            textout( _( "pool gold(y/n)? "  ));

                            if ( answerYN == 'n' )
                                continue;

                            party.poolGold( mem );
                            if ( mem.gold < item_data[ i ].gold )
                            {
                                textout( _( "sorry, you cannot afford it.\n"  ));
                                dispBoltacBuyMenu;
                                continue;
                            }
                        }

                        mem.gold -= item_data[ i ].gold;
                        mem_takes.getItem( i );

                        boltacitem[ i ]--;
                        last = boltac_list( mem , top, kind, disp_lines , item );
                        party.win_disp();
                        textout( _( "\njust what you needed.\n"  ));
                        break;
                    }
                }
                dispBoltacBuyMenu;
                break;
            default:
                break;
        }
    }
    goto WHO_BUY;
}


/**
  boltac_list
  */ 
int boltac_list( Member mem 
        , int top, ITM_KIND kind , ref int lines , ref int[ MAXITEM ]  item )
{
    int i, j, k;
    string list;
    string canEquip;

    lines = 0;

    rewriteOff;

    for ( k = 0; k < MAXITEM; k++ )
        item[ k ] = 9999;


    setColor( CL.KIND );
    switch ( kind )
    {
        case ITM_KIND.WEAPON:   // weapon
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ weapon: ]                  " );
            break;
        case ITM_KIND.ARMOR:    // armor
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ armor:  ]                  " );
            break;
        case ITM_KIND.SHIELD:   // shield
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ shield: ]                  " );
            break;
        case ITM_KIND.HELM:     // helm
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ helm:   ]                  " );
            break;
        case ITM_KIND.GLOVES:   // gloves
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ gloves: ]                  " );
            break;
        case ITM_KIND.ITEM:     // item
            mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "[ item:   ]                  " );
            break;
        default:
            assert( 0 );
    }
    setColor( CL.NORMAL );

    i = top;
    j = top;

    while ( i < MAXITEM )
    {

        if( item_data[ i ] is null )
        {
            i++;
            continue;
        }

        if ( ( item_data[ i ] !is null ) && ( i != 171 ) 
                && ( item_data[ i ].kind == kind ) )
        {
            if ( boltacitem[ i ] != 0 )
            {
                item[ lines ] = i;
                if ( item_data[ i ].canBeEquipped( mem.Class ) )
                    canEquip = " ";
                else
                    canEquip = "#";

                list = formatText( "%1)%2%3" 
                        , cast(char)( 'a' + lines ) 
                        , canEquip
                        , item_data[ i ].name ) ;

                mvprintw( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP, "                             " );
                mvprintw( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP , list );
                mvIntDispD( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP + 18, item_data[ i ].gold, 8 );
                printw( "*" );

                if ( boltacitem[ i ] > 999 )
                    mvIntDispD( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP + 27, 999, 3 );
                else
                    mvIntDispD( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP + 27, boltacitem[ i ], 3 );
            }
            else
            {
                mvprintw( SCRW_Y_TOP + 1 + lines, SCRW_X_TOP, "-)                out of stock" );
            }
            lines++;
            j = i;
            if ( lines >= SCRW_Y_SIZ - 2 )
                break;
        }
        i++;
    }

    rewriteOn;

    return j ;  // last
}


/**
  boltac_sell
  */
void boltac_sell()
{
    char ch;
    Member mem;
    Item itm;

    while ( true )
    {
        textout( _( "whose item(z:leave(9))? "  ));

        while ( true )
        {
          ch = getChar();
          if (ch == 'z' || ch == '9' 
                  || (ch >= '1' && ch <= '1' + party.num - 1))
              break;
        }
        textout( ch );
        if (ch == 'z' || ch == '9')
        {
            textout( '\n' );
            return;
        }

        mem = party.mem[ ch - '1' ];
        textout( "(" ~ mem.name ~ ")\n" );

        mem.inspect;

        while ( true )
        {
            textout( _( "  which item(z:leave(9))? "  ));

            while ( true )
            {
                ch = getChar();
                if ( ch == 'z' || ch == '9' || 
                        (ch >= '1' && ch <= '8' && ! mem.item[ ch - '1' ].isNothing ) )
                    break;
            }
            textout( ch );
            if ( ch == 'z' || ch == '9' )
            {
                textout( '\n' );
                break;
            }
            else
            {
                itm = mem.item[ ch - '1' ];
                textout( "(" ~ itm.getDispNameA ~ ")\n" );
                if ( itm.cursed )
                {
                    textout( _( "    cursed item.\n"  ));
                    continue;
                }
                else if ( itm.equipped )
                {
                    textout( _( "    equipped item.\n"  ));
                    continue;
                }
                if ( itm.gold != 0 )
                {
                    textout( _( "    It will be %1 gp.(y/n)"  ), itm.gold / 2 );
                    if ( answerYN == 'n' )
                        continue;
                    mem.gold += itm.gold / 2;

                    boltacitem[ itm.itemNo ]++;
                    textout( "    " );
                    textout( itm.name );
                    textout( ".\n" );

                    mem.releaseItem( itm );
                    party.win_disp();
                    textout( _( "    Anything else, noble sir?\n"  ));
                }
                else
                {
                    textout( _( "    Not interested.\n"  ));
                }
                mem.inspect;
            }
        }
    }
}


/**
  uncurse - ボルタック のろいをとく
  */
void uncurse()
{
    char c;
    int i;
    Member mem;
    Item itm;

    while ( true )
    {
        textout( _( "whose item(z:leave(9))? "  ));
        while ( true )
        {
          c = getChar();
          if ( c == 'z' || c == '9' 
                  || ( c >= '1' && c <= '1' + party.num - 1 ) )
              break;
        }
        textout( c );
        if ( c == 'z' || c == '9' )
        {
            textout( '\n' );
            return;
        }

        mem = party.mem[ c - '1' ];
        textout( "(" ~ mem.name ~ ")\n" );
        for ( i = 0; i < MAXCARRY; i++ )
        {
            if ( mem.item[ i ].cursed )
            {
                textout( "  " );
                textout( i + 1 );
                textout( ')' ~ mem.item[ i ].getDispName );
                textout( '\n' );
            }
        }

        while ( true )
        {
            textout( _( "which item(z:leave(9))?  "  ));
            while ( true )
            {
                c = getChar();
                if ( c == 'z' || c == '9' )
                    break;
                if ( ! ( c >= '1' && c <= '0' + MAXCARRY ) )
                    continue;
                itm = mem.item[ c - '1' ];
                if ( itm.cursed )
                     break;
            }
            textout( c );
            if ( c == 'z' || c == '9' )
            {
                textout( '\n' );
                break;
            }
            textout( "(" ~ itm.getDispNameA ~ ")\n" );

            textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
            if ( answerYN == 'n' )
                break;
            if ( mem.gold < itm.gold / 2)
            {
                textout( _( "you can't afford it, pool gold(y/n)? " ) );
                if ( answerYN == 'n' )
                    return;
                party.poolGold( mem );
                if ( mem.gold < itm.gold / 2)
                {
                    textout( _( "  still, you can't afford it\n" ) );
                    return;
                }
            }
            mem.gold -= itm.gold / 2;
            textout( _( "uncursed and %1 is vanished...\n" ) , itm.getDispNameA );
            mem.releaseItem( itm );
            getChar();
            return;
        }
    }  
}


/**
  boltac_identify -
 */
void boltac_identify()
{
    char c;
    Member mem;
    Item itm;

    TOP:

    scrwin_clear();
    textout( _( "whose item(z:leave(9))? " ) );
    while ( true )
    {
        c = getChar();
        if ( c == 'z' || c == '9' || 
                ( c >= '1' && c <= '1' + party.num - 1 ) )
            break;
    }
    textout( c );
    if ( c == 'z' || c == '9' )
    {
        textout( '\n' );
        return;
    }

    mem = party.mem[ c - '1'];
    textout( "(" ~ mem.name ~ ")\n" );

    mem.inspect;

    while ( true )
    {
        textout( _( "which item(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if (c == 'z' || c == '9')
                break;
            if ( ! ( c >= '1' && c <= '0' + MAXCARRY ) )
                continue;
            itm = mem.item[ c - '1' ];
            if ( ! itm.isNothing )
                break;
        }
        textout( c );
        if (c == 'z' || c == '9')
        {
            textout( '\n' );
            break;
        }

        textout( "(" ~ itm.getDispNameA ~ ")\n" );
        if ( itm.undefined )
        {
            textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
            if ( answerYN == 'n' )
                break;
            if ( mem.gold < itm.gold / 2 )
            {
                textout( _( "you can't afford it, pool gold(y/n)? " ) );
                if ( answerYN == 'n')
                    return;
                party.poolGold( mem );
                if ( mem.gold < itm.gold / 2 )
                {
                    textout( _( "  still, you can't afford it\n" ) );
                    return;
                }
            }
            mem.gold -= itm.gold / 2;
            itm.undefined = false;
            mem.inspect;
        }

        itm.dispInfo;

    }
    goto TOP;
}


//////////////////////////////////////////////////////////////////////////////////
//
//------ shelton yankee flipper hotel --------------------------
//
//////////////////////////////////////////////////////////////////////////////////
void temple()
{
    int i, ratio;
    long donation;
    char c;
    Member mem , p;
  
    if ( party.num == 0 )
        return;
  
    header_disp( HSTS.TEMPLE );
  
    while ( true )
    {

        setColor( CL.MENU );
        textout( "\n" );
        textout( _( "*** temple of dice, we have: ***\n" ) );
        setColor( CL.NORMAL );

        for ( i = 0; i < MAXMEMBER ; i++ )
        {
            if ( member[ i ].name != "" && member[ i ].status >= STS.PARALY
              && member[ i ].outflag==0 )
            {
                textout( "  " );
                textout( to!char( i + 'a' ) );
                textout( ')' );
                textout( member[ i ].name );
                switch ( member[ i ].status )
                {
                    case STS.PARALY:
                        textout( "(paralized)\n" );
                        break;
                    case STS.STONED:
                        textout("(stoned)\n");
                        break;
                    case STS.DEAD:
                        textout("(dead)\n");
                        break;
                    case STS.ASHED:
                        textout( "(ashed)\n" );
                        break;
                    default:
                        assert( 0 );
                }
            }
        }
        textout( _( "  who needs help(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c < 'a' || c >= 'a' + MAXMEMBER )
                continue;
            if ( member[ c - 'a' ].name != "" && member[ c - 'a' ].status >= STS.PARALY
              && member[ c - 'a' ].outflag == 0 )
                break;
        }
        textout( c );
        if ( c == 'z' || c == '9' )
        {
            textout( '\n' );
            goto EXIT;
        }

        mem = member[ c - 'a' ];
        textout( "(" ~ mem.name ~ ")\n" );
        switch ( mem.status )
        {
            case STS.PARALY:
                donation = 100;
                ratio = 100;
                break;
            case STS.STONED:
                donation = 150;
                ratio = 100;
                break;
            case STS.DEAD:
                donation = 250;
                ratio = 70;
                break;
            default: // STS.ASHED
                donation = 500;
                ratio = 40;
                break;
        }
        donation *= mem.level;
        textout( _( "the donation is %1 gp.\n" ) , donation );
        textout( _( "  who will pay(z:leave(9))? " ) );

        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c < '1' + party.num )
                break;
        }
        textout( c );

        if ( c == 'z' || c == '9' )
        {
            textout( '\n' );
            break;
        }

        p = party.mem[ c - '1' ];
        textout( "(" ~ p.name ~ ")\n" );
        if ( p.gold < donation )
        {
            textout( _( "you don't have enough money.\n" ) );
            textout( _( "  pool gold(y/n)? " ) );
            if (answerYN == 'n')
                goto EXIT;
            party.poolGold( p );
            if ( p.gold < donation )
            {
              textout( _( "  still not enough...\n" ) );
              getChar();
              goto EXIT;
            }
        }

        p.gold -= donation;
        if ( ratio < 100 )
        { // vitalityによる修正
            if ( p.vit[ 0 ] + p.vit[ 1 ] >= 18)
                ratio += 30;
            else if ( p.vit[ 0 ] + p.vit[ 1 ] >= 17)
                ratio += 20;
            else if ( p.vit[ 0 ] + p.vit[ 1 ] >= 16)
                ratio += 10;
            else if ( p.vit[ 0 ] + p.vit[ 1 ] <= 3)
                ratio -= -20;
            else if ( p.vit[ 0 ] + p.vit[ 1 ] <= 5)
                ratio -= -10;

            if ( ratio > 95 ) ratio = 95;
            if ( ratio < 10 ) ratio = 10;
        }
        textout( "\n*** murmur - " );
        getChar();
        textout( "chant - " );
        getChar();
        textout( "pray - " );
        getChar();
        textout( "invoke! ***\n" );
        getChar();

        if ( get_rand( 99 ) + 1 <= ratio )
        { // succeed
            mem.hp = mem.maxhp;
            mem.status = STS.OK;
            if ( ratio != 100 )
                mem.vit[ 0 ]--;
        }
        else if( mem.status == STS.DEAD )
        {
            textout( _( " %1 needs Bless now!\n" ) , mem.name );
            mem.status = STS.ASHED;
        }
        else
        {
            textout( _( " %1 is buried...\n" ) , mem.name );
            mem.status = STS.LOST;
            mem.name = "";
        }
    }

EXIT:
    header_disp( HSTS.CASTLE );
    return;
}

