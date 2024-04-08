// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import def;
import app;

import clistmanager;

import cmonster_team;
import cmonster_def;
import cmonster;

import cparty;


class MonsterParty : ListManager!( MonsterParty , MonsterTeam )
{

    char treasure; /* treasure level */
    bool suprised;

    // MonsterTeam[] details;   // template
    // MonsterTeam top;         // template
    // MonsterTeam end;         // template

    this()
    {
        super( MAX_MONSTER_TEAM );
        return;
    }


    /*--------------------
       set encount monsters
       --------------------*/
    void setEncounterMonsters( int[] monsterDefNo )
    {

        assert( monsterDefNo.length <= 4 );

        MonsterDef mondef;
        MonsterTeam mt;

        reset;      // clistmanager.reset -> monster team all reset
        foreach( MonsterTeam mt_ ; details )
            mt_.initialize;     // monsterTeam.initialize -> monster.initialize

        assert( (  monsterDefNo.length  >= 1 &&  monsterDefNo.length <= 4  ) 
                , "err : count : " ~ to!string( monsterDefNo.length  ) );

        top = null;
        end = null;
        foreach( i , d ; monsterDefNo )
            generateMonsterTeam( monster_data[ d ] );

        return;
    }


    /*--------------------
       generateMonsterTeam - MonsterTeam 追加
       --------------------*/
    MonsterTeam generateMonsterTeam( MonsterDef df )
    {

        MonsterTeam mt;

        // get empty slot
        mt = add;
        if( mt is null )
            return null;

        mt.addParty( df );
        if( end is null )
        {
            // top
            top = mt;
            mt.previous = null;
            mt.next = null;
        }
        else
        {
            end.insertNext( mt );
        }
        end = mt;

        return mt;

    }


    /*--------------------
       def - モンスター定義取得（先頭）
       --------------------*/
    MonsterDef def()
    {
        return top.def;
    }


    /*--------------------
       ident - モンスター識別（先頭）
       --------------------*/
    bool ident()
    {
        return top.ident;
    }
    void ident( bool flg )
    {
        top.ident = flg;
        return;
    }


    /*--------------------
       getDispNameA - モンスター名称（先頭）（単数）
       --------------------*/
    string getDispNameA()
    {
        return top.getDispNameA;
    }


    /*--------------------
       getDispName - モンスター名称（先頭）（複数確認）
       --------------------*/
    string getDispNameS()
    {
        return top.getDispNameS;
    }


    /*--------------------
       getDispNameA - モンスター名称（指定）（単数）
       --------------------*/
    string getDispNameA( int target )
    {
        return getGroup( target ).getDispNameA;
    }


    /*--------------------
       getDispName - モンスター名称（指定）（複数確認）
       --------------------*/
    string getDispNameS( int target )
    {
        return getGroup( target ).getDispNameS;
    }


    /*--------------------
       updateIdentify - モンスター名識別チェック
       --------------------*/
    void updateIdentify()
    {
        foreach( MonsterTeam mt ; this )
            if ( ! mt.ident )
              mt.ident = ( get_rand( 1 ) == 0 );
        return;
    }


    /*--------------------
       disp - モンスター表示
       --------------------*/
    void disp()
    {
        int i, j;
        int actCount;
        Monster     mon;
        MonsterTeam monteam;

        monteam = top;
        actCount = 0;

        foreach( no , MonsterTeam mt ; this )
            txtMessage.textout( "%1)%2 %3 (%4)\n" 
                            , no + 1 
                            , mt.count 
                            , ( mt.ident ? "" : "?" ) ~  mt.getDispNameS 
                            , mt.actCount );
        return;
    }


