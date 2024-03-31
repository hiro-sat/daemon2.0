// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import app;
import def;

import cmember;
import cmonster;
import cmonster_team;


import clistmanager;
import cbattleturn;

/**
  Battle Turn Manager
  */
class BattleTurnManager
{

    ListManager!BattleTurn  list;
    // BattleTurn top;      // template
    // BattleTurn end;      // template

    BattleTurn top(){ return list.top; }
    BattleTurn end(){ return list.end; }
    void top( BattleTurn b ){ list.top = b; }
    void end( BattleTurn b ){ list.end = b; }


    this()
    {
        list = new ListManager!BattleTurn;
        list.initListDetails( 9 * 4 + 6 + 2 ); 
        foreach( bt ; list.details )
            bt.initialize( this );
        return ;
    }

    /*--------------------
       foreach -> BattleTurn を返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref BattleTurn ) operations )  
    {
        int result = 0;

        foreach( bt ; list )
            operations( bt );
        return result;
    }

    /*--------------------
       decideOrder - 戦闘時行動順設定
       --------------------*/
    void decideOrder()
    {
        BattleTurn  bt;
        BattleTurn  myturn;

        top = list.details[ 0 ];
        top.agi = 127; /* max */
        top.previous = null;
        top.next = null;

        end = list.details[ 1 ];         
        end.agi = 0;   /* min */
        top.insertNext( end );
      
        int index = 2;      // index 0 , 1 -> 2


        /* party member */
        if( ! party.suprised )
            foreach( p ; party )
                if ( p.status == STS.OK )
                {
                    myturn = list.details[ index ++ ].setActor( p , p.agi[ 0 ] + p.agi[ 1 ] + get_rand( 4 ) );
                    
                    bt = top;
                    while( true )
                    {
                        assert( bt !is null );
                        if( bt.agi > myturn.agi )
                        {
                            bt = bt.next;
                            continue;
                        }
                        bt.insertBefore( myturn );
                        break;
                    }
                    // 上記処理を、下記foreachで処理しようとしたが、動かず...
                    // foreach( opApply )中のdelegateで使用しているクラスを
                    // 編集しているのがわるい？
                    /+
                    foreach( bt ; this )
                    {
                        assert( bt !is null , "bt is null" );
                        if( bt.agi > myturn.agi )
                            continue;
                        bt.insertBefore( myturn );
                        break;
                    }
                    +/
                }

        /* monster */
        if( ! monParty.suprised )
            foreach( MonsterTeam mt ; monParty )
                foreach( Monster m ; mt )
                {
                    myturn = list.details[ index ++ ].setActor( m , m.def.agi + get_rand( 4 ) );

                    bt = top;
                    while( true )
                    {
                        if( bt.agi > myturn.agi )
                        {
                            bt = bt.next;
                            continue;
                        }
                        bt.insertBefore( myturn );
                        break;
                    }
                }

        return ;
    }


    bool isEnd( BattleTurn bt )
    {
        if( bt is end )
            return true;
        return false;
    }

}
