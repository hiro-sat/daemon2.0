/* vim: set nowrap : */

/+
2024.03.11 monster 設定した呪文
ok: bind
ok: silenc
ok: sleep

ok: firstm
ok: flames
ok: icestm
ok: xflames
ok: blizard
ok: nuclear
ok: scourge
ok: spark

ok: fire
ok: curse
ok: mcurse
ok: xcurse
ok: noilatm

ok: panic
ok: xpanic
ok: gpanic

ok: harden
ok: mshild

ok: gvanish
+/


// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string;

// mysource 
import app;
import def;
import cmagic_def;
import cparty;
import cmember;
import cmonster_party;
import cmonster_team;
import cmonster;


class BaseSpell
{

    int castSpell( Member p , bool camp = true ){ return 0; }
    void castInCamp( Member p )  { castSpell( p , true ); }
    int castInBattle( Member p ) { return castSpell( p , false ); }

    bool checkMonsterCastSpell() { return false; }
    void monsterCastSpell( Monster m , Member p ) { assert( 0 , "Error : not exists Spell" ); }

    MagicDef magicDef;

    /*--------------------
       selectMember - パーティメンバー選択
       --------------------*/
    Member selectMember()
    {
        return party.selectMember( _("to whom?: ") );
    }

    /*--------------------
       healOne - 1人回復
       --------------------*/
    void healOne( Member target , bool camp = true )
    {
        int nPoints;

        if ( target.status >= STS.DEAD )
            return;

        nPoints = magicDef.min + get_rand( magicDef.add );

        txtMessage.textout( "  " );
        if ( target.hp + nPoints >= target.maxhp )
        {
            target.hp = target.maxhp;
            txtMessage.textout( _( "%1 is completely healed.\n" ) , target.name );
        }
        else
        {
            target.hp += nPoints;
            txtMessage.textout( _( "%1 hit points are restored\n  to %2.\n" ) , nPoints , target.name );
        }

        if( camp )
        {
            party.dispPartyWindow();
        }
        else    // battle
        {
            party.dispPartyWindow_NoReorder();
            getChar();
        }


        return;
    }

