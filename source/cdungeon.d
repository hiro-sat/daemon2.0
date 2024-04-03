// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : format , split , chop ;
import std.conv;
import std.random;

// mysource 
import lib_screen;
import lib_readline;

import app;
import def;

import cparty;
import cmember;
import cmap;
import citem;
import citem_def;

import cmonster_def;


/*====== dungeon ====================================================*/

class Dungeon
{

public:
    /**
       if rtnval!=0 then quit from maze
    */
    bool dungeonMain()
    {

        int i; 
        bool leave_game = false;
        int  dx, dy;
        char c;
        bool doorflg = false;

        int encountRate;   // -1 : not encount

        char keycode;
      

        foreach( Map d ; dungeonMap )
            d.resetEncounterArea;

        party.ac = 0;
        party.step = 0;
        party.status = 0;
        party.setDungeon;
        party.dungeon.setDispPos;
      
        foreach( p ; party )
        {
            p.outflag = OUT_F.DUNGEON;
            p.x = 0;
            p.y = 0;
            p.layer = 99;
        }
        party.resetAllFlg;
      
        party.dungeon.initDisp();
        party.dungeon.disp();
        dispHeader( HSTS.DUNGEON );
        party.dispPartyWindow();
     

        while ( party.layer > 0 )
        {

            // in rock check
            if ( party.layer >= MAXLAYER || party.dungeon.checkInRock  )
            {
                party.dungeon.textoutNow( _( "\n*** in rock! ***\n" ) );
                foreach( p ; party )
                    p.isLost;
                party.dispPartyWindow();
                getChar();
                party.layer = 0;
                party.olayer = 0;
                goto EXIT;
            }

            dx = 0;
            dy = 0;
            encountRate = ENCOUNT_RATE;

            if( debugmode || debugmodeOffFlg )
                keycode = getCharFromList( "?QS<>o5h4l6k8j2.3usc9 " ~ CURSOR_KEY ~ "DEMFIL<>");   // debug
            else
                keycode = getCharFromList( "?QS<>o5h4l6k8j2.3usc9 " ~ CURSOR_KEY);

            switch ( keycode )
            {
                case '?':
                    txtMessage.clear;
                    setColor( CL.MENU );
                    txtMessage.textout( _( "************* dungeon help *************\n" ) );
                    txtMessage.textout( _( "--- assigned keys ---\n" ) );
                    txtMessage.textout( _( "h/4:west, j/2:south, k/8:north, l/6:east\n" ) );
                    txtMessage.textout( _( "c/9:camp, o/5/' ':open door, u:unlock door\n" ) );
                    txtMessage.textout( _( "./3:look for monsters, S:protect all\n" ) );
                    txtMessage.textout( _( "s:search hidden doors, Q:heal all\n" ) );
                    txtMessage.textout( _( "--- map info ---\n" ) );
                    txtMessage.textout( _( "|/-/X:wall, +:door, =:locked door\n" ) );
                    txtMessage.textout( _( "$:darkzone, </>:stairs, ' ':floor\n" ) );
                    txtMessage.textout( _( "@:your party, ^:unknown\n" ) );
                    txtMessage.textout( _( "*****************************************\n" ) );
                    setColor( CL.NORMAL );
                    break;
                case 'Q':
                    if ( party.layer > 0 )
                    {
                        party.healAll();
                        // txtMessage.clear;
                        // txtMessage.textout( _( "heal all done.\n" ) );
                        dispHeader( HSTS.DUNGEON );
                        party.dispPartyWindow();
                    }
                    break;
                case 'S':
                    if ( party.layer > 0 )
                    {
                        txtMessage.clear;
                        party.protectAll();
                        txtMessage.textout( _( "protect all done.\n" ) );
                        rewriteOn;
                        party.dispPartyWindow();
                        dispHeader( HSTS.DUNGEON );
                    }
                    break;
                case '<':   // up stairs
                    switch( party.dungeon.upStairs() )
                    {
                        case 2: /* exit from maze */
                            goto EXIT;
                        case 1: /* not encount */
                            encountRate = -1;
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
                            encountRate = -1;
                            break;
                        default:
                            break;
                    }
                    break;
                case 'o':
                case '5':
                case ' ':
                    if( ! doorflg )
                    {
                        doorflg = true;
                        party.dungeon.textoutNow( _( "\nwhich door? " ) );
                    }
                    break;
                case 'h':
                case '4':
                case LEFT_ARROW:
                    dx = -1;
                    break;
                case 'l':
                case '6':
                case RIGHT_ARROW:
                    dx = 1;
                    break;
                case 'k':
                case '8':
                case UP_ARROW:
                    dy =  -1;
                    break;
                case 'j':
                case '2':
                case DOWN_ARROW:
                    dy = 1;
                    break;
                case '.':
                case '3':
                    party.ox = party.x;
                    party.oy = party.y;
                    party.olayer = party.layer;
                    stepProcess();
                    encountRate = ENCOUNT_RATE_STOP;
                    break;
                case 'u': // unlock a door
                    if ( ! party.dungeon.unlockDoor )
                        party.dungeon.textoutNow( _( "\nfailed." ) );
                    else
                        party.dungeon.textoutNow( _( "\nclick!" ) );
                    break;
                case 's': // search a hidden door (and members in maze)
                    party.dungeon.textoutNow( _( "\nsearching" ) );
                    for ( i = 0; i < get_rand( 7 ) + 3; i++ )
                    {
                        party.dungeon.textoutNow( "." );
                        getChar();
                    }
                    getChar();
                    party.dungeon.textoutNow( _( "done." ) );

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
                    stepProcess();
                    break;
                default:
                    if( debugmode || debugmodeOffFlg )
                        checkDebugCommand( keycode );
                    break;
            }


            if ( dx != 0 || dy != 0 || keycode == '.' || keycode == '3' )
            {

                stepProcess();

                if( ! party.dungeon.isPassable( party.y + dy , party.x + dx , doorflg  ) )
                {
                    party.dungeon.textoutNow( _( "\n      ... ouch!" ) );
                }
                else
                {

                    if (dx > 0)
                        party.dungeon.textout( _( "\neast" ) );
                    else if (dx < 0)
                        party.dungeon.textout( _( "\nwest" ) );
                    else if (dy < 0)
                        party.dungeon.textout( _( "\nnorth" ) );
                    else if (dy > 0)
                        party.dungeon.textout( _( "\nsouth" ) );

                    party.olayer = party.layer;
                    party.ox = party.x;
                    party.oy = party.y;
                    party.x += dx;
                    party.y += dy;
                    party.dungeon.disp();

                    switch( party.dungeon.checkEvent() )
                    {
                        case 2: /* exit from maze */
                            goto EXIT;
                        case 1: /* not encount */
                            encountRate = -1;
                            break;
                        default:
                            break;
                    }

                    party.dungeon.disp();
                }

                // check encounter
                if ( encountRate > 0 ) 
                {
                    encountRate = recalculateEncountRate( encountRate );

                    if ( get_rand( encountRate ) == 0 )
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
                }

                if ( doorflg )
                    doorflg = false;
            }
        }

    EXIT:
        party.ac = 0;
      
        party.dispPartyWindow();
        txtMessage.clear;
        if( leave_game )
            return false;   // leave game
        else
            return true;    // go to castle

    }

    
    /**--------------------
       recalculateRateEncount - エンカウント率の再計算
       --------------------*/
    int recalculateEncountRate( int rate )
    {

        switch( party.dungeon.getMapTile( party.y , party.x ) )
        {
            case '+':
                return ENCOUNT_RATE_DOOR;
            case '$':
                return ENCOUNT_RATE_DARKZONE;
            default:
                break;
        }

        int cornerCount = 0;
        int cnt = 0;

        int countOpenSpace()
        {
            cnt = 0;
            // オープンスペースをカウント
            if( party.dungeon.isPassable( party.y - 1 , party.x     ) )
                cnt ++; // up
            if( party.dungeon.isPassable( party.y     , party.x - 1 ) )
                cnt ++; // left
            if( party.dungeon.isPassable( party.y + 1 , party.x     ) )
                cnt ++; // down
            if( party.dungeon.isPassable( party.y     , party.x + 1 ) )
                cnt ++; // right
            return cnt;
        }

        // 曲がり角かどうかチェック
        if( ! party.dungeon.isPassable( party.y - 1 , party.x - 1 ) )
            cornerCount ++;
        if( ! party.dungeon.isPassable( party.y + 1 , party.x - 1 ) )
            cornerCount ++;
        if( ! party.dungeon.isPassable( party.y - 1 , party.x + 1 ) )
            cornerCount ++;
        if( ! party.dungeon.isPassable( party.y + 1 , party.x + 1 ) )
            cornerCount ++;

        switch( cornerCount )
        {
            case 4: // 曲がり角
                switch( countOpenSpace() )
                {
                    case 4: // 十字路
                    case 3: // Ｔ字路
                        return ENCOUNT_RATE_CORNER;

                    case 2: // 曲がり角 or 通路
                        if( party.dungeon.isPassable( party.y , party.x - 1 ) 
                         || party.dungeon.isPassable( party.y , party.x - 1 ) ) 
                             return rate;   // 通路
                        if( party.dungeon.isPassable( party.y + 1 , party.x )
                         || party.dungeon.isPassable( party.y - 1 , party.x ) )
                             return rate;   // 通路
                        return ENCOUNT_RATE_CORNER; // 曲がり角

                    case 1: // 行き止まり
                        return rate;
                    default:    // 個室
                        return rate / 2;
                }
            case 3:
            case 2: // 
            case 1: // 角
            case 0: // オープンスペース
                return rate;
            default:
                assert( 0 );
        }

    }


