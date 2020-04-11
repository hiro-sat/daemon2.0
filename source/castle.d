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
  
    header_disp( HSTS.CASTLE );
    party.win_disp();
    scrClear;
  
    // ending check
    if ( party.num >= 1 && party.doTheyHave( 171 ) == 1 )
        ending();
  
    win_msg.disp;

    while( true )
    {
        setColor( CL.MENU );
        win_msg.textout( "\n" );
        win_msg.textout( _( "******** castle ********\n"  ));
        win_msg.textout( _( "g)inger's forest bar\n"  ));
        win_msg.textout( _( "s)helton yankee flipper\n"  ));
        win_msg.textout( _( "t)emple of dice\n"  ));
        win_msg.textout( _( "a)lbertsan's mart\n"  ));
        win_msg.textout( _( "e)dge of town\n"  ));
        win_msg.textout( _( "************************\n"  ));
        setColor( CL.NORMAL );
        win_msg.textout( _( "option? "  ));


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
                win_msg.textout( _( "shelton hotel\n"  ));
                inn();
                break;
            case 'a': // albertsan's
                if ( party.num == 0 )
                    continue;
                win_msg.textout( _( "albertsan's mart\n"  ));
                shop();
                break;
            case 'g': // ginger's bar
                win_msg.textout( _( "ginger's forest bar\n"  ));
                bar();
                break;
            case 't': /* temple of dice */ 
                if ( party.num == 0 )
                    continue;
                win_msg.textout( _( "temple of dice\n"  ));
                temple();
                break;
            case 'e': /* edge of town */ 
                win_msg.textout( _( "edge of tonw\n"  ));
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
        win_status.clear;
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
    win_msg.textout( "\n" );
    win_msg.textout( "****** monster marks! ******\n" );
    win_msg.textout( _( "n)ext(6) z)leave(9)\n"  ));
    setColor( CL.NORMAL );
    win_msg.textout( "option?\n" );
    top = 0;
    while( true )
    {

        rewriteOff;
        
        win_status.clear;

        for( i = 0; i < win_status.height - 2 ; i++ )
        {
            if( top + i > 108)
                continue; // 108 as # of DAEMON
            if( monstermarks[ top + i ] != 0)
            {
                win_status.print( i + 1 , 0 
                        , formatText( "%1)%2" 
                            , fillR( top + i , 3 ) 
                            , monster_data[ top + i ].name ) );
                win_status.print( i + 1 , win_status.width - 8 , fillR( monstermarks[ top + i ] , 7 ) );
            }
            else
            {
                win_status.print( i + 1 , 0 
                        , formatText( "%1)?????" , fillR( top + i , 3 ) ) );
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
                top += win_status.height - 2;
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
        win_msg.textout( "\n" );
        win_msg.textout( _( "****** shelton yankee flipper hotel ******\n" ));
        setColor( CL.NORMAL );
        win_msg.textout( _( "who will stay(z:leave(9))? "  ));
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
        win_msg.textout( mem.name ~ "\n" );
  
        if( mem.status >= STS.PARALY )
        {
            win_msg.textout( _( "\n  ...You must be joking!\n\n"  ));
            continue;
        }

        mem.char_disp;

        // どうせみんな馬小屋にしか泊まらないんでしょ？
        // だからHP全回復にした。
        win_msg.textout( _( "sleeping ...\n" ) );
        if( mem.hp < mem.maxhp )
        {
            mem.hp = mem.maxhp;
            win_msg.textout( _( "%1 have been healed.\n" ) , mem.name );
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
            win_msg.textout( "*** happy birthday to you! ***\n" );
            getChar();
        }
        party.win_disp();

        mem.char_disp;
        getChar;
    }
    win_msg.textout( "\n" );
    header_disp( HSTS.CASTLE );

    return;
}



//////////////////////////////////////////////////////////////////////////////////
//
//------ ginger's forest bar -----------------------------------
//
//////////////////////////////////////////////////////////////////////////////////
//
void bar()
{

    //////////////////// 
    // Menu 表示
    //////////////////// 
    void dispBarMenu()
    {
        setColor( CL.MENU );
        win_msg.textout( "\n" );
        win_msg.textout( _( "*** ginger's forest bar ***\n"  ));
        win_msg.textout( _( "a)dd  r)emove  n)inspect\n"  ));
        win_msg.textout( _( "d)ivvy gold  z)leave(9)\n"  ));
        win_msg.textout( _( "e)quip #)see character\n"  ));
        win_msg.textout( _( "s)ee monster marks\n"  ));
        win_msg.textout( _( "***************************\n"  ));
        setColor( CL.NORMAL );
        win_msg.textout( "option? " );
        return;
    }
    //////////////////// 


    int i, current=0;
    char keycode;

    header_disp( HSTS.BAR );
    dispBarMenu;

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
                win_msg.textout( _( "see monster marks\n"  ));
                seeMonsterMarks;
                win_status.clear();
                dispBarMenu;
                break;

            case 'e':   // equip
                if( party.num < 1 )
                    break;
                win_msg.textout( _( "equip\n"  ));
                party.equip;
                dispBarMenu;
                break;

            case 'i':
            case 'n':   // n) inspect
                if( party.num < 1 )
                    break;
                win_msg.textout( _( "inspect\n"  ));
                party.inspect();
                win_status.clear();
                dispBarMenu;
                break;

            case 'd':   // divvy
                if( party.num < 1 )
                    break;
                win_msg.textout( _( "divvy gold\n"  ));
                party.divvy;
                party.mem[ current ].char_disp;
                dispBarMenu;
                break;

            case 'z': 
            case '9':   // z)leave(9)
                win_msg.textout( _( "leave the bar\n"  ));
                header_disp( HSTS.CASTLE );
                return;

            case 'a': /* add */
                if( party.num == 6 )
                    break;
                win_msg.textout( _( "add\n"  ));
                party.add();
                win_status.clear();
                dispBarMenu;
                break;

            case 'r': /* remove */
                if( party.num < 1 )
                    break;
                win_msg.textout( _( "remove\n"  ));
                party.remove();
                win_status.clear();
                dispBarMenu;
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

void shop()
{
    char c;
  
    header_disp( HSTS.SHOP );
  
    while ( true )
    {
        win_status.clear();
        setColor( CL.MENU );
        win_msg.textout( "\n" );
        win_msg.textout( _( "****** albertsan's mart ******\n"  ));
        win_msg.textout( _( "b)uy s)ell u)ncurse i)dentify\n"  ));
        win_msg.textout( _( "p)ool gold z)leave(9)\n"  ));
        win_msg.textout( _( "******************************\n"  ));
        setColor( CL.NORMAL );
        win_msg.textout( "option? " );

        while ( true )
        {
            c = getChar();
            if ( c == 'b' || c == 's' || c == 'u' || c == 'i' || c == 'p' || c == 'z' || c == '9' )
                break;
        }

        switch ( c )
        {
            case 'p': /* pool gold */
                win_msg.textout( _( "pool gold\n"  ));
                win_msg.textout( _( "pool gold to whom(z:leave(9))? "  ));
                while ( true )
                {
                  c = getChar();
                  if ( c == 'z' || c == '9' || 
                          ( c >= '1' && c <= '1' + party.num - 1 ) )
                      break;
                }
                win_msg.textout( to!string( c ) ~ "(" ~ party.mem[ c - '1' ].name ~ ")\n" );

                if ( c >= '1' && ( c <= '1' + party.num - 1 ) )
                    party.poolGold( c - '1' );

                break;
            case 'z': /* leave */
            case '9': /* leave */
                win_msg.textout( _( "leave the mart\n"  ));
                header_disp( HSTS.CASTLE );
                return;
            case 'b': /* buy */
                win_msg.textout( _( "buy\n"  ));
                header_disp( HSTS.CASTLE );
                shop_buy();
                break;
            case 's': /* sell */
                win_msg.textout( _( "sell\n"  ));
                shop_sell();
                break;
            case 'u': // uncurse
                win_msg.textout( _( "uncurse\n"  ));
                uncurse();
                party.calcAtkAC;
                party.win_disp();
                break;
            case 'i': // identify
                win_msg.textout( _( "identify\n"  ));
                shop_identify();
                break;
            default:
                break;
        }

    }
}


/**
  shop_buy - 
  */
void shop_buy()
{
    char c;
    ITM_KIND kind = ITM_KIND.WEAPON; // weapon
    int top = 1, last;
    int i, disp_lines;
    int[ MAXITEM ] item;

    Member mem;
    Member mem_takes;


    void dispShopBuyMenu()
    {
        setColor( CL.MENU );
        win_msg.textout( "\n" );
        win_msg.textout( _( "********* buy **********\n"  ));
        win_msg.textout( _( "b)uy p)ick it up\n"  ));
        win_msg.textout( _( "n)ext page(6) z)leave(9)\n"  ));
        win_msg.textout( _( "------\n"  ));
        win_msg.textout( _( "w)eapon a)rmor s)hield\n"  ));
        win_msg.textout( _( "h)elm g)loves i)tem\n"  ));
        win_msg.textout( _( "************************\n"  ));
        setColor( CL.NORMAL );
        win_msg.textout( "option? " );
        return;
    }

WHO_BUY:
    mem = party.selectActiveMember( _( "who will buy(z:leave(9))? " ) , _( "leave" ) );
    if( mem is null )
        return;

    dispShopBuyMenu;

    while ( true )
    {
        win_status.clear();
        // ref: disp_lines , item[]
        last = shop_list( mem , top, kind, disp_lines, item );   

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
                win_msg.textout( _( "leave\n"  ));
                win_status.clear();
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
                win_msg.textout( _( "pick it up\n"  ));
                win_msg.textout( _( "which pick it up(a,b,...,z:quit(9))? "  ));
                while ( true )
                {
                  c = getChar();
                  if ( c == 'z' || c == '9' || 
                          ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                      break;
                }
                win_msg.textout( c );
                win_msg.textout( '\n' );
                if ( c == 'z' || c == '9' )
                    break;

                i = item[ c - 'a' ];
                item_data[ i ].dispInfo;
                getChar;
                dispShopBuyMenu;
                break;
            case 'b':
                win_msg.textout( _( "buy\n"  ));
                while ( true )
                {
                    win_msg.textout( _( "which buy(a,b,...,z:quit(9))? "  ));
                    while ( true )
                    {
                      c = getChar();
                      if ( c == 'z' || c == '9' || 
                              ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                          break;
                    }
                    win_msg.textout( c );
                    win_msg.textout( '\n' );
                    if ( c == 'z' || c == '9' )
                    {
                      break;
                    }
                    else
                    {
                        i = item[ c - 'a' ];
                        if ( i >= MAXITEM || shopitem[ i ] == 0 )
                        {
                            win_msg.textout( _( "out of stock.\n"  ));
                            break;
                        }
                        win_msg.textout( '>' );
                        win_msg.textout( item_data[ i ].name );
                        win_msg.textout( '\n' );

                        win_msg.textout(_( "  classes :  " ));
                        if ( item_data[ i ].canBeEquipped( CLS.FIG ) ) win_msg.textout( 'f' );
                        if ( item_data[ i ].canBeEquipped( CLS.THI ) ) win_msg.textout( 't' );
                        if ( item_data[ i ].canBeEquipped( CLS.PRI ) ) win_msg.textout( 'p' );
                        if ( item_data[ i ].canBeEquipped( CLS.MAG ) ) win_msg.textout( 'm' );
                        if ( item_data[ i ].canBeEquipped( CLS.BIS ) ) win_msg.textout( 'b' );
                        if ( item_data[ i ].canBeEquipped( CLS.SAM ) ) win_msg.textout( 's' );
                        if ( item_data[ i ].canBeEquipped( CLS.LOR ) ) win_msg.textout( 'l' );
                        if ( item_data[ i ].canBeEquipped( CLS.NIN ) ) win_msg.textout( 'n' );
                        win_msg.textout(" \n");

                        if ( mem.canCarry )
                        {
                            mem_takes = mem;
                        }
                        else
                        {
                            win_msg.textout( _( "you cannot carry anything more.\n"  ));

                        ANOTHER_PUR:
                            win_msg.textout( _( "anyone else takes it(y/n)?"  ));

                            if ( answerYN != 'y')
                                break;

                            mem_takes = party.selectActiveMember( _( "who takes it(z:leave(9))? " ) 
                                                                , _( "leave" ) );
                            if( mem_takes is null )
                                break;
                            if( ! mem_takes.canCarry )
                            {
                                win_msg.textout( _( "%1 cannot carry anything more.\n" ) , mem_takes.name );
                                goto ANOTHER_PUR;
                            }
                        }

                        if ( mem.gold < item_data[ i ].gold )
                        {
                            win_msg.textout( _( "sorry, you cannot afford it.\n"  ));
                            win_msg.textout( _( "pool gold(y/n)? "  ));

                            if ( answerYN == 'n' )
                                continue;

                            party.poolGold( mem );
                            if ( mem.gold < item_data[ i ].gold )
                            {
                                win_msg.textout( _( "sorry, you cannot afford it.\n"  ));
                                dispShopBuyMenu;
                                continue;
                            }
                        }

                        mem.gold -= item_data[ i ].gold;
                        mem_takes.getItem( i );

                        shopitem[ i ]--;
                        last = shop_list( mem , top, kind, disp_lines , item );
                        party.win_disp();
                        win_msg.textout( _( "\njust what you needed.\n"  ));
                        break;
                    }
                }
                dispShopBuyMenu;
                break;
            default:
                break;
        }
    }
    goto WHO_BUY;
}


/**
  shop_list
  */ 
int shop_list( Member mem 
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
            win_status.print( 0, 0, "[ weapon: ]                  " );
            break;
        case ITM_KIND.ARMOR:    // armor
            win_status.print( 0, 0, "[ armor:  ]                  " );
            break;
        case ITM_KIND.SHIELD:   // shield
            win_status.print( 0, 0, "[ shield: ]                  " );
            break;
        case ITM_KIND.HELM:     // helm
            win_status.print( 0, 0, "[ helm:   ]                  " );
            break;
        case ITM_KIND.GLOVES:   // gloves
            win_status.print( 0, 0, "[ gloves: ]                  " );
            break;
        case ITM_KIND.ITEM:     // item
            win_status.print( 0, 0, "[ item:   ]                  " );
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
            if ( shopitem[ i ] != 0 )
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

                win_status.print( 1 + lines, 0 , "                             " );
                win_status.print( 1 + lines, 18, fillR( item_data[ i ].gold, 8 ) );
                win_status.print( 1 + lines, 0 , list );

                if ( shopitem[ i ] > 999 )
                    win_status.print( 1 + lines, 26, "*%1" , fillR( 999 , 3 ) );
                else
                    win_status.print( 1 + lines, 26, "*%1" , fillR( shopitem[ i ] , 3 ) );
            }
            else
            {
                win_status.print( 1 + lines , 0 , "-)                out of stock" );
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
  shop_sell
  */
void shop_sell()
{
    char ch;
    Member mem;
    Item itm;

    while ( true )
    {
        win_msg.textout( _( "whose item(z:leave(9))? "  ));

        while ( true )
        {
          ch = getChar();
          if (ch == 'z' || ch == '9' 
                  || (ch >= '1' && ch <= '1' + party.num - 1))
              break;
        }
        win_msg.textout( ch );
        if (ch == 'z' || ch == '9')
        {
            win_msg.textout( '\n' );
            return;
        }

        mem = party.mem[ ch - '1' ];
        win_msg.textout( "(" ~ mem.name ~ ")\n" );

        mem.inspect;

        while ( true )
        {
            win_msg.textout( _( "  which item(z:leave(9))? "  ));

            while ( true )
            {
                ch = getChar();
                if ( ch == 'z' || ch == '9' || 
                        (ch >= '1' && ch <= '8' && ! mem.item[ ch - '1' ].isNothing ) )
                    break;
            }
            win_msg.textout( ch );
            if ( ch == 'z' || ch == '9' )
            {
                win_msg.textout( '\n' );
                break;
            }
            else
            {
                itm = mem.item[ ch - '1' ];
                win_msg.textout( "(" ~ itm.getDispNameA ~ ")\n" );
                if ( itm.cursed )
                {
                    win_msg.textout( _( "    cursed item.\n"  ));
                    continue;
                }
                else if ( itm.equipped )
                {
                    win_msg.textout( _( "    equipped item.\n"  ));
                    continue;
                }
                if ( itm.gold != 0 )
                {
                    win_msg.textout( _( "    It will be %1 gp.(y/n)"  ), itm.gold / 2 );
                    if ( answerYN == 'n' )
                        continue;
                    mem.gold += itm.gold / 2;

                    shopitem[ itm.itemNo ]++;
                    win_msg.textout( "    " );
                    win_msg.textout( itm.name );
                    win_msg.textout( ".\n" );

                    mem.releaseItem( itm );
                    party.win_disp();
                    win_msg.textout( _( "    Anything else, noble sir?\n"  ));
                }
                else
                {
                    win_msg.textout( _( "    Not interested.\n"  ));
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
        win_msg.textout( _( "whose item(z:leave(9))? "  ));
        while ( true )
        {
          c = getChar();
          if ( c == 'z' || c == '9' 
                  || ( c >= '1' && c <= '1' + party.num - 1 ) )
              break;
        }
        win_msg.textout( c );
        if ( c == 'z' || c == '9' )
        {
            win_msg.textout( '\n' );
            return;
        }

        mem = party.mem[ c - '1' ];
        win_msg.textout( "(" ~ mem.name ~ ")\n" );
        for ( i = 0; i < MAXCARRY; i++ )
        {
            if ( mem.item[ i ].cursed )
            {
                win_msg.textout( "  " );
                win_msg.textout( i + 1 );
                win_msg.textout( ')' ~ mem.item[ i ].getDispName );
                win_msg.textout( '\n' );
            }
        }

        while ( true )
        {
            win_msg.textout( _( "which item(z:leave(9))?  "  ));
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
            win_msg.textout( c );
            if ( c == 'z' || c == '9' )
            {
                win_msg.textout( '\n' );
                break;
            }
            win_msg.textout( "(" ~ itm.getDispNameA ~ ")\n" );

            win_msg.textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
            if ( answerYN == 'n' )
                break;
            if ( mem.gold < itm.gold / 2)
            {
                win_msg.textout( _( "you can't afford it, pool gold(y/n)? " ) );
                if ( answerYN == 'n' )
                    return;
                party.poolGold( mem );
                if ( mem.gold < itm.gold / 2)
                {
                    win_msg.textout( _( "  still, you can't afford it\n" ) );
                    return;
                }
            }
            mem.gold -= itm.gold / 2;
            win_msg.textout( _( "uncursed and %1 is vanished...\n" ) , itm.getDispNameA );
            mem.releaseItem( itm );
            getChar();
            return;
        }
    }  
}


/**
  shop_identify -
 */
void shop_identify()
{
    char c;
    Member mem;
    Item itm;

    TOP:

    win_status.clear();
    win_msg.textout( _( "whose item(z:leave(9))? " ) );
    while ( true )
    {
        c = getChar();
        if ( c == 'z' || c == '9' || 
                ( c >= '1' && c <= '1' + party.num - 1 ) )
            break;
    }
    win_msg.textout( c );
    if ( c == 'z' || c == '9' )
    {
        win_msg.textout( '\n' );
        return;
    }

    mem = party.mem[ c - '1'];
    win_msg.textout( "(" ~ mem.name ~ ")\n" );

    mem.inspect;

    while ( true )
    {
        win_msg.textout( _( "which item(z:leave(9))? " ) );
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
        win_msg.textout( c );
        if (c == 'z' || c == '9')
        {
            win_msg.textout( '\n' );
            break;
        }

        win_msg.textout( "(" ~ itm.getDispNameA ~ ")\n" );
        if ( itm.undefined )
        {
            win_msg.textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
            if ( answerYN == 'n' )
                break;
            if ( mem.gold < itm.gold / 2 )
            {
                win_msg.textout( _( "you can't afford it, pool gold(y/n)? " ) );
                if ( answerYN == 'n')
                    return;
                party.poolGold( mem );
                if ( mem.gold < itm.gold / 2 )
                {
                    win_msg.textout( _( "  still, you can't afford it\n" ) );
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
        win_msg.textout( "\n" );
        win_msg.textout( _( "*** temple of dice, we have: ***\n" ) );
        setColor( CL.NORMAL );

        for ( i = 0; i < MAXMEMBER ; i++ )
        {
            if ( member[ i ].name != "" && member[ i ].status >= STS.PARALY
              && member[ i ].outflag==0 )
            {
                win_msg.textout( "  " );
                win_msg.textout( to!char( i + 'a' ) );
                win_msg.textout( ')' );
                win_msg.textout( member[ i ].name );
                switch ( member[ i ].status )
                {
                    case STS.PARALY:
                        win_msg.textout( "(paralized)\n" );
                        break;
                    case STS.STONED:
                        win_msg.textout("(stoned)\n");
                        break;
                    case STS.DEAD:
                        win_msg.textout("(dead)\n");
                        break;
                    case STS.ASHED:
                        win_msg.textout( "(ashed)\n" );
                        break;
                    default:
                        assert( 0 );
                }
            }
        }
        win_msg.textout( _( "  who needs help(z:leave(9))? " ) );
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
        win_msg.textout( c );
        if ( c == 'z' || c == '9' )
        {
            win_msg.textout( '\n' );
            goto EXIT;
        }

        mem = member[ c - 'a' ];
        win_msg.textout( "(" ~ mem.name ~ ")\n" );
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
        win_msg.textout( _( "the donation is %1 gp.\n" ) , donation );
        win_msg.textout( _( "  who will pay(z:leave(9))? " ) );

        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c < '1' + party.num )
                break;
        }
        win_msg.textout( c );

        if ( c == 'z' || c == '9' )
        {
            win_msg.textout( '\n' );
            break;
        }

        p = party.mem[ c - '1' ];
        win_msg.textout( "(" ~ p.name ~ ")\n" );
        if ( p.gold < donation )
        {
            win_msg.textout( _( "you don't have enough money.\n" ) );
            win_msg.textout( _( "  pool gold(y/n)? " ) );
            if (answerYN == 'n')
                goto EXIT;
            party.poolGold( p );
            if ( p.gold < donation )
            {
              win_msg.textout( _( "  still not enough...\n" ) );
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
        win_msg.textout( "\n*** murmur - " );
        getChar();
        win_msg.textout( "chant - " );
        getChar();
        win_msg.textout( "pray - " );
        getChar();
        win_msg.textout( "invoke! ***\n" );
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
            win_msg.textout( _( " %1 needs Bless now!\n" ) , mem.name );
            mem.status = STS.ASHED;
        }
        else
        {
            win_msg.textout( _( " %1 is buried...\n" ) , mem.name );
            mem.status = STS.LOST;
            mem.name = "";
        }
    }

EXIT:
    header_disp( HSTS.CASTLE );
    return;
}