    /*--------------------
       attackOne - 1体魔法攻撃
       --------------------*/
    void attackOne( Member p , Monster m )
    {
        MonsterTeam mt = m.parent.team;

        int damage;

        if ( m.def.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) , m.getDispNameA );
            getChar();
            return;
        }

        damage = magicDef.min + get_rand( magicDef.add );
        switch ( magicDef.attr )
        {
            case TYPE_MAGIC_ATTRIBUTE.fire : /* fire */
            case TYPE_MAGIC_ATTRIBUTE.smallfire : /* small fire */
                if( m.def.isDefefFire )
                    damage /= 2;
                  break;
            case TYPE_MAGIC_ATTRIBUTE.ice : /* ice */
                if( m.def.isDefefCold )
                    damage /= 2;
                break;
            case TYPE_MAGIC_ATTRIBUTE.undead  : /* undead only */
                if( m.def.isDefefUndead )
                    damage = 0;
                break;
            case TYPE_MAGIC_ATTRIBUTE.no :
            default:
                break;
        }

        if (damage > 0)
        {
            txtMessage.textout( _( "  %1 takes %2 damage.\n" ) , m.getDispNameA , damage );
            m.hp -= damage;
            if ( m.hp <= 0 )
            {
                txtMessage.textout( _( "    %1 is dead!\n" ) , m.getDispNameA );
                
                get_exp += m.exp;
                m.marksUp;
                p.marks ++;
          
                m.del;
            }
            getChar();
        }
        return;
    }

    /*--------------------
       attackGroup- 1グループ魔法攻撃
       --------------------*/
    void attackGroup( Member p , MonsterTeam mt )
    {
        Monster m , next ;

        m = mt.top;
        while( m !is null )
        {
            next = m.next;
            attackOne( p , m );
            m = next;
        }
        return;
    }

    /*--------------------
       attackAll - 全体魔法攻撃
       --------------------*/
    void attackAll( Member p )
    {
        MonsterTeam mt , next ;

        mt = monParty.top;
        while( mt !is null )
        {
            next = mt.next;
            attackGroup( p , mt );
            mt = next;
        }
        return;
    }


    /*--------------------
       vanished - 1グループ消滅
       --------------------*/
    void vanish( Member p , MonsterTeam mt )
    {
        Monster m , next ;

        m = mt.top;
        while( m !is null )
        {
            next = m.next;
            if ( m.def.level < 8 )
            {
                txtMessage.textout( _( "  %1 is vanished!\n" ) , m.getDispNameA );

                get_exp += m.exp;
                m.marksUp;
                p.marks ++;

                m.del;
            }
            else
            {
                txtMessage.textout( _( "  %1 is alive.\n" ) , m.getDispNameA );
            }
            getChar();
            m = next;
        }
        return;
    }


    /*--------------------
       acUpGroup - 1グループ AC+
       --------------------*/
    void acUpGroup( MonsterTeam mt )
    {
        int acplus = magicDef.min;
        Monster m;

        m = mt.top;
        while( m !is null )
        {
            m.acplus += acplus;
            m = m.next;
        }

        txtMessage.textout( N_( "  %1's AC +%2.\n" 
                   , "  %1' AC +%2.\n", mt.count )
                        , mt.getDispNameS , acplus );
        getChar;
        return;
    }

    /*--------------------
       acUpAll - 全体 AC+
       --------------------*/
    void acUpAll()
    {
        MonsterTeam mt;

        mt = monParty.top;
        while ( mt !is null )
        {
            acUpGroup( mt );
            mt = mt.next;
        }
        return;
    }

    /*--------------------
       acDownPlayer - Player AC-
       --------------------*/
    void acDownPlayer( Member mem )
    {
        mem.ac[ 1 ] += magicDef.min;
        party.dispPartyWindow_NoReorder;
        getChar();
        return;
    }


    /*--------------------
       acDownParty - Party AC-
       --------------------*/
    void acDownParty()
    {
        foreach( p ; party )
            p.ac[ 1 ] += magicDef.min;
        party.dispPartyWindow_NoReorder;
        getChar();
        return;
    }

    /*--------------------
       monsterAttackOne - プレイヤー1人 魔法攻撃
       --------------------*/
    void monsterAttackOne( Member p )
    {

        int damage;

        if ( p.status >= STS.DEAD )
            return;

        damage = magicDef.min + get_rand( magicDef.add );

        // 装備と魔法の属性によって増減 ++++++++++++++++++++++++++++++++
        switch( magicDef.attr )
        {
            case TYPE_MAGIC_ATTRIBUTE.fire: // fire
            case TYPE_MAGIC_ATTRIBUTE.smallfire: // small fire
                if ( p.isDefefFire ) 
                    damage /= 2;
                break;
            case TYPE_MAGIC_ATTRIBUTE.ice: // ice
                if ( p.isDefefIce )
                    damage /= 2;
                break;
            case TYPE_MAGIC_ATTRIBUTE.undead: // undead only
                damage = 0;
                break;
            default:
                break;
        }

        if ( damage <= 0 || p.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) , p.name );
        }
        else
        {
            txtMessage.textout( _( "  %1 gets %2 damage!\n" ) , p.name , damage );
            if ( p.hp <= damage )
            { // dead
                p.hp = 0;
                p.status = STS.DEAD; /* dead */
                p.rip++;
                txtMessage.textout( _( "    %1 is killed!\n"  ) , p.name );
            }
            else
            {
                p.hp -= damage;
            }
        }
        party.dispPartyWindow_NoReorder;
        getChar();

        return;
    }

    /*--------------------
       monsterAttackGroupy / monsterAttackAll - パーティ全員 魔法攻撃
       --------------------*/
    void monsterAttackGroup()
    {
        foreach( p ; party )
            monsterAttackOne( p );
        return;
    }
    void monsterAttackAll()
    {
        monsterAttackGroup;
        return;
    }


    /*--------------------
       monsterAcDownOne - Player AC+
       --------------------*/
    void monsterAcDownOne( Monster m )
    {
        m.acplus += magicDef.min;
        txtMessage.textout( _( "  %1 AC %2.\n" ) , m.getDispNameA , magicDef.min );
        return;
    }


    /*--------------------
       monsterAcUpPlayer - Player AC+
       --------------------*/
    void monsterAcDownAll( Monster m )
    {
        Monster mon = m.parent.top;
        while( mon !is null )
        {
            mon.acplus += magicDef.min;
            mon = mon.next;
        }
        txtMessage.textout( N_( "  %1's AC -%2.\n" 
                   , "  %1' AC -%2.\n", m.parent.count )
                        , m.getDispNameS , magicDef.min );
        party.dispPartyWindow_NoReorder();
        return;
    }


    /*--------------------
       monsterAcUpParty - Party AC+
       --------------------*/
    void monsterAcUpParty()
    {
        foreach( p ; party )
            p.ac[ 1 ] += magicDef.min;
        txtMessage.textout( _( "  Party AC +%1.\n" ) , magicDef.min ) ;
        party.dispPartyWindow_NoReorder;
        getChar();
        return;
    }


    /*--------------------
       monsterVanish - パーティ消滅
       --------------------*/
    void monsterVanish()
    {
        foreach( p ; party )
        {
            if ( p.status >= STS.DEAD )
                continue;

            if ( p.level < 8 )
            {
                txtMessage.textout( _( "  %1 is suffocated.\n" ) , p.name );
                p.status = STS.DEAD;
                p.hp = 0;
                p.rip++;
                party.dispPartyWindow_NoReorder;
            }
            else
            {
                txtMessage.textout( _( "  %1 is alive.\n" ) , p.name );
            }
            getChar();
        }
        return;
    }

}

