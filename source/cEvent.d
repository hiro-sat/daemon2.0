
// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;
import std.json;

// mysource 
import lib_json;
import cTextarea;

import cTextareaEvent;

import cParty;
import cMember;
import cMonsterParty;
import cMonsterEncount;

import def;
import app;
import battle;
import dungeon;

/* import lib_sdl; */

class Event
{

    int layer;
    bool[ 50 ] eventflg;

    Json      json;  // map info , event
    JSONValue event;  // event

    EventTextarea   eventmsg;   // event 用テキストエリア

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
        eventmsg = new EventTextarea( EVENT_X_SIZ , EVENT_Y_SIZ );

        resetFlg;
        return;
    }

    void resetFlg()
    {
        for( int i = 0 ; i < 20 ; i++ )
            eventflg = false;
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

        eventmsg.textout( _( "\n*** up stairs ***\n" ) );
        eventmsg.textout( _( "go up(y/n)? " ) );
        eventmsg.dispNow;

        if ( answerEventYN == 'n')
        {
            eventmsg.textout( _( "leaved...\n" ) );
            eventmsg.dispNow;
            getChar;
            eventmsg.clear;
            party.dungeon.disp;
            return 0;
        }
        else
        {
            eventmsg.clear;
            party.layer--;
            if( party.layer == 0 )
            {
                for ( int i = 0; i < party.num; i++ )
                    party.mem[ i ].outflag = OUT_F.CASTLE; // in castle
                return 2; /* exit from maze */
            }
            else
            {
                party.setDungeon;
                party.dungeon.setEndPos;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
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

        eventmsg.textout( _( "\n*** down stairs ***\n" ) );
        eventmsg.textout( _( "go down(y/n)? " ) );

        if ( answerEventYN == 'y')
        {
            party.layer++;
            party.setDungeon;
            party.dungeon.setStartPos;
            party.dungeon.initDisp;
            party.dungeon.disp;
            header_disp( HSTS.DUNGEON );
            return 1;
        }
        return 0;
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
        for ( i = 0; i < party.num; i++ )
        {
            if ( party.mem[ i ].status < STS.DEAD )
            {
                party.mem[ i ].hp -= get_rand( party.layer * 4 );
                if ( party.mem[ i ].hp <= 0 )
                {
                    party.mem[ i ].hp = 0;
                    party.mem[ i ].status = STS.DEAD;
                }
            }
        }
        party.win_disp();
        

        if( party.checkAlive )
            return 0;

         //全滅!
        for ( i = 0; i < party.num; i++ )
            if ( party.mem[ i ].status < STS.DEAD )
                party.mem[ i ].status = STS.DEAD;

        party.num = 0;
        party.layer = 0;
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
            // special
        {
            assert( ( encID ~ ENC_TBL_SP ) in encountTable );
            return encountTable[ encID ~ ENC_TBL_SP ].getEncount;
        }
        else
        {
            assert( encID in encountTable );
            return encountTable[ encID ].getEncount;
        }
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

        BATTLE_RESULT bt_result;
        char c;

        setColor( CL.MONSTER );
        party.dungeon.textoutNow( _( "\n   ====== ENCOUNTER!! =====" ) );
        gsdl.delay( 1000 );
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

        monParty.add( mon[] );

        // bt_result = 1 : won
        //             2 : ran
        //             3 : lost
        bt_result = battle_main();

        if ( bt_result == BATTLE_RESULT.WON )
        { /* won */
            if ( tre == TRE.TREASURE )
            {
                if( ! treasure_main( mon[ 0 ] ) )
                    return BATTLE_RESULT.LOST;      // 罠により全滅
            }
            else if ( tre == TRE.GOLD )
            {
                getgold = monster_data[ mon[ 0 ] ].mingp 
                        + get_rand( monster_data[ mon[ 0 ] ].addgp );
                getgold /= party.num;
                /* eventmsg.textout( _( "  each survivor gets %1 gp.\n" ) , getgold ); */
                win_msg.textout( _( "  each survivor gets %1 gp.\n" ) , getgold );
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status  == STS.OK )
                        party.mem[ i ].gold += getgold;
                }
            }
        }

        getChar;
        party.dungeon.disp;

        return bt_result;
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int event_chk( char m ) 
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
            eventmsg.textout( "not event : " ~ to!string( m ) );
            return 0;
        }
        
        JSONValue ev;
        ev = event[ to!string( m ) ].object;
        
        int ret = 0;
        bool exit = false;

        eventmsg.disp( party.dungeon.dispPartyX , party.dungeon.dispPartyY );

        executeEvent( ev , ret , exit );
        getChar;
        eventmsg.clear;
        return ret;

    }


    /*--------------------
       executeEvent - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       --------------------*/
    void executeEvent( JSONValue ev , ref int ret , ref bool exit )
    {

        int count = 1;
        string index;
        int[] mdef;

        JSONValue com;
        JSONValue result;

        while( !exit )
        {

            index = "00" ~ to!string( count ++ );
            index = index[ index.length - 3 .. $ ];

            if( ! ( index in ev ) )
                break;

            com = ev[ index ].object;
            
            switch( com[ "command" ].str )
            {
                case "msg":
                    eventmsg.textout( com[ "text" ].str );
                    eventmsg.dispNow;
                    break;
                case "getkey":
                    getChar;
                    break;
                case "ret":
                    exit = true;
                    ret = to!int( com[ "value" ].integer );
                    return;
                case "battle":
                    foreach( m ; com[ "monster" ].array )
                        mdef ~= to!int( m.integer );
                    monParty.add( mdef );
                    battle_main;
                    break;
                case "jumplayer":
                    party.layer = to!byte( com[ "layer" ].integer );
                    party.setDungeon;
                    party.x = to!byte( com[ "x" ].integer );
                    party.y = to!byte( com[ "y" ].integer );
                    party.dungeon.initDisp;
                    party.dungeon.disp;
                    header_disp( HSTS.DUNGEON );
                    break;
                case "jump":
                    party.x = to!byte( com[ "x" ].integer );
                    party.y = to!byte( com[ "y" ].integer );
                    party.dungeon.initDisp;
                    party.dungeon.disp;
                    header_disp( HSTS.DUNGEON );
                    break;
                case "setflg":
                    eventflg[ to!int( com[ "flg" ].integer ) ] = true;
                    break;
                case "resetfg":
                    eventflg[ to!int( com[ "flg" ].integer ) ] = false;
                    break;
                case "getitem":
                    party.theyGet( to!int( com[ "item" ].integer ) );
                    break;

                case "if_yn":
                    result = com[ "result" ].object;
                    event_ifYN( result , ret , exit );
                    if( exit )
                        return;
                    break;
                case "if_battle":
                    result = com[ "result" ].object;
                    event_ifBattle( result , ret , exit );
                    if( exit )
                        return;
                    break;
                case "if_flg":
                    result = com[ "result" ].object;
                    event_ifFlg( result , ret , exit );
                    if( exit )
                        return;
                    break;
                case "if_item":
                    result = com[ "result" ].object;
                    event_ifItem( result , ret , exit );
                    if( exit )
                        return;
                    break;
                default:
                    assert( 0 );
            }
        }
        return;
    }

    /*--------------------
       event_ifYN - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifYN( JSONValue ev , ref int ret , ref bool exit)
    {

        JSONValue result;

        switch( answerEventYN )
        {
            case 'y':
                if( "y" in ev )
                {
                    result = ev[ "y" ].object;
                    executeEvent( result , ret , exit );
                }
                return;
            case 'n':
                if( "n" in ev )
                {
                    result = ev[ "n" ].object;
                    executeEvent( result , ret , exit );
                }
                return;
            default:
                assert( 0 );
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
        eventmsg.textout( c );
        eventmsg.textout( '\n' );
        eventmsg.dispNow();
        
        return c;
    }

    /*--------------------
       event_ifBattle - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       --------------------*/
    void event_ifBattle( JSONValue ev , ref int ret , ref bool exit )
    {

        int[] mdef;
        JSONValue result;

        foreach( m ; ev[ "monster" ].array )
            mdef ~= to!int( m.integer );
        monParty.add( mdef );

        switch( battle_main )
        {
            case BATTLE_RESULT.WON:
                if( "win" in ev )
                {
                    result = ev[ "win" ].object;
                    executeEvent( result , ret , exit );
                }
                return;
            case BATTLE_RESULT.LOST:
                if( "lose" in ev )
                {
                    result = ev[ "lose" ].object;
                    executeEvent( result , ret , exit );
                }
                return;
            case BATTLE_RESULT.RAN:
                if( "escape" in ev )
                {
                    result = ev[ "escape" ].object;
                    executeEvent( result , ret , exit );
                }
                return;
            default:
                assert( 0 );
        }
    }

    /*--------------------
       event_ifFlg - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifFlg( JSONValue ev , ref int ret , ref bool exit )
    {

        JSONValue result;

        if( eventflg[ ev[ "flg" ].integer ] )
        {
            if( "on" in ev )
            {
                result = ev[ "on" ].object;
                executeEvent( result , ret , exit );
            }
        }
        else
        {
            if( "off" in ev )
            {
                result = ev[ "off" ].object;
                executeEvent( result , ret , exit );
            }
        }
        return;

    }

    /*--------------------
       event_ifItem - イベント実行
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
       true: event end / false: continue
       --------------------*/
    void event_ifItem( JSONValue ev , ref int ret , ref bool exit )
    {

        JSONValue result;

        if ( party.doTheyHave( to!int( ev[ "item" ].integer ) ) )
        {
            if( "have" in ev )
            {
                result = ev[ "have" ].object;
                executeEvent( result , ret , exit );
            }
        }
        else
        {
            if( "dont" in ev )
            {
                result = ev[ "dont" ].object;
                executeEvent( result , ret , exit );
            }
        }
        return;

    }

}

