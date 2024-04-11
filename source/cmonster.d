// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import def;
import app;
import clistdetail;
import cbattleturn;
import cmonster_team;
import cmonster_def;
import cparty;
import cmember;
import cmagic_def;


/**
  Monster - モンスター1体を管理
  */
class Monster : ListDetails!( MonsterTeamManager , Monster )
{

    MonsterDef def() { return parent.team.def; }

    // MonsterTeam parent;  // template
    // Monster next;        // template
    // Monster previous;    // templatey

    int maxhp;
    int hp;
    char status;   /* 0:ok, 1:sleep, 2:paralized, 3:stoned */
    bool silenced; // 1:silenced, 0:not
    char acplus;   // AC plus

    BattleTurn turn;



    @property
    {
        int   ac()    { assert( def !is null , "ac:def is null ");      return def.ac; }
        byte  type()  { assert( def !is null , "type:def is null ");    return def.type; }
        byte  defef() { assert( def !is null , "defef:def is null ");   return def.defef; }
        byte  magdef(){ assert( def !is null , "magdef:def is null ");  return def.magdef; }
        short level() { assert( def !is null , "level:def is null ");   return def.level; }
        int   exp()   { assert( def !is null , "exp:def is null ");     return def.exp; }
        bool  ident() { assert( def !is null , "ident:def is null ");   return parent.team.ident; }
    }


    this( MonsterTeamManager teamManager )
    {
        super( teamManager );
        return;
    }


    /*--------------------
       isExist - 設定ある？
       --------------------*/
    bool isExist()
    {
        if( hp > 0 )
            return true;
        else
            return false;
    }


    /*--------------------
       isActive - 動ける？
       --------------------*/
    bool isActive()
    {
        if( hp > 0 && status == 0 )     // ok
            return true;
        else
            return false;
    }


    /*--------------------
       init - 初期化
       --------------------*/
    void initialize()
    {
        hp = 0;
        return;
    }

    /*--------------------
       addTeam - モンスター新規追加
       --------------------*/
    void addTeam()
    {

        maxhp = def.minhp + get_rand( def.addhp );
        hp    = maxhp;

        status   = MON_STS.OK;
        silenced = false;
        acplus   = 0;

        return;

    }


    /*--------------------
       getTeamNo - モンスターNo
       --------------------*/
    int getTeamNo()
    {
        int no = -1;
        foreach( i , m ; parent )
        /* foreach( i , Monster m ; team.list ) */
        {

            if( m is this )
            {
                no = to!int( i ); 
                break;
                // 下記returnが効かずに全てのforeachが実行されてしまう？
                // opApply の不具合？opApply をネストしてるから？
                /* return to!int( i ); */   
            }
        }
        if( no == -1 )
            assert( 0 );

        return no;
    }