// ---------------------------------------- 
//  ↓以下、派生クラス
// ---------------------------------------- 
class SpellSleep : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        MonsterTeam mt = p.getTargetMonsterTeam();
        Monster     m  = mt.top;

        getChar();

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if  ( m.def.isDefefSlpEzy )
            { // sleep easily
                if ( get_rand( 5 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    txtMessage.textout( _( "  %1 is slept.\n" ) , m.getDispNameA );
                }
                else
                {
                    txtMessage.textout( _( "  %1 is not slept.\n" ) , m.getDispNameA );
                }
            }
            else
            {
                if ( get_rand( 1 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP  ; // sleep
                    txtMessage.textout( _( "  %1 is slept.\n" ) , m.getDispNameA );
                }
                else
                {
                    txtMessage.textout( _( "  %1 is not slept.\n" ) , m.getDispNameA );
                }
            }

            getChar();
            m = m.next;
        }
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        foreach( p ; party )
        {
            if ( p.status != STS.OK )
                continue;

            if ( p.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,  p.name );
            }
            else if ( get_rand( 3 ) == 0 )
            {
                txtMessage.textout( _( "  %1 is slept.\n" ) ,  p.name );
                p.status = STS.SLEEP;
            }
            else
            {
                txtMessage.textout( _( "  %1 is not slept.\n" ) , p.name  );
            }
            party.dispPartyWindow_NoReorder();
            getChar();
        }
        return;
    }
}


class SpellFire : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        attackOne( p , p.getTargetMonster );
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAttackOne( pl );
        return;
    }

}
alias SpellAttackOne = SpellFire;


class SpellMap : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        int s;

        party.setMapper;

        s = S_SCOPE_COUNT * p.level + party.scopeCount;
        if( s > MAX_SCOPE_COUNT ) s = MAX_SCOPE_COUNT;
        party.scopeCount = s;

        if( camp )
        {
            txtMessage.textout( _( "You are in ...\n" ) );
            txtMessage.textout( _( "Floor: B%1F , X: %2 , Y: %3 \n" )
                                , party.layer
                                , party.dungeon.convertRelativePositionX( party.x )
                                , party.dungeon.convertRelativePositionY( party.y ) );
            getChar();
            dispHeader( HSTS.CAMP );
        }
        return 0;
    }
}


class SpellHarden : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        acDownPlayer( p );
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAcDownOne( m );
        return ;
    }
}
alias SpellAcDownPlayer = SpellHarden;


class SpellFlames : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        attackGroup( p , p.getTargetMonsterTeam );
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAttackGroup();
        return;
    }
}
alias SpellAttackGroup = SpellFlames;


class SpellPanic : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        acUpGroup( p.getTargetMonsterTeam );
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAcUpParty();
        return;
    }
}


alias SpellXharden = SpellAcDownPlayer;     // SpellHarden;
// class SpellXharden : BaseSpell


alias SpellXflames = SpellAttackGroup;      // SpellFlames
// class SpellXflames : BaseSpell


alias SpellSpark = SpellAttackAll;          // SpellNuclear
// class SpellSpark : BaseSpell


alias SpellXpanic = SpellPanic;
// class SpellXpanic : BaseSpell