/+ 
/*====== event L1 ===================================================*/
class EventL1 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'A':
                eventmsg.textout( "*** Welcome to the Dungeon of Daemon ***\n" );
                eventmsg.textout( "    Copyright by K.Achiwa, 1996,2002.\n" );
                eventmsg.textout( "                 All Rights Reserved.\n" );
                eventmsg.textout( "****************************************\n" );
                break;
            case 'B':
                eventmsg.textout( "壁にmessageが書かれている:\n" );
                eventmsg.textout( "「ここでsearch('s')してみな。\n" );
                eventmsg.textout( "　。。うわ、俺ってやさしいぜ！ S.」\n" );
                break;
            case 'c':
                eventmsg.textout( "ムッとするような湿気で満たされている部屋だ。\n" );
                break;
            case 'C':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「おまえら初心者だな。悪いことは言わねえ。\n" );
                eventmsg.textout( "　痛い目に遭わない内に引き返すこった。 S.」\n" );
                break;
            case 'D':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「うーむ。。。\n" );
                eventmsg.textout( "　戻る気は無いってことか。。。 S.」\n" );
                break;
            case 'e':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「しかし残念だったな。お宝は残ってないぜ。\n" );
                eventmsg.textout( "　俺たちflorin公国の精鋭部隊purple beretが\n" );
                eventmsg.textout( "　お先にいただいちまってる筈さ! S.」\n" );
                break;
            case 'f':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                eventmsg.textout( "「この先にdarkzoneがあるぜ。 S.」\n" );
                break;
            case 'g':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「flip!! flip!! flipしてるか?\n" );
                eventmsg.textout( "　冒険には何よりflipが大切さ! S.」\n" );
                break;
            case 'h':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「Howdy! 調子はどうだい?\n" );
                eventmsg.textout( "　そろそろお家に帰りたくなってきたろ? S.」\n" );
                break;
            case 'i':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「この中には強いモンスターがいるぜ。 S.」\n" );
                break;
            case 'j':
                eventmsg.textout( "*** 異常な妖気が満ちている。\n  探しますか(y/n)? " );
                if ( answerYN == 'y')
                {
                    monParty.add( [ 77 ] );
                    battle_main();
                }
                rtncode = 1;
                break;
            case 'k':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「おい、何だかおかしいぜ?\n" );
                eventmsg.textout( "　ここのモンスターは普通じゃない。\n" );
                eventmsg.textout( "　何らかの力で強化されてるみたいだ S.」\n" );
                break;
            case 'l':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「いやー、無駄に広い部屋だ。。 S.」\n" );
                break;
            case 'm':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「。。。メンバーには内緒だけどな、\n" );
                eventmsg.textout( "　モンスターを倒して宝を取ってこい、\n" );
                eventmsg.textout( "　なんてミッションには裏がありそうだ。\n" );
                eventmsg.textout( "　。。。。。\n" );
                getChar();
                eventmsg.textout( "　ここには何かある。\n" );
                eventmsg.textout( "　俺の直感がそう言っているぜ。 S.」\n" );
                break;
            case 'n':
                eventmsg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                eventmsg.textout( "「ここまで来たか。\n　おまえらなかなかやるな S.」\n" );
                break;
            case 'o':
                eventmsg.textout( "どこか遠くの部屋でガタガタと物音が聞こえてくる。 \n" );
                getChar();
                break;


            case 'p':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '3':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();

                party.layer=3;
                party.setDungeon;
                party.x = 37;
                party.y = 17;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'q':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '4':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();
                party.layer=4;
                party.setDungeon;
                party.x =  4;
                party.y = 16;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'r':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '5':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();
                party.layer=5;
                party.setDungeon;
                party.x = 28;
                party.y =  4;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 's':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '6':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();
                party.layer=6;
                party.setDungeon;
                party.x = 37;
                party.y = 24;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 't':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '7':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();
                party.layer=7;
                party.setDungeon;
                party.x =  1;
                party.y =  2;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'u':
                eventmsg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '8':
                eventmsg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
                getChar();
                party.layer=8;
                party.setDungeon;
                party.x =  1;
                party.y =  2;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;

            default:
                break;
        }

        return rtncode;

    }
}


