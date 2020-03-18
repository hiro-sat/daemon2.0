// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import def;
import app;

import cMonsterTeam;
import cMonsterDef;
import cMonster;

import cParty;


class MonsterParty
{
    char treasure; /* treasure level */
    int num;
    MonsterTeam top;
    MonsterTeam end;

    bool suprised;


    /*--------------------
       add - Encounter
       --------------------*/
    void add( int[] mdef )
    {

        assert( mdef.length <= 4 );

        /* int[ 4 ] mdef; */
        MonsterDef mondef;
        int i, j;
        int moncount , sum;

        for ( i = 0; i < 4 * 9; i++ )
            monster[ i ].def = null;
      
        num = to!int( mdef.length );
        assert( ( num >= 1 && num <= 4  ) , "err : tnum : " ~ to!string( num ) );

        top = monTeam[ 0 ];
        end = monTeam[ num - 1 ];
      
        sum = 0;
        for ( j = 0; j < num; j++ )
        {
            mondef = monster_data[ mdef[ j ] ];

            moncount = mondef.minnum + get_rand( mondef.addnum );
            monTeam[ j ].num = moncount;
            monTeam[ j ].top = monster[ sum ];

            monTeam[ j ].ident = party.isIdentify;  // latumapic invalid?

            if ( j == 0 )
                monTeam[ j ].previous = null;
            else
                monTeam[ j ].previous = monTeam[ j - 1 ];

            if ( j < num - 1 )
                monTeam[ j ].next = monTeam[ j + 1 ];
            else
                monTeam[ j ].next = null;
      
            for ( i = 0; i < moncount; i++ )
            {
                monster[ sum + i ].team     = monTeam[ j ];
                monster[ sum + i ].def      = mondef;

                /* monster[ sum + i ].maxhp    = mondef.minhp + mondef.addhp;  // get_rand?? */
                monster[ sum + i ].maxhp    = mondef.minhp + get_rand( mondef.addhp );  // get_rand??
                monster[ sum + i ].hp       = monster[ sum + i ].maxhp;

                monster[ sum + i ].status   = 0;
                monster[ sum + i ].silenced = false;
                monster[ sum + i ].acplus   = 0;

                if ( i == 0 )
                    monster[ sum + i ].previous = null;
                else
                    monster[ sum + i ].previous = monster[ sum + i - 1 ];

                if ( i < moncount - 1 )
                    monster[ sum + i ].next = monster[ sum + i + 1 ];
                else
                    monster[ sum + i ].next = null;
            }
            sum += moncount;
        }
        return;

    }


    /*--------------------
       def - モンスター定義取得（先頭）
       --------------------*/
    MonsterDef def()
    {
        return top.top.def;
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
        for ( int i = 0; i < num; i++ )
            if ( ! monTeam[ i ].ident )
              monTeam[ i ].ident = ( get_rand( 1 ) == 0 );
        return;
    }

    /*--------------------
       disp - モンスター表示
       --------------------*/
    void disp()
    {
        int i, j;
        int actnum;
        Monster     mon;
        MonsterTeam monteam;

        monteam = top;
        actnum = 0;

        for ( i = 0; i < num; i++ )
        {
            mon = monteam.top;
            for (j = 0; j < monteam.num; j++)
            {
                if ( mon.status == 0 )
                    actnum ++;
                mon = mon.next;
            }
            monteam.actnum = actnum;

            actnum = 0;
            textout( i + 1 );
            textout( ") " );
            textout( monteam.num );
            textout(" ");

            if( monteam.ident )
                textout( monteam.getDispNameS );
            else
                textout( "?" ~ monteam.getDispNameS );


            textout( " (" );
            textout( monteam.actnum );
            textout( ")\n" );
            monteam = monteam.next;
        }
        return;
    }

    /*--------------------
       dispMonsterInfo - モンスター詳細表示
       --------------------*/
    void dispMonsterInfo()
    {

        MonsterTeam  monteam;
        MonsterDef   mondef;    // mdefp

        monteam = top;
        mondef = null;

        while ( monteam !is null )
        {
            if ( monteam.ident )
            { // identified
                if ( monteam.top.def == mondef )
                {
                    monteam = monteam.next;
                    continue;
                }
                mondef = monteam.top.def;
                textout( mondef.name );
                textout( ":\n  level:" );
                textout( mondef.level );
                textout( ", ac:" );
                textout( mondef.ac );
                textout( ", hp:" );
                textout( mondef.minhp );
                textout( "-" );
                textout( mondef.minhp + mondef.addhp );
                textout( "\n" );
                if ( mondef.atkef != 0 )
                {
                    textout( _( "  special attacks:" ) );
                    if ( mondef.isAtkPoison )
                        textout( _( "poison " ) );
                    if ( mondef.isAtkStone )
                        textout( _( "stone " ) );
                    if ( mondef.isAtkParalize )
                        textout( _( "paralize " ) );
                    if ( mondef.isAtkSleep )
                        textout( _( "sleep " ) );
                    if ( mondef.isAtkCritical )
                        textout( _( "critical " ) );
                    if ( mondef.getAtkDrainLv > 0 )
                        textout( _( "drain" ) );
                    textout( "\n" );
                }
                if ( mondef.magdef !=0 )
                {
                    textout( _( "  resistance to spells:" ) );
                    textout( to!int( mondef.magdef ) )  ;
                    textout( "%\n" );
                }
            }
            else
            { // unidentified
              textout( monteam.top.def.unname );
              textout( _( ":\n  unidentified\n" ) );
            }
            monteam = monteam.next;
        }
        return;
    }


    /*--------------------
       selectGroup - グループ選択 ( 0 - 3 )
       --------------------*/
    int selectGroup( int row )
    {

        char c ;

        void delMsg()
        {
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55, "                       " );
        }

        if( num == 1 )
        {
            delMsg;
            return 0;
        }
        
        mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55, _( "which group?           " ) );
        while ( true )
        {
            c = getChar();
            if ( c == '1' )
            {
                delMsg;
                return 0;
            }

            if ( c == '2' && num >= 2 )
            {
                delMsg;
                return 1;
            }

            if ( c == '3' && num >= 3 )
            {
                delMsg;
                return 2;
            }

            if ( c == '4' && num >= 4 )
            {
                delMsg;
                return 3;
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

