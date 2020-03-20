// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;

// mysource 
import def;
import app;
import cMonster;
import cMonsterDef;

class MonsterTeam
{
    int num;
    int actnum; /* can action */

    bool ident; /* identify flag true:identify, false:not */
                /* identify flag 0:identify, 1:not  // original*/

    MonsterDef def;

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
            return name ~ "es";

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
       addMonsterTeam - MonsterTeam 追加
       --------------------*/
    void addMonsterTeam()
    {

        Monster m;
        Monster prev;

        num = def.minnum + get_rand( def.addnum );
        ident = party.isIdentify;  // latumapic invalid?

        top = addMonster();
        assert( top !is null );

        top.previous = null;

        prev = top;
        for( int i = 1 ; i < num ; i++ )
        {
            m = addMonster;
            m.previous = prev;
            m.next = null;
            
            if( prev !is null )
                prev.next = m;

            prev = m;
        }
        end = m;
        return;
    }

    /*--------------------
       callHelp - 仲間を呼ぶ
       --------------------*/
    bool callHelp()
    {

        Monster m;

        if ( num == 9 ) /* max mons in a team */
            return false;

        m = addMonster();
        if( m is null )
            return false;

        end.next = m;
        m.previous = end;
        m.next = null;

        end = m;
        num ++;
        actnum ++;  // 未使用？

        return true;
    }

    /*--------------------
       addMonster - Monster 追加
       --------------------*/
    Monster addMonster()
    {

        Monster m;

        // get empty slot
        m = null;
        foreach( s ; monster )
            if( s.def is null )
            {
                m = s;
                break;
            }

        if( m is null )
            return null;

        m.add( this , def );
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

