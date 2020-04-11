
// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;
import std.json;

// mysource 
import lib_json;
import cTextarea;

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

    // encount
    /* int specialRate = 4; */
    /* string encID= "1"; */
    int specialRate;
    string encID;


    this( int l )
    {
        layer = l;

        // json 確認
        json = new Json( formatText( ORGMAPJSON , fill0( layer , 2 ) ) );
        JSONValue mapJson = json[ "encount" ].object;

        encID = mapJson[ "id" ].str;
        specialRate = to!int( mapJson[ "special_rate" ].integer );

        event = json[ "event" ].object;

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

        win_msg.textout( _( "\n*** up stairs ***\n" ) );
        win_msg.textout( _( "go up(y/n)? " ) );

        if ( answerYN == 'y')
        {
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
        return 0;
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

        win_msg.textout( _( "\n*** down stairs ***\n" ) );
        win_msg.textout( _( "go down(y/n)? " ) );

        if ( answerYN == 'y')
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
    BATTLE_RESULT
        encounter( TRE tre )
    {
        int getgold;
        int i;

        int[] mon;

        BATTLE_RESULT bt_result;
        char c;

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
                win_msg.textout( _( "  each survivor gets %1 gp.\n" ) , getgold );
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status  == STS.OK )
                        party.mem[ i ].gold += getgold;
                }
            }
        }

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
            win_msg.textout( "not event : " ~ to!string( m ) );
            return 0;
        }
        
        JSONValue ev;
        ev = event[ to!string( m ) ].object;
        
        int ret = 0;
        bool exit = false;
        executeEvent( ev , ret , exit );
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
                    win_msg.textout( com[ "text" ].str );
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

        switch( answerYN )
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
                win_msg.textout( "*** Welcome to the Dungeon of Daemon ***\n" );
                win_msg.textout( "    Copyright by K.Achiwa, 1996,2002.\n" );
                win_msg.textout( "                 All Rights Reserved.\n" );
                win_msg.textout( "****************************************\n" );
                break;
            case 'B':
                win_msg.textout( "壁にmessageが書かれている:\n" );
                win_msg.textout( "「ここでsearch('s')してみな。\n" );
                win_msg.textout( "　。。うわ、俺ってやさしいぜ！ S.」\n" );
                break;
            case 'c':
                win_msg.textout( "ムッとするような湿気で満たされている部屋だ。\n" );
                break;
            case 'C':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「おまえら初心者だな。悪いことは言わねえ。\n" );
                win_msg.textout( "　痛い目に遭わない内に引き返すこった。 S.」\n" );
                break;
            case 'D':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「うーむ。。。\n" );
                win_msg.textout( "　戻る気は無いってことか。。。 S.」\n" );
                break;
            case 'e':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「しかし残念だったな。お宝は残ってないぜ。\n" );
                win_msg.textout( "　俺たちflorin公国の精鋭部隊purple beretが\n" );
                win_msg.textout( "　お先にいただいちまってる筈さ! S.」\n" );
                break;
            case 'f':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                win_msg.textout( "「この先にdarkzoneがあるぜ。 S.」\n" );
                break;
            case 'g':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「flip!! flip!! flipしてるか?\n" );
                win_msg.textout( "　冒険には何よりflipが大切さ! S.」\n" );
                break;
            case 'h':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「Howdy! 調子はどうだい?\n" );
                win_msg.textout( "　そろそろお家に帰りたくなってきたろ? S.」\n" );
                break;
            case 'i':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「この中には強いモンスターがいるぜ。 S.」\n" );
                break;
            case 'j':
                win_msg.textout( "*** 異常な妖気が満ちている。\n  探しますか(y/n)? " );
                if ( answerYN == 'y')
                {
                    monParty.add( [ 77 ] );
                    battle_main();
                }
                rtncode = 1;
                break;
            case 'k':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「おい、何だかおかしいぜ?\n" );
                win_msg.textout( "　ここのモンスターは普通じゃない。\n" );
                win_msg.textout( "　何らかの力で強化されてるみたいだ S.」\n" );
                break;
            case 'l':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「いやー、無駄に広い部屋だ。。 S.」\n" );
                break;
            case 'm':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「。。。メンバーには内緒だけどな、\n" );
                win_msg.textout( "　モンスターを倒して宝を取ってこい、\n" );
                win_msg.textout( "　なんてミッションには裏がありそうだ。\n" );
                win_msg.textout( "　。。。。。\n" );
                getChar();
                win_msg.textout( "　ここには何かある。\n" );
                win_msg.textout( "　俺の直感がそう言っているぜ。 S.」\n" );
                break;
            case 'n':
                win_msg.textout( "壁にメッセージが書かれている:\n" );
                getChar();
                win_msg.textout( "「ここまで来たか。\n　おまえらなかなかやるな S.」\n" );
                break;
            case 'o':
                win_msg.textout( "どこか遠くの部屋でガタガタと物音が聞こえてくる。 \n" );
                getChar();
                break;


            case 'p':
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '3':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '4':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '5':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '6':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '7':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '8':
                win_msg.textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「悪いことは言わない。\n　とりあえず北からにしろ S.」\n");
                break;
            case 'b':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「bishopのCynthiaも何か気づいてるみてぇだ\n");
                win_msg.textout("　dispelのかかりが悪いと言ってる。 S.」\n");
                break;
            case 'c':
                win_msg.textout("*** ここはかつて宝物庫であったらしい。\n");
                win_msg.textout("    しかし、荒らされて貴重な物は何も\n    残っていないようだ。\n");
                break;
            case 'd':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「へへへ。いただき! S.」\n");
                break;
            case 'e':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「ここ、コーヒーの臭いがしねぇか? S.」\n");
                win_msg.textout("探しますか(y/n)? ");
                if( answerYN == 'y' && ! eventflg[ 0 ] )
                {
                    eventflg[ 0 ] = true;
                    monParty.add( [ 12,12,12,12 ] );
                    if ( battle_main == BATTLE_RESULT.WON )
                        party.theyGet( 19 );
                }
                else
                {
                  win_msg.textout("気のせいだったようだ。\n");
                }
                break;
            case 'f':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「vorpal_toothは持ったかい? S.」\n");
                break;
            case 'g':
                if ( ! party.doTheyHave( 170 ) )
                {
                    win_msg.textout("*** 頭の中で声が響いた:\n");
                    getChar();
                    win_msg.textout("「お前達にはここに来る資格が無い!」\n");
                    party.y -= 2;
                    party.oy -= 2;
                }
                break;
            case 'h':
                win_msg.textout("*** なんだかウサギ臭い。。。。\n");
                win_msg.textout("探しますか(y/n)? ");
                if ( answerYN == 'y' && !eventflg[ 1 ] )
                {
                    eventflg[ 1 ] = true;
                    monParty.add( [ 14,14,14,14 ] );
                    if ( battle_main() == BATTLE_RESULT.WON )
                        party.theyGet( 170 ); // vorpal_toth, 3Fへの階段のキーアイテム
                }
                else
                {
                  win_msg.textout("気のせいだったようだ。\n");
                }
                break;
            case 'i':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「darkzoneってのは歩きにくいよな。\n");
                win_msg.textout("　shineとmapperを唱えておけよ。 S.」\n");
                break;
            case 'j':
                win_msg.textout("*** ひんやりとした冷気が漂っている\n");
                win_msg.textout("    ここはかつて冷暗所だったのだろうか。\n");
                break;
            case 'k':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「floatを覚えてりゃpitは怖く\n　ないんだが。 S.」\n");
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
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!南に行くな」\n");
                break;
            case 'b':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!北に行くな」\n");
                break;
            case 'c':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「右を向け」\n");
                break;
            case 'd':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「左を向け」\n");
                break;
            case 'e':
                win_msg.textout("焚き火をした跡がある。\n");
                win_msg.textout("まだ暖かい。他の冒険者達が\n");
                win_msg.textout("キャンプを張っていたのだろうか。\n");
                break;
            case 'f':
                win_msg.textout("息苦しい空気の立ち込めた部屋だ。\n");
                win_msg.textout("足元には赤みがかった苔がむしている。\n");
                break;
            case 'g':
                win_msg.textout("壁に小さな人影が焼きついている。\n");
                win_msg.textout("おそらくfireかflamesで焼かれた\n");
                win_msg.textout("モンスターであろう。\n");
                break;
            case 'h':
                win_msg.textout("真っ暗な部屋の一部の壁が\n");
                win_msg.textout("ぼうっと青白く光っている。\n");
                break;
            case 'i':
                win_msg.textout("壁の向こうをガシャガシャと、数名の冒険者\n");
                win_msg.textout("(モンスターか?)が通る音が聞こえた。\n");
                break;
            case 'j':
                win_msg.textout("何体かのモンスターの死体が横たわってる。\n");
                win_msg.textout("一体はまっぷたつに切り裂かれ、別の一体は\n");
                win_msg.textout("上半身が黒こげだ。その横に、蓋の開いた宝箱\n");
                win_msg.textout("がある。中には何も残っていないようだ。\n");
                break;
            case 'k':
                win_msg.textout("暗闇の中に、ぶきみな二つの目が光った。\n");
                win_msg.textout("それは君たちに襲い掛かってくることもなく、\n");
                win_msg.textout("数秒して消えてしまった。\n");
                break;
            case 'l':
                win_msg.textout("突然けたたましい音が鳴り響いた!\n");
                win_msg.textout("が、その音に集まってくるモンスターは\n");
                win_msg.textout("いなかった。\n");
                break;
            case 'm':
                win_msg.textout("ビュン! 目の前を何本かの矢が風きり音を\n");
                win_msg.textout("たてて横切った。。トラップだ! しかし、\n");
                win_msg.textout("作動が少し早すぎたようだ。\n");
                break;
            case 'n':
                win_msg.textout("床が動いている!\n");
                win_msg.textout("と思ったら、それは大量のゴキブリだった。\n");
                break;
            case 'o':
                win_msg.textout("邪悪な気配に満ちた部屋だ。\n");
                break;
            case 'p':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「このダンジョンのヌシは相当あぶねぇ\n");
                win_msg.textout("　奴のようだ。こんなに上層にwerebearが\n");
                win_msg.textout("　うろついているとは。 S.」\n");
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
                win_msg.textout("焼け付くように熱い部屋だ。\n");
                win_msg.textout("何者かがflamoeでも使ったあとか?\n");
                break;
            case 'b':
                win_msg.textout("バナナの皮が落ちている。\n");
                win_msg.textout("それで滑って転んだ時にちょうど頭が\n");
                win_msg.textout("来る位置に、硬そうな石が置いてある。\n");
                win_msg.textout("・・・罠だ!\n");
                break;
            case 'c':
                win_msg.textout("首のない死体が3体横たわっている。\n");
                win_msg.textout("忍者に殺された冒険者か?\n");
                break;
            case 'd':
                win_msg.textout("操り人形が落ちている。\n");
                win_msg.textout("どうやら生きているらしいが、糸がからまって\n");
                win_msg.textout("身動きができないようだ。\n");
                break;
            case 'e':
                win_msg.textout("壊れた機械らしきものが置いてある。\n");
                win_msg.textout("蹴ってみたが反応は無かった。\n");
                break;
            case 'f':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「しくじった!\n");
                win_msg.textout("　Cynthiaの奴が呪いのメイスに取り付かれ\n");
                win_msg.textout("　ちまった。進むべきか、いったん引き上げ\n");
                win_msg.textout("　るか。。。 S.」\n");
                break;
            case 'h':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「まいった。。。\n");
                win_msg.textout("　Cynthiaの奴、ショック状態から回復しねぇ。\n");
                win_msg.textout("　ここでは呪いが強くなっているのか。。 S.」\n");
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                win_msg.textout("突然、目の前に黒い影が現れた!\n");
                win_msg.textout("「グルルル・・・ガガガッ」\n");
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
                win_msg.textout("このフロアは壁が磨き上げられた大理石で\n");
                win_msg.textout("できているようだ。カツカツと足音が響く。\n");
                break;
            case 'b':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「Cynthiaを宿屋に預けてきた。\n");
                win_msg.textout("　ずいぶんと時間をロスしちまったぜ。 S.」\n");
                break;
            case 'c':
                win_msg.textout("!! モンスターが!\n");
                win_msg.textout("・・と思ったら、壁に映った自分たちだった。\n");
                break;
            case 'd':
                win_msg.textout("ポロンポロン、とピアノを弾く音が聞こえて\n");
                win_msg.textout("くる。なぜこのようなダンジョンにピアノが??\n");
                break;
            case 'e':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「やはり一人欠けると厳しいか。。\n");
                win_msg.textout("　回復魔法の残りが気になる。 S.」\n");
                break;
            case 'f':
                win_msg.textout("グランドピアノが置いてある。\n");
                win_msg.textout("モンスターがピアノを・・・?\n");
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
                win_msg.textout("突然、目の前に黒い影が現れた!\n");
                win_msg.textout("「おや、珍しい。お客さんだ。」\n");
                getChar();
                monParty.add([ 99,86,86,86 ]); // vampire lordとvampire
                if ( battle_main() == BATTLE_RESULT.WON  )
                {
                    eventflg[ 0 ] = true;
                    party.theyGet( 102 ); // amulet of muomoe(makanito)
                }
                break;
            case 'b':
                win_msg.textout("ふわふわと風船のような物が漂っている。\n");
                win_msg.textout("特に何もしないようだ。\n");
                break;
            case 'c':
                win_msg.textout("ちろちろと水が流れている。\n");
                win_msg.textout("ひんやりとしたきれいな水だ。\n");
                break;
            case 'd':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「やべぇ。\n");
                win_msg.textout("　モンスターがかなり手強くなってきた。 S.」\n");
                break;
            case 'e':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「くそっ。\n");
                win_msg.textout("　なんだ、この部屋の数は!? S.」\n");
                break;
            case 'f':
                win_msg.textout("耳鳴りがする。圧迫されたダンジョンの\n");
                win_msg.textout("空気で、気が変になりそうだ。。\n");
                break;
            case 'g':
                win_msg.textout("冒険者とみられる死体が6体倒れている。\n");
                win_msg.textout("こうはなりたくないものだ。。。\n");
                break;
            case 'h':
                win_msg.textout("フランス人形が笑い声をたてている。\n");
                win_msg.textout("剣でまっぷたつに切ったら笑い声は止んだ。\n");
                break;
            case 'i':
                win_msg.textout("壁に大きな字で｢6｣と書いてある。\n");
                win_msg.textout("何かの意味があるのだろうか?\n");
                break;
            case 'j':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!回れ右をせよ」\n");
                break;
            case 'k':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!立ち止まるな」\n");
                break;
            case 'l':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!右に行け」\n");
                break;
            case 'm':
                win_msg.textout("たて看板がある:\n");
                win_msg.textout("「危険!南に行くな」\n");
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
                win_msg.textout("\n*** chute! ***\n");

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
                win_msg.textout("壁に大きな看板がかかっている。\n");
                win_msg.textout("「引き返せ!さもないと、」\n");
                win_msg.textout("その続きは汚れて読めない。\n");
                break;
            case 'c':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「地下1Fに似ているな。\n");
                win_msg.textout("　しかし、陰険な罠だらけのフロアだ。 S.」\n");
                break;
            case 'd':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「やべぇ。前衛の一人が倒れて、\n");
                win_msg.textout("　盗賊が前衛に立つことになった。 S.」\n");
                break;
            case 'e':
                if( eventflg[ 0 ] )
                    break;
                win_msg.textout("*** 異常な妖気が満ちている。\n  探しますか(y/n)? ");
                if ( answerYN == 'y' )
                {
                    win_msg.textout( "地鳴りがする。。。来るぞ!!!\n" );
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
                win_msg.textout( "\n*** jump to the castle! ***\n" );
                getChar();
                party.x = 1;
                party.y = 2;
                party.layer = 0;
                for ( int i = 0; i < party.num; i++ )
                    party.mem[ i ].outflag = OUT_F.CASTLE ; // in castle
                break;
            case 'c':
                win_msg.textout( "\n*** teleporter! ***\n" );
                party.x = 1;
                party.y = 2;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'd':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「俺は見た!\n");
                win_msg.textout("　50回攻撃し、最後には首を刎ねるという\n");
                win_msg.textout("　伝説の魔神を! S.」\n");
                break;
            case 'e':
                win_msg.textout("頭の中に声が響いた。\n");
                win_msg.textout("「お前たちは来てはいけない領域に迷い混んで\n");
                win_msg.textout("　しまった。引き返すがよい。今のうちに。。」\n");
                break;
            case 'f':
                win_msg.textout("壁にmessageが書かれている:\n");
                getChar();
                win_msg.textout("「俺たちはもうボロボロだ。\n");
                win_msg.textout("　最強のpurple beretがこんなにも簡単に\n");
                win_msg.textout("　やられるとは。。。。 S.」\n");
                getChar();
                win_msg.textout("その下に、白骨化した死体が転がっている。\n");
                break;
            case 'g':
                if( eventflg[ 0 ] )
                    break;
                win_msg.textout("頭の中に声が響いた。\n");
                win_msg.textout("「私の忠告を無視したようだな。\n");
                win_msg.textout("　あの世で後悔するがいい。。。」\n");
                break;
            case 'h':
                if( eventflg[ 1 ] )
                {
                    rtncode = 1;
                    break;
                }
                win_msg.textout( "一筋の風が吹いた。\n" );
                getChar();
                monParty.add( [ 91,91,91,91 ] ); // the_high_masters
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 1 ] = true;
                rtncode = 1;
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                win_msg.textout("頭の中に声が響いた。\n");
                win_msg.textout("「思ったよりやるようだ。\n");
                win_msg.textout("　楽しみになってきたよ。。。」\n");
                break;
            case 'j':
                if( eventflg[ 2 ] )
                {
                    rtncode = 1;
                    break;
                }
                win_msg.textout( "暗闇に雷が轟いた!!\n" );
                getChar();
                monParty.add( [ 102,97,87,68 ] ); // demon lord
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 2 ] = true;
                rtncode = 1;
                break;
            case 'k':
                if( eventflg[ 0 ] )
                    break;
                win_msg.textout("頭の中に声が響いた。\n");
                win_msg.textout("「ほほう。よかろう。\n");
                win_msg.textout("　来るがいい、私の元へ。。。」\n");
                break;
            case 'l':
                if( eventflg[ 0 ] )
                {
                    rtncode = 1;
                    break;
                }
                win_msg.textout( "長身の男が立ったまま瞑想している。\n" );
                getChar();
                monParty.add( [ 108,101,91,91 ] ); // DAEMON, petit_daemon

                if( battle_main == BATTLE_RESULT.WON )
                    eventflg[ 0 ] = true;

                rtncode = 1;
                break;
            case 'm':
                if ( party.doTheyHave(171) )
                    break;
                win_msg.textout( "一冊の本が落ちている。\n" );
                party.theyGet( 171 ); // diary
                break;
            default:
                break;
        }

        return rtncode;
    }
}

+/
