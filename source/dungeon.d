// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : format , split , chop ;
import std.conv;
import std.random;

// derelict SDL
/* import derelict.sdl2.sdl; */

// mysource 
/* import lib_sdl; */
import lib_screen;
import lib_readline;
import app;
import def;

import cParty;
import cMember;
import cMap;
import cItem;
import cItemDef;

import cMonsterDef;


/*====== dangeon ====================================================*/

/**
   if rtnval!=0 then quit from maze
*/
bool dungeon_main()
{

    int i; 
    bool leave_game = false;
    int  dx, dy;
    char c;
    bool doorflg = false;

    int rate_encount;   // -1 : not encount

    char keycode;
  
    /* static char dummy_test_cnt[4]; */
    /* strcpy (&(dummy_test_cnt[0]),"00¥n"); */
  
    party.ac = 0;
    party.step = 0;
    party.status = 0;
    party.setDungeon;
    party.dungeon.setDispPos;
  
    for ( i = 0; i < party.num; i++ )
    {
        party.mem[ i ].outflag = OUT_F.DUNGEON;
        party.mem[ i ].x = 0;
        party.mem[ i ].y = 0;
        party.mem[ i ].layer = 99;
    }
  
    party.dungeon.initDisp();
    party.dungeon.disp();
    header_disp( HSTS.DUNGEON );
    party.win_disp();
 

    while ( party.layer > 0 )
    {

        // in rock check
        if ( party.dungeon.checkInRock )
        {
            win_msg.textout( _( "\n*** in rock! ***\n" ) );
            for ( i = 0; i < party.num; i++ )
                party.mem[ i ].status = STS.LOST;
            party.win_disp();
            getChar();
            party.layer = 0;
            party.olayer = 0;
            party.setDungeon;
            party.num = 0;
            goto EXIT;
        }

        dx = 0;
        dy = 0;
        rate_encount = RATE_ENCOUNT;

        keycode = getChar();
        switch ( keycode )
        {
            case '?':
                setColor( CL.MENU );
                win_msg.textout( _( "************* dungeon help *************\n" ) );
                win_msg.textout( _( "--- assigned keys ---\n" ) );
                win_msg.textout( _( "h/4:west, j/2:south, k/8:north, l/6:east\n" ) );
                win_msg.textout( _( "c/9:camp, o/5:open door, u:unlock door\n" ) );
                win_msg.textout( _( "./3:look for monsters, S:protect all\n" ) );
                win_msg.textout( _( "s:search hidden doors, Q:heal all\n" ) );
                win_msg.textout( _( "--- map info ---\n" ) );
                win_msg.textout( _( "|/-/X:wall, +:door, =:locked door\n" ) );
                win_msg.textout( _( "$:darkzone, </>:stairs, ' ':floor\n" ) );
                win_msg.textout( _( "@:your party, ^:unknown\n" ) );
                win_msg.textout( _( "*****************************************\n" ) );
                setColor( CL.NORMAL );
                break;
            case 'Q':
                if ( party.layer > 0 )
                {
                    party.heal_all();
                    win_msg.textout( _( "heal all done.\n" ) );
                    header_disp( HSTS.DUNGEON );
                    party.win_disp();
                }
                break;
            case 'S':
                if ( party.layer > 0 )
                {
                    party.protect_all();
                    win_msg.textout( _( "protect all done.\n" ) );
                    header_disp( HSTS.DUNGEON );
                    party.win_disp();
                }
                break;
            case '<':   // up stairs
                switch( party.dungeon.upStairs() )
                {
                    case 2: /* exit from maze */
                        goto EXIT;
                    case 1: /* not encount */
                        rate_encount = -1;
                        break;
                    default:
                        break;
                }
                break;
            case '>':   // down stairs   
                switch( party.dungeon.downStairs() )
                {
                    case 2: /* exit from maze */
                        goto EXIT;
                    case 1: /* not encount */
                        rate_encount = -1;
                        break;
                    default:
                        break;
                }
                break;
            case 'o':
            case '5':
                if( ! doorflg )
                {
                    doorflg = true;
                    win_msg.textout( _( "which door? " ) );
                    win_msg.textout( "\n" );
                }
                break;
            case 'h':
            case '4':
                dx = -1;
                break;
            case 'l':
            case '6':
                dx = 1;
                break;
            case 'k':
            case '8':
                dy =  -1;
                break;
            case 'j':
            case '2':
                dy = 1;
                break;
            case '.':
            case '3':
                party.ox = party.x;
                party.oy = party.y;
                party.olayer = party.layer;
                step_proc();
                rate_encount = RATE_ENCOUNT_STOP;   // 1/64
                break;
            case 'u': // unlock a door
                if ( ! party.dungeon.unlockDoor )
                    win_msg.textout( _( "failed.\n" ) );
                else
                    win_msg.textout( _( "click!\n" ) );
                break;
            case 's': // search a hidden door (and members in maze)
                win_msg.textout( _( "searching" ) );
                for ( i = 0; i < get_rand( 7 ) + 3; i++ )
                {
                    win_msg.textout( '.' );
                    getChar();
                }
                win_msg.textout( _( "done\n" ) );

                party.dungeon.searchMember;
                party.dungeon.searchHiddenDoor;

                break;
            case 'c':
            case '9':
                if ( camp() != 0 )
                {
                    leave_game = true; // quit from maze
                    goto EXIT;
                }
                step_proc();
                break;
            default:
                if( debugmode || debugmodeOffFlg )
                    checkDebugCommand( keycode );
                break;
        }


        if ( dx != 0 || dy != 0 || keycode == '.' || keycode == '3' )
        {

            step_proc();

            if( ! party.dungeon.isPassable( party.y + dy , party.x + dx , doorflg  ) )
            {
                win_msg.textout( _( "      ... ouch!\n" ) );
            }
            else
            {
                party.olayer = party.layer;
                party.ox = party.x;
                party.oy = party.y;
                party.x += dx;
                party.y += dy;
                party.dungeon.disp();

                switch( party.dungeon.event_chk() )
                {
                    case 2: /* exit from maze */
                        goto EXIT;
                    case 1: /* not encount */
                        rate_encount = -1;
                        break;
                    default:
                        break;
                }

                party.dungeon.disp();
                /* header_disp( HSTS.DUNGEON ); */
            }


            /////////////////
            //debug 用
            if( party.x < -99 )
            /////////////////
            // check encounter
            if ( rate_encount > 0 && ( get_rand( rate_encount ) == 0 ) )
                switch( party.dungeon.encounter( 0 ) )
                {
                    case BATTLE_RESULT.WON:
                    case BATTLE_RESULT.RAN:
                    case BATTLE_RESULT.LEAVE:
                        break;
                    case BATTLE_RESULT.LOST:
                        goto EXIT;
                    default:
                        assert( 0 );
                }


            if ( doorflg )
                doorflg = false;
        }
    }

EXIT:
    party.ac = 0;
  
    party.win_disp();
    if( leave_game )
        return false;   // leave game
    else
        return true;    // go to castle

}