    /*====== treasure ================================================*/
    // rtn : true : OK , false : 全滅!
    bool treasureMain( int monnum )
    {

        int i;
        int ratio;
        int rtn;
        string disarm;
        char c;

        Member mem;
        int trap;
        string trapname;       // 入力
        int inspected;
        int inspected_bycast = -1;

        int getgold;
      
        trap = get_rand( MAXTRAP );

        foreach( p ; party )
        {

            if ( p.status >= STS.PARALY )
                continue;

            p.predict = 0;

            ratio = p.agi[ 0 ] + p.agi[ 1 ];
            switch ( p.Class )
            {
                case CLS.THI :  /* thief */
                    ratio *= 6;
                    if ( ratio > 95 )
                        ratio = 95;
                    p.predict = get_rand( MAXTRAP );
                    break;
                case CLS.NIN : 
                    ratio *= 4;
                    if ( ratio > 95 )
                        ratio = 95;
                    p.predict = get_rand( MAXTRAP );
                    break;
                case CLS.PRI :  /* priest */
                case CLS.LOR :  /* lord */
                    p.predict = 8; /* priest blaster */
                    break;
                case CLS.MAG :  /* mage */
                case CLS.SAM :  /* samurai */
                    p.predict = 7; /* mage blaster */
                    break;
                default :  /* fighter, bishop */
                    p.predict = get_rand( MAXTRAP );
                    break;
            }
            if ( get_rand( 100 ) <= ratio )
                p.predict = trap;
        }
      
        while ( true )
        {
            setColor( CL.TREASURE );
            txtMessage.textout( _( "\n*** a chest! you may: ***\n" ) );
            setColor( CL.MENU );

            txtMessage.textout( _( "o)pen i)nspect&disarm(4)\n" ) );
            txtMessage.textout( _( "c)ast inspct(6) z)leave alone(9)\n" ) );
            txtMessage.textout( _( "*************************\n" ) );
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );

            c = getCharFromList( "oidcz946" );
            txtMessage.textout( c );
            txtMessage.textout( '\n' );
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
                    txtMessage.textout( "\n=== " ~ TRAP_NAME[ inspected ] ~ "? ===\n" );
                    setColor( CL.NORMAL );

                    txtMessage.textout( _( "%1 disarm?(y/n)\n" ) , mem.name );
                    if( answerYN( "" , "n\n"  ) == 'n' )
                        continue;

                    // disarm
                    if( inputTrapName )
                    {
                        trapname = txtMessage.input( MAX_TRAP_NAME , "> " );
                        if( trapname == "" )
                            continue;
                        txtMessage.textout( "> " ~ trapname ~ "\n" );
                        if( trapname != TRAP_NAME[ trap ] )
                            goto FAIL;
                    }
                    else
                    {
                        txtMessage.textout( ">" ~ TRAP_NAME[ inspected ] );
                        txtMessage.textout( "\n" );
                        if ( inspected != trap )
                            goto FAIL;
                    }

                    // Successful!!
                    if ( trap == TRAP.NO )
                    {
                        txtMessage.textout( _( "no trap ...\n" ) );
                        goto SUCEED;
                    }

                    ratio = mem.level - party.layer - 7;
                    if ( mem.Class == CLS.THI || mem.Class == CLS.NIN )
                    { /* thief or ninja */
                        ratio += 50;
                    }

                    if ( ratio > get_rand( 70 ) )
                    {
                        txtMessage.textout( _( "  you disarmed the trap.\n" ) );
                        goto SUCEED;
                    }

                    if ( ratio < get_rand( 20 ) )
                        goto FAIL;
                    txtMessage.textout( _( "  you could not disarm it.\n" ) );
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
                    txtMessage.textout( _( "leave alone ...\n" ) );
                    goto EXIT;

                case 'c':   // spell
                case '6':
                    mem = party.selectActiveMember( _( "who casts a inspct(z:leave(9))? " ) 
                                                  , _( "leave" ) );
                    if( mem is null )
                        continue;

                    /* 1 : don't know    */
                    /* 2 : have used up   */
                    if( ! mem.isSpellKnown( magic_all[ SPELL_INSPECT ] ) )
                    {
                        txtMessage.textout( _( "  you don't know the spell.\n" ) );
                        break;
                    }
                    if( ! mem.consumeSpell( magic_all[ SPELL_INSPECT ] ) )
                    {
                        txtMessage.textout( _( "  you've used that spell up.\n" ) );
                        break;
                    }

                    if ( get_rand( 99 ) <= 95 )
                        inspected_bycast = trap;
                    else
                        inspected_bycast = get_rand( MAXTRAP );

                    txtMessage.textout( "\n=== " ~ TRAP_NAME[ inspected_bycast ] ~ "? ===\n" );
                    break;
                default:
                    assert( 0 );
            }
        }
      
    FAIL:
        // remark:
        // mem = party.selectActiveMember( _( "who opens the chest(z:leave(9))? " ) 

        if ( trap == TRAP.NO )
        {
            txtMessage.textout( _( "no trap ...\n" ) );
            goto SUCEED;
        }

        setColor( CL.TRAP_FAIL );
        txtMessage.textout( _( "oops! %1\n" ) , TRAP_NAME[ trap ] );
        getChar;
        setColor( CL.NORMAL );
        switch ( trap )
        {
            case TRAP.POISON: /* poison needle */
                mem.poisoned = true;
                break;
            case TRAP.GASBOMB: /* gas bomb */
                foreach( p ; party )
                {
                    if ( p.status < STS.PARALY 
                            && get_rand( 19 ) > p.luk[ 0 ] + p.luk[ 1 ] )
                        p.poisoned = true;
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
                foreach( p ; party )
                {
                    if ( p.status >= STS.DEAD )
                        continue;
                    p.hp -= get_rand( 50 );
                    if ( p.hp <= 0 )
                    {
                        p.hp = 0;
                        p.status = STS.DEAD;
                        p.rip++;
                    }
                }
                break;
            case TRAP.STUNNER: /* stunner */
                mem.status = STS.PARALY;
                break;
            case TRAP.TELEPORT: /* teleporter */
                party.ox = party.x;
                party.oy = party.y;
                while( party.ox == party.x && party.oy == party.y )
                {
                    party.x = get_rand( party.dungeon.width - 2 ) + 1;
                    party.y = get_rand( party.dungeon.height - 2 ) + 1;
                    if( ! party.dungeon.isPassableOrgmap( party.y , party.x ) )
                    {
                        party.x = party.ox;
                        party.y = party.oy;
                        continue;
                    }
                }
                party.dungeon.setDispPos;
                party.dungeon.initDisp;
                party.dungeon.disp();
                dispHeader( HSTS.DUNGEON );
                break;
            case 7: /* mage blaster */
                foreach( p ; party )
                {
                    if( ( p.Class == CLS.MAG || p.Class == CLS.BIS || p.Class == CLS.SAM )
                     && ( p.status < STS.PARALY ) )
                        p.status = STS.PARALY;
                }
                break;
            case 8: /* priest blaster */
                foreach( p ; party )
                {
                    if( ( p.Class == CLS.PRI || p.Class == CLS.BIS || p.Class == CLS.LOR  ) 
                     && ( p.status < STS.PARALY ) )
                        p.status = STS.PARALY;
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
      
        // failed
        if( ! party.checkAlive )
        {
            party.dispPartyWindow();
            party.saveLocate;
            party.layer = 0;
            setColor( STS_CL.DEAD );
            txtMessage.textout( _( "\n*** your party is lost...<push space bar>\n" ) );
            c = getCharFromList( " 5" );
            return false;
        }

    SUCEED:
        getTreasure( monnum );
        getgold = monster_data[ monnum ].mingp + get_rand( monster_data[ monnum ].addgp );
        getgold /= party.memCountAlive;
        txtMessage.textout( _( "  each survivor gets %1 gold.\n" ) , getgold );
        foreach( p ; party )
        {
            if ( p.status == 0 )
                p.gold += getgold;
        }
      
    EXIT:
        party.dispPartyWindow();
        return true;
    }


private:
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
                    dispHeader( HSTS.DUNGEON );
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
                    dispHeader( HSTS.DUNGEON );
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
                    dispHeader( HSTS.DUNGEON );
                }
                break;
            case 'I':
                if ( debugmode && party.layer > 0 )
                {
                    if( ! party.isIdentify )
                        party.setIdentify;
                    else
                        party.resetIdentify;
                    dispHeader( HSTS.DUNGEON );
                }
                break;
            /* case 'H': */
            /*     if ( debugmode && party.layer > 0 ) */
            /*     { */
            /*         if( ! party.isScope ) */
            /*         { */
            /*             party.setScope; */
            /*             party.scopeCount = 999; */
            /*         } */
            /*         else */
            /*         { */
            /*             party.resetScope; */
            /*         } */
            /*         dispHeader( HSTS.DUNGEON ); */
            /*         party.dungeon.disp; */
            /*     } */
            /*     break; */
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
                    dispHeader( HSTS.DUNGEON );
                    party.dungeon.disp;
                }
                break;
            case '<':
                if ( debugmode && party.layer > 0 ){
                  party.layer--;
                  party.setDungeon;
                  party.dungeon.initDisp;
                  party.dungeon.disp;
                  dispHeader( HSTS.DUNGEON );
                }
                break;
            case '>':
                if ( debugmode && party.layer < MAXLAYER ){
                  party.layer++;
                  party.setDungeon;
                  party.dungeon.initDisp;
                  party.dungeon.disp;
                  dispHeader( HSTS.DUNGEON );
                }
                break;
            default:
                break;
        }
    }

    // 一歩毎の処理
    void stepProcess()
    {
        int i;

        party.step++;
        party.hpPlus();

        foreach( p ; party )
        {
            if ( p.poisoned  && ( get_rand( 7 ) == 0 ) )
                p.damagedByPoison;

            if ( p.status <= STS.AFRAID && get_rand( 15 ) == 0 )
            {
                if (p.status == STS.AFRAID )
                    p.status = STS.OK;
            }
        }

        party.dispPartyWindow( false );

        if ( party.isLight && --party.lightCount < 0 )
        {
            party.lightCount = 0;
            party.resetLight;
            dispHeader( HSTS.DUNGEON , false);
        }

        if ( party.isMapper && --party.scopeCount < 0 )
        {
            party.scopeCount = 0;
            party.resetMapper;
            dispHeader( HSTS.DUNGEON , false);
        }

        rewriteOn;

        return;

    }


    /*====== camp ====================================================*/
    // rtnval!=0 : quit from maze(leave game)
    int camp()
    {

        appSave;

        void dispCommandHelp()
        {
            setColor( CL.MENU );
            txtMessage.textout( _( "******** camp ********\n" ) );
            txtMessage.textout( _( "d)rop(0)     e)quip\n" ) );
            txtMessage.textout( _( "i)dentify(8) z)leave(9)\n" ) );
            txtMessage.textout( _( "r)ead spell  c)ast spell\n" ) );
            txtMessage.textout( _( "t)rade       u)se\n" ) );
            txtMessage.textout( _( "o)reorder    n)inspect\n" ) );
            txtMessage.textout( _( "#)see a character\n" ) );
            txtMessage.textout( _( "q)uit playing daemon(7)\n" ) );
            txtMessage.textout( _( "**********************\n" ) );
            return;
        }


        int i, rtnval = 0;
        char ch, c;

        Member mem;

        dispHeader( HSTS.CAMP );

        mem = party.mem[ 0 ];
        mem.inspect;

        bool first_disp = true;

        txtMessage.clear;
        party.dungeon.textoutOff;

        while ( true )
        {

            dispCommandHelp;
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );

            ch = 0;
            while( ch == 0 )
            {
                ch = getCharFromList( "?td0ucsoi8rez9q7n2" ~ party.getCharList );
                if( ch >= '1' && ch <= '6' )
                {
                    mem = party.mem[ ch - '1' ];
                    mem.inspect();
                    ch = 0;
                }
            }

            switch( ch )
            {
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                    mem = party.mem[ ch - '1' ];
                    mem.inspect();
                    break;

                case '?':
                    setColor( CL.MENU );
                    txtMessage.textout(  "\n" );
                    continue;

                case 't':
                    // trade
                    if( ! mem.item[ 0 ].isNothing )
                    {
                        txtMessage.textout( _( "trade\n" ) );
                        mem.tradeItem();
                    }
                    break;

                case 'd':
                case '0':
                    if ( ! mem.item[ 0 ].isNothing )
                    {   // drop
                        txtMessage.textout( _( "drop\n" ) );
                        mem.dropItem();
                    }
                    break;

                case 'u':
                    if( ( ! mem.item[ 0 ].isNothing ) && ( mem.status == STS.OK ) )
                    {   // use
                        txtMessage.textout( _( "use\n" ) );
                        mem.useItem();
                        mem.inspect;
                    }
                    break;

                case 'c':
                case 's':
                    if ( mem.status == STS.OK )
                    {   // spell
                        txtMessage.textout( _( "cast spell\n" ) );
                        mem.castSpellInCamp();
                    }
                    break;

                case 'o':
                    // reorder
                    txtMessage.textout( _( "reorder\n" ) );
                    party.reorder( mem );
                    break;   

                case 'i':
                case '8':
                    // identify
                    if( ( ! mem.item[ 0 ].isNothing )
                            && ( mem.Class == CLS.BIS )
                            && ( mem.status == STS.OK ) )
                    {   // inspect
                        txtMessage.textout( _( "identify\n" ) );
                        mem.identify();
                    }
                    break;

                case 'r':
                    // read spell
                    txtMessage.textout( _( "read spell\n" ) );
                    mem.dispSpellsInCamp;
                    break;

                case 'e':
                    // equip
                    txtMessage.textout( _( "equip\n" ) );
                    mem.equip;
                    break;

                case 'z':
                case '9':
                    // leave camp
                    txtMessage.textout( ch );
                    txtMessage.textout( _( "\nleave camp ...\n" ) );
                    goto EXIT;

                case 'q':
                case '7':
                    // quit game
                    txtMessage.textout( ch );
                    txtMessage.textout( _( "\nquit game ...\n" ) );

                    party.saveLocate;
                    appSave;

                    txtMessage.textout( _( "  leave game(y(1)/n(2))? \n" ) );
                    c = getCharFromList ( "yn12" );
                    if ( c == 'y' || c == '1' )
                    {
                        txtMessage.textout( "bye !" );
                        return 1;       // leave game
                    }
                    break;

                case 'n':
                    // inspect
                    txtMessage.textout( "n\n" );
                    party.inspect();
                    txtStatus.clear();
                    break;

                default:
                    assert( 0 , "cdengeon.camp" );
            }
        }
    EXIT:
        if( party.layer == 0 )
            return rtnval;  // return castle or leave game;

        party.dungeon.disp;
        dispHeader( HSTS.DUNGEON );
        // in rock check
        if ( party.dungeon.checkInRock )
        {
            txtMessage.textout( _( "\n*** in rock! ***\n" ) );
            foreach( p ; party )
                p.isLost;
            party.dispPartyWindow();
            getChar();
            party.layer=0;
            party.olayer=0;
        }
        return rtnval;
    }




    /**--------------------
       get_treasure - アイテム取得
       --------------------*/
    void getTreasure( int mon )
    {
        int itemno;
        MonsterDef mdata = monster_data[ mon ]; 
        Item itm;

        for ( int i = 0; i < 3; i++ )
        {

            if ( mdata.itemratio[ i ] < get_rand( 100 ) )
                continue;

            itemno = mdata.itemmin[ i ] 
                    + get_rand( mdata.itemmax[ i ] - mdata.itemmin[ i ] );

            foreach_reverse( Member p ; party )
            {
                if( p.canCarry )
                {
                    if (item_data[ itemno ].name == "")
                    {
                        txtMessage.textout("item#: ");
                        txtMessage.textout( itemno );
                        txtMessage.textout( "\n" );
                    }
                    itm = p.getItem( itemno );
                    itm.undefined = true;

                    txtMessage.textout( _( "  %1 discovered a %2.\n" ) , p.name , itm.getDispName );
                    getChar();
                    return;
                }
            }
            txtMessage.textout( _( "you cannot carry anything more.\n" ) );
            return;
        }

        return ;
    }

}
