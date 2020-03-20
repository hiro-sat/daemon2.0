
// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;

// mysource 
import cParty;
import cMember;
import cMonsterParty;

import def;
import app;
import battle;
import dungeon;

/* import lib_sdl; */

abstract class Event
{
    // virtual
    abstract int getEncounterMonster();

    bool[ 50 ] eventflg;

    this()
    {
        resetFlg;
        return;
    }

    void resetFlg()
    {
        for( int i = 0 ; i < 20 ; i++ )
            eventflg = false;
        return;
    }

    // (super) override  event_chk
    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int event_chk( char m ) 
    {
        switch( m )
        {
            /+  階段のチェックはイベントで行わない
            case '>':
                return downStairs;
            case '<':
                return upStairs;
            +/
            case '_':
                return pit;
            default:
                break;
        }
        return 0;        
    }

    // ret : 2: exit from maze , 1:not encount , defalut: encount check
    int upStairs( char m )
    {
        if( m != '<' )
        {
            textout( _( "what?\n" ) );
            return 0;
        }

        textout( _( "\n*** up stairs ***\n" ) );
        textout( _( "go up(y/n)? " ) );

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
            textout( _( "what?\n" ) );
            return 0;
        }

        textout( _( "\n*** down stairs ***\n" ) );
        textout( _( "go down(y/n)? " ) );

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
            textout( _( "a pit, but floating.\n" ) );
            return 0;
        }

        // pit!
        textout( _( "\n*** a pit! ***\n\n" ) );
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
        textout( _( "\n*** your party is lost...\n<push space bar(5)>\n" ) );

        while ( true )
        {
            c = getChar();
            if ( c == ' ' || c == '5' )
                break;
        }

        return 2;
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
                textout( _( "  each survivor gets %1 gp.\n" ) , getgold );
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status  == STS.OK )
                        party.mem[ i ].gold += getgold;
                }
            }
        }

        return bt_result;
    }
}


/*====== event L1 ===================================================*/
class EventL1 : Event
{

    override int getEncounterMonster()
    {
        if ( get_rand( 3 ) != 0 )
            return get_rand( 3 );
        else
            return get_rand( 5 );
    }

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
                textout( "*** Welcome to the Dungeon of Daemon ***\n" );
                textout( "    Copyright by K.Achiwa, 1996,2002.\n" );
                textout( "                 All Rights Reserved.\n" );
                textout( "****************************************\n" );
                break;
            case 'B':
                textout( "壁にmessageが書かれている:\n" );
                textout( "「ここでsearch('s')してみな。\n" );
                textout( "　。。うわ、俺ってやさしいぜ！ S.」\n" );
                break;
            case 'c':
                textout( "ムッとするような湿気で満たされている部屋だ。\n" );
                break;
            case 'C':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「おまえら初心者だな。悪いことは言わねえ。\n" );
                textout( "　痛い目に遭わない内に引き返すこった。 S.」\n" );
                break;
            case 'D':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「うーむ。。。\n" );
                textout( "　戻る気は無いってことか。。。 S.」\n" );
                break;
            case 'e':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「しかし残念だったな。お宝は残ってないぜ。\n" );
                textout( "　俺たちflorin公国の精鋭部隊purple beretが\n" );
                textout( "　お先にいただいちまってる筈さ! S.」\n" );
                break;
            case 'f':
                textout( "壁にメッセージが書かれている:\n" );
                textout( "「この先にdarkzoneがあるぜ。 S.」\n" );
                break;
            case 'g':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「flip!! flip!! flipしてるか?\n" );
                textout( "　冒険には何よりflipが大切さ! S.」\n" );
                break;
            case 'h':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「Howdy! 調子はどうだい?\n" );
                textout( "　そろそろお家に帰りたくなってきたろ? S.」\n" );
                break;
            case 'i':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「この中には強いモンスターがいるぜ。 S.」\n" );
                break;
            case 'j':
                textout( "*** 異常な妖気が満ちている。\n  探しますか(y/n)? " );
                if ( answerYN == 'y')
                {
                    monParty.add( [ 77 ] );
                    battle_main();
                }
                rtncode = 1;
                break;
            case 'k':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「おい、何だかおかしいぜ?\n" );
                textout( "　ここのモンスターは普通じゃない。\n" );
                textout( "　何らかの力で強化されてるみたいだ S.」\n" );
                break;
            case 'l':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「いやー、無駄に広い部屋だ。。 S.」\n" );
                break;
            case 'm':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「。。。メンバーには内緒だけどな、\n" );
                textout( "　モンスターを倒して宝を取ってこい、\n" );
                textout( "　なんてミッションには裏がありそうだ。\n" );
                textout( "　。。。。。\n" );
                getChar();
                textout( "　ここには何かある。\n" );
                textout( "　俺の直感がそう言っているぜ。 S.」\n" );
                break;
            case 'n':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「ここまで来たか。\n　おまえらなかなかやるな S.」\n" );
                break;
            case 'o':
                textout( "どこか遠くの部屋でガタガタと物音が聞こえてくる。 \n" );
                getChar();
                break;