/*====== event L2 ===================================================*/
class EventL2 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {

        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「悪いことは言わない。\n　とりあえず北からにしろ S.」\n");
                break;
            case 'b':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「bishopのCynthiaも何か気づいてるみてぇだ\n");
                eventmsg.textout("　dispelのかかりが悪いと言ってる。 S.」\n");
                break;
            case 'c':
                eventmsg.textout("*** ここはかつて宝物庫であったらしい。\n");
                eventmsg.textout("    しかし、荒らされて貴重な物は何も\n    残っていないようだ。\n");
                break;
            case 'd':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「へへへ。いただき! S.」\n");
                break;
            case 'e':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「ここ、コーヒーの臭いがしねぇか? S.」\n");
                eventmsg.textout("探しますか(y/n)? ");
                if( answerYN == 'y' && ! eventflg[ 0 ] )
                {
                    eventflg[ 0 ] = true;
                    monParty.add( [ 12,12,12,12 ] );
                    if ( battle_main == BATTLE_RESULT.WON )
                        party.theyGet( 19 );
                }
                else
                {
                  eventmsg.textout("気のせいだったようだ。\n");
                }
                break;
            case 'f':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「vorpal_toothは持ったかい? S.」\n");
                break;
            case 'g':
                if ( ! party.doTheyHave( 170 ) )
                {
                    eventmsg.textout("*** 頭の中で声が響いた:\n");
                    getChar();
                    eventmsg.textout("「お前達にはここに来る資格が無い!」\n");
                    party.y -= 2;
                    party.oy -= 2;
                }
                break;
            case 'h':
                eventmsg.textout("*** なんだかウサギ臭い。。。。\n");
                eventmsg.textout("探しますか(y/n)? ");
                if ( answerYN == 'y' && !eventflg[ 1 ] )
                {
                    eventflg[ 1 ] = true;
                    monParty.add( [ 14,14,14,14 ] );
                    if ( battle_main() == BATTLE_RESULT.WON )
                        party.theyGet( 170 ); // vorpal_toth, 3Fへの階段のキーアイテム
                }
                else
                {
                  eventmsg.textout("気のせいだったようだ。\n");
                }
                break;
            case 'i':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「darkzoneってのは歩きにくいよな。\n");
                eventmsg.textout("　shineとmapperを唱えておけよ。 S.」\n");
                break;
            case 'j':
                eventmsg.textout("*** ひんやりとした冷気が漂っている\n");
                eventmsg.textout("    ここはかつて冷暗所だったのだろうか。\n");
                break;
            case 'k':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「floatを覚えてりゃpitは怖く\n　ないんだが。 S.」\n");
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L3 ===================================================*/
class EventL3 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {

