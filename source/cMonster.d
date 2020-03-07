// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;

// mysource 
import def;
import app;
import cBattleTurn;
import cMonsterTeam;
import cMonsterDef;
import cParty;
import cMember;

import spell;


/**
  Monster - モンスター1体を管理
  */
class Monster
{
    MonsterDef  def;    // montypep
    MonsterTeam team;   // parent
    int maxhp;
    int hp;
    char status;   /* 0:ok, 1:sleep, 2:paralized, 3:stoned */
    bool silenced; // 1:silenced, 0:not
    char acplus;   // AC plus

    Monster previous;   // fp
    Monster next;     // tp

    BattleTurn turn;

    @property
    {
        int   ac()    { return def.ac; }
        byte  type()  { return def.type; }
        byte  defef() { return def.defef; }
        byte  magdef(){ return def.magdef; }
        short level() { return def.level; }
        int   exp()   { return def.exp; }
        bool  ident() { return team.ident; }
    }

    /*--------------------
       getDispName - モンスター表示名称取得（単数）
       --------------------*/
    string getDispNameA()
    {
        return team.getDispNameA;
    }
    /*--------------------
       getDispName - モンスター表示名称取得（複数確認）
       --------------------*/
    string getDispNameS()
    {
        return team.getDispNameS;
    }

    /**--------------------
       marksUp - marks + 1
       --------------------*/
    void marksUp()
    {
        def.marksUp;
        return;
    }

    /*--------------------
       isAtkef - atkef確認
       --------------------*/
    bool isAtkPoison()    { return def.isAtkPoison; }
    bool isAtkStone()     { return def.isAtkStone; }
    bool isAtkParalize()  { return def.isAtkParalize; }
    bool isAtkSleep()     { return def.isAtkSleep; }
    bool isAtkCritical()  { return def.isAtkCritical; }
    int  getAtkDrainLv()  { return def.getAtkDrainLv; }

    /*--------------------
       isDefef - defef確認
       --------------------*/
    bool isDefefLngRange() { return def.isDefefLngRange; }
    bool isDefefUndead()   { return def.isDefefUndead; }
    bool isDefefSleep()    { return def.isDefefSleep; }
    bool isDefefCritical() { return def.isDefefCritical; }
    bool isDefefDrain()    { return def.isDefefDrain; }
    bool isDefefFire()     { return def.isDefefFire; }
    bool isDefefCold()     { return def.isDefefCold; }
    bool isDefefSlpEzy()   { return def.isDefefSlpEzy; }