class SpellFloatn : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        party.setFloat;

        if( camp )
        {
            txtMessage.textout( _( "done.\n" ) );
            dispHeader( HSTS.CAMP );
        }
        return 0;
    }
}


alias SpellIcestm = SpellAttackGroup;       // SpellFlames
// class SpellIcestm : BaseSpell


alias SpellFirstm = SpellAttackGroup;       // SpellFlames
// class SpellFirstm : BaseSpell


class SpellGpanic : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        acUpAll;
        return 0 ;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAcUpParty();
        return;
    }

}


class SpellVanish : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        vanish( p , p.getTargetMonsterTeam );
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterVanish();
        return;
    }
}


alias SpellBlizard = SpellAttackGroup;      // SpellFlames
// class SpellBlizard : BaseSpell


class SpellGharden : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        acDownParty;
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAcDownAll( m );
        return;
    }
}
alias SpellAcDownParty = SpellGharden;


alias SpellBurial = SpellAttackOne;     // SpellFire
// class SpellBurial : BaseSpell


class SpellGvanish : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        MonsterTeam mt = monParty.top;

        while( mt !is null )
        {
            vanish( p , mt );
            mt = mt.next;
        }
        return 0;

    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterVanish();
        return;
    }

}


alias SpellNoilatm = SpellAttackOne;    // SpellFire
// class SpellNoilatm : BaseSpell


class SpellTelept : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        int xpos, ypos, layer;

        if( ! camp )
        {
            //battle;
            // escape( random )
            party.x = get_rand( party.dungeon.width ) ;
            party.y = get_rand( party.dungeon.height ) ;
            return 2;
        }
        else    // camp
        {
            txtMessage.textout( _( "\n*** where do you want to teleport? ***\n" ) );

            bool inputTeleptPosition( string msg , ref int pos )
            {
                bool cancel = false;
                pos = inputPosition( msg , cancel );
                if( cancel )
                    return false;
                else 
                    return true;
            }


            layer = 0;
            while( layer == 0 ) 
            {
                if( ! inputTeleptPosition( _( "enter xpos(z:leave): \n" ) , xpos ) )
                {
                    txtMessage.textout( _( "quit.\n" ) );
                    return 0;
                }

                if( ! inputTeleptPosition( _( "enter ypos(z:enter xpos again): \n" ) , ypos ) )
                    continue;
                
                if( ! inputTeleptPosition( _( "enter layer(z:enter xpos again): \n" ) , layer ) )
                    continue;

            }


            if( layer < 1 || layer >= MAXLAYER )
            {
                // in rock
                party.layer = to!byte( layer );
                txtMessage.textout( _( "done.\n" ) );
                getChar;
                return 2;
            }


            if( party.layer != layer )
            {
                party.layer = to!byte( layer );
                party.setDungeon;
            }

            party.x = party.dungeon.convertAbsolutePositionX( xpos );
            party.y = party.dungeon.convertAbsolutePositionY( ypos );

            if( ! party.dungeon.checkMapRange( party.x , party.y ) )
            {
                // in rock
                txtMessage.textout( _( "done.\n" ) );
                getChar;
                return 2;
            }
            else
            {
                party.dungeon.setDispPos;
                party.dungeon.initDisp;
                party.dungeon.disp;
            }

            txtMessage.textout( _( "done.\n" ) );
            getChar;
            dispHeader( HSTS.CAMP );
            party.dispPartyWindow();
            return 0;
        }

    }

    int inputPosition( string msg , ref bool cancel )
    {

        int pos;
        string numtext;

        while( true )
        {
            txtMessage.textout( msg );
            numtext = txtMessage.input( 4 , "> " );
            txtMessage.textout( "> %1\n" , numtext );

            if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
            {
                cancel = true;
                return 0;
            }

            if( ! isNumeric( numtext ) )
            {
                txtMessage.textout( _( "what?\n" ) );
                continue;
            }

            pos = to!int( numtext );

            break;
        }

        return pos;
    }
}


class SpellNuclear : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        attackAll( p );
        return 0;
    }
    override void monsterCastSpell( Monster m , Member pl )
    {
        monsterAttackAll();
        return;
    }

}
alias SpellAttackAll = SpellNuclear;


class SpellHeal : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        healOne( mem , camp );
        return 0;
    }
}
alias SpellHealOne = SpellHeal;


