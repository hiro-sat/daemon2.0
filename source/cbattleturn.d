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
class BattleTurn : ListDetails!( BattleTurnManager , BattleTurn )
{
private:
    char kind; /* 0:player, 1:monster */

public:

    int no;

    // BattleTurn next;         // template
    // BattleTurn previous;     // templatey


    this( BattleTurnManager mgr )
    {
        super( mgr );
        return;
    }


    bool isPlayer()  { return (kind == 0); }
    bool isMonster() { return (kind == 1); }
    Member  member;
    Monster monster;

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
            return monster.parent.team;     // MonsterTeamManager.team -> MonsterTeam
        }
    }

    int agi;

    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    int act()
    {

        if (isPlayer)
        { /* member action */
            setColor( CL.NORMAL );
            /+
            if (party.suprised)
                return 0;
            else
            +/
            member.act();
        }
        else if (isMonster)
        { /* monster action */
            setColor( CL.MONSTER );
            /+
            if (monParty.suprised)
                return 0;
            else
            +/
            monster.act();
        }

        return 0;
    }

}