            case 'a':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!南に行くな」\n");
                break;
            case 'b':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!北に行くな」\n");
                break;
            case 'c':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「右を向け」\n");
                break;
            case 'd':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「左を向け」\n");
                break;
            case 'e':
                eventmsg.textout("焚き火をした跡がある。\n");
                eventmsg.textout("まだ暖かい。他の冒険者達が\n");
                eventmsg.textout("キャンプを張っていたのだろうか。\n");
                break;
            case 'f':
                eventmsg.textout("息苦しい空気の立ち込めた部屋だ。\n");
                eventmsg.textout("足元には赤みがかった苔がむしている。\n");
                break;
            case 'g':
                eventmsg.textout("壁に小さな人影が焼きついている。\n");
                eventmsg.textout("おそらくfireかflamesで焼かれた\n");
                eventmsg.textout("モンスターであろう。\n");
                break;
            case 'h':
                eventmsg.textout("真っ暗な部屋の一部の壁が\n");
                eventmsg.textout("ぼうっと青白く光っている。\n");
                break;
            case 'i':
                eventmsg.textout("壁の向こうをガシャガシャと、数名の冒険者\n");
                eventmsg.textout("(モンスターか?)が通る音が聞こえた。\n");
                break;
            case 'j':
                eventmsg.textout("何体かのモンスターの死体が横たわってる。\n");
                eventmsg.textout("一体はまっぷたつに切り裂かれ、別の一体は\n");
                eventmsg.textout("上半身が黒こげだ。その横に、蓋の開いた宝箱\n");
                eventmsg.textout("がある。中には何も残っていないようだ。\n");
                break;
            case 'k':
                eventmsg.textout("暗闇の中に、ぶきみな二つの目が光った。\n");
                eventmsg.textout("それは君たちに襲い掛かってくることもなく、\n");
                eventmsg.textout("数秒して消えてしまった。\n");
                break;
            case 'l':
                eventmsg.textout("突然けたたましい音が鳴り響いた!\n");
                eventmsg.textout("が、その音に集まってくるモンスターは\n");
                eventmsg.textout("いなかった。\n");
                break;
            case 'm':
                eventmsg.textout("ビュン! 目の前を何本かの矢が風きり音を\n");
                eventmsg.textout("たてて横切った。。トラップだ! しかし、\n");
                eventmsg.textout("作動が少し早すぎたようだ。\n");
                break;
            case 'n':
                eventmsg.textout("床が動いている!\n");
                eventmsg.textout("と思ったら、それは大量のゴキブリだった。\n");
                break;
            case 'o':
                eventmsg.textout("邪悪な気配に満ちた部屋だ。\n");
                break;
            case 'p':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「このダンジョンのヌシは相当あぶねぇ\n");
                eventmsg.textout("　奴のようだ。こんなに上層にwerebearが\n");
                eventmsg.textout("　うろついているとは。 S.」\n");
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L4 ===================================================*/
class EventL4 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                eventmsg.textout("焼け付くように熱い部屋だ。\n");
                eventmsg.textout("何者かがflamoeでも使ったあとか?\n");
                break;
            case 'b':
                eventmsg.textout("バナナの皮が落ちている。\n");
                eventmsg.textout("それで滑って転んだ時にちょうど頭が\n");
                eventmsg.textout("来る位置に、硬そうな石が置いてある。\n");
                eventmsg.textout("・・・罠だ!\n");
                break;
            case 'c':
                eventmsg.textout("首のない死体が3体横たわっている。\n");
                eventmsg.textout("忍者に殺された冒険者か?\n");
                break;
            case 'd':
                eventmsg.textout("操り人形が落ちている。\n");
                eventmsg.textout("どうやら生きているらしいが、糸がからまって\n");
                eventmsg.textout("身動きができないようだ。\n");
                break;
            case 'e':
                eventmsg.textout("壊れた機械らしきものが置いてある。\n");
                eventmsg.textout("蹴ってみたが反応は無かった。\n");
                break;
            case 'f':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「しくじった!\n");
                eventmsg.textout("　Cynthiaの奴が呪いのメイスに取り付かれ\n");
                eventmsg.textout("　ちまった。進むべきか、いったん引き上げ\n");
                eventmsg.textout("　るか。。。 S.」\n");
                break;
            case 'h':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「まいった。。。\n");
                eventmsg.textout("　Cynthiaの奴、ショック状態から回復しねぇ。\n");
                eventmsg.textout("　ここでは呪いが強くなっているのか。。 S.」\n");
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("突然、目の前に黒い影が現れた!\n");
                eventmsg.textout("「グルルル・・・ガガガッ」\n");
                getChar();
                monParty.add( [ 86,59 ] ); // vampireとwerewolf
                if ( battle_main() == BATTLE_RESULT.WON )
                {
                    eventflg[ 0 ] = true;
                    party.theyGet( 43 ); // garcon jacket(e)
                }
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L5 ===================================================*/
class EventL5 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                eventmsg.textout("このフロアは壁が磨き上げられた大理石で\n");
                eventmsg.textout("できているようだ。カツカツと足音が響く。\n");
                break;
            case 'b':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「Cynthiaを宿屋に預けてきた。\n");
                eventmsg.textout("　ずいぶんと時間をロスしちまったぜ。 S.」\n");
                break;
            case 'c':
                eventmsg.textout("!! モンスターが!\n");
                eventmsg.textout("・・と思ったら、壁に映った自分たちだった。\n");
                break;
            case 'd':
                eventmsg.textout("ポロンポロン、とピアノを弾く音が聞こえて\n");
                eventmsg.textout("くる。なぜこのようなダンジョンにピアノが??\n");
                break;
            case 'e':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「やはり一人欠けると厳しいか。。\n");
                eventmsg.textout("　回復魔法の残りが気になる。 S.」\n");
                break;
            case 'f':
                eventmsg.textout("グランドピアノが置いてある。\n");
                eventmsg.textout("モンスターがピアノを・・・?\n");
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L6 ===================================================*/
class EventL6 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("突然、目の前に黒い影が現れた!\n");
                eventmsg.textout("「おや、珍しい。お客さんだ。」\n");
                getChar();
                monParty.add([ 99,86,86,86 ]); // vampire lordとvampire
                if ( battle_main() == BATTLE_RESULT.WON  )
                {
                    eventflg[ 0 ] = true;
                    party.theyGet( 102 ); // amulet of muomoe(makanito)
                }
                break;
            case 'b':
                eventmsg.textout("ふわふわと風船のような物が漂っている。\n");
                eventmsg.textout("特に何もしないようだ。\n");
                break;
            case 'c':
                eventmsg.textout("ちろちろと水が流れている。\n");
                eventmsg.textout("ひんやりとしたきれいな水だ。\n");
                break;
            case 'd':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「やべぇ。\n");
                eventmsg.textout("　モンスターがかなり手強くなってきた。 S.」\n");
                break;
            case 'e':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「くそっ。\n");
                eventmsg.textout("　なんだ、この部屋の数は!? S.」\n");
                break;
            case 'f':
                eventmsg.textout("耳鳴りがする。圧迫されたダンジョンの\n");
                eventmsg.textout("空気で、気が変になりそうだ。。\n");
                break;
            case 'g':
                eventmsg.textout("冒険者とみられる死体が6体倒れている。\n");
                eventmsg.textout("こうはなりたくないものだ。。。\n");
                break;
            case 'h':
                eventmsg.textout("フランス人形が笑い声をたてている。\n");
                eventmsg.textout("剣でまっぷたつに切ったら笑い声は止んだ。\n");
                break;
            case 'i':
                eventmsg.textout("壁に大きな字で｢6｣と書いてある。\n");
                eventmsg.textout("何かの意味があるのだろうか?\n");
                break;
            case 'j':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!回れ右をせよ」\n");
                break;
            case 'k':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!立ち止まるな」\n");
                break;
            case 'l':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!右に行け」\n");
                break;
            case 'm':
                eventmsg.textout("たて看板がある:\n");
                eventmsg.textout("「危険!南に行くな」\n");
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L7 ===================================================*/
class EventL7 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                eventmsg.textout("\n*** chute! ***\n");

