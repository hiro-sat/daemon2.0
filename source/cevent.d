
// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;
import std.json;

// mysource 
import lib_json;
import ctextarea;

import ctextarea_event;

import cparty;
import cmember;
import cmonster_party;
import cmonster_encount;

import def;
import app;
import cbattle;
import cdungeon;

/* import lib_sdl; */

class Event
{

    int layer;
    bool[ string ] eventflg;

    Json      json;  // map info , event
    JSONValue event;  // event

    EventTextarea   txtEventMessage;   // event 用テキストエリア

    // encount
    /* int specialRate = 4; */
    /* string encID= "1"; */
    int specialRate;
    string encID;

    this( int l )
    {
        layer = l;

        // json 確認 )
        json = new Json( formatText( ORGMAPJSON , fill0( layer , 2 ) ) );
        JSONValue mapJson = json[ "encount" ].object;

        encID = mapJson[ "id" ].str;
        specialRate = to!int( mapJson[ "special_rate" ].integer );

        event = json[ "event" ].object;

        // textarea
        txtEventMessage = new EventTextarea( EVENT_X_SIZ , EVENT_Y_SIZ );

        resetFlg;
        return;
    }

    void resetFlg()
    {
        foreach( key ,f ; eventflg)
            eventflg[ key ] = false;
        return;
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int upStairs( char m )
    {
        if( m != '<' )
        {
            party.dungeon.textoutNow( _( "what?\n" ) );
            getChar;
            return 0;
        }

        txtEventMessage.textout( _( "\n*** up stairs ***\n" ) );
        txtEventMessage.textout( _( "go up(y/n)? " ) );
        txtEventMessage.dispNow;

        if ( answerEventYN == 'n')
        {
            txtEventMessage.textout( _( "leaved...\n" ) );
            txtEventMessage.dispNow;
            getChar;
            txtEventMessage.clear;
            party.dungeon.disp;
            return 0;
        }
        else
        {
            txtEventMessage.clear;
            party.layer--;
            if( party.layer == 0 )
            {
                foreach( p ; party )
                    p.outflag = OUT_F.CASTLE; // in castle
                return 2; /* exit from maze */
            }
            else
            {
                party.setDungeon;
                party.dungeon.setEndPos;
                party.dungeon.initDisp;
                party.dungeon.disp;
                dispHeader( HSTS.DUNGEON );
            }
            return 1;
        }
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int downStairs( char m )
    {

        if( m != '>' )
        {
            party.dungeon.textoutNow( _( "\nwhat?" ) );
            getChar;
            return 0;
        }

        txtEventMessage.textout( _( "\n*** down stairs ***\n" ) );
        txtEventMessage.textout( _( "go down(y/n)? " ) );
        txtEventMessage.dispNow;

        if ( answerEventYN == 'n')
        {
            txtEventMessage.textout( _( "leaved...\n" ) );
            txtEventMessage.dispNow;
            getChar;
            txtEventMessage.clear;
            party.dungeon.disp;
            return 0;
        }
        else
        {
            txtEventMessage.clear;
            party.layer++;
            party.setDungeon;
            party.dungeon.setStartPos;
            party.dungeon.initDisp;
            party.dungeon.disp;
            dispHeader( HSTS.DUNGEON );
            return 1;
        }
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int pit()
    {

        int i;
        char c;

        // pit! but floating.
        if ( party.isFloat )
        {
            party.dungeon.textout( _( "\na pit, but floating." ) );
            return 0;
        }

        // pit!
        party.dungeon.textoutNow( _( "\n*** a pit! ***" ) );
        getChar;
        foreach( p ; party )
        {
            if ( p.status < STS.DEAD )
            {
                p.hp -= get_rand( party.layer * 4 );
                if ( p.hp <= 0 )
                {
                    p.hp = 0;
                    p.status = STS.DEAD;
                }
            }
        }
        party.dispPartyWindow();
        

        if( party.checkAlive )
            return 0;

        //全滅!
        foreach( p ; party ) 
            if ( p.status < STS.DEAD )
                p.status = STS.DEAD;    // 麻痺等のメンバーも死亡扱い

        party.saveLocate;
        party.layer = 0;
        setColor( STS_CL.DEAD );
        party.dungeon.textoutNow( _( "\n*** your party is lost..." ) );
        getChar;
        party.dungeon.textoutNow( _( "\n<push space bar(5)>" ) );

        while ( true )
        {
            c = getChar();
            if ( c == ' ' || c == '5' )
                break;
        }

        return 2;
    }


    /*--------------------
       getEncounterMonster - エンカウンターモンスター取得
       --------------------*/
    int getEncounterMonster()
    {
        if( specialRate != 0 && ( get_rand( specialRate - 1 ) == 0 ) )
        {
            // special
            if ( ( encID ~ ENC_TBL_SP ) in encountTable )
                return encountTable[ encID ~ ENC_TBL_SP ].getEncount;
        }

        assert( encID in encountTable );
        return encountTable[ encID ].getEncount;
    }

    /*====== encount =================================================*/
    /* tre=0 : gold */
    /* tre=1 : treasure */
    /* tre=2 : no gold nor treasure (alarm) */
    // rtncode = 1 : won
    //           2 : ran
    BATTLE_RESULT encounter( TRE tre )
    {
        int getgold;
        int i;

        int[] mon;

        BATTLE_RESULT battleResult;
        char c;

        setColor( CL.MONSTER );
        party.dungeon.textoutNow( _( "\n   ====== ENCOUNTER!! =====" ) );
        gsdl.delay( 800 );
        party.dungeon.textoutOff;
        party.dungeon.disp;

        mon.length = 1;
        mon[ 0 ] = getEncounterMonster();

        int buddy_no;
        while ( mon.length < 4 )
        {
            /* if ( monster_data[ mon[ mon.length - 1 ] ].budratio < get_rand( 100 ) ) */
            if ( monster_data[ mon.back ].budratio < get_rand( 100 ) )
                break;
            buddy_no = monster_data[ mon.back ].buddy;
            mon.length ++;
            mon.back = buddy_no;
        }

        monParty.encounter( mon[] );

        // bt_result = 1 : won
        //             2 : ran
        //             3 : lost
        
        battleResult = sceneBattle.battleMain;
        if ( battleResult == BATTLE_RESULT.WON )
        { /* won */
            if ( tre == TRE.TREASURE )
            {
                if( ! sceneDungeon.treasureMain( mon[ 0 ] ) )
                    return BATTLE_RESULT.LOST;      // 罠により全滅
            }
            else if ( tre == TRE.GOLD )
            {
                getgold = monster_data[ mon[ 0 ] ].mingp 
                        + get_rand( monster_data[ mon[ 0 ] ].addgp );
                getgold /= party.memCountAlive;
                txtMessage.textout( _( "  each survivor gets %1 gp.\n" ) , getgold );
                foreach( p ; party )
                    if ( p.status < STS.PARALY )
                        p.gold += getgold;
            }
        }

        if( battleResult != BATTLE_RESULT.LOST )
            getChar;
        party.dungeon.disp;

        return battleResult;
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int checkEvent( char m ) 
    {
        switch( m )
        {
            case '_':
                return pit;
            default:
                break;
        }

        // check event
        if( ( m >= 'a' && m <= 'z') 
         || ( m >= 'A' && m <= 'Z' && m != 'X' ) 
         || ( m >= '0' && m <= '9' ) )
        {
            // fall through
        }
        else
        {
            return 0;
        }

        // check json
        if( ! ( to!string( m ) in event ) )
        {
            txtEventMessage.textout( "[ not event : " ~ to!string( m ) ~ "]" );
            return 0;
        }
        
        // txtEventMessage.disp( party.dungeon.dispPartyX , party.dungeon.dispPartyY );

        party.dungeon.textoutOff;

        JSONValue[] list;
        list = event[ to!string( m ) ].array;
        
        // イベント実行開始
        int ret = 0;
        bool exit = false;
        bool presskey = false;
        txtEventMessage.resetEventDispFlg;

        eventLoop( list , presskey , ret , exit );

        if( presskey )
            getChar;

        if( txtEventMessage.eventDispFlg )
            txtEventMessage.clear;

        return ret;

    }

    /*--------------------
       eventLoop - イベントループ用
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       --------------------*/
    void eventLoop( JSONValue[] list , ref bool presskey , ref int ret , ref bool exit )
    {
        foreach( ev ; list )
        {
            executeEvent( ev , presskey , ret , exit );
            if( exit ) return;
        }
        return;
    }

    /*--------------------
       executeEvent - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       --------------------*/
    void executeEvent( JSONValue ev , ref bool presskey , ref int ret , ref bool exit )
    {

        int[] monsterList;

        JSONValue ifdata;

        if( "remark" in ev )
            return; // コメント

        switch( ev[ "command" ].str )
        {
            // case "remark":  // コメント
            //     break;  // 何もしない
            case "msg":
                txtEventMessage.textout( ev[ "text" ].str );
                txtEventMessage.dispNow;
                presskey = true;
                break;
            case "getkey":
                getChar;
                break;
            case "ret":
                exit = true;
                ret = to!int( ev[ "value" ].integer );
                break;
            case "battle":
                foreach( m ; ev[ "monster" ].array )
                    monsterList ~= to!int( m.integer );
                monParty.encounter( monsterList );
                sceneBattle.battleMain;
                break;

            case "notpresskey":
                presskey = false;
                break;
            case "jump":
                party.x = to!int( ev[ "x" ].integer );
                party.y = to!int( ev[ "y" ].integer );
                if( "layer" in ev)
                {
                    party.layer = to!byte( ev[ "layer" ].integer );
                    party.setDungeon;
                }
                party.dungeon.setDispPos;
                party.dungeon.initDisp;
                party.dungeon.disp;
                dispHeader( HSTS.DUNGEON );
                break;
            case "move":
                party.x += ev[ "dx" ].integer;
                party.y += ev[ "dy" ].integer;
                party.dungeon.initDisp;
                party.dungeon.disp;
                dispHeader( HSTS.DUNGEON );
                break;
            case "setflg":
                eventflg[ ev[ "flg" ].str ] = true;
                break;
            case "resetfg":
                if( ev[ "flg" ].str in eventflg )
                    eventflg[ ev[ "flg" ].str ] = false;
                break;
            case "getitem":
                party.theyGet( to!int( ev[ "item" ].integer ) );
                break;

            case "if":
                ifdata = ev[ "data" ].object;
                if( "yn" in ifdata)
                    event_ifYN( ifdata , presskey , ret , exit );
                else if( "monster" in ifdata )
                    event_ifBattle( ifdata , presskey , ret , exit );
                else if( "flg" in ifdata )
                    event_ifFlg( ifdata , presskey , ret , exit );
                else if( "item" in ifdata )
                    event_ifItem( ifdata , presskey , ret , exit );
                else
                    assert( 0 , "event if ?" );
                break;
                
            default:
                assert( 0 , "event command?" );
        }
        return;
    }

    /*--------------------
       event_ifYN - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifYN( JSONValue ev , ref bool presskey ,ref int ret , ref bool exit)
    {
        switch( answerEventYN )
        {
            case 'y':
                if( "y" in ev )
                    eventLoop( ev[ "y" ].array , presskey , ret , exit );
                return;
            case 'n':
                if( "n" in ev )
                    eventLoop( ev[ "n" ].array , presskey , ret , exit );
                return;
            default:
                assert( 0 , "error ifYN" );
        }
    }

    /**-------------------- 
       answerEventYN - y or n を入力
       --------------------*/
    char answerEventYN()
    {
        char c;

        while ( true )
        {
            c = getChar();
            if ( c == 'y' || c == 'n' )
                break;
        }
        txtEventMessage.textout( c );
        txtEventMessage.textout( '\n' );
        txtEventMessage.dispNow();
        
        return c;
    }

    /*--------------------
       event_ifBattle - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       --------------------*/
    void event_ifBattle( JSONValue ev , ref bool presskey , ref int ret , ref bool exit )
    {

        int[] monsterList;

        foreach( m ; ev[ "monster" ].array )
           monsterList ~= to!int( m.integer );
        monParty.encounter( monsterList );

        switch( sceneBattle.battleMain )
        {
            case BATTLE_RESULT.WON:
                if( "win" in ev )
                    eventLoop( ev[ "win" ].array , presskey , ret , exit );
                return;
            case BATTLE_RESULT.LOST:
                if( "lose" in ev )
                    eventLoop( ev[ "lose" ].array , presskey , ret , exit );
                return;
            case BATTLE_RESULT.RAN:
                if( "escape" in ev )
                    eventLoop( ev[ "escape" ].array , presskey , ret , exit );
                return;
            default:
                // 友好的？
                if( "friendly" in ev )
                    eventLoop( ev[ "friendly" ].array , presskey , ret , exit );
                return;
        }

    }

    /*--------------------
       event_ifFlg - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifFlg( JSONValue ev , ref bool presskey , ref int ret , ref bool exit )
    {
        string flg = ev[ "flg" ].str;

        if( ( flg in eventflg ) && ( eventflg[ flg ] ) )
        {
            if( "on" in ev )
                eventLoop( ev[ "on" ].array , presskey , ret , exit );
            return;
        }
        else
        {
            if( "off" in ev )
                eventLoop( ev[ "off" ].array , presskey , ret , exit );
            return;
        }

    }

    /*--------------------
       event_ifItem - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifItem( JSONValue ev , ref bool presskey , ref int ret , ref bool exit )
    {

        if ( party.doTheyHave( to!int( ev[ "item" ].integer ) ) )
        {
            if( "have" in ev )
                eventLoop( ev[ "have" ].array , presskey , ret , exit );
            return;
        }
        else
        {
            if( "dont" in ev )
                eventLoop( ev[ "dont" ].array , presskey , ret , exit );
            return;
        }

    }

}
