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

import cmonster;
import cmonster_def;



class MonsterTeam
{

    ListManager!Monster     list;
    ListDetails!MonsterTeam listDetails;

    bool ident; /* identify flag true:identify, false:not */
                /* identify flag 0:identify, 1:not  // original*/

    MonsterDef def;

    // Monster top;     // template
    // Monster end;     // template

    Monster top(){ return list.top; }
    Monster end(){ return list.end; }
    void top( Monster m ){ list.top = m; }
    void end( Monster m ){ list.end = m; }
    
    MonsterTeam next()      { return listDetails.next; }
    MonsterTeam previous()  { return listDetails.previous; }
    void next( MonsterTeam mt )     { listDetails.next     = mt; }
    void previous( MonsterTeam mt ) { listDetails.previous = mt; }

    void insertNext( MonsterTeam mt )   { listDetails.insertNext  ( this , mt ); }
    void insertBefore( MonsterTeam mt ) { listDetails.insertBefore( this , mt ); }


    this()
    {
        listDetails = new ListDetails!MonsterTeam();

        list = new ListManager!Monster;
        list.initListDetails( MAX_MONSTER_MEMBER ); 
        return;
    }


    /*--------------------
       foreach -> Monster を返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref Monster ) operations )  
    {
        int result = 0;

        foreach( m ; list )
            operations( m );
        return result;
    }
    int opApply( int delegate( ref size_t ,
                               ref Monster ) operations )  
    {

        int result = 0;

        foreach( i , m ; list )
            operations( i , m );
        return result;
    }


    /*--------------------
       init - 初期化
       --------------------*/
    void initialize()
    {
        def = null;

        foreach( Monster m ; list )
            m.initialize;
    }


    /*--------------------
       isExist - 設定ある？
       --------------------*/
    bool isExist()
    {
        if( count > 0 )
            return true;
        else
            return false;
    }

    /*--------------------
       count - 登録モンスター数
       --------------------*/
    int count()
    {
        int n = 0;
        foreach( Monster m ; list )
            n ++ ;
        return n;
    }

    /*--------------------
       actCount - 動ける数
       --------------------*/
    int actCount()
    {
        int n = 0;
        foreach( Monster m ; list )
            if( m.isActive )
                n ++ ;
        return n;
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

        if( count == 1 )
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
        int loop;

        if( count == 1 )
            return top;

        loop = get_rand( count - 1 );

        m = top;
        for ( int i = 0; i < loop; i++ )
            m = m.next;

        assert( m.def !is null , "getRandMonster : m.def is null" );
        return m;
    }

    /*--------------------
        partyAdd - MonsterTeam 追加
       --------------------*/
    void partyAdd( MonsterDef d )
    {

        Monster m;
        Monster prev;

        int num;


        def = d;

        num = def.minnum + get_rand( def.addnum );
        ident = party.isIdentify;  // latumapic invalid?

        top = list.details[ 0 ];     // Monster
        assert( top !is null );

        prev = null;
        foreach( i ; 0 .. num )     // Monster追加
        {
            m = list.details[ i ];
            m.teamAdd( this );

            if( prev is null ) 
            {
                // top
                m.previous = null;
                m.next = null;
            }
            else
            {
                prev.insertNext( m );
            }

            end = m;
            prev = m;

        }

        return;
    }

    /*--------------------
       addMonster - Monster 追加
       --------------------*/
    Monster addMonster()
    {

        Monster m;

        // get empty slot
        m = null;
        foreach( l ; list )
            if( l.def is null )
            {
                m = l;
                break;
            }

        if( m is null )
            return null;

        m.teamAdd( this );
        list.end.insertNext( m );
        list.end = m;

        return m;

    }

    /*--------------------
       callHelp - 仲間を呼ぶ
       --------------------*/
    bool callHelp()
    {

        Monster m;

        if ( count == 9 ) /* max mons in a team */
            return false;

        m = addMonster();
        if( m is null )
            return false;

        return true;
    }

    /*--------------------
       del - MonsterTeam 削除
       --------------------*/
    void del()
    {
        def = null;
        listDetails.del( this , monParty.list.top );
        return;
    }

}

