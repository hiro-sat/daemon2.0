// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string;
import std.array;

// mysource 
import def;
import app;
import cmagic_spell;
import cmonster_encount;

class MonsterDef
{
private:
    enum BIT_ATKEF_POISON   = 0x80;
    enum BIT_ATKEF_STONE    = 0x40;
    enum BIT_ATKEF_PARALIZE = 0x20;
    enum BIT_ATKEF_SLEEP    = 0x10;
    enum BIT_ATKEF_CRITICAL = 0x8;
    enum BIT_ATKEF_DRAINLV  = 0x7;

    enum BIT_BREEF_POISON   = 0x80;
    enum BIT_BREEF_STONE    = 0x40;
    enum BIT_BREEF_PARALIZE = 0x20;
    enum BIT_BREEF_SLEEP    = 0x10;
    enum BIT_BREEF_CRITICAL = 0x8;
    enum BIT_BREEF_DRAINLV  = 0x7;

    enum BIT_DEFEF_LNG_RANGE  = 0x80;
    enum BIT_DEFEF_UNDEAD     = 0x40;
    enum BIT_DEFEF_SLEEP      = 0x20;
    enum BIT_DEFEF_CRITICAL   = 0x10;
    enum BIT_DEFEF_DRAIN      = 0x8;
    enum BIT_DEFEF_FIRE       = 0x4;
    enum BIT_DEFEF_COLD       = 0x2;
    enum BIT_DEFEF_SLP_EZY    = 0x1;

    void checkMonsterCastSpell( string name )
    {
        BaseSpell spell;
        switch( name )
        {
            case "sleep":   spell = new SpellSleep;     break;
            case "fire":    spell = new SpellFire;      break;
            case "map":     spell = new SpellMap;       break;
            case "harden":  spell = new SpellHarden;    break;
            case "flames":  spell = new SpellFlames;    break;
            case "panic":   spell = new SpellPanic;     break;
            case "xharden": spell = new SpellXharden;   break;
            case "xflames": spell = new SpellXflames;   break;
            case "spark":   spell = new SpellSpark;     break;
            case "xpanic":  spell = new SpellXpanic;    break;
            case "floatn":  spell = new SpellFloatn;    break;
            case "icestm":  spell = new SpellIcestm;    break;
            case "firstm":  spell = new SpellFirstm;    break;
            case "gpanic":  spell = new SpellGpanic;    break;
            case "vanish":  spell = new SpellVanish;    break;
            case "blizard": spell = new SpellBlizard;   break;
            case "gharden": spell = new SpellGharden;   break;
            case "burial":  spell = new SpellBurial;    break;
            case "gvanish": spell = new SpellGvanish;   break;
            case "noilatm": spell = new SpellNoilatm;   break;
            case "telept":  spell = new SpellTelept;    break;
            case "nuclear": spell = new SpellNuclear;   break;
            case "heal":    spell = new SpellHeal;      break;
            case "shild":   spell = new SpellShild;     break;
            case "curse":   spell = new SpellCurse;     break;
            case "light":   spell = new SpellLight;     break;
            case "protct":  spell = new SpellProtct;    break;
            case "mshild":  spell = new SpellMshild;    break;
            case "inspct":  spell = new SpellInspct;    break;
            case "bind":    spell = new SpellBind;      break;
            case "silenc":  spell = new SpellSilenc;    break;
            case "cure":    spell = new SpellCure;      break;
            case "identfy": spell = new SpellIdentfy;   break;
            case "xlight":  spell = new SpellXlight;    break;
            case "xshild":  spell = new SpellXshild;    break;
            case "mheal":   spell = new SpellMheal;     break;
            case "mcurse":  spell = new SpellMcurse;    break;
            case "detxify": spell = new SpellDetxify;   break;
            case "guard":   spell = new SpellGuard;     break;
            case "xheal":   spell = new SpellXheal;     break;
            case "xcurse":  spell = new SpellXcurse;    break;
            case "holyfla": spell = new SpellHolyfla;   break;
            case "breathe": spell = new SpellBreathe;   break;
            case "death":   spell = new SpellDeath;     break;
            case "bless":   spell = new SpellBless;     break;
            case "dyng":    spell = new SpellDyng;      break;
            case "ndlstm":  spell = new SpellNdlstm;    break;
            case "return":  spell = new SpellReturn;    break;
            case "scourge": spell = new SpellScourge;   break;
            case "grace":   spell = new SpellGrace;     break;
            case "healer":  spell = new SpellHealer;    break;
            default: assert( 0 );
        }

        assert( spell.checkMonsterCastSpell , "Error Monster cmagic_spell : " ~ name );
        return;
    }

public:
    int  id;
    string name;
    string unname; /* unrecognized name */
    byte minnum;
    byte addnum;