void checkDebugCommand( char keycode )
{
    switch( keycode )
    {
        case 'D':
            if( debugmode || debugmodeOffFlg )
            {
                if( debugmode )
                {
                    debugmode = false;
                    debugmodeOffFlg = true;
                }
                else
                {
                    debugmode = true;
                    debugmodeOffFlg = true;
                }
                header_disp( HSTS.DUNGEON );
                party.dungeon.disp;
            }
            break;
        case 'E':   // EncountRoom 出力
            if ( debugmode && party.layer > 0 )
                party.dungeon.testOutputEncountRoom;
            break;
        case 'M':
            if ( debugmode && party.layer > 0 )
            {
                if( ! party.isMapper )
                {
                    party.setMapper;
                    party.setLight;
                    party.lightCount = 0;
                }
                else
                {
                    party.resetMapper;
                }
                header_disp( HSTS.DUNGEON );
                party.dungeon.disp;
            }
            break;
        case 'F':
            if ( debugmode && party.layer > 0 )
            {
                if( ! party.isFloat )
                    party.setFloat;
                else
                    party.resetFloat;
                header_disp( HSTS.DUNGEON );
            }
            break;
        case 'I':
            if ( debugmode && party.layer > 0 )
            {
                if( ! party.isIdentify )
                    party.setIdentify;
                else
                    party.resetIdentify;
                header_disp( HSTS.DUNGEON );
            }
            break;
        case 'H':
            if ( debugmode && party.layer > 0 )
            {
                if( ! party.isScope )
                {
                    party.setScope;
                    party.scopeCount = 999;
                }
                else
                {
                    party.resetScope;
                }
                header_disp( HSTS.DUNGEON );
                party.dungeon.disp;
            }
            break;
        case 'L':
            if ( debugmode && party.layer > 0 )
            {
                if( ! party.isLight )
                {
                    party.setLight;
                    party.lightCount = 999;
                }
                else
                {
                    party.resetLight;
                }
                header_disp( HSTS.DUNGEON );
                party.dungeon.disp;
            }
            break;
        case '<':
            if ( debugmode && party.layer > 0 ){
              party.layer--;
              party.setDungeon;
              party.dungeon.initDisp;
              party.dungeon.disp;
              header_disp( HSTS.DUNGEON );
            }
            break;
        case '>':
            if ( debugmode && party.layer < MAXLAYER ){
              party.layer++;
              party.setDungeon;
              party.dungeon.initDisp;
              party.dungeon.disp;
              header_disp( HSTS.DUNGEON );
            }
            break;
        default:
            break;
    }
}