    /*---------
       getDispName - モンスター表示名称取得（単数）
       --------------------*/
    string getDispNameA()
    {
        return parent.team.getDispNameA;
    }
    /*--------------------
       getDispName - モンスター表示名称取得（複数確認）
       --------------------*/
    string getDispNameS()
    {
        return parent.team.getDispNameS;
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
       escape - Monster 逃げる（Monster 削除）
       --------------------*/
    void escape()
    {

        hp = 0;

        super.del();

        if ( parent.count == 0 )
            parent.team.del;

        /+  → しない。Loop中の BattleTurnを削除しちゃうので foreach が動かない
        if( turn !is null )   // monster suprised -> turn is null
            turn.del;
        +/

        return;
    }

    /**--------------------
       del - Monster 削除
       --------------------*/
    override void del()
    {

        hp = 0;

        super.del();

        if ( parent.count == 0 )
            parent.team.del;

        if( turn !is null )   // monster suprised -> turn is null
            turn.del;

        return;
    }


    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    void act()
    {
        int target;
        int i,j;
        int no;
        Member pl;
        MON_ACT monaction;
        string monactionDetails;
        MagicDef spell;


        if ( status != STS.OK )
            return;
      
        if( ! party.checkAlive )
            return;
      
        if( party.suprised ) 
        {
            monaction = def.getActionNoMagic;
            monactionDetails = "";
        }
        else
        {
            no = get_rand( 7 );
            monaction = def.action[ no ];
            monactionDetails = def.actionDetails[ no ];
            if( monaction == MON_ACT.MGC )
                spell = magic_all[ monactionDetails ];
        }


        for ( i = 0; i < 100; i++ )
        {
            if ( monaction == MON_ACT.MGC )
                target = get_rand( 5 );     // cast spell
            else if ( isDefefLngRange ) /* long range flag */
                target = get_rand( 5 );     // attack long rang 
            else 
                target = get_rand( 2 );     // attack normal

            if ( target >= party.memCount )
                continue;

            if ( ( party.mem[ target ] !is null ) 
                    && ( party.mem[ target ].name != "" ) 
                    && ( party.mem[ target ].status < STS.DEAD ) )
                break;
        }
        if ( i == 100 )
            return; // no target(前衛全滅とか)

        pl = party.mem[ target ];

        switch ( monaction )
        {
            case MON_ACT.RUN: /* run away */
                txtMessage.textout( _( "A %1 runs away.\n" ) , getDispNameA );

                // del;     // del でなく escape で削除する
                escape;
                
                getChar();
                break;

            case MON_ACT.HLP: /* help */
                txtMessage.textout( _( "A %1 calls for help.\n" ) , getDispNameA );
                if ( get_rand( 2 ) == 0 )
                {
                    if ( help() )
                        txtMessage.textout( _( "  A %1 appeared.\n" ) , getDispNameA );
                    else
                        txtMessage.textout( _( "  but, no one responded.\n" ) );
                }
                else
                {
                    txtMessage.textout( _( "  but, no one responded.\n" ) );
                }
                getChar();
                break;

            case MON_ACT.BRT:   /* breathe */
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
                attack( monaction, pl );
                break;

            case MON_ACT.MGC:   /* magic */

                if ( monParty.suprised )
                {
                    attack( MON_ACT.ATK_ATKE, pl );
                    break;
                }

                txtMessage.textout( _( "A %1 casts a %2.\n" ) , getDispNameA , spell.name );
                getChar();
                if ( silenced )
                {
                    txtMessage.textout( _( "  but, %1 is silenced!\n" ) , getDispNameA );
                    getChar();
                    break;
                }
                spell.monsterCastSpell( this , pl );
                break;

            default:    
                assert( 0 , "Error - MON_ACT:" ~ monaction.to!string );
        }
        
        return;
    }


    /**--------------------
        help - 仲間を呼ぶ
       --------------------*/
    bool help()
    {
        return parent.team.callHelp;
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

        /**--------------------
           checkBreathEffect - ブレスエフェクトチェック
           --------------------*/
        bool checkBreathEffect( Member _p )
        {
            resist = false;
            for ( j = 0; j < ( _p.luk[ 0 ] + _p.luk[ 1 ] ) / 3; j++ )
                if ( get_rand( 99 ) < 10 )
                    resist = true;
            return resist;
        }


        txtMessage.textout( _( "A %1 exhales breathe.\n" ) , getDispNameA );

        foreach( p ; party )
        {

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
                txtMessage.textout( _( "  %1 resists\n"  ), p.name );
            }
            else
            {
                damage = hp >> 1;
                if ( reduce )
                    damage /= 2;
                if ( damage == 0 && get_rand( 3 ) == 0 )
                    damage++;

                txtMessage.textout( _( "  %1 takes %2 damage!\n" ) , p.name , damage );
                p.hp -= damage;
                if ( p.hp <= 0 )
                {
                    p.hp = 0;
                    p.rip++;
                    p.status = STS.DEAD; /* dead */
                    txtMessage.textout( _( "    %1 is killed!\n" ) , p.name );
                }
                else if ( def.breef != 0 )
                {

                    /* poison effect */
                    if( def.isBreEfPoison )
                        if( !p.isDefefPoison && checkBreathEffect( p ) )
                        {
                            p.poisoned = true;
                            txtMessage.textout( _( "    and is poisoned!\n" ) );
                        }
                
                    /* sleep effect */
                    if( def.isBreEfParalize )
                        if( !p.isDefefSleep && p.status < STS.SLEEP && checkBreathEffect( p ) ) 
                        {
                            p.status = STS.SLEEP;
                            txtMessage.textout( _( "    and is asleep!\n" ) );
                        }
                
                    /* paralize effect */
                    if( def.isBreEfParalize )
                        if( !p.isDefefParalize && p.status < STS.PARALY && checkBreathEffect( p ) ) 
                        {
                            p.status = STS.PARALY;
                            txtMessage.textout( _( "    and is paralized!\n" ) );
                        }
                
                    /* stone effect */
                    if( def.isBreEfStone )
                        if( !p.isDefefStone && p.status < STS.STONED && checkBreathEffect( p ) ) 
                        {
                            p.status = STS.STONED;
                            txtMessage.textout( _( "    and is petrified!\n" ) );
                        }
                
                    /* critical effect */
                    if( def.isBreEfCritical )
                        if( !p.isDefefCritical && p.status < STS.DEAD && checkBreathEffect( p ) ) 
                        {
                            p.hp = 0;
                            p.rip++;
                            p.status = STS.DEAD;
                            txtMessage.textout( _( "    and is killed instantly!\n" ) );
                        }
                
                    /* Level drain  effect */
                    if( def.getBreEfDrainLv != 0 )
                        if( !p.isDefefDrain && p.status < STS.DEAD && checkBreathEffect( p ) ) 
                            attackLvDrain( p );

                }
            }
            party.dispPartyWindow_NoReorder();
            getChar();
        }

        return;
    }