                party.layer++;
                party.setDungeon;

                /* party.dungeon.setStartPos; */
                party.x = 1;
                party.y = 2;

                party.dungeon.initDisp;
                party.dungeon.disp;

                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'b':
                eventmsg.textout("壁に大きな看板がかかっている。\n");
                eventmsg.textout("「引き返せ!さもないと、」\n");
                eventmsg.textout("その続きは汚れて読めない。\n");
                break;
            case 'c':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「地下1Fに似ているな。\n");
                eventmsg.textout("　しかし、陰険な罠だらけのフロアだ。 S.」\n");
                break;
            case 'd':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「やべぇ。前衛の一人が倒れて、\n");
                eventmsg.textout("　盗賊が前衛に立つことになった。 S.」\n");
                break;
            case 'e':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("*** 異常な妖気が満ちている。\n  探しますか(y/n)? ");
                if ( answerYN == 'y' )
                {
                    eventmsg.textout( "地鳴りがする。。。来るぞ!!!\n" );
                    getChar();
                    monParty.add( [ 98,89,89,89 ] ); // maelificとdoragon zombies
                    if ( battle_main() == BATTLE_RESULT.WON )
                    {
                        eventflg[ 0 ] = true;
                        party.theyGet( 96 ); // dragon slayer
                    }
                }
                rtncode = 1;
                break;
            default:
                break;
        }