// 一歩毎の処理
void step_proc()
{
    int i;

    party.step++;
    party.hpplus();

    for ( i = 0; i < party.num; i++ )
    {
        if ( party.mem[ i ].poisoned  && ( get_rand( 7 ) == 0 ) )
        {
            if( party.mem[ i ].hp < 10 )
                party.mem[ i ].hp --;
            else
                party.mem[ i ].hp -= party.mem[ i ].hp / 10 ;

            if ( party.mem[ i ].hp < 1 )
                party.mem[ i ].hp = 1;
        }

        if ( party.mem[ i ].status <= STS.AFRAID && get_rand( 15 ) == 0 )
        {
            if (party.mem[ i ].status == STS.AFRAID )
                party.mem[ i ].status = STS.OK;
        }
    }

    party.win_disp( false );

    if ( party.isLight && --party.lightCount < 0 )
    {
        party.lightCount = 0;
        party.resetLight;
        header_disp( HSTS.DUNGEON , false);
    }

    if ( party.isScope && --party.scopeCount < 0 )
    {
        party.scopeCount = 0;
        party.resetScope;
        header_disp( HSTS.DUNGEON , false);
    }

    rewriteOn;

    return;

}


/*====== camp ====================================================*/
// rtnval!=0 : quit from maze(leave game)
int camp()
{
    int i, rtnval = 0;
    char ch, c;

    Member mem;

    header_disp( HSTS.CAMP );

    mem = party.mem[ 0 ];
    mem.inspect;

    bool first_disp = true;

    while ( true )
    {
        setColor( CL.MENU );
        win_msg.textout( _( "******** camp ********\n" ) );
        win_msg.textout( _( "d)rop(0)     e)quip\n" ) );
        win_msg.textout( _( "i)dentify(8) z)leave(9)\n" ) );
        win_msg.textout( _( "r)ead spell  c)ast spell\n" ) );
        win_msg.textout( _( "t)rade       u)se\n" ) );
        win_msg.textout( _( "o)reorder    n)inspect\n" ) );
        win_msg.textout( _( "#)see a character\n" ) );
        win_msg.textout( _( "q)uit playing daemon(7)\n" ) );
        win_msg.textout( _( "**********************\n" ) );
        /+
        if( first_disp )
        {
            win_msg.textout( _( "d)rop(0)     e)quip\n" ) );
            win_msg.textout( _( "i)dentify(8) z)leave(9)\n" ) );
            win_msg.textout( _( "r)ead spell  c)ast spell\n" ) );
            win_msg.textout( _( "t)rade       u)se\n" ) );
            win_msg.textout( _( "o)reorder    n)inspect\n" ) );
            win_msg.textout( _( "#)see a character\n" ) );
            win_msg.textout( _( "q)uit playing daemon(7)\n" ) );
            win_msg.textout( _( "**********************\n" ) );
            first_disp = false;
        }
        +/
        setColor( CL.NORMAL );
        win_msg.textout( "option? " );
        while ( true )
        {
            ch = getChar();
            if ( ch >= '1' && ch <= '0' + party.num )
            {
                mem = party.mem[ ch - '1' ];
                mem.inspect;
                continue;
            }
            else if ( ch == '?'  )
            {
                setColor( CL.MENU );
                win_msg.textout(  "\n" );
                win_msg.textout( _( "******** camp ********\n" ) );
                win_msg.textout( _( "d)rop(0)     e)quip\n" ) );
                win_msg.textout( _( "i)dentify(8) z)leave(9)\n" ) );
                win_msg.textout( _( "r)ead spell  c)ast spell\n" ) );
                win_msg.textout( _( "t)rade       u)se\n" ) );
                win_msg.textout( _( "o)reorder    n)inspect\n" ) );
                win_msg.textout( _( "#)see a character\n" ) );
                win_msg.textout( _( "q)uit playing daemon(7)\n" ) );
                win_msg.textout( _( "**********************\n" ) );
                setColor( CL.NORMAL );
                win_msg.textout( "option? " );
                continue;
            }
            else if ( ch == 't' && ! mem.item[ 0 ].isNothing )
            {   // trade
                win_msg.textout( _( "trade\n" ) );
                mem.tradeitem();
                break;
            }
            else if ( ( ch == 'd' || ch == '0' ) 
                    && ( ! mem.item[ 0 ].isNothing ) )
            {   // drop
                win_msg.textout( _( "drop\n" ) );
                mem.dropitem();
                break;
            }
            else if ( ch == 'u' 
                    && ( ! mem.item[ 0 ].isNothing )
                    && ( mem.status == STS.OK ) )
            {   // use
                win_msg.textout( _( "use\n" ) );
                mem.useitem();
                mem.inspect;
                break;
            }
            else if ( ( ch == 'c' || ch == 's' )
                    && ( mem.status == STS.OK ) )
            {   // spell
                win_msg.textout( _( "cast spell\n" ) );
                mem.camp_spell();
                break;
            }
            else if (ch == 'o')
            {   // reorder
                win_msg.textout( _( "reorder\n" ) );
                party.reorder( mem );
                break;
            }   // identify
            else if ( ( ch == 'i' || ch == '8' ) 
                    && ( ! mem.item[ 0 ].isNothing )
                    && ( mem.Class == CLS.BIS )
                    && ( mem.status == STS.OK ) )
            {   // inspect
                win_msg.textout( _( "identify\n" ) );
                mem.identify();
                break;
            }
            else if ( ch == 'r' )
            {   // read spell
                win_msg.textout( _( "read spell\n" ) );
                mem.dispSpellsInCamp;
                break;
            }
            else if ( ch == 'e' )
            {   // equip
                win_msg.textout( _( "equip\n" ) );
                mem.equip;
                break;
            }
            else if ( ch == 'z' || ch == '9' )
            {   // leave camp
                win_msg.textout( ch );
                win_msg.textout( _( "\nleave camp ...\n" ) );
                goto EXIT;
            }
            else if (ch == 'q' || ch == '7')
            {   // quit game
                win_msg.textout( ch );
                win_msg.textout( _( "\nquit game ...\n" ) );
                for ( i = 0; i < party.num; i++ )
                {
                    party.mem[ i ].x = party.x;
                    party.mem[ i ].y = party.y;
                    party.mem[ i ].layer = party.layer;
                    party.mem[ i ].outflag = OUT_F.DUNGEON;
                }

                appSave;

                win_msg.textout( _( "  leave game(y(1)/n(2))? \n" ) );
                while ( true )
                {
                    c = getChar();
                    if ( c == 'y' || c == 'n' )
                        break;
                    if ( c == '1' || c == '2' )
                        break;
                }
                if ( c == 'y' || c == '1' )
                {
                    party.layer = 0;
                    party.num = 0;
                    rtnval = 1; // leave game
                    win_msg.textout( "bye !" );
                    goto EXIT;
                }
                break;
            }   // inspect
            else if (ch == 'n' || c == '2')
            {
                win_msg.textout( "i\n" );
                party.inspect();
                win_status.clear();
                break;
            }
        }
    }
EXIT:
    if( party.layer == 0 )
        return rtnval;  // return castle or leave game;

    party.dungeon.disp;
    header_disp( HSTS.DUNGEON );
    // in rock check
    if ( party.dungeon.checkInRock )
    {
        win_msg.textout( _( "\n*** in rock! ***\n" ) );
        for ( i = 0; i < party.num; i++ )
            party.mem[i].status = STS.LOST;
        party.win_disp();
        getChar();
        party.layer=0;
        party.olayer=0;
        party.num=0;
    }
    return rtnval;
}