    /**--------------------
       del - Monster 削除
       --------------------*/
    void del()
    {

        def = null;

        if ( previous is null ) /* top? */
          team.top = next;
        else
          previous.next = next;

        if ( next is null )     /* end? */
          team.end = previous;
        else
          next.previous = previous;

        team.num--;

        if ( team.num == 0 )
            team.del;

        return;
    }


    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    void act()
    {
        int target;
        int i;
        int monaction;


        if ( status != STS.OK )
            return;
      
        for ( i = 0; i < party.num; i++ )
          if ( party.mem[ i ].status < STS.DEAD )
              break;
        if ( i == party.num )
            return;
      
      
        monaction = def.action[ get_rand( 7 ) ];

        for ( i = 0; i < 100; i++ )
        {
            if ( ( monaction & 0x80 ) != 0 )
                target = get_rand( 5 );
            else if ( isDefefLngRange ) /* long range flag */
                target = get_rand( 5 );
            else 
                target = get_rand( 2 );

            if ( target >= party.num )
                continue;

            if ( ( party.mem[ target ].name != "" ) 
                    && ( ( party.mem[ target ].status ) < STS.DEAD ) )
                break;
        }
        if ( i == 100 )
            return; // no target(前衛全滅とか)

        switch ( monaction )
        {
            case MON_ACT.RUN: /* run away */
                textout( "A " );
                textout( getDispNameA );
                textout( " runs away.\n" );

                turn.del;
                del;

                getChar();
                break;

            case MON_ACT.HLP: /* help */
                textout( "A " );
                textout( getDispNameA );
                textout( " calls for help.\n" );
                if ( get_rand( 2 ) == 0 )
                {
                    if ( add() )
                    {
                        textout( "  A " );
                        textout( getDispNameA );
                        textout( " appeared.\n" );
                    }
                    else
                    {
                        textout( "  but, no one responded.\n" );
                    }
                }
                else
                {
                    textout( "  but, no one responded.\n" );
                }
                getChar();
                break;
            case MON_ACT.BRT: /* breathe */
                breathe();
                break;
            case MON_ACT.ATK_ATK: /* attack no effect */
            case MON_ACT.ATK_SLS: /* slash no effect */
            case MON_ACT.ATK_TCH: /* touch no effect */
            case MON_ACT.ATK_BIT: /* bite no effect */
            case MON_ACT.ATK_ATKE: /* attack with effect */
            case MON_ACT.ATK_SLSE: /* slash with effect */
            case MON_ACT.ATK_TCHE: /* touch with effect */
            case MON_ACT.ATK_BITE: /* bite with effect */
                attack( monaction, target );
                break;
            default:
                if ( ( monaction & 0x80 ) != 0 && ! monParty.suprised )
                {
                    textout( "A " );
                    textout( getDispNameA );
                    textout( " casts a " );
                    textout( magic_data[ monaction & 0x7f ].name );
                    textout(".\n");
                    getChar();
                    if ( silenced )
                    {
                      textout( "  but, " );
                      textout( getDispNameA );
                      textout( " is silenced!\n" );
                      getChar();
                      break;
                    }
                    spell( monaction & 0x7f , target );
                }
                else
                {
                    attack( MON_ACT.ATK_ATKE, target );
      //            textout("A ");
      //            textout(&(name[0]));
      //            textout(" looks at you carefully.\n");
                }
        }
        return;
    }


    /**--------------------
       add - 仲間を呼ぶ
       --------------------*/
    bool add()
    {
        int i;
        Monster m;
        Monster mprevious;
      
        if ( team.num == 9 ) /* max mons in a team */
            return false;

        m = null;
        for ( i = 0; i < 4 * 9; i++ )
            if ( monster[ i ].def is null )
            {
                m = monster[ i ];
                break;
            }
        if( m is null )
            return false;
      
        mprevious = team.top;
        while ( mprevious.next !is null )
            mprevious = mprevious.next;

        mprevious.next = m;
        m.previous = mprevious;
        m.next = null;
        team.end = m;

        team.num++;
        team.actnum++;
        m.def = mprevious.def;


        m.maxhp    = m.def.minhp + get_rand( m.def.addhp );
        m.hp       = m.maxhp;
        m.status   = MON_STS.OK;
        m.silenced = false;

        return true;
    }