    short minhp;
    short addhp;
    int exp;
    int ac;
    short[ 2 ] atk; /* 0:dmg, 1:cnt */
    byte str;
    byte agi;

    byte atkef; /* bit7:poison, bit6:stone, bit5:paralize */
                /* bit4:sleep, bit3:critical, bit2-0:drain level */
    bool isAtkPoison()
        { return ( ( atkef & BIT_ATKEF_POISON ) != 0 ); }
    bool isAtkStone()
        { return ( ( atkef & BIT_ATKEF_STONE ) != 0 ); }
    bool isAtkParalize()
        { return ( ( atkef & BIT_ATKEF_PARALIZE ) != 0 ); }
    bool isAtkSleep()
        { return ( ( atkef & BIT_ATKEF_SLEEP ) != 0 ); }
    bool isAtkCritical()
        { return ( ( atkef & BIT_ATKEF_CRITICAL ) != 0 ); }
    int getAtkDrainLv()
        { return ( atkef & BIT_ATKEF_DRAINLV ); }


    byte breef; /* bit7:poison, bit6:stone, bit5:paralize */
                /* bit4:sleep, bit3:critical, bit2-0:drain level */
    bool isBreEfPoison()
        { return ( ( breef & BIT_BREEF_POISON     ) != 0 );  }
    bool isBreEfSleep()
        { return ( ( breef & BIT_BREEF_SLEEP      ) != 0 );  }
    bool isBreEfParalize()
        { return ( ( breef & BIT_BREEF_PARALIZE   ) != 0 );  }
    bool isBreEfStone()
        { return ( ( breef & BIT_BREEF_STONE      ) != 0 );  }
    bool isBreEfCritical()
        { return ( ( breef & BIT_BREEF_CRITICAL   ) != 0 );  }
    int getBreEfDrainLv()
        { return ( breef & BIT_BREEF_DRAINLV ); }


    byte defef; /* bit3:drain, bit2:fire, bit1:cold, bit0:sleep easily */
                // bit5:sleep(anti), bit4:critical
                /* bit6=1:undead, bit7=1:long range */
    bool isDefefLngRange()
        { return ( ( defef & BIT_DEFEF_LNG_RANGE  ) != 0 );  }
    bool isDefefUndead()
        { return ( ( defef & BIT_DEFEF_UNDEAD     ) != 0 );  }
    bool isDefefSleep()
        { return ( ( defef & BIT_DEFEF_SLEEP      ) != 0 );  }
    bool isDefefCritical()
        { return ( ( defef & BIT_DEFEF_CRITICAL   ) != 0 );  }
    bool isDefefDrain()
        { return ( ( defef & BIT_DEFEF_DRAIN      ) != 0 );  }
    bool isDefefFire()
        { return ( ( defef & BIT_DEFEF_FIRE       ) != 0 );  }
    bool isDefefCold()
        { return ( ( defef & BIT_DEFEF_COLD       ) != 0 );  }
    bool isDefefSlpEzy()
        { return ( ( defef & BIT_DEFEF_SLP_EZY    ) != 0 );  }


    byte hpplus;  /* +HP/turn */
    byte magdef; /* magic defend % */
    byte lakanidef; /* lakanito defend % */
    short level;
    byte budratio; /* buddy ratio % */
    short buddy;  /* buddy monster number */
    byte type;


    int mingp; /* min GP */
    int addgp; /* additional GP */
    byte[ 3 ] itemratio; /* item1[%] */
    short[ 3 ] itemmin;
    short[ 3 ] itemmax;
    MON_ACT[ 8 ] action; /* possible action */
                    /* for example, 0-3:atk, 4-5:run, 6-7:LABADI */
                    /*   -> attack 50%, run away 25%, LABADI 25% */
    /* 0:none, 1:run, 2:call, 3:breath, 4:magic */
    /* 10-:atk(no effect), 10:attack, 11:slash, 12:touch, 13:bite, etc.*/
    /* 20-:atk(effect) */
    string[ 8 ] actionDetails;  // spell

