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
class BattleTurnManager : ListManager!( BattleTurnManager , BattleTurn )
{

    // BattleTurn[] details;    // template
    // BattleTurn top;          // template
    // BattleTurn end;          // template

    this( int length )
    {
        super( length );
        return;
    }

    override void reset()
    {
        foreach( MonsterTeam mt ; monParty )
            foreach( Monster m ; mt.manager )
                m.turn = null;

        foreach( BattleTurn bt ; details )
        {
            bt.agi = 0;
            bt.member = null;
            bt.monster = null;
        }
        super.reset;
        return;
    }

    /*--------------------
       decideOrder - 戦闘時行動順設定
       --------------------*/
    void decideOrder()
    {
        BattleTurn  bt;
        BattleTurn  myturn;

        reset;

        // top
        top = add;   
        top.agi = 127; /* max */
        top.previous = null;
        top.next = null;

        // end
        end = add;
        end.agi = 0;   /* min */
        top.insertNext( end );
      
        /* party member */
        if( ! party.suprised )
            foreach( p ; party )
                if ( p.status == STS.OK )
                {
                    myturn = add;
                    myturn.setActor( p , p.agi[ 0 ] + p.agi[ 1 ] + get_rand( 4 ) );
                    
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
                foreach( Monster m ; mt.manager )
                {
                    myturn = add;
                    myturn.setActor( m , m.def.agi + get_rand( 4 ) );

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


    void debugList()
    {
        int i;
        BattleTurn bt;

        writeln("/+---------------");
        i = 0 ;
        bt = top;
        while( bt !is null )
        {
            i++;
            if( bt.member !is null )
                writeln( i.to!string ~ ":" ~ bt.member.name ~ "," ~ (bt.previous !is null).to!string ~ "/" ~ (bt.next !is null).to!string ~ " / " ~ bt.agi.to!string );
            else if( bt.monster !is null )
                writeln( i.to!string ~ ":" ~ bt.monster.getDispNameA ~ "," ~ (bt.previous !is null).to!string ~ "/" ~ (bt.next !is null).to!string ~ " / " ~ bt.agi.to!string );
            else if( bt is top )
                writeln( i.to!string ~ ": top ," ~ (bt.previous !is null).to!string ~ "/" ~ (bt.next !is null).to!string ~ " / " ~ bt.agi.to!string );
            else if( bt is end ) 
                writeln( i.to!string ~ ": end ," ~ (bt.previous !is null).to!string ~ "/" ~ (bt.next !is null).to!string ~ " / " ~ bt.agi.to!string );
            bt = bt.next;
        }
        writeln("---------------+/");
    }

}