alias SpellShild = SpellAcDownParty;    // SpellGharden
// class SpellShild : BaseSpell


alias SpellCurse = SpellAttackOne;      // SpellFire
// class SpellCurse : BaseSpell


class SpellLight : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        int light;
        light = S_LIGHT_COUNT + party.lightCount;
        if( light > MAX_LIGHT_COUNT ) light = MAX_LIGHT_COUNT;
        party.setLight;
        party.lightCount = light;

        txtMessage.textout( _( "done.\n" ) );
        dispHeader( HSTS.CAMP );
        return 0;
    }
}


alias SpellProtct = SpellAcDownPlayer;  // SpellHarden
// class SpellProtct : BaseSpell



alias SpellMshild = SpellShild;     // SpellShild -> SpellGharden
// class SpellMshild : BaseSpell


class SpellInspct : BaseSpell
{
    // trap識別
    override int castSpell( Member p , bool camp = true )
    {
        return 0;   // dummy
    }
}


class SpellBind : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        MonsterTeam mt = p.getTargetMonsterTeam;
        Monster     m  = mt.top;

        getChar();

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if ( m.def.isDefefSlpEzy ) // sleep easily
            { // sleep easily
                if ( get_rand( 5 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    txtMessage.textout( _( "  %1 is held.\n" ) , m.getDispNameA );
                }
                else
                {
                    txtMessage.textout( _( "  %1 is not held.\n" ) , m.getDispNameA );
                }
            }
            else
            {
                if ( get_rand( 1 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    txtMessage.textout( _( "  %1 is held.\n" ) , m.getDispNameA );
                }
                else
                {
                    txtMessage.textout( _( "  %1 is not held.\n" ) , m.getDispNameA );
                }
            }
            getChar();
            m = m.next;
        }
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        foreach( p ; party )
        {
            if ( p.status != STS.OK )
                continue;

            if ( p.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) , p.name );
            }
            else if ( get_rand( 3 ) == 0 )
            {
                txtMessage.textout( _( "  %1 is held.\n" ) , p.name );
                p.status = STS.SLEEP;
            }
            else
            {
                txtMessage.textout( _( "  %1 is not held.\n" ) , p.name );
            }
            party.dispPartyWindow_NoReorder();
            getChar();
        }
        return ;
    }
}


class SpellSilenc : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        MonsterTeam mt = p.getTargetMonsterTeam;
        Monster     m  = mt.top;

        getChar();

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if ( ! m.silenced )
            {
                if ( get_rand( 1 ) == 0 )
                {
                    m.silenced = true;
                    txtMessage.textout( _( "  %1 is silenced!\n" ) , m.getDispNameA );
                }
                else
                {
                    txtMessage.textout( _( "  %1 is not silenced.\n" ) , m.getDispNameA );
                }
            }
            getChar();
            m = m.next;
        }
        return 0;

    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        foreach( p ; party )
        {
            if ( p.silenced )
                continue;

            if ( p.status >= STS.PARALY )
                continue;

            if ( p.magdef >= get_rand( 99 ) + 1 )
            {
                txtMessage.textout( _( "  %1 resisted the spell.\n" ) , p.name  );
            }
            else if ( get_rand( 1 ) == 0 )
            { // possibility = 1/2
                p.silenced = true;
                txtMessage.textout( _( "  %1 is silenced!\n" ) , p.name  );
            }
            else
            {
                txtMessage.textout( _( "  %1 is not silenced.\n" ) , p.name  );
            }
            getChar();
        }
        return;
    }

}


class SpellCure : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        if( mem.status <= STS.PARALY )
        {
            mem.status = STS.OK;
            txtMessage.textout( _( "  %1 is cured.\n" ) , mem.name );
        }
        else
        {
            txtMessage.textout( _( "  * done *\n" ) );
        }

        if( camp )
            party.dispPartyWindow();
        else    // battle
            party.dispPartyWindow_NoReorder();

        getChar();

        return 0;
    }
}


class SpellIdentfy : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        party.setIdentify;

        if( camp )
        {
            txtMessage.textout( _( "done.\n" ) );
            dispHeader( HSTS.CAMP );
        }
        else    // battle
        {
            MonsterTeam mt = monParty.top;
            for (int i = 0; i < monParty.count; i++)
            {
              mt.ident = false; // identified
              mt = mt.next;
            }
        }
        return 0;
    }
}

