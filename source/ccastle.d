// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import lib_sdl;
import lib_screen;

import def;
import app;
import cedgeoftown;
import cparty;
import cmember;
import citem;



/**====== castle ==================================================*/
class Castle
{

public: 
    bool castleMain()
    {
        int rtncode=0;
        int i, j;
        char keycode;
        Member[] ng;
      
        if( party.memCount > 0 && party.memCountAlive == 0 )
        {
            // 全滅
            party.disband;  // 解散 -> p.outflag = OUT_F.DUNGEON
        }
        else
        {
            foreach( p ; party )
            {
                p.poisoned = false;

                if( p.status <= STS.AFRAID )
                {
                    p.status = STS.OK;
                    p.outflag = OUT_F.CASTLE; // in castle
                }
                else    // p.status >= STS.PARALY
                {
                    p.outflag = OUT_F.BAR; // in bar (and Temple of Cant)
                    ng ~= p;
                }
            }

            // 動けない人はパーティを抜ける
            foreach( p ; ng )
                party.remove( p );
            ng.length = 0;

        }


        dispHeader( HSTS.CASTLE );
        party.dispPartyWindow();
        scrClear;
      
        // ending check
        if ( party.memCountAlive >= 1 && party.doTheyHave( 171 ) == 1 )
            ending();
      
        txtMessage.disp;

        while( true )
        {
            setColor( CL.MENU );
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "******** castle ********\n"  ));
            txtMessage.textout( _( "g)inger's forest bar\n"  ));
            txtMessage.textout( _( "s)helton yankee flipper\n"  ));
            txtMessage.textout( _( "a)lbertsan's mart\n"  ));
            txtMessage.textout( _( "t)emple of dice\n"  ));
            txtMessage.textout( _( "e)dge of town\n"  ));
            txtMessage.textout( _( "************************\n"  ));
            setColor( CL.NORMAL );
            txtMessage.textout( _( "option? "  ));


            keycode = getCharFromList( "gsate" );

            switch( keycode )
            {
                case 'g': // ginger's bar
                    txtMessage.textout( _( "ginger's forest bar\n"  ));
                    bar();
                    break;
                case 's': // shelton hotel
                    if ( ! party.checkAlive )
                        continue;
                    txtMessage.textout( _( "shelton hotel\n"  ));
                    inn();
                    break;
                case 'a': // albertsan's
                    if ( ! party.checkAlive )
                        continue;
                    txtMessage.textout( _( "albertsan's mart\n"  ));
                    shop();
                    break;
                case 't': /* temple of dice */ 
                    if ( ! party.checkAlive )
                        continue;
                    txtMessage.textout( _( "temple of dice\n"  ));
                    temple();
                    break;
                case 'e': /* edge of town */ 
                    txtMessage.textout( _( "edge of tonw\n"  ));
                    rtncode = sceneEdgeOfTown.egOfTown();
                    if ( rtncode==1 )
                    {
                        goto MAZE;
                    } 
                    else if ( rtncode == 2 )
                    {
                        goto EXIT;
                    }
                    dispHeader( HSTS.CASTLE );
                    party.dispPartyWindow();
                    break;
                default:
                    continue;
            }
            txtStatus.clear;
        }
        EXIT:
        txtMessage.clear;
        return false;  /* leave game */
      
        MAZE:
        txtMessage.clear;
        return true;
    }