            case 'p':
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '3':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '4':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '5':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '6':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '7':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
                textout( "この部屋は異様な妖気で満たされている。\n" );
                break;
            case '8':
                textout("突然、目もくらむほど強烈な光につつまれた！\n");
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
    override int getEncounterMonster()
    {
        return 6 + get_rand(8);
    }

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
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「悪いことは言わない。\n　とりあえず北からにしろ S.」\n");
                break;
            case 'b':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「bishopのCynthiaも何か気づいてるみてぇだ\n");
                textout("　dispelのかかりが悪いと言ってる。 S.」\n");
                break;
            case 'c':
                textout("*** ここはかつて宝物庫であったらしい。\n");
                textout("    しかし、荒らされて貴重な物は何も\n    残っていないようだ。\n");
                break;
            case 'd':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「へへへ。いただき! S.」\n");
                break;
            case 'e':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「ここ、コーヒーの臭いがしねぇか? S.」\n");
                textout("探しますか(y/n)? ");
                if( answerYN == 'y' && ! eventflg[ 0 ] )
                {
                    eventflg[ 0 ] = true;
                    monParty.add( [ 12,12,12,12 ] );
                    if ( battle_main == BATTLE_RESULT.WON )
                        party.theyGet( 19 );
                }
                else
                {
                  textout("気のせいだったようだ。\n");
                }
                break;
            case 'f':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「vorpal_toothは持ったかい? S.」\n");
                break;
            case 'g':
                if ( ! party.doTheyHave( 170 ) )
                {
                    textout("*** 頭の中で声が響いた:\n");
                    getChar();
                    textout("「お前達にはここに来る資格が無い!」\n");
                    party.y -= 2;
                    party.oy -= 2;
                }
                break;
            case 'h':
                textout("*** なんだかウサギ臭い。。。。\n");
                textout("探しますか(y/n)? ");
                if ( answerYN == 'y' && !eventflg[ 1 ] )
                {
                    eventflg[ 1 ] = true;
                    monParty.add( [ 14,14,14,14 ] );
                    if ( battle_main() == BATTLE_RESULT.WON )
                        party.theyGet( 170 ); // vorpal_toth, 3Fへの階段のキーアイテム
                }
                else
                {
                  textout("気のせいだったようだ。\n");
                }
                break;
            case 'i':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「darkzoneってのは歩きにくいよな。\n");
                textout("　shineとmapperを唱えておけよ。 S.」\n");
                break;
            case 'j':
                textout("*** ひんやりとした冷気が漂っている\n");
                textout("    ここはかつて冷暗所だったのだろうか。\n");
                break;
            case 'k':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「floatを覚えてりゃpitは怖く\n　ないんだが。 S.」\n");
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
    override int getEncounterMonster()
    {
        return 15 + get_rand(14);
    }

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
                textout("たて看板がある:\n");
                textout("「危険!南に行くな」\n");
                break;
            case 'b':
                textout("たて看板がある:\n");
                textout("「危険!北に行くな」\n");
                break;
            case 'c':
                textout("たて看板がある:\n");
                textout("「右を向け」\n");
                break;
            case 'd':
                textout("たて看板がある:\n");
                textout("「左を向け」\n");
                break;
            case 'e':
                textout("焚き火をした跡がある。\n");
                textout("まだ暖かい。他の冒険者達が\n");
                textout("キャンプを張っていたのだろうか。\n");
                break;
            case 'f':
                textout("息苦しい空気の立ち込めた部屋だ。\n");
                textout("足元には赤みがかった苔がむしている。\n");
                break;
            case 'g':
                textout("壁に小さな人影が焼きついている。\n");
                textout("おそらくfireかflamesで焼かれた\n");
                textout("モンスターであろう。\n");
                break;
            case 'h':
                textout("真っ暗な部屋の一部の壁が\n");
                textout("ぼうっと青白く光っている。\n");
                break;
            case 'i':
                textout("壁の向こうをガシャガシャと、数名の冒険者\n");
                textout("(モンスターか?)が通る音が聞こえた。\n");
                break;
            case 'j':
                textout("何体かのモンスターの死体が横たわってる。\n");
                textout("一体はまっぷたつに切り裂かれ、別の一体は\n");
                textout("上半身が黒こげだ。その横に、蓋の開いた宝箱\n");
                textout("がある。中には何も残っていないようだ。\n");
                break;
            case 'k':
                textout("暗闇の中に、ぶきみな二つの目が光った。\n");
                textout("それは君たちに襲い掛かってくることもなく、\n");
                textout("数秒して消えてしまった。\n");
                break;
            case 'l':
                textout("突然けたたましい音が鳴り響いた!\n");
                textout("が、その音に集まってくるモンスターは\n");
                textout("いなかった。\n");
                break;
            case 'm':
                textout("ビュン! 目の前を何本かの矢が風きり音を\n");
                textout("たてて横切った。。トラップだ! しかし、\n");
                textout("作動が少し早すぎたようだ。\n");
                break;
            case 'n':
                textout("床が動いている!\n");
                textout("と思ったら、それは大量のゴキブリだった。\n");
                break;
            case 'o':
                textout("邪悪な気配に満ちた部屋だ。\n");
                break;
            case 'p':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「このダンジョンのヌシは相当あぶねぇ\n");
                textout("　奴のようだ。こんなに上層にwerebearが\n");
                textout("　うろついているとは。 S.」\n");
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
    override int getEncounterMonster()
    {
        return 20 + get_rand(19);
    }

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
                textout("焼け付くように熱い部屋だ。\n");
                textout("何者かがflamoeでも使ったあとか?\n");
                break;
            case 'b':
                textout("バナナの皮が落ちている。\n");
                textout("それで滑って転んだ時にちょうど頭が\n");
                textout("来る位置に、硬そうな石が置いてある。\n");
                textout("・・・罠だ!\n");
                break;
            case 'c':
                textout("首のない死体が3体横たわっている。\n");
                textout("忍者に殺された冒険者か?\n");
                break;
            case 'd':
                textout("操り人形が落ちている。\n");
                textout("どうやら生きているらしいが、糸がからまって\n");
                textout("身動きができないようだ。\n");
                break;
            case 'e':
                textout("壊れた機械らしきものが置いてある。\n");
                textout("蹴ってみたが反応は無かった。\n");
                break;
            case 'f':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「しくじった!\n");
                textout("　Cynthiaの奴が呪いのメイスに取り付かれ\n");
                textout("　ちまった。進むべきか、いったん引き上げ\n");
                textout("　るか。。。 S.」\n");
                break;
            case 'h':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「まいった。。。\n");
                textout("　Cynthiaの奴、ショック状態から回復しねぇ。\n");
                textout("　ここでは呪いが強くなっているのか。。 S.」\n");
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                textout("突然、目の前に黒い影が現れた!\n");
                textout("「グルルル・・・ガガガッ」\n");
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
    override int getEncounterMonster()
    {
        return 30 + get_rand(24);
    }

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
                textout("このフロアは壁が磨き上げられた大理石で\n");
                textout("できているようだ。カツカツと足音が響く。\n");
                break;
            case 'b':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「Cynthiaを宿屋に預けてきた。\n");
                textout("　ずいぶんと時間をロスしちまったぜ。 S.」\n");
                break;
            case 'c':
                textout("!! モンスターが!\n");
                textout("・・と思ったら、壁に映った自分たちだった。\n");
                break;
            case 'd':
                textout("ポロンポロン、とピアノを弾く音が聞こえて\n");
                textout("くる。なぜこのようなダンジョンにピアノが??\n");
                break;
            case 'e':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「やはり一人欠けると厳しいか。。\n");
                textout("　回復魔法の残りが気になる。 S.」\n");
                break;
            case 'f':
                textout("グランドピアノが置いてある。\n");
                textout("モンスターがピアノを・・・?\n");
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
    override int getEncounterMonster()
    {
        return 40 + get_rand(39);
    }

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
                textout("突然、目の前に黒い影が現れた!\n");
                textout("「おや、珍しい。お客さんだ。」\n");
                getChar();
                monParty.add([ 99,86,86,86 ]); // vampire lordとvampire
                if ( battle_main() == BATTLE_RESULT.WON  )
                {
                    eventflg[ 0 ] = true;
                    party.theyGet( 102 ); // amulet of muomoe(makanito)
                }
                break;
            case 'b':
                textout("ふわふわと風船のような物が漂っている。\n");
                textout("特に何もしないようだ。\n");
                break;
            case 'c':
                textout("ちろちろと水が流れている。\n");
                textout("ひんやりとしたきれいな水だ。\n");
                break;
            case 'd':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「やべぇ。\n");
                textout("　モンスターがかなり手強くなってきた。 S.」\n");
                break;
            case 'e':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「くそっ。\n");
                textout("　なんだ、この部屋の数は!? S.」\n");
                break;
            case 'f':
                textout("耳鳴りがする。圧迫されたダンジョンの\n");
                textout("空気で、気が変になりそうだ。。\n");
                break;
            case 'g':
                textout("冒険者とみられる死体が6体倒れている。\n");
                textout("こうはなりたくないものだ。。。\n");
                break;
            case 'h':
                textout("フランス人形が笑い声をたてている。\n");
                textout("剣でまっぷたつに切ったら笑い声は止んだ。\n");
                break;
            case 'i':
                textout("壁に大きな字で｢6｣と書いてある。\n");
                textout("何かの意味があるのだろうか?\n");
                break;
            case 'j':
                textout("たて看板がある:\n");
                textout("「危険!回れ右をせよ」\n");
                break;
            case 'k':
                textout("たて看板がある:\n");
                textout("「危険!立ち止まるな」\n");
                break;
            case 'l':
                textout("たて看板がある:\n");
                textout("「危険!右に行け」\n");
                break;
            case 'm':
                textout("たて看板がある:\n");
                textout("「危険!南に行くな」\n");
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
    override int getEncounterMonster()
    {
        return 55 + get_rand(34);
    }

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
                textout("\n*** chute! ***\n");

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
                textout("壁に大きな看板がかかっている。\n");
                textout("「引き返せ!さもないと、」\n");
                textout("その続きは汚れて読めない。\n");
                break;
            case 'c':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「地下1Fに似ているな。\n");
                textout("　しかし、陰険な罠だらけのフロアだ。 S.」\n");
                break;
            case 'd':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「やべぇ。前衛の一人が倒れて、\n");
                textout("　盗賊が前衛に立つことになった。 S.」\n");
                break;
            case 'e':
                if( eventflg[ 0 ] )
                    break;
                textout("*** 異常な妖気が満ちている。\n  探しますか(y/n)? ");
                if ( answerYN == 'y' )
                {
                    textout( "地鳴りがする。。。来るぞ!!!\n" );
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
    override int getEncounterMonster()
    {
        if ( get_rand( 9 ) != 0 )
            return 70 + get_rand(28); // maelificまで
        else
            return 70 + get_rand(37);
    }

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
                textout( "\n*** jump to the castle! ***\n" );
                getChar();
                party.x = 1;
                party.y = 2;
                party.layer = 0;
                for ( int i = 0; i < party.num; i++ )
                    party.mem[ i ].outflag = OUT_F.CASTLE ; // in castle
                break;
            case 'c':
                textout( "\n*** teleporter! ***\n" );
                party.x = 1;
                party.y = 2;
                party.dungeon.initDisp;
                party.dungeon.disp;
                header_disp( HSTS.DUNGEON );
                rtncode = 1;
                break;
            case 'd':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「俺は見た!\n");
                textout("　50回攻撃し、最後には首を刎ねるという\n");
                textout("　伝説の魔神を! S.」\n");
                break;
            case 'e':
                textout("頭の中に声が響いた。\n");
                textout("「お前たちは来てはいけない領域に迷い混んで\n");
                textout("　しまった。引き返すがよい。今のうちに。。」\n");
                break;
            case 'f':
                textout("壁にmessageが書かれている:\n");
                getChar();
                textout("「俺たちはもうボロボロだ。\n");
                textout("　最強のpurple beretがこんなにも簡単に\n");
                textout("　やられるとは。。。。 S.」\n");
                getChar();
                textout("その下に、白骨化した死体が転がっている。\n");
                break;
            case 'g':
                if( eventflg[ 0 ] )
                    break;
                textout("頭の中に声が響いた。\n");
                textout("「私の忠告を無視したようだな。\n");
                textout("　あの世で後悔するがいい。。。」\n");
                break;
            case 'h':
                if( eventflg[ 1 ] )
                {
                    rtncode = 1;
                    break;
                }
                textout( "一筋の風が吹いた。\n" );
                getChar();
                monParty.add( [ 91,91,91,91 ] ); // the_high_masters
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 1 ] = true;
                rtncode = 1;
                break;
            case 'i':
                if( eventflg[ 0 ] )
                    break;
                textout("頭の中に声が響いた。\n");
                textout("「思ったよりやるようだ。\n");
                textout("　楽しみになってきたよ。。。」\n");
                break;
            case 'j':
                if( eventflg[ 2 ] )
                {
                    rtncode = 1;
                    break;
                }
                textout( "暗闇に雷が轟いた!!\n" );
                getChar();
                monParty.add( [ 102,97,87,68 ] ); // demon lord
                if ( battle_main() == BATTLE_RESULT.WON )
                    eventflg[ 2 ] = true;
                rtncode = 1;
                break;
            case 'k':
                if( eventflg[ 0 ] )
                    break;
                textout("頭の中に声が響いた。\n");
                textout("「ほほう。よかろう。\n");
                textout("　来るがいい、私の元へ。。。」\n");
                break;
            case 'l':
                if( eventflg[ 0 ] )
                {
                    rtncode = 1;
                    break;
                }
                textout( "長身の男が立ったまま瞑想している。\n" );
                getChar();
                monParty.add( [ 108,101,91,91 ] ); // DAEMON, petit_daemon

                if( battle_main == BATTLE_RESULT.WON )
                    eventflg[ 0 ] = true;

                rtncode = 1;
                break;
            case 'm':
                if ( party.doTheyHave(171) )
                    break;
                textout( "一冊の本が落ちている。\n" );
                party.theyGet( 171 ); // diary
                break;
            default:
                break;
        }

        return rtncode;
    }
}