class SpellXlight : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        int light;
        light = L_LIGHT_COUNT * p.level + party.lightCount;
        if( light > MAX_LIGHT_COUNT ) light = MAX_LIGHT_COUNT;
        party.setLight;
        party.lightCount = light;

        if( camp )
        {
            txtMessage.textout( _( "done.\n" ) );
            dispHeader(HSTS.CAMP);

        }
        return 0;
    }
}


alias SpellXshild = SpellAcDownParty;   // SpellGharden
// class SpellXshild : BaseSpell


alias SpellMheal = SpellHealOne;        // SpellHeal
// class SpellMheal : BaseSpell


alias SpellMcurse = SpellAttackOne;     // SpellFire
// class SpellMcurse : BaseSpell


class SpellDetxify : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        if( mem.poisoned )
        {
            mem.poisoned = false;
            txtMessage.textout( _( "  %1 is cured.\n" ) , mem.name );
        }
        else
        {
            txtMessage.textout( _( "  * done *\n" ) );
        }

        if( camp )
            party.dispPartyWindow;
        else    // battle
            party.dispPartyWindow_NoReorder();

        getChar();

        return 0;
    }
}


class SpellGuard : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        party.ac =  - 2;
        party.dispPartyWindow();
        if( camp )
        {
            dispHeader( HSTS.CAMP );
        }
        else    // battle;
        {
            party.dispPartyWindow_NoReorder;
            getChar;
        }
        return 0;
    }
}


alias SpellXheal = SpellHealOne;        // SpellHeal
// class SpellXheal : BaseSpell



alias SpellXcurse = SpellAttackOne;     // SpellFire
// class SpellXcurse : BaseSpell


alias SpellHolyfla = SpellAttackGroup;  // SpellFlames
// class SpellHolyfla : BaseSpell


class SpellBreathe : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        int total;
        int plus;

        if ( mem.status != STS.DEAD )
        {
            txtMessage.textout( _( "  what?\n" ) );
        }
        else
        {
            total = mem.vit[ 0 ] + mem.vit[ 1 ]
                  + mem.luk[ 0 ] + mem.luk[ 1 ];
            total /= 2;
            if ( total <= 3 )
                plus =  - 2;
            else if ( total <= 5 )
                plus =  - 1;
            else if ( total <= 15 )
                plus = 0;
            else if ( total <= 16 )
                plus = 1;
            else if ( total <= 17 )
                plus = 2;
            else
                plus = 3;

            if ( get_rand( 18 ) <= 11 + plus )
            { // possibility of resurrection is 2/3 if plus=0
                txtMessage.textout( "  * ok *\n" );
                mem.status = STS.OK;
                mem.hp = 1;
            }
            else
            {
                txtMessage.textout( _( "  oops!!\n" ) );
                mem.status = STS.ASHED;
            }
            if( get_rand( 3 ) == 0 )
                mem.vit[ 0 ]--;
        }

        if( camp )
            party.dispPartyWindow();
        else    // battle
            party.dispPartyWindow_NoReorder;
        getChar;
        return 0;
    }
}

class SpellDeath: BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {
        Monster m = p.getTargetMonsterTeam.getRandMonster;

        if ( m.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
        }
        else if ( ! m.def.isDefefUndead && get_rand( 3 ) == 0 )
        { // possibility is 1/4
            txtMessage.textout( _( "  %1 is dead!\n" ) , m.getDispNameA );

            get_exp += m.exp;
            m.marksUp;
            p.marks ++;

            m.del;
        }
        else
        {
            txtMessage.textout( _( "  %1 is alive!\n" ) , m.getDispNameA );
        }
        getChar();
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {
        if ( pl.status >= STS.DEAD )
            return;

        if ( pl.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,  pl.name  );
        }
        else if ( get_rand( 3 ) == 0 )
        {
            pl.status = STS.DEAD;
            pl.hp = 0;
            pl.rip++;
            txtMessage.textout( _( "  %1 is dead!\n" ) , pl.name  );
            party.dispPartyWindow_NoReorder();
        }
        else
        {
            txtMessage.textout( _( "  %1 is alive.\n" ) , pl.name  );
        }
        return;
    }
}