private:
    /**--------------------
       see Monster marks
       --------------------*/
    void seeMonsterMarks()
    {

        int i , top;
        char c;

        setColor( CL.MENU );
        txtMessage.textout( "\n" );
        txtMessage.textout( "****** monster marks! ******\n" );
        txtMessage.textout( _( "n)ext(6) z)leave(9)\n"  ));
        setColor( CL.NORMAL );
        txtMessage.textout( "option?\n" );
        top = 0;
        while( true )
        {

            rewriteOff;
            
            txtStatus.clear;

            for( i = 0; i < txtStatus.getHeight - 2 ; i++ )
            {
                if( top + i > 108)
                    continue; // 108 as # of DAEMON
                if( monstermarks[ top + i ] != 0)
                {
                    txtStatus.print( i + 1 , 0 
                            , formatText( "%1)%2" 
                                , fillR( top + i , 3 ) 
                                , monster_data[ top + i ].name ) );
                    txtStatus.print( i + 1 , txtStatus.getWidth - 8 , fillR( monstermarks[ top + i ] , 7 ) );
                }
                else
                {
                    txtStatus.print( i + 1 , 0 
                            , formatText( "%1)?????" , fillR( top + i , 3 ) ) );
                }
            }

            rewriteOn;

            c = getCharFromList( "z9n6" );

            if( c == 'z' || c == '9' )
                break;

            if( c == 'n' || c == '6' )
            {
                top += txtStatus.getHeight - 2;
                if (top > 108)
                    top = 0; // 108 as # of DAEMON ++++++++++++++++++
            }

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
      
        dispHeader( HSTS.INN );
      
        while ( true )
        {
            setColor( CL.MENU );
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "****** shelton yankee flipper hotel ******\n" ));
            setColor( CL.NORMAL );
            txtMessage.textout( _( "who will stay(z:leave(9))? "  ));

            ch = getCharFromList( "z9" ~ party.getCharList );

            if ( ch == 'z' || ch == '9' ) 
                break;

            mem = party.mem[ ch - '1' ];
            txtMessage.textout( mem.name ~ "\n" );
      
            if( mem.status >= STS.PARALY )
            {
                txtMessage.textout( _( "\n  ...You must be joking!\n\n"  ));
                continue;
            }

            // どうせみんな馬小屋にしか泊まらないんでしょ？
            // だからHP全回復にした。
            txtMessage.textout( _( "sleeping ...\n" ) );
            if( mem.hp < mem.maxhp )
            {
                mem.hp = mem.maxhp;
                txtMessage.textout( _( "%1 have been healed.\n" ) , mem.name );
            }

            mem.checkLevelUp();
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
                party.dispPartyWindow();
                txtMessage.textout( "*** happy birthday to you! ***\n" );
                mem.dispCharacter;
                getChar();
            }
            party.dispPartyWindow();

            mem.dispCharacter;
            // getChar;
        }
        txtMessage.textout( "\n" );
        dispHeader( HSTS.CASTLE );

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
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "*** ginger's forest bar ***\n"  ));
            txtMessage.textout( _( "f)orm a party  i)inspect\n"  ));
            txtMessage.textout( _( "d)ivvy gold  z)leave(9)\n"  ));
            txtMessage.textout( _( "e)quip #)see character\n"  ));
            txtMessage.textout( _( "s)ee monster marks\n"  ));
            txtMessage.textout( _( "***************************\n"  ));
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );
            return;
        }
        //////////////////// 


        int i, current=0;
        char keycode;

        dispHeader( HSTS.BAR );
        dispBarMenu;

        while( true )
        {
            keycode = getCharFromList( "fidz9es" ~ party.getCharList );

            if( keycode >= '1' && keycode <= party.memCount + '0')
            {
                current = keycode - '1';
                party.mem[ current ].dispCharacter;
                continue;
            }

            switch( keycode )
            {
                case 'f': /* form a party */
                    txtMessage.textout( _( "form a party\n"  ));
                    barFormParty();
                    txtStatus.clear();
                    dispBarMenu;
                    break;

                case 'i':   // i) inspect
                    if( party.memCount < 1 )
                        break;
                    txtMessage.textout( _( "inspect\n"  ));
                    party.inspect();
                    txtStatus.clear();
                    dispBarMenu;
                    break;

                case 'd':   // divvy
                    if( party.memCount < 2 )
                        break;
                    txtMessage.textout( _( "divvy gold\n"  ));
                    party.divvy;
                    party.mem[ current ].dispCharacter;
                    dispBarMenu;
                    break;

                case 'z': 
                case '9':   // z)leave(9)
                    txtMessage.textout( _( "leave the bar\n"  ));
                    dispHeader( HSTS.CASTLE );
                    return;


                case 'e':   // equip
                    if( party.memCount < 1 )
                        break;
                    txtMessage.textout( _( "equip\n"  ));
                    party.equip;
                    dispBarMenu;
                    break;

                case 's':   // see monster marks 
                    txtMessage.textout( _( "see monster marks\n"  ));
                    seeMonsterMarks;
                    txtStatus.clear();
                    dispBarMenu;
                    break;

                default:
                    break;
            }
        }

    }



    /*--------------------
       barFormParty - パーティー編成
       --------------------*/
    void barFormParty()
    {
        char keycode;
        char c;
        
        barMemberDisp();
        txtMessage.textout( _( "select members(1,..,6,a,b,... ,z:leave(9))\n" ) );
        while( true )
        {
            keycode = getCharFromList( "abcdefghijklmnopqrstuvwx" ~ party.getCharList ~ "z9" );

            if ( keycode == 'z' || keycode == '9' )
                break;

            // add member
            if ( keycode >= 'a' && keycode <= 'a' + MAXMEMBER )
            {
                if ( party.memCount == 6 )
                    continue;

                if( member[ keycode - 'a' ].name != ""
                        && member[ keycode - 'a' ].outflag == 0 )
                {
                    if( member[ keycode - 'a' ].status == STS.LOST )
                    {
                        txtMessage.textout( _( "  ...You must be joking!\n"  ));
                        continue;
                    }

                    member[ keycode - 'a' ].outflag = OUT_F.CASTLE;
                    party.add( member[ keycode - 'a' ] );

                    barMemberDisp();
                    party.dispPartyWindowSub();
                }

            }
            else
            // remove member    1-6   
            {
                if ( party.memCount == 0 )
                    continue;

                c = to!char( keycode - '1' );
                party.mem[ c ].outflag = OUT_F.BAR;
                party.remove( party.mem[ c ] );

                barMemberDisp();
                party.dispPartyWindowSub();
            }
        }
        return;
    }


    /*--------------------
       barMemberDisp - 追加メンバーリスト表示
       --------------------*/
    void barMemberDisp()
    {
        int i, j, dispCount;
        int x;
        string name;
      
        txtStatus.clear();
      
        rewriteOff;

        dispCount = 0;

        for ( i = 0; i < MAXMEMBER; i++ )
        {
            if ( member[ i ].name != "" && member[ i ].outflag == OUT_F.BAR )
            {

                // パーティ内にいる
                foreach( p ; party )
                    if ( p is member[ i ] )
                        continue;

                name = formatText( "%1)%2"  
                                , to!string( cast(char)( 'a' + i ) )
                                , leftB( member[ i ].name , 13 ) );

                x = ( ( dispCount % 2 == 0 ) ? 0 : 16 );
                member[ i ].setStatusColor;
                txtStatus.print( 1 + ( dispCount / 2 ),  x , name ) ;

                dispCount ++;

            }
        }

        setColor( CL.NORMAL );
        rewriteOn;
        
        return;

    }


    //////////////////////////////////////////////////////////////////////////////////
    //
    //------ albertsan's mart --------------------------------------
    //
    //////////////////////////////////////////////////////////////////////////////////

    void shop()
    {
        char c;
      
        dispHeader( HSTS.SHOP );
      
        while ( true )
        {
            txtStatus.clear();
            setColor( CL.MENU );
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "****** albertsan's mart ******\n"  ));
            txtMessage.textout( _( "b)uy s)ell u)ncurse i)dentify\n"  ));
            txtMessage.textout( _( "p)ool gold z)leave(9)\n"  ));
            txtMessage.textout( _( "******************************\n"  ));
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );

            c = getCharFromList( "bsuipz9" );
            switch ( c )
            {
                case 'p': /* pool gold */
                    txtMessage.textout( _( "pool gold\n"  ));
                    txtMessage.textout( _( "pool gold to whom(z:leave(9))? "  ));
                    c = getCharFromList( "z9" ~ party.getCharList );
                    if( ( c == 'z' || c == '9' ) )
                    {
                        txtMessage.textout( to!string( c ) ~ ")\n" );
                    }
                    else
                    {
                        txtMessage.textout( to!string( c ) ~ "(" ~ party.mem[ c - '1' ].name ~ ")\n" );
                        party.poolGold( c - '1' );
                    }
                    break;
                    
                case 'z': /* leave */
                case '9': /* leave */
                    txtMessage.textout( _( "leave the mart\n"  ));
                    dispHeader( HSTS.CASTLE );
                    return;

                case 'b': /* buy */
                    txtMessage.textout( _( "buy\n"  ));
                    dispHeader( HSTS.CASTLE );
                    shopBuy();
                    break;

                case 's': /* sell */
                    txtMessage.textout( _( "sell\n"  ));
                    shopSell();
                    break;

                case 'u': // uncurse
                    txtMessage.textout( _( "uncurse\n"  ));
                    uncurse();
                    party.calcAtkAC;
                    party.dispPartyWindow();
                    break;

                case 'i': // identify
                    txtMessage.textout( _( "identify\n"  ));
                    shopIdentify();
                    break;

                default:
                    break;
            }

        }
    }


    /**
      shop_buy - 
      */
    void shopBuy()
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
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "********* buy **********\n"  ));
            txtMessage.textout( _( "b)uy p)ick it up\n"  ));
            txtMessage.textout( _( "n)ext page(6) z)leave(9)\n"  ));
            txtMessage.textout( _( "------\n"  ));
            txtMessage.textout( _( "w)eapon a)rmor s)hield\n"  ));
            txtMessage.textout( _( "h)elm g)loves i)tem\n"  ));
            txtMessage.textout( _( "************************\n"  ));
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );
            return;
        }

    WHO_BUY:
        mem = party.selectActiveMember( _( "who will buy(z:leave(9))? " ) , _( "leave" ) );
        if( mem is null )
            return;

        dispShopBuyMenu;

        while ( true )
        {
            txtStatus.clear();
            // ref: disp_lines , item[]
            last = shopDispList( mem , top, kind, disp_lines, item );   

            c = getCharFromList( "bpn6z9washgi" );
            switch ( c )
            {
                case 'z':
                case '9':
                    txtMessage.textout( _( "leave\n"  ));
                    txtStatus.clear();
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
                    txtMessage.textout( _( "pick it up\n"  ));
                    txtMessage.textout( _( "which pick it up(a,b,...,z:quit(9))? "  ));
                    while ( true )
                    {
                        c = getChar();
                        if ( c == 'z' || c == '9' || 
                              ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                            break;
                    }
                    txtMessage.textout( c );
                    txtMessage.textout( '\n' );
                    if ( c == 'z' || c == '9' )
                        break;

                    i = item[ c - 'a' ];
                    item_data[ i ].dispInfo;
                    getChar;
                    dispShopBuyMenu;
                    break;
                case 'b':
                    txtMessage.textout( _( "buy\n"  ));
                    while ( true )
                    {
                        txtMessage.textout( _( "which buy(a,b,...,z:quit(9))? "  ));
                        while ( true )
                        {
                          c = getChar();
                          if ( c == 'z' || c == '9' || 
                                  ( ( c >= 'a' ) && ( c < 'a' + disp_lines ) && ( item[ c - 'a' ] < MAXITEM ) ) )
                              break;
                        }
                        txtMessage.textout( c );
                        txtMessage.textout( '\n' );
                        if ( c == 'z' || c == '9' )
                        {
                          break;
                        }
                        else
                        {
                            i = item[ c - 'a' ];
                            if ( i >= MAXITEM || shopitem[ i ] == 0 )
                            {
                                txtMessage.textout( _( "out of stock.\n"  ));
                                break;
                            }
                            txtMessage.textout( '>' );
                            txtMessage.textout( item_data[ i ].name );
                            txtMessage.textout( '\n' );

                            txtMessage.textout(_( "  classes :  " ));
                            if ( item_data[ i ].canBeEquipped( CLS.FIG ) ) txtMessage.textout( 'f' );
                            if ( item_data[ i ].canBeEquipped( CLS.THI ) ) txtMessage.textout( 't' );
                            if ( item_data[ i ].canBeEquipped( CLS.PRI ) ) txtMessage.textout( 'p' );
                            if ( item_data[ i ].canBeEquipped( CLS.MAG ) ) txtMessage.textout( 'm' );
                            if ( item_data[ i ].canBeEquipped( CLS.BIS ) ) txtMessage.textout( 'b' );
                            if ( item_data[ i ].canBeEquipped( CLS.SAM ) ) txtMessage.textout( 's' );
                            if ( item_data[ i ].canBeEquipped( CLS.LOR ) ) txtMessage.textout( 'l' );
                            if ( item_data[ i ].canBeEquipped( CLS.NIN ) ) txtMessage.textout( 'n' );
                            txtMessage.textout(" \n");

                            if ( mem.canCarry )
                            {
                                mem_takes = mem;
                            }
                            else
                            {
                                txtMessage.textout( _( "you cannot carry anything more.\n"  ));

                            ANOTHER_PUR:
                                txtMessage.textout( _( "anyone else takes it(y/n)?"  ));

                                if ( answerYN != 'y')
                                    break;

                                mem_takes = party.selectActiveMember( _( "who takes it(z:leave(9))? " ) 
                                                                    , _( "leave" ) );
                                if( mem_takes is null )
                                    break;
                                if( ! mem_takes.canCarry )
                                {
                                    txtMessage.textout( _( "%1 cannot carry anything more.\n" ) , mem_takes.name );
                                    goto ANOTHER_PUR;
                                }
                            }

                            if ( mem.gold < item_data[ i ].gold )
                            {
                                txtMessage.textout( _( "sorry, you cannot afford it.\n"  ));
                                txtMessage.textout( _( "pool gold(y/n)? "  ));

                                if ( answerYN == 'n' )
                                    continue;

                                party.poolGold( mem );
                                if ( mem.gold < item_data[ i ].gold )
                                {
                                    txtMessage.textout( _( "sorry, you cannot afford it.\n"  ));
                                    dispShopBuyMenu;
                                    continue;
                                }
                            }

                            mem.gold -= item_data[ i ].gold;
                            mem_takes.getItem( i );

                            shopitem[ i ]--;
                            last = shopDispList( mem , top, kind, disp_lines , item );
                            party.dispPartyWindow();
                            txtMessage.textout( _( "\njust what you needed.\n"  ));
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
      shopDispList
      */ 
    int shopDispList( Member mem 
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
                txtStatus.print( 0, 0, "[ weapon: ]                  " );
                break;
            case ITM_KIND.ARMOR:    // armor
                txtStatus.print( 0, 0, "[ armor:  ]                  " );
                break;
            case ITM_KIND.SHIELD:   // shield
                txtStatus.print( 0, 0, "[ shield: ]                  " );
                break;
            case ITM_KIND.HELM:     // helm
                txtStatus.print( 0, 0, "[ helm:   ]                  " );
                break;
            case ITM_KIND.GLOVES:   // gloves
                txtStatus.print( 0, 0, "[ gloves: ]                  " );
                break;
            case ITM_KIND.ITEM:     // item
                txtStatus.print( 0, 0, "[ item:   ]                  " );
                break;
            default:
                assert( 0 );
        }
        setColor( CL.GOLD );
        txtStatus.print( 0, 12, "%1 gp." , fillR( mem.gold, 14 ) );

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

                    if( item_data[ i ].kind == ITM_KIND.ITEM )
                    {
                        setColor = CL.EQUIP_OK;
                    }
                    else if ( item_data[ i ].canBeEquipped( mem.Class ) )
                    {
                        setColor = CL.EQUIP_OK;
                        canEquip = " ";
                    }
                    else
                    {
                        setColor = CL.EQUIP_NG;
                        canEquip = "#";
                    }

                    list = formatText( "%1)%2%3" 
                            , cast(char)( 'a' + lines ) 
                            , canEquip
                            , item_data[ i ].name ) ;

                    txtStatus.print( 1 + lines, 0 , "                             " );
                    txtStatus.print( 1 + lines, 18, fillR( item_data[ i ].gold, 8 ) );
                    txtStatus.print( 1 + lines, 0 , list );

                    if ( shopitem[ i ] > 999 )
                        txtStatus.print( 1 + lines, 26, "*%1" , fillR( 999 , 3 ) );
                    else
                        txtStatus.print( 1 + lines, 26, "*%1" , fillR( shopitem[ i ] , 3 ) );
                }
                else
                {
                    setColor = CL.EQUIP_NG;
                    txtStatus.print( 1 + lines , 0 , "-)                out of stock" );
                }
                lines++;
                j = i;
                if ( lines >= SCRW_Y_SIZ - 2 )
                    break;
            }
            i++;
        }

        rewriteOn;
        setColor = CL.NORMAL;

        return j ;  // last
    }


    /**
      shop_sell
      */
    void shopSell()
    {
        char ch;
        Member mem;
        Item itm;

        while ( true )
        {
            txtMessage.textout( _( "whose item(z:leave(9))? "  ));

            ch = getCharFromList( "z9" ~ party.getCharList );
            txtMessage.textout( ch );
            if (ch == 'z' || ch == '9')
            {
                txtMessage.textout( '\n' );
                return;
            }

            mem = party.mem[ ch - '1' ];
            txtMessage.textout( "(" ~ mem.name ~ ")\n" );

            mem.inspect;

            while ( true )
            {
                txtMessage.textout( _( "  which item(z:leave(9))? "  ));

                ch = getCharFromList( "z9" ~ mem.getCharItemList );
                txtMessage.textout( ch );
                if ( ch == 'z' || ch == '9' )
                {
                    txtMessage.textout( '\n' );
                    break;
                }

                itm = mem.item[ ch - '1' ];
                txtMessage.textout( "(" ~ itm.getDispNameA ~ ")\n" );
                if ( itm.cursed )
                {
                    txtMessage.textout( _( "    cursed item.\n"  ));
                    continue;
                }
                else if ( itm.equipped )
                {
                    txtMessage.textout( _( "    equipped item.\n"  ));
                    continue;
                }
                if ( itm.gold != 0 )
                {
                    txtMessage.textout( _( "    It will be %1 gp.(y/n)"  ), itm.gold / 2 );
                    if ( answerYN == 'n' )
                        continue;
                    mem.gold += itm.gold / 2;

                    shopitem[ itm.itemNo ]++;
                    txtMessage.textout( "    " );
                    txtMessage.textout( itm.name );
                    txtMessage.textout( ".\n" );

                    mem.releaseItem( itm );
                    party.dispPartyWindow();
                    txtMessage.textout( _( "    Anything else, noble sir?\n"  ));
                }
                else
                {
                    txtMessage.textout( _( "    Not interested.\n"  ));
                }
                mem.inspect;
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
            txtMessage.textout( _( "whose item(z:leave(9))? "  ));
            while ( true )
            {
              c = getChar();
              if ( c == 'z' || c == '9' 
                      || ( c >= '1' && c <= '1' + party.memCount - 1 ) )
                  break;
            }
            txtMessage.textout( c );
            if ( c == 'z' || c == '9' )
            {
                txtMessage.textout( '\n' );
                return;
            }

            mem = party.mem[ c - '1' ];
            txtMessage.textout( "(" ~ mem.name ~ ")\n" );
            for ( i = 0; i < MAXCARRY; i++ )
            {
                if ( mem.item[ i ].cursed )
                {
                    txtMessage.textout( "  " );
                    txtMessage.textout( i + 1 );
                    txtMessage.textout( ')' ~ mem.item[ i ].getDispName );
                    txtMessage.textout( '\n' );
                }
            }

            while ( true )
            {
                txtMessage.textout( _( "which item(z:leave(9))?  "  ));
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
                txtMessage.textout( c );
                if ( c == 'z' || c == '9' )
                {
                    txtMessage.textout( '\n' );
                    break;
                }
                txtMessage.textout( "(" ~ itm.getDispNameA ~ ")\n" );

                txtMessage.textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
                if ( answerYN == 'n' )
                    break;
                if ( mem.gold < itm.gold / 2)
                {
                    txtMessage.textout( _( "you can't afford it, pool gold(y/n)? " ) );
                    if ( answerYN == 'n' )
                        return;
                    party.poolGold( mem );
                    if ( mem.gold < itm.gold / 2)
                    {
                        txtMessage.textout( _( "  still, you can't afford it\n" ) );
                        return;
                    }
                }
                mem.gold -= itm.gold / 2;
                txtMessage.textout( _( "uncursed and %1 is vanished...\n" ) , itm.getDispNameA );
                mem.releaseItem( itm );
                getChar();
                return;
            }
        }  
    }


    /**
      shop_identify -
     */
    void shopIdentify()
    {
        char c;
        Member mem;
        Item itm;

        TOP:

        txtStatus.clear();
        txtMessage.textout( _( "whose item(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' || 
                    ( c >= '1' && c <= '1' + party.memCount - 1 ) )
                break;
        }
        txtMessage.textout( c );
        if ( c == 'z' || c == '9' )
        {
            txtMessage.textout( '\n' );
            return;
        }

        mem = party.mem[ c - '1'];
        txtMessage.textout( "(" ~ mem.name ~ ")\n" );

        mem.inspect;

        while ( true )
        {
            txtMessage.textout( _( "which item(z:leave(9))? " ) );
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
            txtMessage.textout( c );
            if (c == 'z' || c == '9')
            {
                txtMessage.textout( '\n' );
                break;
            }

            txtMessage.textout( "(" ~ itm.getDispNameA ~ ")\n" );
            if ( itm.undefined )
            {
                txtMessage.textout( _( "That will be %1 gp.(y/n)"  ), itm.gold / 2 );
                if ( answerYN == 'n' )
                    break;
                if ( mem.gold < itm.gold / 2 )
                {
                    txtMessage.textout( _( "you can't afford it, pool gold(y/n)? " ) );
                    if ( answerYN == 'n')
                        return;
                    party.poolGold( mem );
                    if ( mem.gold < itm.gold / 2 )
                    {
                        txtMessage.textout( _( "  still, you can't afford it\n" ) );
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
      
        dispHeader( HSTS.TEMPLE );
      
        while ( true )
        {

            setColor( CL.MENU );
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "*** temple of dice, we have: ***\n" ) );

            for ( i = 0; i < MAXMEMBER ; i++ )
            {
                if ( member[ i ].name != "" && member[ i ].status >= STS.PARALY
                  && member[ i ].outflag==0 )
                {
                    member[ i ].setStatusColor;
                    txtMessage.textout( "  " );
                    txtMessage.textout( to!char( i + 'a' ) );
                    txtMessage.textout( ')' );
                    txtMessage.textout( member[ i ].name );
                    switch ( member[ i ].status )
                    {
                        case STS.PARALY:
                            txtMessage.textout( "(paralized/lv%1)\n" , member[ i ].level );
                            break;
                        case STS.STONED:
                            txtMessage.textout( "(stoned/lv%1)\n" , member[ i ].level );
                            break;
                        case STS.DEAD:
                            txtMessage.textout( "(dead/lv%1)\n" , member[ i ].level );
                            break;
                        case STS.ASHED:
                            txtMessage.textout( "(ashed/lv%1)\n" , member[ i ].level );
                            break;
                        case STS.LOST:
                            txtMessage.textout( "(lost/lv%1)\n" , member[ i ].level );
                            break;
                        default:
                            assert( 0 );
                    }
                }
            }
            setColor( CL.NORMAL );
            txtMessage.textout( _( "  who needs help(z:leave(9))? " ) );
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
            txtMessage.textout( c );
            if ( c == 'z' || c == '9' )
            {
                txtMessage.textout( '\n' );
                goto EXIT;
            }

            mem = member[ c - 'a' ];
            txtMessage.textout( "(" ~ mem.name ~ ")\n" );
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
                case STS.ASHED:
                    donation = 350;
                    ratio = 67;
                    break;
                default: // STS.LOST
                    donation = 500;
                    ratio = 50;
                    break;
            }
            donation *= mem.level;
            txtMessage.textout( _( "the donation is %1 gp.\n" ) , donation );
            txtMessage.textout( _( "  who will pay(z:leave(9))? " ) );

            while ( true )
            {
                c = getChar();
                if ( c == 'z' || c == '9' )
                    break;
                if ( c >= '1' && c < '1' + party.memCount )
                    break;
            }
            txtMessage.textout( c );

            if ( c == 'z' || c == '9' )
            {
                txtMessage.textout( '\n' );
                break;
            }

            p = party.mem[ c - '1' ];
            txtMessage.textout( "(" ~ p.name ~ ")\n" );
            if ( p.gold < donation )
            {
                txtMessage.textout( _( "you don't have enough money.\n" ) );
                txtMessage.textout( _( "  pool gold(y/n)? " ) );
                if (answerYN == 'n')
                    goto EXIT;
                party.poolGold( p );
                if ( p.gold < donation )
                {
                  txtMessage.textout( _( "  still not enough...\n" ) );
                  getChar();
                  goto EXIT;
                }
            }

            p.gold -= donation;
            if ( ratio < 100 )
            { // vitalityによる修正
                if ( p.vit[ 0 ] + p.vit[ 1 ] >= 18)
                    /* ratio += 30; */
                    ratio += 20;
                else if ( p.vit[ 0 ] + p.vit[ 1 ] >= 17)
                    /* ratio += 20; */
                    ratio += 15;
                else if ( p.vit[ 0 ] + p.vit[ 1 ] >= 16)
                    ratio += 10;
                else if ( p.vit[ 0 ] + p.vit[ 1 ] <= 3)
                    ratio -= -20;
                else if ( p.vit[ 0 ] + p.vit[ 1 ] <= 5)
                    ratio -= -10;

                if ( ratio > 95 ) ratio = 95;
                if ( ratio < 10 ) ratio = 10;
            }
            txtMessage.textout( "\n*** murmur - " );
            getChar();
            txtMessage.textout( "chant - " );
            getChar();
            txtMessage.textout( "pray - " );
            getChar();

            int dice = get_rand( 99 ) + 1;
            foreach( dot ; 0 .. dice / 10 ) 
            {
                txtMessage.textout( "." );
                getChar( 50 );
            }

            txtMessage.textout( "\ninvoke! ***\n" );
            getChar();

            if ( dice <= ratio )
            { // succeed
                mem.hp = mem.maxhp;
                mem.status = STS.OK;
                if ( ratio != 100 )
                    mem.vit[ 0 ]--;
            }
            else if( mem.status == STS.DEAD )
            {
                txtMessage.textout( _( " %1 needs Bless now!\n" ) , mem.name );
                mem.status = STS.ASHED;
            }
            else if( mem.status == STS.ASHED )
            {
                txtMessage.textout( _( " %1's body is vanished...\n" ) , mem.name );
                foreach( itm ; mem.item )
                    itm.release;
                mem.gold = 0;
                mem.status = STS.LOST;
            }
            else
            {
                txtMessage.textout( _( " %1 is no longer in this world...\n" ) , mem.name );
                mem.status = STS.NIL;
                mem.name = "";
            }
        }

        if( autosave ) appSave;

    EXIT:
        dispHeader( HSTS.CASTLE );
        return;
    }

}