    /*--------------------
       dispMonsterInfo - モンスター詳細表示
       --------------------*/
    void dispMonsterInfo()
    {
        MonsterDef   monDef;    // mdefp

        foreach( MonsterTeam mt ; this )
        {
            if ( ! mt.ident )
            { // unidentified
                txtMessage.textout( mt.def.unname );
                txtMessage.textout( _( ":\n  unidentified\n" ) );
            }
            else
            { // identified
                monDef = mt.def;
                txtMessage.textout( monDef.name ~ ":\n");
                txtMessage.textout( "  level:%1, ac:%2, hp:%3-%4\n" 
                        , monDef.level
                        , monDef.ac
                        , monDef.minhp
                        , monDef.minhp + monDef.addhp );
                if ( monDef.atkef != 0 )
                {
                    txtMessage.textout( _( "  special attacks:" ) );
                    if ( monDef.isAtkPoison )
                        txtMessage.textout( _( "poison " ) );
                    if ( monDef.isAtkStone )
                        txtMessage.textout( _( "stone " ) );
                    if ( monDef.isAtkParalize )
                        txtMessage.textout( _( "paralize " ) );
                    if ( monDef.isAtkSleep )
                        txtMessage.textout( _( "sleep " ) );
                    if ( monDef.isAtkCritical )
                        txtMessage.textout( _( "critical " ) );
                    if ( monDef.getAtkDrainLv > 0 )
                        txtMessage.textout( _( "drain" ) );
                    txtMessage.textout( "\n" );
                }
                foreach( a ; monDef.action )
                    if( a == MON_ACT.MGC )
                    {
                        txtMessage.textout( _( "  cast spells.\n" ) );
                        break;
                    }
                foreach( a ; monDef.action )
                    if( a == MON_ACT.BRT )
                    {
                        txtMessage.textout( _( "  exhales breath\n" ) );
                        string effect = "";
                        if ( monDef.isBreEfPoison )
                            effect ~= _( "poison " );
                        if ( monDef.isBreEfSleep )
                            effect ~= _( "sleep " );
                        if ( monDef.isBreEfParalize )
                           effect ~=  _( "paralize " );
                        if ( monDef.isBreEfStone )
                            effect ~= _( "stone " );
                        if ( monDef.isBreEfCritical )
                            effect ~= _( "critical " );
                        if ( monDef.getBreEfDrainLv > 0 )
                            effect ~= _( "drain" );

                        if( effect != "" )
                            txtMessage.textout( _( "  breath effect:%1" ) , effect );
                        break;
                    }
                if ( monDef.magdef !=0 )
                {
                    txtMessage.textout( _( "  resistance to spells:" ) );
                    txtMessage.textout( to!int( monDef.magdef ) )  ;
                    txtMessage.textout( "%\n" );
                }
            }
            getChar;
        }
        return;
    }


    /*--------------------
       selectGroup - グループ選択 ( 0 - 3 )
       --------------------*/
    MonsterTeam selectGroup( int row )
    {

        char c ;

        void delMsg()
        {
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55, "                       " );
        }

        if( count == 1 )
        {
            delMsg;
            return top;
        }
        
        mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55, _( "which group?           " ) );
        while ( true )
        {
            c = getChar();
            if ( c == '1' )
            {
                delMsg;
                return top;
            }

            if ( c == '2' && count >= 2 )
            {
                delMsg;
                return top.next;
            }

            if ( c == '3' && count >= 3 )
            {
                delMsg;
                return top.next.next;
            }

            if ( c == '4' && count >= 4 )
            {
                delMsg;
                return top.next.next.next;
            }
        }

    }


    /*--------------------
       getGroup - グループ取得 ( 0 - 3 )
       --------------------*/
    MonsterTeam getGroup( int target )
    {
        MonsterTeam mt = top;

        switch( target )
        {
            case 0:
                mt = top;
                break;
            case 1:
                mt = top.next;
                break;
            case 2:
                mt = top.next.next;
                break;
            case 3:
                mt = end;
                break;
            default:
                assert( 0 );
        }

        assert( mt !is null );
        return mt;

    }

    void debugList()
    {
        writeln("/+---------------");
        foreach( mt ; monParty )
        {
            writeln( "team: (" ~ mt.manager.count.to!string ~ ")" ~ mt.getDispNameA ~ "," ~ (mt.previous !is null).to!string ~ "/" ~ (mt.next !is null).to!string );
            foreach( Monster m ; mt.manager )
                writeln( "  monster: " ~ m.getDispNameA ~ "," ~ (m.previous !is null).to!string ~ "/" ~ (m.next !is null).to!string ~ " HP:" ~ m.hp.to!string ) ;
        }
        writeln("---------------+/");
    }


    // debug
    override void delDetail()
    {
        super.delDetail;
    }


}