class SpellBless: BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        if ( mem.status >= STS.DEAD )
        {
            txtMessage.textout( _( "  * done *\n" ) );
        }
        else
        {
            mem.status = STS.OK;

            txtMessage.textout( "  " );
            mem.hp = mem.maxhp;
            txtMessage.textout( _( "%1 is completely healed.\n" ) , mem.name );
        }

        if( camp )
            party.dispPartyWindow();
        else    // battle
            party.dispPartyWindow_NoReorder;

        getChar();
        return 0;
    }
}

class SpellDyng : BaseSpell
{
    // battle only
    override int castSpell( Member p , bool camp = true )
    {

        Monster m = p.getTargetMonsterTeam.getRandMonster;

        int mon_hp;

        if ( m.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
        }
        else
        {
            mon_hp = get_rand( 7 ) + 1;
            if ( mon_hp > m.hp )
                mon_hp = m.hp;
            int damage = m.hp - mon_hp;
            txtMessage.textout( _( "  %1 gets %2 damage!\n" ) , m.getDispNameA , damage );
            m.hp = mon_hp;
        }
        getChar();
        return 0;
    }

    override bool checkMonsterCastSpell() { return true; }
    override void monsterCastSpell( Monster m , Member pl )
    {

        int mag_hp;

        if ( pl.status >= STS.DEAD )
            return;

        if ( pl.magdef >= get_rand( 99 ) + 1 )
        {
            txtMessage.textout( _( "  %1 resisted the spell.\n" ) , pl.name );
        }
        else
        {
            mag_hp = get_rand( 7 ) + 1;
            if ( mag_hp > pl.hp )
                mag_hp = pl.hp;
            txtMessage.textout( _( "  %1 gets %2 damage!\n" ) 
                    , pl.name , pl.hp - mag_hp );
            pl.hp = mag_hp;
        }
        party.dispPartyWindow_NoReorder();
        getChar();

        return;
    }
}


alias SpellNdlstm = SpellAttackGroup;       // SpellNuclear
// class SpellNdlstm : BaseSpell


// camp only
class SpellReturn : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        party.x = 1;
        party.y = 2;
        party.layer = 0;

        if( camp )  // camp only
        {
            txtMessage.textout( _( "teleport to the castle!\n" ) );
            getChar;
        }
        else    // battle
        {
            /* foreach( p_ ; party ) */
            /*     p_.outflag = OUT_F.CASTLE ; // in castle */
            /* getChar; */
        }
        return 2;
    }
}


alias SpellScourge = SpellAttackAll;        // SpellNuclear
// class SpellScourge : BaseSpell



class SpellGrace : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {

        Member mem;

        if( camp )
            mem = selectMember;
        else    // battle
            mem = p.targetPlayer;

        if( mem is null ) return 0;

        int total;
        int plus;

        if ( ! ( mem.status == STS.DEAD || mem.status == STS.ASHED ) )
        {
            txtMessage.textout( _( "  what?\n" ) );
        }
        else
        {
            total = mem.vit[ 0 ] + mem.vit[ 1 ]
                  + mem.luk[ 0 ] + mem.luk[ 1 ];
            total /= 2;
            if ( total <= 3 )
                plus =  - 2;
            else if ( total <= 5 )
                plus =  - 1;
            else if ( total <= 15 )
                plus = 0;
            else if ( total <= 16 )
                plus = 1;
            else if ( total <= 17 )
                plus = 2;
            else
                plus = 3;

            if ( mem.status == STS.ASHED )
                plus += 5; // possibility of resurrection is 1/3(ASHED) if plus=0
            else
                plus += 14; // possibility of resurrection is 14/19(DEAD) if plus=0

            if ( get_rand( 18 ) <= plus )
            {
                txtMessage.textout( _( "  * ok *\n" ) );
                mem.status = STS.OK;
                mem.hp = mem.maxhp;
            }
            else
            {
                txtMessage.textout( _( "  oops!!\n" ) );
                if ( mem.status == STS.ASHED )
                    mem.getLost;
                else
                    mem.status = STS.ASHED;
            }
            if( get_rand( 3 ) == 0 )
                mem.vit[ 0 ]--;
        }

        if( camp )
            party.dispPartyWindow();
        else    // battle
            party.dispPartyWindow_NoReorder;

        getChar();
        return 0;
    }
}


class SpellHealer : BaseSpell
{
    override int castSpell( Member p , bool camp = true )
    {
        foreach( target ; party )
            healOne( target , camp );
        if( camp )
            getChar;
        return 0;
    }
}