    /**--------------------
       breathe - ブレス攻撃
       --------------------*/
    void breathe()
    {
        int i, j;
        int damage = 0;

        bool reduce;
        bool resist;

        Member p;

        /**--------------------
           checkBreathEffect - ブレスエフェクトチェック
           --------------------*/
        bool checkBreathEffect()
        {
            resist = false;
            for ( j = 0; j < ( p.luk[ 0 ] + p.luk[ 1 ] ) / 3; j++ )
                if ( get_rand( 99 ) < 10 )
                    resist = true;
            return resist;
        }


        textout( "A " );
        textout( getDispNameA );
        textout( " exhales breathe.\n" );

        for ( i = 0; i < party.num; i++ )
        {

            p = party.mem[ i ];

            if ( p.hp == 0 )
                continue;

            resist = false;
            for ( j = 0 ; j < ( p.agi[ 0 ] + p.agi[ 1 ] ) / 3; j++ )
              if ( get_rand( 99 ) < 3 )
                  resist = true;

            reduce = false;
            for ( j =  0; j < ( p.luk[ 0 ] + p.luk[ 1 ] ) / 3; j++ )
              if ( get_rand( 99 ) < 6 )
                  reduce = false;

            if ( resist )
            {
                textout( "  " );
                textout( p.name );
                textout( " resists\n" );
            }
            else
            {
                damage = hp >> 1;
                if ( reduce )
                    damage /= 2;
                if ( damage == 0 && get_rand( 3 ) == 0 )
                    damage++;

                textout( "  " );
                textout( p.name );
                textout( " takes " );
                textout( damage );
                textout( " damage!\n" );
                p.hp -= damage;
                if ( p.hp <= 0 )
                {
                    p.hp = 0;
                    p.status = STS.DEAD; /* dead */
                    p.rip++;
                    textout( "    " );
                    textout( p.name );
                    textout( " is killed!\n" );
                }
                else if ( def.breef != 0 )
                {

                    /* poison effect */
                    if( def.isBreEfPoison )
                        if( !p.isDefefPoison && checkBreathEffect )
                        {
                            p.poisoned = true;
                            textout("    and is poisoned!\n");
                        }
                
                    /* sleep effect */
                    if( def.isBreEfParalize )
                        if( !p.isDefefSleep && p.status < STS.SLEEP && checkBreathEffect ) 
                        {
                            p.status = STS.SLEEP;
                            textout("    and is asleep!\n");
                        }
                
                    /* paralize effect */
                    if( def.isBreEfParalize )
                        if( !p.isDefefParalize && p.status < STS.PARALY && checkBreathEffect ) 
                        {
                            p.status = STS.PARALY;
                            textout("    and is paralized!\n");
                        }
                
                    /* stone effect */
                    if( def.isBreEfStone )
                        if( !p.isDefefStone && p.status < STS.STONED && checkBreathEffect ) 
                        {
                            p.status = STS.STONED;
                            textout("    and is petrified!\n");
                        }
                
                    /* critical effect */
                    if( def.isBreEfCritical )
                        if( !p.isDefefCritical && p.status < STS.DEAD && checkBreathEffect ) 
                        {
                            p.status = STS.DEAD;
                            p.hp = 0;
                            p.rip++;
                            textout("    and is killed instantly!\n");
                        }
                
                    /* Level drain  effect */
                    if( def.getBreEfDrainLv != 0 )
                        if( !p.isDefefDrain && p.status < STS.DEAD && checkBreathEffect ) 
                            attackLvDrain( p );

                }
            }
            party.win_disp_noreorder();
            getChar();
        }

        return;
    }