    MON_ACT[] actionNoMagic;   // suprised

    
    /*--------------------
       this - コンストラクタ
       data : readItem のデータ 
       --------------------*/
    this( char[][] data )
    {

        int i = 0;  // i = 0 : item ID

        id         = to!int( data[ i++ ] );

        name   = to!string( data[ i++ ] );
        unname = to!string( data[ i++ ] );

        minnum = to!byte( data[ i++ ] );
        addnum = to!byte( data[ i++ ] );
    
        minhp  = cast(short) to!int( data[ i++ ] );
        addhp  = cast(short) to!int( data[ i++ ] );
        exp    = to!int( data[ i++ ] );
        ac     = to!int( data[ i++ ] );
        atk[0] = cast(short) to!int( data[ i++ ] );
        atk[1] = cast(short) to!int( data[ i++ ] );
        str    = to!byte( data[ i++ ] );
        agi    = to!byte( data[ i++ ] );
    
        atkef = cast( byte ) parse!(int)( data[ i++ ], 16);
        breef = cast( byte ) parse!(int)( data[ i++ ], 16);
        defef = cast( byte ) parse!(int)( data[ i++ ], 16);

        hpplus    = to!byte( data[ i++ ] );
        magdef    = to!byte( data[ i++ ] );
        lakanidef = to!byte( data[ i++ ] );
        level     = cast(short) to!int( data[ i++ ] );
        budratio  = to!byte( data[ i++ ] );
        buddy     = cast(short) to!int( data[ i++ ] );
        type      = to!byte( data[ i++ ] );
    
        mingp        = to!int( data[ i++ ] );
        addgp        = to!int( data[ i++ ] );
        itemratio[0] = to!byte( data[ i++ ] );
        itemmin[0]   = cast(short) to!int( data[ i++ ] );
        itemmax[0]   = cast(short) to!int( data[ i++ ] );

        itemratio[1] = to!byte( data[ i++ ] );
        itemmin[1]   = cast(short) to!int( data[ i++ ] );
        itemmax[1]   = cast(short) to!int( data[ i++ ] );

        itemratio[2] = to!byte( data[ i++ ] );
        itemmin[2]   = cast(short) to!int( data[ i++ ] );
        itemmax[2]   = cast(short) to!int( data[ i++ ] );
    
        action[0]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[0]    = to!string( data[ i++ ] );
        assert( ( action[0] != MON_ACT.MGC ) ||
                ( action[0] == MON_ACT.MGC && actionDetails[0] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[0] ~ "'" );
        
        action[1]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[1]    = to!string( data[ i++ ] );
        assert( ( action[1] != MON_ACT.MGC ) ||
                ( action[1] == MON_ACT.MGC && actionDetails[1] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[1] ~ "'" );

        action[2]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[2]    = to!string( data[ i++ ] );
        assert( ( action[2] != MON_ACT.MGC ) ||
                ( action[2] == MON_ACT.MGC && actionDetails[2] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[2] ~ "'" );

        action[3]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[3]    = to!string( data[ i++ ] );
        assert( ( action[3] != MON_ACT.MGC ) ||
                ( action[3] == MON_ACT.MGC && actionDetails[3] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[3] ~ "'" );

        action[4]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[4]    = to!string( data[ i++ ] );
        assert( ( action[4] != MON_ACT.MGC ) ||
                ( action[4] == MON_ACT.MGC && actionDetails[4] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[4] ~ "'" );

        action[5]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[5]    = to!string( data[ i++ ] );
        assert( ( action[5] != MON_ACT.MGC ) ||
                ( action[5] == MON_ACT.MGC && actionDetails[5] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[5] ~ "'" );

        action[6]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[6]    = to!string( data[ i++ ] );
        assert( ( action[6] != MON_ACT.MGC ) ||
                ( action[6] == MON_ACT.MGC && actionDetails[6] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[6] ~ "'" );

        action[7]           = cast(MON_ACT) to!int( data[ i++ ] );
        actionDetails[7]    = to!string( data[ i++ ] );
        assert( ( action[7] != MON_ACT.MGC ) ||
                ( action[7] == MON_ACT.MGC && actionDetails[7] in magic_all  )
             , "Error Monster Spell '" ~ actionDetails[7] ~ "'" );



        foreach( a ; action )
            if( a != MON_ACT.MGC )
            {
                actionNoMagic.length ++;
                actionNoMagic.back = a;
            }
        assert( actionNoMagic.length > 0 , "monster data no action without magic." );

        // encount table
        string[] tbl_id;
        MonsterEncountTable table;
        tbl_id = to!string( data[ i++ ] ).chop.split( "," );

        foreach( t ;tbl_id )
        {
            if( t in encountTable )
            {
                table = encountTable[ t ];
            }
            else
            {
                table = new MonsterEncountTable( t );
                encountTable[ t ] = table;
            }
            table.add( id );
        }

        return;
    }

    /*--------------------
       marksUp - marks + 1
       --------------------*/
    void marksUp()
    {
        monstermarks[ id ]++;
        if (monstermarks[ id ] > 9999999  )
            monstermarks[ id ] = 9999999 ;
        return;
    }

    /*--------------------
       getActionNoMagic - サプライズ時のアクション ※魔法なし
       --------------------*/
    MON_ACT getActionNoMagic()
    {
         return actionNoMagic[ get_rand( to!int( actionNoMagic.length - 1 ) ) ];
    }


}
