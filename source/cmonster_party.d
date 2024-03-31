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


class MonsterParty
{

    ListManager!MonsterTeam list;

    char treasure; /* treasure level */
    bool suprised;


    void top( MonsterTeam mt ){ list.top = mt ; }
    void end( MonsterTeam mt ){ list.end = mt ; }
    MonsterTeam top(){ return list.top; }
    MonsterTeam end(){ return list.end; }

    this()
    {
        list = new ListManager!MonsterTeam;
        list.initListDetails( MAX_MONSTER_TEAM ); 
        return;
    }


    /*--------------------
       foreach -> MonsterTeam を返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref MonsterTeam ) operations )  
    {

        int result = 0;

        foreach( mt ; list )
            operations( mt );
        return result;
    }
    int opApply( int delegate( ref size_t ,
                               ref MonsterTeam ) operations )  
    {

        int result = 0;

        foreach( i , mt ; list )
            operations( i , mt );
        return result;
    }



    /*--------------------
       encounter
       --------------------*/
    void encounter( int[] monsterDefNo )
    {

        assert( monsterDefNo.length <= 4 );

        MonsterDef mondef;
        MonsterTeam mt;
        MonsterTeam prev;

        int moncount , sum;

        foreach( MonsterTeam mt_ ; list )
            mt_.initialize;

        assert( (  monsterDefNo.length  >= 1 &&  monsterDefNo.length <= 4  ) 
                , "err : count : " ~ to!string( monsterDefNo.length  ) );

        top = list.details[ 0 ];

        prev = null;
        foreach( i , d ; monsterDefNo )
        {
            mt = list.details[ i ];
            mt.partyAdd( monster_data[ d ] );

            if( prev is null ) 
            {
                // top
                mt.previous = null;
                mt.next = null;
            }
            else
            {
                prev.insertNext( mt );
            }

            end = mt;
            prev = mt;

        }

        return;
    }


    /*--------------------
       count - 登録モンスターチーム数
       --------------------*/
    int count()
    {
        int n = 0;
        foreach( MonsterTeam mt ; list )
            n ++ ;
        return n;
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
        foreach( MonsterTeam mt ; list )
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

        foreach( no , MonsterTeam mt ; list )
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

        foreach( MonsterTeam mt ; list )
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
}