    /**--------------------
       attack - 通常攻撃
       --------------------*/
    void attack( int monaction , int target )
    {

        int i;
        int hit_times = 0, damage = 0;
        int resist; 
        int parryup = 0 ,acup = 0;
        Member mem; 

        bool checkLuck( int rate )
        {
            return ( mem.luk[ 0 ] + mem.luk[ 1 ] > get_rand( rate ) );
        }

        mem = party.mem[ target ];
        
        textout( "A " );
        textout( getDispNameA );
        switch ( monaction )
        {
            case MON_ACT.ATK_ATK:
            case MON_ACT.ATK_ATKE:
                textout( " attacks at " );
                break;
            case MON_ACT.ATK_SLS:
            case MON_ACT.ATK_SLSE:
                textout( " tries to sting " );
                break;
            case MON_ACT.ATK_TCH:
            case MON_ACT.ATK_TCHE:
                textout( " tries to touch " );
                break;
            case MON_ACT.ATK_BIT:
            case MON_ACT.ATK_BITE:
                textout( " tries to bite " );
                break;
            default:
                assert( 0 );
        }
        textout( mem.name);
        textout( "\n" );
        
        if ( mem.status != STS.OK )
            acup = AC_UP_SLEEP;
        
        if ( mem.action == ACT.PARRY  )
            parryup = AC_UP_PARRY;

        for ( i = 0; i < def.atk[ 1 ]; i++ )
        {
            if ( 20 - mem.ac[ 0 ] - mem.ac[ 1 ] + parryup - acup - party.ac
                    - def.level < get_rand( 19 ) + 1 )
            {
                hit_times++;
                damage += def.atk[ 0 ] / 2 + ( get_rand( def.atk[ 0 ] - 1 ) ) / 2 + 1;
            }
        }
        if ( hit_times == 0 )
        {
            textout( "   ... and misses\n" );
            getChar();
            return;
        }
        else
        {   // hit_times > 0
            if ( hit_times == 1 )
            {
                textout( "  and hits once for " );
            }
            else
            {
                textout( "  and hits " );
                textout( hit_times );
                textout( " times for " );
            }
            textout( damage );
            textout(" damage!\n");
            mem.hp -= damage;
            if (mem.hp <= 0)
                mem.hp = 0;
            party.win_disp_noreorder();
            getChar();

            if ( ( monaction >= MON_ACT.WITH_EFEECT_ST 
                && monaction <  MON_ACT.WITH_EFEECT_ED ) && def.atkef != 0 )
            {
                if ( def.isAtkPoison )
                { /* poison effect */
                    resist = false;
                    if ( checkLuck( 40 ) || ! mem.isDefefPoison )
                    {
                        resist = true;
                    }
                    else
                    {
                        textout( "  " );
                        textout( mem.name );
                        textout( " is poisoned!\n" );
                        mem.poisoned = true;
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                if ( def.isAtkSleep )
                { /* sleep effect */
                    resist = false;
                    if ( checkLuck( 40 ) || ! mem.isDefefSleep || mem.status >= STS.SLEEP )
                    {
                        resist = true;
                    }
                    else
                    {
                        mem.poisoned = true;
                        textout( "  " );
                        textout( mem.name );
                        textout( " is asleep!\n" );
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                if ( def.isAtkParalize )
                { /* paralize effect */
                    resist = false;
                    if ( checkLuck( 30 ) || ! mem.isDefefParalize || mem.status >= STS.PARALY )
                    {
                        resist = true;
                    }
                    else
                    {
                        mem.status = STS.PARALY;
                        textout( "  " );
                        textout( mem.name );
                        textout( " is paralized!\n" );
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                if ( def.isAtkStone )
                { /* stone effect */
                    resist = false;
                    if ( checkLuck( 30 ) || mem.isDefefStone || mem.status >= STS.STONED )
                    {
                        resist = true;
                    }
                    else
                    {
                        mem.status = STS.STONED;
                        textout( "  " );
                        textout( mem.name );
                        textout( " is petrified!\n" );
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                if ( def.isAtkCritical )
                { /* critical hit */
                    resist = false;
                    if ( checkLuck( 25 ) || mem.isDefefCritical || mem.status >= STS.DEAD )
                    {
                        resist = true;
                    }
                    else
                    {
                        mem.status = STS.DEAD;
                        mem.hp = 0;
                        mem.rip++;
                        textout( "  " );
                        textout( mem.name );
                        textout( " gets the head cut off!\n" );
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                if ( def.getAtkDrainLv != 0)
                { // drain
                    resist = false;
                    if ( checkLuck( 25 ) || mem.isDefefDrain || mem.status >= STS.ASHED )
                        resist = true;
                    else
                        attackLvDrain( mem );
                }
            }

            if ( mem.status < STS.DEAD)
            {
                if ( mem.hp <= 0 )
                {
                    mem.hp = 0;
                    mem.status = STS.DEAD; /* dead */
                    mem.rip++;
                    textout( "  " );
                    textout( mem.name );
                    textout( " is killed!\n" );
                    party.win_disp_noreorder();
                    getChar();
                }
            }
        }
        return;
    }


    /**--------------------
       attackLvDrain - レベルドレイン攻撃
       --------------------*/
    void attackLvDrain( Member mem )
    {
        textout( "  " );
        textout( mem.name );
        textout( " gets " );
        textout( def.getAtkDrainLv );
        textout( " level drained!\n" );
        if ( mem.level - def.getAtkDrainLv < 1 )
        {
            mem.status = STS.LOST;
            mem.hp = 0;
            textout( "  " );
            textout( mem.name );
            textout( " is killed!\n" );
            getChar();
        }
        else
        {
            mem.level -= def.getAtkDrainLv;
            if ( mem.level == 1 )
            {
                mem.exp = 0;
                mem.nextexp = mem.calcNextExp;
            }
            else
            {   // mem.level >= 2
                mem.level--;
                mem.nextexp = mem.calcNextExp;
                mem.exp = mem.nextexp;
                mem.level++;
                mem.nextexp = mem.calcNextExp;
            }

            mem.calcProperty;

            mem.maxhp = mem.calcHp;
            if ( mem.maxhp < mem.hp )
                mem.hp = mem.maxhp;
            if ( mem.vit[ 0 ] < 3 )
            {
                mem.status = STS.LOST;
                mem.hp = 0;
                textout( "  " );
                textout( mem.name );
                textout( " is killed!\n" );
                getChar();
            }
        }

        return;
    }


    /**--------------------
       spell - モンスター呪文
       --------------------*/
    void spell( int mag , int target )
    {
        int i, mag_hp;

        switch ( magic_data[ mag ].type )
        {
            case MAG.MONTI:     // silence
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].silenced )
                        continue;

                    textout( "  " );
                    textout( party.mem[ i ].name );
                    if ( party.mem[ i ].magdef >= get_rand( 99 ) + 1 )
                    {
                        textout( " resisted the spell.\n" );
                    }
                    else if ( get_rand( 1 ) == 0 )
                    { // possibility = 1/2
                        party.mem[ i ].silenced = true;
                        textout( " is silenced!\n" );
                    }
                    else
                    {
                        textout( " is not silenced.\n" );
                    }
                    getChar();
                }
                break;
            case MAG.LABADI:    // dying
                if ( party.mem[ target ].status >= STS.DEAD )
                    break;
                textout( "  " );
                textout( party.mem[ target ].name );
                if ( party.mem[ target ].magdef >= get_rand( 99 ) + 1 )
                {
                    textout( " resisted the spell.\n" );
                }
                else
                {
                    mag_hp = get_rand( 7 ) + 1;
                    if ( mag_hp > party.mem[ target ].hp )
                        mag_hp = party.mem[ target ].hp;
                    textout( " gets " );
                    textout( party.mem[ target ].hp - mag_hp );
                    textout( " damage!\n" );
                    party.mem[ target ].hp = mag_hp;
                }
                party.win_disp_noreorder();
                getChar();
                break;
            case MAG.BADI:      // sudden death
                if ( party.mem[ target ].status >= STS.DEAD )
                    break;
                textout( "  " );
                textout( party.mem[ target ].name );
                if ( party.mem[ target ].magdef >= get_rand( 99 ) + 1 )
                {
                    textout( " resisted the spell.\n" );
                }
                else if ( get_rand( 3 ) == 0 )
                {
                    party.mem[ target ].status = STS.DEAD;
                    party.mem[ target ].hp = 0;
                    party.mem[ target ].rip++;
                    textout( " is dead!\n" );
                    party.win_disp_noreorder();
                }
                else
                {
                    textout( " is alive.\n" );
                }
                break;
            case MAG.ATKONE: /* atk(1) */
                spell_atk( mag , target );
                break;
            case MAG.ATKGRP: /* atk(gr) */
            case MAG.ATKALL: /* atk(all) */
                spell_atk( mag, -1 );
                break;
            case MAG.ACONE: // plus player AC(one)
                party.mem[ target ].ac[ 1 ] += magic_data[ mag ].min;
                party.win_disp_noreorder();
                break;
            case MAG.ACGRP: // plus player AC(gr)
            case MAG.ACALL: // plus player AC(all)
                for ( i = 0; i < party.num; i++ )
                    party.mem[ i ].ac[ 1 ] += magic_data[ mag ].min;
                party.win_disp_noreorder;
                break;
            case MAG.KATINO: /* katino(gr) */
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status == STS.OK )
                    {
                        textout( "   " );
                        textout( party.mem[ i ].name );
                        if ( party.mem[ i ].magdef >= get_rand( 99 ) + 1 )
                        {
                            textout( " resisted the spell.\n" );
                        }
                        else if ( get_rand( 3 ) == 0 )
                        {
                            textout( " is slept.\n" );
                            party.mem[ i ].status = STS.SLEEP;
                        }
                        else
                        {
                            textout( " is not slept.\n" );
                        }
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                break;
            case MAG.MANIFO: /* manifo(gr) */
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status == STS.OK )
                    {
                        textout( "   " );
                        textout( party.mem[ i ].name );
                        if ( party.mem[ i ].magdef >= get_rand( 99 ) + 1 )
                        {
                            textout( " resisted the spell.\n" );
                        }
                        else if ( get_rand( 3 ) == 0 )
                        {
                            textout( " is held.\n" );
                            party.mem[ i ].status = STS.SLEEP;
                        }
                        else
                        {
                            textout( " is not held.\n" );
                        }
                        party.win_disp_noreorder();
                        getChar();
                    }
                }
                break;
            case MAG.KANI:   // kanito(gr)
            case MAG.MAKANI: // makanito(all)
                for ( i = 0; i < party.num; i++ )
                {
                    if ( party.mem[ i ].status >= STS.DEAD )
                        continue;

                    if ( party.mem[ i ].level < 8 )
                    {
                        textout( "   " );
                        textout( party.mem[ i ].name );
                        textout( " is suffocated.\n" );
                        party.mem[ i ].status = STS.DEAD;
                        party.mem[ i ].hp = 0;
                        party.mem[ i ].rip++;
                        party.win_disp_noreorder;
                    }
                    else
                    {
                        textout( "   " );
                        textout( party.mem[ i ].name );
                        textout( " is alive.\n" );
                    }
                    getChar();
                }
                break;
            default:
                textout( "  but, nothing happened...\n" );
                break;
        }
        return;
    }


    /**--------------------
       spell_atk - モンスター呪文攻撃
    // target=-1 : group or all
       --------------------*/
    void spell_atk( int mag, int target )
    {
        int damage;
        int i = target;

        if ( magic_data[ mag ].attr == 4 )
            return;

        /**--------------------
           spell_atk_sub - プレイヤー単位の処理
           --------------------*/
        void spell_atk_sub( Member p )
        {
            if ( p.status >= STS.DEAD )
                return;

            damage = magic_data[ mag ].min + get_rand( magic_data[ mag ].add );

            // 装備と魔法の属性によって増減 ++++++++++++++++++++++++++++++++
            switch( magic_data[ mag ].attr )
            {
                case 1: // fire
                case 3: // small fire
                    if ( p.isDefefFire ) 
                        damage /= 2;
                    break;
                case 2: // ice
                    if ( party.mem[i].isDefefIce )
                        damage /= 2;
                    break;
                case 4: // undead only
                    damage = 0;
                    break;
                default:
                    assert( 0 );
            }

            textout( "   " );
            textout( p.name );
            if ( p.magdef >= get_rand( 99 ) + 1 )
            {
                textout( " resisted the spell.\n" );
            }
            else
            {
                textout( " gets " );
                textout( damage );
                textout( " damage!\n" );
                if ( p.hp <= damage )
                { // dead
                    p.hp = 0;
                    p.status = STS.DEAD; /* dead */
                    p.rip++;
                    textout( "     " );
                    textout( p.name );
                    textout(" is killed!\n");
                }
                else
                {
                    p.hp -= damage;
                }
            }
            party.win_disp_noreorder;
            getChar();

            return;
        }

        if( target != -1 )
        {
            spell_atk_sub( party.mem[ target ] );
        }
        else
        {
            for ( i = 0; i < party.num; i++ )
                spell_atk_sub( party.mem[ i ] );
        }

        return;
    }


}

