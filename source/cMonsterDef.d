// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string;

// mysource 
import def;

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
    byte[ 8 ] action; /* possible action */
                    /* for example, 0-3:atk, 4-5:run, 6-7:LABADI */
                    /*   -> attack 50%, run away 25%, LABADI 25% */
    /* 0:none, 1:run, 2:call, 3:breath */
    /* 10-:atk(no effect), 10:attack, 11:slash, 12:touch, 13:bite, etc.*/
    /* 20-:atk(effect) */
    /* bit7=1 as spell# */

    
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
    
        action[0]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[1]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[2]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[3]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[4]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[5]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[6]    = cast( byte ) parse!(int)( data[ i++ ], 16);
        action[7]    = cast( byte ) parse!(int)( data[ i++ ], 16);

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



}
