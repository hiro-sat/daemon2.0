// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;

// mysource 
import app;
import def;
import cMember;
import cMonster;
import cMonsterTeam;

/**
  Battle Turn
  */
class BattleTurn
{
private:
    char kind; /* 0:player, 1:monster */

public:
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
        void set(Member p)
        {
            kind = 0;
            member = p;
            agi = member.agi[0] + member.agi[1] + get_rand(4);
            return;
        }

        void set(Monster m)
        {
            kind = 1;
            monster = m;
            agi = m.def.agi + get_rand(4);
            m.turn = this;
            return;
        }

        MonsterTeam monsterTeam()
        {
            return monster.team;
        }
    }

    Member member;
    Monster monster;
    int agi;

    BattleTurn previous;
    BattleTurn next;

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

    /*--------------------
       del - BattleTurn 削除
       --------------------*/
    void del()
    {
        if (previous is top_turn)
            top_turn.next = next;
        else
            previous.next = next;

        if (next is end_turn)
            end_turn.previous = previous;
        else
            next.previous = previous;

        return;

    }

}
