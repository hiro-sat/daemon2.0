// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.array;

// mysource 
import def;
import app;

import clistmanager;
import clistdetail;

import cmonster_party;
import cmonster;
import cmonster_def;


class MonsterTeam : ListDetails!( MonsterParty , MonsterTeam )
// class MonsterTeam : ListManager!( MonsterTeam , Monster )
{

    bool ident; /* identify flag true:identify, false:not */
                /* identify flag 0:identify, 1:not  // original*/
    MonsterDef def;

    MonsterTeamManager  manager;
    // manager
    Monster top() { return manager.top; }
    Monster end() { return manager.end; }
    void top( Monster m ) { manager.top = m; }
    void end( Monster m ) { manager.end = m; }
    int count() { return manager.count; }
    void delDetail(){ manager.delDetail; }

    /+
    // details
    MonsterTeam next()      { return team.next; }
    MonsterTeam previous()  { return team.previous; }
    void next( MonsterTeam mt )     { team.next     = mt; }
    void previous( MonsterTeam mt ) { team.previous = mt; }
    void insertNext( MonsterTeam mt )   { team.insertNext( mt ); }
    void insertBefore( MonsterTeam mt ) { team.insertBefore( mt ); }
    +/



    this( MonsterParty pty )
    {
        super( pty );                               // ListDetails.this
        manager = new MonsterTeamManager( this );   // ListManager.this
        return;
    }

    /*--------------------
       init - 初期化
       --------------------*/
    void initialize()
    {
        def = null;

        manager.reset;

        foreach( Monster m ; manager.details )
            m.initialize;
    }

    /*--------------------
       isExist - いる？
       --------------------*/
    bool isExist()
    {
        if( manager.count > 0 )
            return true;
        else
            return false;
    }


    /*--------------------
       getPartyNo - モンスターNo
       --------------------*/
    int getPartyNo()
    {
        int no = -1;
        foreach( i , mt ; monParty )
            if( mt is this )
            {
                no = to!int( i ); 
                break;
                // returnが効かずに全てのforeachが実行されてしまう？
                // opApply の不具合？opApply をネストしてるから？
                /* return to!int( i ); */   
            }

        if( no == -1 )
            assert( 0 );

        return no;
    }


    /*--------------------
       getDispNameA - モンスター表示名称取得（単数）
       --------------------*/
    string getDispNameA()
    {
        if( ident )
            return def.name;
        else
            return def.unname;
    }

    /*--------------------
       getDispNameS - モンスター表示名称取得（複数確認）
       --------------------*/
    string getDispNameS()
    {
        string name;
        name = getDispNameA;

        if( manager.count == 1 )
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
       actCount - 動ける数
       --------------------*/
    int actCount()
    {
        int n = 0;
        foreach( Monster m ; manager )
            if( m.isActive )
                n ++ ;
        return n;
    }


    /*--------------------
       getRandMonster - モンスター1体ランダム取得
       --------------------*/
    Monster getRandMonster()
    {
        Monster m;

        if( count == 1 )
            return top;

        m = top;
        foreach( i ; 0 .. get_rand( count - 1 ) )
            m = m.next;

        assert( m.def !is null , "getRandMonster : m.def is null" );
        return m;
    }


    /*--------------------
       callHelp - 仲間を呼ぶ
       --------------------*/
    bool callHelp()
    {

        Monster m;

        if ( count == MAX_MONSTER_MEMBER ) /* max mons in a team */
            return false;

        m = generateMonster();
        if( m is null )
            return false;

        return true;
    }


    /*--------------------
        addParty - MonsterTeam 追加
       --------------------*/
    void addParty( MonsterDef d )
    {

        Monster m;
        int num;

        def = d;

        num = def.minnum + get_rand( def.addnum );
        ident = party.isIdentify;  // latumapic invalid?

        top = null;
        end = null;
        foreach( i ; 0 .. num )     // Monster追加
            generateMonster;

        return;
    }


    /*--------------------
       generateMonster - Monster 追加
       --------------------*/
    Monster generateMonster()
    {

        Monster m;

        // get empty slot
        m = manager.add;
        if( m is null )
            return null;

        m.addTeam;
        if( end is null )
        {
            // top
            top = m;
            m.previous = null;
            m.next = null;
        }
        else
        {
            end.insertNext( m );
        }
        end = m;

        return m;

    }

    /*--------------------
       del - MonsterTeam 削除
       --------------------*/
    override void del()
    {
        def = null;
        super.del();
        return;
    }

}


class MonsterTeamManager : ListManager!( MonsterTeamManager , Monster )
{

    MonsterTeam     team;

    this( MonsterTeam mt )
    {
        team = mt;
        super( MAX_MONSTER_MEMBER );
        return;
    }

}

