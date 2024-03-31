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

import cbattleturnmanager;
import clistdetail;

/**
  Battle Turn
  */
class BattleTurn
{
private:
    char kind; /* 0:player, 1:monster */
    BattleTurnManager parent;

    ListDetails!BattleTurn  listDetails;

public:

    int no;

    BattleTurn next()     { return listDetails.next; }
    BattleTurn previous() { return listDetails.previous; }
    void next( BattleTurn bt )     { listDetails.next     = bt; }
    void previous( BattleTurn bt ) { listDetails.previous = bt; }

    void insertNext( BattleTurn bt )   { listDetails.insertNext  ( this , bt ); }
    void insertBefore( BattleTurn bt ) { listDetails.insertBefore( this , bt ); }


    void initialize( BattleTurnManager manager )
    {
        listDetails = new ListDetails!BattleTurn;
        parent = manager;
        return;
    }

    bool isPlayer()
    {
        return (kind == 0);
    }

    bool isMonster()
    {
        return (kind == 1);
    }

    @property
    {
        BattleTurn setActor( Member p , int a )
        {
            kind = 0;
            member = p;
            agi = a;
            return this;
        }

        BattleTurn setActor( Monster m , int a )
        {
            kind = 1;
            monster = m;
            agi = a ;
            m.turn = this;
            return this;
        }

        MonsterTeam monsterTeam()
        {
            return monster.team;
        }
    }

    Member  member;
    Monster monster;
    int agi;

    // BattleTurn previous;     // template
    // BattleTurn next;         // template

    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    int act()
    {

        if (isPlayer)
        { /* member action */
            setColor( CL.NORMAL );
            if (party.suprised)
                return 0;
            else
                member.act();
        }
        else if (isMonster)
        { /* monster action */
            setColor( CL.MONSTER );
            if (monParty.suprised)
                return 0;
            else
                monster.act();
        }

        return 0;
    }


    /**--------------------
       del - BattleTurn 削除
       --------------------*/
    void del()
    {
        listDetails.del( this , parent.list.top );
        return;
    }


}
