// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : capitalize;
import std.conv;

// mysource 
import def;
import cmagic_spell;
import cmember;
import cmonster;


class MagicDef
{
private:
    BaseSpell       spell;

    void setCastSpell()
    {
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
            default: assert( 0 , "Error - not exists :" ~ name );
        }

        spell.magicDef = this;
        return;
    }


public:
    @property
    {

        static int[ 7 ] magLvSpellCount;      // level別index作成用
        static int[ 7 ] priLvSpellCount;      // level別index作成用

        TYPE_MAGIC      Class;
        int level;
        int index;
        string name;
        TYPE_MAGIC_CAMPMODE     camp; /* 0:can't,1:no target,2:sel mem */
        TYPE_MAGIC_BATTLEMODE   batl; /* 0:can't,1:no target,2:sel mem,3:sel mon */
        TYPE_MAGIC_ATTRIBUTE    attr; /* 0:no,1:fire,2:ice,3:small fire,4:undead only */
        short min;
        short add;
    }

    /*--------------------
       this - コンストラクタ
       data : readItem のデータ 
       --------------------*/
    this( char[][] data )
    {
        int i = 0;

        /* id        = to!int( data[ i++ ] ); */
        Class     = cast( TYPE_MAGIC ) to!int( data[ i++ ] );
        level     = to!int( data[ i++ ] ) - 1;
        if( Class == TYPE_MAGIC.mage )
            index     = magLvSpellCount[ level ] ++;
        else
            index     = priLvSpellCount[ level ] ++;
        name      = to!string( data[ i++ ] );

        camp      = cast( TYPE_MAGIC_CAMPMODE ) to!byte( data[ i++ ] );
        batl      = cast( TYPE_MAGIC_BATTLEMODE ) to!byte( data[ i++ ] );
        attr      = cast( TYPE_MAGIC_ATTRIBUTE ) to!byte( data[ i++ ] );
        min       = to!short( data[ i++ ] );
        add       = to!short( data[ i++ ] );

        setCastSpell();

    }

    // 呪文を唱える
    int castSpell( Member p , bool camp = true )
    {
        return spell.castSpell( p , camp );
    }

    void castInCamp( Member p )     { castSpell( p , true ); }
    int castInBattle( Member p  )   { return castSpell( p , false ); }

    // モンスター呪文唱える
    void monsterCastSpell( Monster m , Member p )
    {
        spell.monsterCastSpell( m , p );
    }

}
