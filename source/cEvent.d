
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
    int event_chk( char m ) 
    {
        switch( m )
        {
            case '>':
                return downStairs;
            case '<':
                return upStairs;
            default:
                break;
        }
        return 0;        
    }

    int upStairs()
    {
        textout( "\n*** up stairs ***\n" );
        textout( "go up(y/n)? " );

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
        }
        return 1;
    }

    int downStairs()
    {
        textout( "\n*** down stairs ***\n" );
        textout( "go down(y/n)? " );

        if ( answerYN == 'y')
        {
            party.layer++;
            party.setDungeon;
            party.dungeon.setStartPos;
            party.dungeon.initDisp;
            party.dungeon.disp;
            header_disp( HSTS.DUNGEON );
        }
        return 1;
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

        BATTLE_RESULT rtncode;
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

        // rtncode = 1 : won
        //           2 : ran
        //           3 : lost
        rtncode = battle_main();

        if ( rtncode == BATTLE_RESULT.WON )
        { /* won */
            if ( tre == TRE.TREASURE )
            {
                treasure_main( mon[ 0 ] );
            }
            else if ( tre == TRE.GOLD )
            {
                getgold = monster_data[ mon[ 0 ] ].mingp 
                        + get_rand( monster_data[ mon[ 0 ] ].addgp );
                getgold /= party.num;
                textout( "  each survivor gets " ~ to!string( getgold ) ~ " gp.\n" );
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status  == STS.OK )
                        party.mem[ i ].gold += getgold;
                }
            }
        }

        for ( i = 0; i < party.num; i++ )
            if ( party.mem[ i ].status < STS.PARALY )
                break;

        if ( i == party.num  )
        {
            party.win_disp();
            party.num = 0;
            party.layer = 0;
            textout( "\n*** your party is lost...<push space bar>\n" );
            while ( true )
            {
                c = getChar();
                if ( c == ' ' || c == '5' )
                    break;
            }
        }
        return rtncode;
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
                textout( "*** Welcome to the Dungeon of Daemon ***\n" );
                textout( "    Copyright by K.Achiwa, 1996,2002.\n" );
                textout( "                 All Rights Reserved.\n" );
                textout( "****************************************\n" );
                getChar();
                break;
            case 'b':
                textout( "壁にmessageが書かれている:\n" );
                textout( "「ここでsearch('s')してみな。\n" );
                textout( "　。。うわ、俺ってやさしいぜ！ S.」\n" );
                break;
            case 'c':
                textout( "壁にメッセージが書かれている:\n" );
                getChar();
                textout( "「おまえら初心者だな。悪いことは言わねえ。\n" );
                textout( "　痛い目に遭わない内に引き返すこった。 S.」\n" );
                break;
            case 'd':
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
            case 'p':
                textout( "どこか遠くの部屋でガタガタと物音が聞こえてくる。 \n" );
                getChar();
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
                if ( answerYN == 'y' )
                {
                    monParty.add( [ 14,14,14,14 ] );
                    if ( battle_main() == BATTLE_RESULT.WON )
                        party.theyGet( 170 ); // vorpal_toth, 3Fへの階段のキーアイテム
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
                textout("上半身が黒こげだ。その横に、蓋の開いた宝箱が\n");
                textout("ある。中には何も残っていないようだ。\n");
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
                getchar();
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

    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

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

    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

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

    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

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

    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

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

    override int event_chk( char m )
    {
        int rtncode = 0;
      
        // 階段チェック
        rtncode = super.event_chk( m );
        if( rtncode != 0 )
            return rtncode;

        return rtncode;
    }
}