    /**--------------------
       attack - 通常攻撃
       --------------------*/
    void attack( MON_ACT monaction , Member mem )
    {

        int i;
        int hit_times = 0, damage = 0;
        int resist; 
        int parryup = 0 ,acup = 0;

        bool checkLuck( int rate )
        {
            return ( mem.luk[ 0 ] + mem.luk[ 1 ] > get_rand( rate ) );
        }

        switch ( monaction )
        {
            case MON_ACT.ATK_ATK:
            case MON_ACT.ATK_ATKE:
                txtMessage.textout( _( "A %1 attacks at %2\n" ) , getDispNameA , mem.name );
                break;
            case MON_ACT.ATK_SLS:
            case MON_ACT.ATK_SLSE:
                txtMessage.textout( _( "A %1 tries to sting %2\n" ) , getDispNameA , mem.name );
                break;
            case MON_ACT.ATK_TCH:
            case MON_ACT.ATK_TCHE:
                txtMessage.textout( _( "A %1 tries to touch %2\n" ) , getDispNameA , mem.name );
                break;
            case MON_ACT.ATK_BIT:
            case MON_ACT.ATK_BITE:
                txtMessage.textout( _( "A %1 tries to bite %2\n" ) , getDispNameA , mem.name );
                break;
            default:
                assert( 0 );
        }
        
        if ( mem.status != STS.OK )
            acup = AC_UP_SLEEP;
        
        if ( mem.action == ACT.parry  )
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
            txtMessage.textout( _( "   ... and misses\n" ) );
            getChar();
            return;
        }
        else
        {   // hit_times > 0
            txtMessage.textout( N_( "  and hits once for %1 damage!\n" 
                       , "  and hits %2 times for %1 damage!\n" , hit_times )
                   , damage , hit_times );
            mem.hp -= damage;

            if (mem.hp <= 0)
                mem.hp = 0;
            party.dispPartyWindow_NoReorder();
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
                        txtMessage.textout( _( "  %1 is poisoned!\n" ) , mem.name );
                        mem.poisoned = true;
                        party.dispPartyWindow_NoReorder();
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
                        txtMessage.textout( _( "  %1 is asleep!\n" ) , mem.name );
                        party.dispPartyWindow_NoReorder();
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
                        txtMessage.textout( _( "  %1 is paralized!\n" ) , mem.name );
                        party.dispPartyWindow_NoReorder();
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
                        txtMessage.textout( _( "  %1 is petrified!\n" ) , mem.name );
                        party.dispPartyWindow_NoReorder();
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
                        mem.hp = 0;
                        mem.rip++;
                        mem.status = STS.DEAD;
                        txtMessage.textout( _( "  %1 gets the head cut off!\n" ) , mem.name );
                        party.dispPartyWindow_NoReorder();
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
                    mem.rip++;
                    mem.status = STS.DEAD; /* dead */
                    txtMessage.textout( _( "  %1 is killed!\n" ) , mem.name );
                    party.dispPartyWindow_NoReorder();
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
        txtMessage.textout( _( "  %1 gets %2 level drained!\n" ) , mem.name , def.getAtkDrainLv );
        if ( mem.level - def.getAtkDrainLv < 1 )
        {
            mem.hp = 0;
            mem.status = STS.LOST;
            txtMessage.textout( _( "  %1 is killed!\n" ) , mem.name );
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

            if( autosave ) appSave;

            if ( mem.vit[ 0 ] < 3 )
            {
                mem.hp = 0;
                mem.status = STS.LOST;
                txtMessage.textout( _( "  %1 is killed!\n" ) , mem.name );
                getChar();
            }
        }

        return;
    }

}