/*====== treasure ================================================*/
// rtn : true : OK , false : 全滅!
bool treasure_main( int monnum )
{

    int i;
    int ratio;
    int rtn;
    Member mem;
    string disarm;
    char c;

    int trap;
    int inspected;
    int inspected_bycast = -1;

    int getgold;
  
  
    trap = get_rand( MAXTRAP );

    for ( i = 0; i < 6; i++ )
        party.mem[ i ].predict = 0;

    for ( i = 0; i < party.actnum; i++ )
    {
        mem = party.mem[ i ];
        ratio = mem.agi[ 0 ] + mem.agi[ 1 ];
        switch ( mem.Class )
        {
            case CLS.THI :  /* thief */
                ratio *= 6;
                if ( ratio > 95 )
                    ratio = 95;
                mem.predict = get_rand( MAXTRAP );
                break;
            case CLS.NIN : 
                ratio *= 4;
                if ( ratio > 95 )
                    ratio = 95;
                mem.predict = get_rand( MAXTRAP );
                break;
            case CLS.PRI :  /* priest */
            case CLS.LOR :  /* lord */
                mem.predict = 8; /* priest blaster */
                break;
            case CLS.MAG :  /* mage */
            case CLS.SAM :  /* samurai */
                mem.predict = 7; /* mage blaster */
                break;
            default :  /* fighter, bishop */
                mem.predict = get_rand( MAXTRAP );
                break;
        }
        if ( get_rand( 100 ) <= ratio )
            mem.predict = trap;
    }
  
    while ( true )
    {
        setColor( CL.TREASURE );
        win_msg.textout( _( "\n*** a chest! you may: ***\n" ) );
        setColor( CL.MENU );

        win_msg.textout( _( "o)pen i)nspect&disarm(4)\n" ) );
        win_msg.textout( _( "c)ast inspct(6) z)leave alone(9)\n" ) );
        win_msg.textout( _( "*************************\n" ) );
        setColor( CL.NORMAL );
        win_msg.textout( "option? " );

        c = 0;
        while ( c == 0 )
        {
            c = getChar;
            switch( c )
            {
                case 'o':
                case 'i':
                case 'd':
                case 'c':
                case 'z':
                case '9':
                case '4':
                case '6':
                    break;
                default:
                    c = 0;
                    break;
            }
        }

        win_msg.textout( c );
        win_msg.textout( '\n' );
        switch( c )
        {
            case 'i':   // inspect
            case '4':
                mem = party.selectActiveMember( _( "who inspects the chest(z:leave(9))? " ) 
                                              , _( "leave" ) );
                if( mem is null )
                    continue;

                if ( mem.Class != CLS.THI && mem.Class != CLS.NIN )
                    if ( get_rand( 6 ) == 0 )
                        goto FAIL;

                if( inspected_bycast != -1 )
                    inspected = inspected_bycast;
                else
                    inspected = mem.predict;

                setColor( CL.TRAP );
                win_msg.textout( "\n=== " ~ TRAP_NAME[ inspected ] ~ "? ===\n" );
                setColor( CL.NORMAL );

                win_msg.textout( _( "%1 disarm?(y/n)\n" ) , mem.name );
                if( answerYN == 'n' )
                    continue;

                // disarm
                win_msg.textout( ">" );
                win_msg.textout( TRAP_NAME[ inspected ] );
                win_msg.textout( "\n" );
                if ( inspected != trap )
                {
                    goto FAIL;
                }
                else
                {

                    if ( trap == TRAP.NO )
                    {
                        win_msg.textout( _( "no trap ...\n" ) );
                        goto SUCEED;
                    }

                    ratio = mem.level - party.layer - 7;
                    if ( mem.Class == CLS.THI || mem.Class == CLS.NIN )
                    { /* thief or ninja */
                        ratio += 50;
                    }

                    if ( ratio > get_rand( 70 ) )
                    {
                        win_msg.textout( _( "  you disarmed the trap.\n" ) );
                        goto SUCEED;
                    }

                    if ( ratio < get_rand( 20 ) )
                        goto FAIL;
                    win_msg.textout( _( "  you could not disarm it.\n" ) );
                }
                break;

            case 'o':   // open
                mem = party.selectActiveMember( _( "who opens the chest(z:leave(9))? " ) 
                                              , _( "leave" ) );
                if( mem is null )
                    continue;

                if ( trap == 0 )
                    goto SUCEED;
                else
                    goto FAIL;

            case 'z':   // leave alone
            case '9':
              win_msg.textout( _( "leave alone ...\n" ) );
              goto EXIT;

            case 'c':   // spell
            case '6':
                mem = party.selectActiveMember( _( "who casts a inspct(z:leave(9))? " ) 
                                              , _( "leave" ) );
                if( mem is null )
                    continue;

                /* 1 : don't know    */
                /* 2 : have used up   */
                rtn = mem.consume_spell( 0x24 ); // calfo
                if ( rtn == 1 )
                {
                    win_msg.textout( _( "  you don't know the spell.\n" ) );
                    break;
                }
                else if ( rtn == 2 )  
                {
                    win_msg.textout( _( "  you've used that spell up.\n" ) );
                    break;
                }

                if ( get_rand( 99 ) <= 95 )
                    inspected_bycast = trap;
                else
                    inspected_bycast = get_rand( MAXTRAP );

                win_msg.textout( "\n=== " ~ TRAP_NAME[ inspected_bycast ] ~ "? ===\n" );
                break;
            default:
                assert( 0 );
        }
    }
  
FAIL:
    if ( trap == TRAP.NO )
    {
        win_msg.textout( _( "no trap ...\n" ) );
        goto SUCEED;
    }

    setColor( CL.TRAP_FAIL );
    win_msg.textout( _( "oops! %1\n" ) , TRAP_NAME[ trap ] );
    setColor( CL.NORMAL );
    switch ( trap )
    {
        case TRAP.POISON: /* poison needle */
            mem.poisoned = true;
            break;
        case TRAP.GASBOMB: /* gas bomb */
            for ( i = 0; i < party.num; i++ )
            {
                mem = party.mem[ i ];
                if ( mem.status < STS.PARALY 
                        && get_rand( 19 ) > mem.luk[ 0 ] + mem.luk[ 1 ] )
                    mem.poisoned = true;
            }
            break;
        case TRAP.CROSSBOW: /* crossbow bolt */
            mem.hp -= get_rand( 50 );
            if ( mem.hp <= 0 )
            {
                mem.hp = 0;
                mem.status = STS.DEAD;
                mem.rip++;
            }
            break;
        case TRAP.EXPLODING: /* exploding box */
            for ( i = 0; i < party.num; i++ )
            {
                mem = party.mem[ i ];
                if ( mem.status >= STS.DEAD )
                    continue;
                mem.hp -= get_rand( 50 );
                if ( mem.hp <= 0 )
                {
                    mem.hp = 0;
                    mem.status = STS.DEAD;
                    mem.rip++;
                }
            }
            break;
        case TRAP.STUNNER: /* stunner */
            mem.status = STS.PARALY;
            break;
        case TRAP.TELEPORT: /* teleporter */
            party.ox = party.x;
            party.oy = party.y;
            party.x = to!byte( get_rand( party.dungeon.width - 4 ) + 1 );
            party.y = to!byte( get_rand( party.dungeon.height - 4 ) + 1 );
            party.dungeon.disp();
            header_disp( HSTS.DUNGEON );
            break;
        case 7: /* mage blaster */
            for ( i = 0; i < party.num; i++ )
            {
                mem = party.mem[ i ];
                if( ( mem.Class == CLS.MAG 
                       || mem.Class == CLS.BIS 
                       || mem.Class == CLS.SAM  ) && ( mem.status < STS.PARALY ) )
                    mem.status = STS.PARALY;
            }
            break;
        case 8: /* priest blaster */
            for ( i = 0; i < party.num; i++ )
            {
                mem = party.mem[ i ];
                if( ( mem.Class == CLS.PRI 
                       || mem.Class == CLS.BIS 
                       || mem.Class == CLS.LOR  ) && ( mem.status < STS.PARALY ) )
                    mem.status = STS.PARALY;
            }        
            break;
        case 9: /* alarm */
            switch ( party.dungeon.encounter( TRE.ALARM ) ) /* recursive call */
            {
                case BATTLE_RESULT.WON : 
                case BATTLE_RESULT.LEAVE :
                    goto SUCEED;
                case BATTLE_RESULT.RAN :
                    goto EXIT;
                case BATTLE_RESULT.LOST :
                    return false;
                default:
                    break;      
                    /* assert( 0 ); */  // friendly group -> error!
            }
            break;
        default:
            assert( 0 );
    }
    getChar();
  
    // failed
    if( ! party.checkAlive )
    {
        party.win_disp();
        party.num = 0;
        party.layer = 0;
        win_msg.textout( _( "\n*** your party is lost...<push space bar>\n" ) );
        while ( true )
        {
            c = getChar();
            if ( c == ' ' || c == '5' )
                break;
        }
        return false;
    }

SUCEED:
    get_treasure( monnum );
    getgold = monster_data[ monnum ].mingp + get_rand( monster_data[ monnum ].addgp );
    getgold /= party.num;
    win_msg.textout( _( "  each survivor gets %1 gold.\n" ) , getgold );
    for ( i = 0; i < party.num; i++ )
    {
        if ( party.mem[ i ].status == 0 )
            party.mem[ i ].gold += getgold;
    }
  
EXIT:
    party.win_disp();
    return true;
}


/**--------------------
   get_treasure - アイテム取得
   --------------------*/
void get_treasure( int mon )
{
    int i, j;
    int itemno;
    MonsterDef mdata = monster_data[ mon ]; 
    Item itm;

    for (i = 0; i < 3; i++)
    {

        if ( mdata.itemratio[ i ] < get_rand( 100 ) )
            continue;

        itemno = mdata.itemmin[ i ] 
                + get_rand( mdata.itemmax[ i ] - mdata.itemmin[ i ] );

        for( j = party.num - 1 ; j >= 0 ; j -- )
        {
            if( party.mem[ j ].canCarry )
            {
                if (item_data[ itemno ].name == "")
                {
                    win_msg.textout("item#: ");
                    win_msg.textout( itemno );
                    win_msg.textout( "\n" );
                }
                itm = party.mem[ j ].getItem( itemno );
                itm.undefined = true;

                win_msg.textout( _( "  %1 discovered a %2.\n" ) , party.mem[ j ].name , itm.getDispName );
                getChar();
                return;
            }
        }
        win_msg.textout( _( "you cannot carry anything more.\n" ) );
        return;
    }

    return ;
}
