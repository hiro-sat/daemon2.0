// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;

// mysource 
import def;
import app;
import cMonster;

class MonsterTeam
{
    int num;
    int actnum; /* can action */

    bool ident; /* identify flag true:identify, false:not */
                /* identify flag 0:identify, 1:not  // original*/

    MonsterTeam previous;   // fp
    MonsterTeam next;       // tp

    Monster top;
    Monster end;


    /*--------------------
       getDispNameA - モンスター表示名称取得（単数）
       --------------------*/
    string getDispNameA()
    {
        if( ident )
            return top.def.name;
        else
            return top.def.unname;
    }

    /*--------------------
       getDispNameS - モンスター表示名称取得（複数確認）
       --------------------*/
    string getDispNameS()
    {
        string name;
        name = getDispNameA;

        if( num == 1 )
            return name;

        string check;
        if( name.back == 's' || name.back == 'x' || name.back == 'o' )
            return name ~ "s";

        if( name.back == 'h' )
        {
            if( name.length > 2 )
            {
                check = name;
                check.popBack;
                if( check.back == 'c' || check.back == 's' )   // -ch , -sh
                    return name ~ "es";
            }
            return name ~ "s";
        }

        if( name.back == 'y')
        {
            check = name;
            check.popBack;
            return check ~ "ies";
        }

        if( name.back == 'f')
        {
            check = name;
            check.popBack;
            return check ~ "ves";
        }

        if( name.back == 'e')
        {
            if( name.length <= 2 )
                return name ~ 's';

            check = name;
            check.popBack;
            if( check.back == 'f' )
            {
                check.popBack;
                return check ~ "ves";
            }
            else
            {
                return name ~ "s";
            }
        }

        return name ~ "s";

    }

    /*--------------------
       getRandMonster - モンスター1体ランダム取得
       --------------------*/
    Monster getRandMonster()
    {
        Monster m;

        m = top;
        for ( int i = 0; i < get_rand( num - 1); i++ )
            m = m.next;
        return m;
    }

    /*--------------------
       del - MonsterTeam 削除
       --------------------*/
    void del()
    {

        int i, team = 0;
        MonsterTeam tp = monParty.top;

        /* if ( tp is null ) */
        /*     textout( "MonsterTeam.del: monParty.top is null\n" ); */
        assert( ( tp !is null ) ,"MonsterTeam.del: monParty.top is null\n" );

        for ( i = 0; i < 4; i++ )
        {
            if ( tp is this )
                break;
            team ++;
            tp = tp.next;
        }

        if ( previous is null )
            monParty.top = next;
        else
            previous.next = next;

        if ( next is null )
            monParty.end = previous;
        else
            next.previous = previous;

        monParty.num--;

        for ( i = 0; i < party.num; i++ )
            if ( party.mem[ i ].target >= team 
                    && party.mem[ i ].target > 0 )
                party.mem[ i ].target--;

        return;

    }

}