        return rtncode;
    }
}

/*====== event L8 ===================================================*/
class EventL8 : Event
{

    this( int l ) { super( l ); }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        switch( m )
        {
            case 'a':
                // L8 start 地点
                break;
            case 'b':
                eventmsg.textout( "\n*** jump to the castle! ***\n" );
                getChar();
                party.x = 1;
                party.y = 2;
                party.layer = 0;
                for ( int i = 0; i < party.num; i++ )
                    party.mem[ i ].outflag = OUT_F.CASTLE ; // in castle
                break;
            case 'c':
                eventmsg.textout( "\n*** teleporter! ***\n" );
                party.x = 1;
                party.y = 2;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'd':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「俺は見た!\n");
                eventmsg.textout("　50回攻撃し、最後には首を刎ねるという\n");
                eventmsg.textout("　伝説の魔神を! S.」\n");
                break;
            case 'e':
                eventmsg.textout("頭の中に声が響いた。\n");
                eventmsg.textout("「お前たちは来てはいけない領域に迷い混んで\n");
                eventmsg.textout("　しまった。引き返すがよい。今のうちに。。」\n");
                break;
            case 'f':
                eventmsg.textout("壁にmessageが書かれている:\n");
                getChar();
                eventmsg.textout("「俺たちはもうボロボロだ。\n");
                eventmsg.textout("　最強のpurple beretがこんなにも簡単に\n");
                eventmsg.textout("　やられるとは。。。。 S.」\n");
                getChar();
                eventmsg.textout("その下に、白骨化した死体が転がっている。\n");
                break;
            case 'g':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("頭の中に声が響いた。\n");
                eventmsg.textout("「私の忠告を無視したようだな。\n");
                eventmsg.textout("　あの世で後悔するがいい。。。」\n");
                break;
            case 'h':
                if( eventflg[ 1 ] )
                {
                    rtncode = 1;
                    break;
                }
                eventmsg.textout( "一筋の風が吹いた。\n" );
                getChar();
                monParty.add( [ 91,91,91,91 ] ); // the_high_masters
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 1 ] = true;
                rtncode = 1;
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("頭の中に声が響いた。\n");
                eventmsg.textout("「思ったよりやるようだ。\n");
                eventmsg.textout("　楽しみになってきたよ。。。」\n");
                break;
            case 'j':
                if( eventflg[ 2 ] )
                {
                    rtncode = 1;
                    break;
                }
                eventmsg.textout( "暗闇に雷が轟いた!!\n" );
                getChar();
                monParty.add( [ 102,97,87,68 ] ); // demon lord
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 2 ] = true;
                rtncode = 1;
                break;
            case 'k':
                if( eventflg[ 0 ] )
                    break;
                eventmsg.textout("頭の中に声が響いた。\n");
                eventmsg.textout("「ほほう。よかろう。\n");
                eventmsg.textout("　来るがいい、私の元へ。。。」\n");
                break;
            case 'l':
                if( eventflg[ 0 ] )
                {
                    rtncode = 1;
                    break;
                }
                eventmsg.textout( "長身の男が立ったまま瞑想している。\n" );
                getChar();
                monParty.add( [ 108,101,91,91 ] ); // DAEMON, petit_daemon

                if( battle_main == BATTLE_RESULT.WON )
                    eventflg[ 0 ] = true;

                rtncode = 1;
                break;
            case 'm':
                if ( party.doTheyHave(171) )
                    break;
                eventmsg.textout( "一冊の本が落ちている。\n" );
                party.theyGet( 171 ); // diary
                break;
            default:
                break;
        }

        return rtncode;
    }
}

+/
